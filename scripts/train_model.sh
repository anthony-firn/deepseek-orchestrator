#!/usr/bin/env bash
#
# scripts/train_model.sh
# --------------------------------------------
# One‑shot launcher for QLoRA / full‑parameter
# fine‑tuning of DeepSeek‑R1‑671B.
#
#   ./train_model.sh                        # uses defaults
#   HF_MODEL_PATH=./models/checkpoints ...  # override paths
#
# ────────────────────────────────────────────

set -euo pipefail
IFS=$'\n\t'

# ---------- Config overridables (env or defaults) ----------
PROJECT_NAME=${PROJECT_NAME:-"deepseek-orchestrator"}
EXP_DIR=${EXP_DIR:-"$HOME/${PROJECT_NAME}_experiments"}
HF_MODEL_PATH=${HF_MODEL_PATH:-"$HOME/hf_models/deepseek-r1-671b"}
DATASET_PATH=${DATASET_PATH:-"$HOME/datasets/custom"}
CONFIG_YAML=${CONFIG_YAML:-"$(dirname "$0")/../configs/training_config.yaml"}

# ---------- Runtime options ----------
N_NODES=${N_NODES:-1}
GPUS_PER_NODE=${GPUS_PER_NODE:-8}
BATCH_SIZE=${BATCH_SIZE:-1}

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RUN_NAME=${RUN_NAME:-"dsr1-finetune-${TIMESTAMP}"}

echo "─────────────────────────────────────────────"
echo "🚀  DeepSeek‑R1 Fine‑Tune Launcher"
echo "Project     : $PROJECT_NAME"
echo "Run name    : $RUN_NAME"
echo "Exp dir     : $EXP_DIR"
echo "Model (base): $HF_MODEL_PATH"
echo "Dataset     : $DATASET_PATH"
echo "Config YAML : $CONFIG_YAML"
echo "Nodes x GPU : ${N_NODES} x ${GPUS_PER_NODE}"
echo "Batch size  : $BATCH_SIZE"
echo "─────────────────────────────────────────────"
sleep 2

# ---------- Create experiment directory ----------
RUN_DIR="$EXP_DIR/$RUN_NAME"
mkdir -p "$RUN_DIR"/{logs,checkpoints}

# ---------- Activate environment ----------
# (Assumes conda env named 'deepseek' was created in setup_env.sh)
source "$HOME/miniconda/etc/profile.d/conda.sh"
conda activate deepseek

# ---------- Launch training ----------
cd "$HOME/DeepSeek-671B-SFT-Guide"  || {
  echo "❌  Training repo not found!"; exit 1; }

python3 train.py \
  --model_path            "$HF_MODEL_PATH" \
  --data_path             "$DATASET_PATH" \
  --output_dir            "$RUN_DIR/checkpoints" \
  --logging_dir           "$RUN_DIR/logs" \
  --config_file           "$CONFIG_YAML" \
  --num_nodes             "$N_NODES" \
  --gpus_per_node         "$GPUS_PER_NODE" \
  --per_device_train_batch_size "$BATCH_SIZE" \
  --run_name              "$RUN_NAME"

echo "✅  Training run complete."
echo "   Checkpoints: $RUN_DIR/checkpoints"
echo "   Logs       : $RUN_DIR/logs"
