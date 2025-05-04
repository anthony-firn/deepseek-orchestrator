[![CI Status](https://github.com/anthony-firn/deepseek-orchestrator/actions/workflows/test.yml/badge.svg)](https://github.com/anthony-firn/deepseek-orchestrator/actions/workflows/test.yml)

# DeepSeek Orchestrator

**DeepSeek Orchestrator** is an open-source, fully automated framework for fine-tuning, distilling, and serving DeepSeek R1 671B and its distilled variants on-demand in the cloud. It leverages Terraform for infrastructure provisioning, vLLM for efficient model serving, and integrates cost-optimization (hibernation, spot instances) and caching strategies to minimize runtime and cost.

## 🚀 Features

* **Full Parameter Fine-Tuning**: Uses the [ScienceOne-AI/DeepSeek-671B-SFT-Guide](https://github.com/ScienceOne-AI/DeepSeek-671B-SFT-Guide) for QLoRA/full-parameter tuning.  
* **Model Distillation**: Creates smaller student models (7B, 70B) via KL-distillation scripts.  
* **On-Demand Serving**: Deploys models with vLLM, auto-scaling behind the scenes.  
* **Cost Optimization**: EC2 hibernation, spot instances, and resource monitoring.  
* **Infrastructure as Code**: Terraform modules for networking, compute, storage; caching for Terraform providers and Python deps.

## 🗂️ Project Structure

deepseek-orchestrator/ ├── README.md ├── LICENSE ├── .gitignore ├── .github/ │   └── workflows/ │       └── test.yml          # CI/CD workflow (caches deps, runs tests & terraform) ├── terraform/ │   ├── main.tf │   ├── variables.tf │   ├── outputs.tf │   └── environments/ │       ├── dev/ │       ├── staging/ │       └── prod/ ├── scripts/ │   ├── setup_env.sh │   ├── train_model.sh │   ├── distill_model.sh │   ├── deploy_model.sh │   └── monitor_resources.sh ├── configs/ │   ├── training_config.yaml │   ├── distillation_config.yaml │   └── deployment_config.yaml ├── tests/ │   ├── unit/ │   └── integration/ └── docs/ ├── architecture.md └── usage.md

## 🛠️ Getting Started

### Prerequisites

- **AWS Account** with IAM permissions for EC2, VPC, S3, etc.  
- **Terraform** v1.4+ and **Python** 3.10+.  
- **GitHub Actions** enabled on this repo.

### 1. Clone & Configure

```bash
git clone https://github.com/anthony-firn/deepseek-orchestrator.git
cd deepseek-orchestrator

2. Secrets Setup

CI: CI_TFVARS

Create a single GitHub Actions secret named CI_TFVARS containing all required Terraform inputs:

key_pair_name = "your-ssh-key"
aws_region    = "us-east-1"
# … other required vars (e.g. subnet_cidr, vpc_cidr)

This drives both terraform validate and terraform plan in CI without committing any sensitive data.

(Optional) Live Inference: VLLM_ENDPOINT_URL

If you have a running vLLM server and want to exercise live-inference tests, create VLLM_ENDPOINT_URL:

https://your-vllm-host:8000

3. Run CI Locally

GitHub Actions will:

1. Cache Python deps and Terraform plugins/modules


2. Run unit tests


3. Auto-format Terraform (terraform fmt)


4. Write terraform/ci.tfvars from CI_TFVARS


5. Validate and Plan Terraform (skipped with warning if CI_TFVARS is unset)


6. Optionally run live-inference tests



You can also mimic this locally by:

export CI_TFVARS="$(cat ~/ci.tfvars)"
export VLLM_ENDPOINT_URL="http://localhost:8000"
github-actions-runner \
  --job test

(or simply push to GitHub and watch the badge update)

4. Provision Dev Environment

cd terraform/environments/dev
terraform init
terraform apply -var-file=../../ci.tfvars

5. Fine-Tune, Distill, Deploy

./scripts/setup_env.sh
./scripts/train_model.sh
./scripts/distill_model.sh      # optional
./scripts/deploy_model.sh

📘 Documentation

See docs/architecture.md and docs/usage.md for detailed guides, examples, and troubleshooting.

🤝 Contributing

Contributions welcome! Please open issues or PRs against this repo—refer to our CONTRIBUTING.md.

📜 License

MIT License. See LICENSE for details.
