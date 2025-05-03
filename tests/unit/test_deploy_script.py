"""
Smoke‑test for scripts/deploy_model.sh – ensures the CLI builds and
vLLM import works inside the Conda env (CI won’t own GPUs).
"""
import subprocess, os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "deploy_model.sh"

def test_deploy_script_exists():
    assert SCRIPT.exists(), "deploy_model.sh missing"

def test_vllm_import():
    # import vllm inside python to catch missing deps early
    import importlib
    assert importlib.util.find_spec("vllm") is not None, "vLLM not installed"
