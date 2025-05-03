# DeepSeek Orchestrator

**DeepSeek Orchestrator** is an open-source, fully automated framework for fine-tuning, distilling, and serving DeepSeek R1 671B and its distilled variants on-demand in the cloud. It leverages Terraform for infrastructure provisioning, vLLM for efficient model serving, and integrates cost-optimization strategies to ensure resources are utilized only when needed.

## 🚀 Features

* **Full Parameter Fine-Tuning**: Utilize the [ScienceOne-AI/DeepSeek-671B-SFT-Guide](https://github.com/ScienceOne-AI/DeepSeek-671B-SFT-Guide) for comprehensive fine-tuning of DeepSeek R1 671B.

* **Model Distillation**: Implement knowledge distillation techniques to create smaller, efficient models from the large-scale DeepSeek R1.

* **On-Demand Serving**: Deploy models using vLLM for high-throughput, low-latency inference, with infrastructure that scales based on demand.

* **Cost Optimization**: Incorporate AWS features like EC2 hibernation and spot instances to minimize costs during idle periods.

* **Infrastructure as Code**: Use Terraform to provision and manage cloud resources, ensuring reproducibility and scalability.

## 🗂️ Project Structure

```
deepseek-orchestrator/
├── README.md
├── LICENSE
├── .gitignore
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── modules/
│   │   ├── compute/
│   │   ├── networking/
│   │   └── storage/
│   └── environments/
│       ├── dev/
│       ├── staging/
│       └── prod/
├── scripts/
│   ├── setup_env.sh
│   ├── train_model.sh
│   ├── distill_model.sh
│   ├── deploy_model.sh
│   └── monitor_resources.sh
├── models/
│   ├── checkpoints/
│   └── logs/
├── data/
│   ├── raw/
│   └── processed/
├── configs/
│   ├── training_config.yaml
│   ├── distillation_config.yaml
│   └── deployment_config.yaml
├── notebooks/
│   └── exploration.ipynb
├── tests/
│   ├── unit/
│   └── integration/
└── docs/
    ├── architecture.md
    └── usage.md
```

## 🛠️ Getting Started

### Prerequisites

* **AWS Account**: Ensure you have an AWS account with permissions to create EC2 instances, VPCs, and other necessary resources.

* **Terraform**: Install Terraform for infrastructure provisioning.

* **Python Environment**: Set up a Python environment with required dependencies listed in `requirements.txt`.

### Installation

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/yourusername/deepseek-orchestrator.git
   cd deepseek-orchestrator
   ```

2. **Configure AWS Credentials**:

   Ensure your AWS credentials are configured, either via environment variables or the AWS credentials file.

3. **Provision Infrastructure**:

   Navigate to the `terraform/environments/dev/` directory and initialize Terraform:

   ```bash
   terraform init
   terraform apply
   ```

   This will set up the necessary infrastructure, including EC2 instances with GPU capabilities.

4. **Set Up the Environment**:

   SSH into the provisioned EC2 instance and run the setup script:

   ```bash
   ./scripts/setup_env.sh
   ```

5. **Fine-Tune the Model**:

   Prepare your dataset and configuration files, then initiate fine-tuning:

   ```bash
   ./scripts/train_model.sh
   ```

6. **Distill the Model** (Optional):

   To create a smaller, efficient version of the model:

   ```bash
   ./scripts/distill_model.sh
   ```

7. **Deploy the Model**:

   Deploy the fine-tuned or distilled model using vLLM:

   ```bash
   ./scripts/deploy_model.sh
   ```

## 📦 Model Management

* **Checkpoints**: Stored in the `models/checkpoints/` directory.

* **Logs**: Training and inference logs are saved in `models/logs/`.

* **Model Registry**: Integrate with tools like MLflow for versioning and tracking.

## 📈 Monitoring and Optimization

* **Resource Monitoring**: Utilize AWS CloudWatch to monitor resource utilization.

* **Cost Optimization**:

  * **EC2 Hibernation**: Enable hibernation for EC2 instances to save costs during inactivity.

  * **Spot Instances**: Configure Terraform to use spot instances where appropriate.

* **Auto-Scaling**: Implement auto-scaling groups to adjust resources based on demand.

## 📄 Documentation

Detailed documentation is available in the `docs/` directory, including:

* **Architecture Overview**: `architecture.md`

* **Usage Guide**: `usage.md`

* **Troubleshooting**: Common issues and solutions.

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request for any enhancements or bug fixes.

## 📜 License

This project is licensed under the MIT License.

---

By following this guide, you can effectively manage the lifecycle of large language models like DeepSeek R1 671B, ensuring efficient utilization of resources and scalability.

If you need further assistance or have specific questions, feel free to ask!
