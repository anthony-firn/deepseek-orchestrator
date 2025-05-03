"""
Integration test: Terraform init/plan
Ensures that Terraform configuration in ./terraform still parses with the
defaults or a provided tfvars file (e.g. CI secrets).
"""
import subprocess
from pathlib import Path

TERRAFORM_DIR = Path(__file__).resolve().parents[2] / "terraform"

def terraform_cmd(*args):
    """Run a Terraform subprocess and return CompletedProcess."""
    return subprocess.run(
        ["terraform", *args],
        cwd=TERRAFORM_DIR,
        check=False,
        text=True,
        capture_output=True,
    )

def test_terraform_init_plan():
    # terraform init (idempotent)
    init = terraform_cmd("init", "-input=false", "-no-color")
    assert init.returncode == 0, f"tf init failed:\n{init.stderr[:400]}"

    # terraform validate
    val = terraform_cmd("validate", "-no-color")
    assert val.returncode == 0, f"tf validate failed:\n{val.stderr[:400]}"

    # terraform plan (no apply) – uses refresh=false so CI doesn’t need AWS creds
    plan = terraform_cmd(
        "plan", "-input=false", "-refresh=false", "-no-color", "-lock=false"
    )
    assert plan.returncode == 0, f"tf plan failed:\n{plan.stderr[:400]}"
