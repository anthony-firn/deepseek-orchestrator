[![CI](https://github.com/anthony-firn/deepseek-orchestrator/actions/workflows/test.yml/badge.svg)](https://github.com/anthony-firn/deepseek-orchestrator/actions/workflows/test.yml)

# DeepSeek Orchestrator

> **DeepSeek Orchestrator** is an open‑source framework for fine‑tuning, distilling, and serving DeepSeek‑R models (671 B and distilled variants) on‑demand.  
> It combines **Terraform** (infrastructure‑as‑code), **vLLM** (fast inference), and a GitHub **CI/CD** pipeline with aggressive caching and cost‑controls (spot, hibernation).

---

## ✨ Features

| Category       | Highlights                                                                                 |
| -------------- | ------------------------------------------------------------------------------------------ |
| **Training**   | QLoRA / full‑parameter fine‑tuning via [DeepSeek‑671B‑SFT‑Guide](https://github.com/ScienceOne-AI/DeepSeek-671B-SFT-Guide) |
| **Distillation** | KL‑style student models (70 B / 7 B) with `scripts/distill_model.sh`                        |
| **Serving**    | vLLM OpenAI‑compatible endpoint, tensor‑parallel, autoscaling                              |
| **Cost**       | EC2 hibernation, spot instances, idle watchdog                                             |
| **IaC**        | Terraform modules for VPC, GPU, storage; provider/module caching                           |
| **CI/CD**      | GitHub Actions workflow with pip + Terraform caches, conditional `plan`, test badge        |

---

## 🗂️ Project Tree (abridged)

```text
deepseek-orchestrator/
├── .github/
│   └── workflows/test.yml    # CI pipeline
├── terraform/                # root module + env overrides
├── scripts/                  # setup, train, distill, deploy
├── configs/                  # YAML configs for training/serving
├── tests/                    # unit + integration tests
└── docs/                     # architecture & usage docs
```

---

## 🚀 Quick Start

### 1 · Clone & enter

```bash
git clone https://github.com/anthony-firn/deepseek-orchestrator.git
cd deepseek-orchestrator
```

### 2 · Add CI secret **`CI_TFVARS`**

<details><summary>Example `CI_TFVARS` content</summary>

```hcl
key_pair_name = "my-ssh-key"
aws_region    = "us-east-1"
vpc_cidr      = "10.0.0.0/16"
subnet_cidr   = "10.0.1.0/24"
```
</details>

*Go to GitHub → Settings → Secrets → Actions → New repository secret → `CI_TFVARS`.*

### 3 · Push & watch CI

The CI pipeline will:

1. Cache Python dependencies & Terraform plugins/modules  
2. Run unit tests  
3. Auto‑format Terraform (`terraform fmt`)  
4. Write `terraform/ci.tfvars` from `CI_TFVARS`  
5. Run `terraform validate` & `terraform plan -var-file=ci.tfvars` (skipped with warning if secret absent)  
6. Optionally, run live inference tests if `VLLM_ENDPOINT_URL` is set

### 4 · Provision Dev Environment

```bash
cd terraform/environments/dev
terraform init
terraform apply -var-file=../../example.dev.tfvars
```

### 5 · Fine‑Tune & Serve

```bash
ssh ubuntu@<gpu-ip>           # or use SSM Session Manager
./scripts/setup_env.sh
./scripts/train_model.sh      # fine‑tune 671 B
./scripts/distill_model.sh    # optional student models
./scripts/deploy_model.sh     # launch vLLM server on :8000
```

---

## 🧪 Testing Matrix

| Layer               | Location                                           |
| ------------------- | -------------------------------------------------- |
| **Unit tests**      | `tests/unit/*`  (pytest)                           |
| **Terraform fmt**   | Auto‑format in CI                                 |
| **Terraform plan**  | CI when `CI_TFVARS` present                        |
| **Live inference**  | CI when `VLLM_ENDPOINT_URL` present                |

---

## 📊 Monitoring & Cost Controls

* AWS CloudWatch dashboards & alarms (CPU, GPU, VRAM)  
* Idle watchdog (`scripts/monitor_resources.sh`) that hibernates after inactivity  
* Spot instances & hibernation flag in Terraform modules  

---

## 🤝 Contributing

1. Fork → feature branch → PR  
2. Run `pre-commit` (Black, Flake8, Terraform fmt)  
3. Ensure CI passes before merging  

---

## 📜 License

MIT License. See [LICENSE](LICENSE) for details.

---

*DeepSeek is a trademark of its respective owners; this repository is community‑maintained.*
