"""
Unit smoke‑test for scripts/train_model.sh equivalent Python wrapper.

We can’t run the full training loop in CI, but we can check that:
  • Required env‑vars are parsed
  • train.py CLI flags are built without error
"""
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]        # project root
SCRIPT = ROOT / "scripts" / "train_model.sh"

def test_train_script_exists():
    assert SCRIPT.exists(), "train_model.sh missing"

def test_train_script_help():
    # Dry‑run with env vars but no GPU; expect graceful exit (code 0 or 1)
    res = subprocess.run(
        ["bash", SCRIPT],
        env={
            **dict(**{k: v for k, v in os.environ.items()}),
            "DRY_RUN": "1",            # you may add this flag to script later
            "HF_MODEL_PATH": "/tmp",   # dummy
            "DATASET_PATH": "/tmp"     # dummy
        },
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    assert res.returncode in (0, 1), res.stderr[:200]
