#!/usr/bin/env bash
#
# scripts/deploy_model.sh
# -----------------------------------------------------------
# Spin up a vLLM server for a fine‑tuned (or base) DeepSeek model.
#
#  Usage:
#     ./deploy_model.sh                        # serve latest checkpoint
#     MODEL_PATH=/path/to/alt_checkpoint ./deploy_model.sh
#     PORT=9000 BACKEND=gpu ./deploy_model.sh  # custom options
#
#  Environment variables (all optional):
#     MODEL_PATH  – directory with model weights/tokenizer (default: latest ckpt)
#     PORT        – port to expose (default 8000)
#     HOST        – bind address (default 0.0.0.0)
#     BACKEND     – "gpu" or "cpu" (default gpu)
#     MAX_BATCH   – max batch size (default 16)
#
#  Logs stream to stdout; use systemd / tmux / nohup as desired.
# -----------------------------------------------------------
set -euo pipefail
IFS=$'\n\t'

PROJECT_NAME=${PROJECT_NAME:-"deepseek-orchestrator"}
EXP_DIR=${EXP_DIR:-"$HOME/${PROJECT_NAME}_experiments"}
PORT=${PORT:-8000}
HOST=${HOST:-"0.0.0.0"}
BACKEND=${BACKEND:-"gpu"}
MAX_BATCH=${MAX_BATCH:-16}

# Pick the latest checkpoint if MODEL_PATH not provided
if [[ -z "${MODEL_PATH:-}" ]]; then
  MODEL_PATH=$(ls -dt "$EXP_DIR"/*/checkpoints 2>/dev/null | head -n1 || true)
  if [[ -z "$MODEL_PATH" ]]; then
    echo "❌  No checkpoints found in $EXP_DIR – specify MODEL_PATH explicitly."
    exit 1
  fi
fi

echo "─────────────────────────────────────────────"
echo "🚀  vLLM Deployment"
echo "Model path  : $MODEL_PATH"
echo "Bind        : $HOST:$PORT"
echo "Backend     : $BACKEND"
echo "Max batch   : $MAX_BATCH"
echo "─────────────────────────────────────────────"
sleep 1

# ── activate Conda env ───────────────────────
source "$HOME/miniconda/etc/profile.d/conda.sh"
conda activate deepseek

# ── install vllm if missing ──────────────────
if ! python -c "import vllm" &>/dev/null; then
  echo "🔧  Installing vLLM ..."
  pip install --upgrade "vllm>=0.3.2"
fi

# ── launch server ────────────────────────────
python -m vllm.entrypoints.openai.api_server \
  --model             "$MODEL_PATH" \
  --host              "$HOST" \
  --port              "$PORT" \
  --backend           "$BACKEND" \
  --max-batch-tokens  "$MAX_BATCH" \
  --download-dir      "$HOME/hf_models" \
  --tensor-parallel-size $(( $(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l) )) \
  "$@"

# Notes:
# • --tensor-parallel-size auto‑sets to GPU count; adjust for multi‑node with vLLM’s distributed launcher.
# • Add --trust-remote-code if your model repo requires custom code.
# • Pass extra CLI flags to vLLM by appending them after "$@".

