#!/usr/bin/env bash
#
# scripts/distill_model.sh
# -----------------------------------------------------------
# Distil a large "teacher" checkpoint into a smaller student
# (e.g., DeepSeek‑R1‑70B or DeepSeek‑R1‑7B).  Uses KL loss
# on matched prompts with vLLM sampling for teacher logits.
#
#   ./distill_model.sh                           # defaults
#   TEACHER=/ckpts/671b STUDENT=deepseek-70b \
#        OUTPUT=/ckpts/70b-distil ./distill_model.sh
#
# Environment variables (override as needed):
#   TEACHER_PATH   – directory of teacher checkpoint
#   STUDENT_BASE   – HF hub ID or local dir of student init
#   DATASET_PATH   – prompts only dataset (jsonl, key=text)
#   OUTPUT_DIR     – where distilled student checkpoints go
#   BATCH_SIZE     – per‑GPU batch (default 2)
#   EPOCHS         – training epochs (default 1)
#
# Requires: vLLM running locally on $TEACHER_PORT (defaults 8001)
# -----------------------------------------------------------
set -euo pipefail
IFS=$'\n\t'

PROJECT_NAME=${PROJECT_NAME:-"deepseek-orchestrator"}
EXP_DIR=${EXP_DIR:-"$HOME/${PROJECT_NAME}_experiments"}
TEACHER_PORT=${TEACHER_PORT:-8001}

TEACHER_PATH=${TEACHER_PATH:-"$(ls -dt $EXP_DIR/*/checkpoints 2>/dev/null | head -n1)"}
STUDENT_BASE=${STUDENT_BASE:-"deepseek-ai/deepseek-llm-7b-base"}
DATASET_PATH=${DATASET_PATH:-"$HOME/datasets/prompts_only.jsonl"}
OUTPUT_DIR=${OUTPUT_DIR:-"$EXP_DIR/distilled-$(basename $STUDENT_BASE)-$(date +%Y%m%d-%H%M%S)"}

BATCH_SIZE=${BATCH_SIZE:-2}
EPOCHS=${EPOCHS:-1}

echo "─────────────────────────────────────────────"
echo "🧪  Distillation Launcher"
echo "Teacher ckpt : $TEACHER_PATH"
echo "Student base : $STUDENT_BASE"
echo "Dataset      : $DATASET_PATH"
echo "Output dir   : $OUTPUT_DIR"
echo "Batch size   : $BATCH_SIZE"
echo "Epochs       : $EPOCHS"
echo "─────────────────────────────────────────────"
sleep 2

mkdir -p "$OUTPUT_DIR"/{logs,checkpoints}

# ── activate conda env ───────────────────────
source "$HOME/miniconda/etc/profile.d/conda.sh"
conda activate deepseek

# ── ensure dependencies ──────────────────────
pip install -qU transformers trl datasets vllm accelerate bitsandbytes

# ── launch teacher vLLM server (background) ──
if ! lsof -i :"$TEACHER_PORT" &>/dev/null; then
  echo "🚀  Starting teacher vLLM server on port $TEACHER_PORT ..."
  python -m vllm.entrypoints.openai.api_server \
      --model "$TEACHER_PATH" \
      --host 127.0.0.1 \
      --port "$TEACHER_PORT" \
      --backend gpu \
      --max-batch-tokens 4096 \
      --tensor-parallel-size $(nvidia-smi -L | wc -l) \
      --download-dir "$HOME/hf_models" \
      --trust-remote-code true \
      >"$OUTPUT_DIR/teacher_vllm.log" 2>&1 &
  TEACHER_PID=$!
  sleep 10
else
  echo "ℹ️  Teacher vLLM already running."
  TEACHER_PID=""
fi

# ── run distillation script ───────────────────
python <<'PY'
import os, json, time, random, requests, pathlib, math
from datasets import load_dataset, Dataset
from transformers import AutoModelForCausalLM, AutoTokenizer, TrainingArguments
from trl.trainer import DPOTrainer

teacher_port = int(os.environ["TEACHER_PORT"])
teacher_url  = f"http://127.0.0.1:{teacher_port}/v1/chat/completions"
student_id   = os.environ["STUDENT_BASE"]
out_dir      = os.environ["OUTPUT_DIR"]
batch_size   = int(os.environ["BATCH_SIZE"])
epochs       = int(os.environ["EPOCHS"])
dataset_file = os.environ["DATASET_PATH"]

print("🔍 Loading student model/tokenizer …")
tokenizer = AutoTokenizer.from_pretrained(student_id, trust_remote_code=True)
model     = AutoModelForCausalLM.from_pretrained(
              student_id, torch_dtype="auto", trust_remote_code=True)

print("📚 Loading prompts dataset …")
ds = load_dataset("json", data_files=dataset_file, split="train")

def get_teacher_response(prompt):
    payload = {"model":"teacher","messages":[{"role":"user","content":prompt}],
               "temperature":0.2, "max_tokens":256}
    for _ in range(3):
        try:
            r = requests.post(teacher_url, json=payload, timeout=120)
            return r.json()["choices"][0]["message"]["content"]
        except Exception as e:
            print("retry teacher call", e); time.sleep(2)
    return ""

records = []
print("💬 Querying teacher for responses …")
for example in ds:
    prompt = example["text"]
    answer = get_teacher_response(prompt)
    if answer:
        records.append({"prompt":prompt, "response":answer})

student_ds = Dataset.from_list(records).train_test_split(test_size=0.05)

print("⚙️  Setting training args …")
args = TrainingArguments(
    per_device_train_batch_size=batch_size,
    per_device_eval_batch_size=batch_size,
    num_train_epochs=epochs,
    logging_steps=50,
    learning_rate=1e-5,
    output_dir=out_dir + "/checkpoints",
    fp16=True,
    save_strategy="epoch",
    report_to="none"
)

print("🎯  Starting DPOTrainer …")
trainer = DPOTrainer(
    model,
    ref_model=None,
    args=args,
    beta=0.1,
    train_dataset=student_ds["train"],
    eval_dataset=student_ds["test"],
    tokenizer=tokenizer,
    text_column="prompt",
    response_column="response"
)
trainer.train()

trainer.save_model(out_dir + "/checkpoints/final")
tokenizer.save_pretrained(out_dir + "/checkpoints/final")
print("✅  Distillation finished. Saved to", out_dir)
PY

# ── shutdown teacher server if we started it ──
if [[ -n "${TEACHER_PID}" ]]; then
  echo "🛑  Stopping teacher vLLM (PID $TEACHER_PID)…"
  kill "$TEACHER_PID"
fi

echo "✅  Distillation artifacts saved in $OUTPUT_DIR"
