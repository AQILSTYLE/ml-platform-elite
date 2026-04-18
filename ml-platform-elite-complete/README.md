# Cloud-Native ML Platform (Elite Submission)

## Executive Summary
This repository presents a production-grade, cloud-native ML platform on AWS designed to support distributed GPU training, scalable low-latency inference, governance, and cost optimization.

The platform standardizes previously fragmented ML workflows by providing a unified foundation for:
- distributed model training on GPU infrastructure
- controlled and scalable real-time inference
- secure data access with least privilege
- operational visibility and repeatable deployment workflows

## Problem Statement
The target environment contains multiple data science teams running inconsistent workloads such as notebooks, manual training jobs, and ad-hoc model APIs. That model does not scale operationally because it creates:
- inconsistent deployment standards
- poor cost visibility for expensive GPU resources
- weak isolation between workloads
- limited governance over data and model access

This design addresses those issues by separating training and inference concerns while keeping them on a common cloud-native platform.

## Architecture Summary
High-level flow:

Client → API Gateway / Load Balancer → EKS Inference → MLflow Registry → EKS Training → S3 Data Lake

Core architectural decisions:
- **Amazon EKS** as the common execution platform for both training and inference
- **Spot GPU capacity** for fault-tolerant training workloads
- **On-Demand GPU capacity** for latency-sensitive inference workloads
- **Karpenter** for dynamic node provisioning
- **Horizontal Pod Autoscaler** for inference scaling
- **MLflow** for model tracking and registry
- **IRSA** for least-privilege S3 access
- **Private subnets and VPC endpoints** for secure network isolation

## Why EKS Instead of SageMaker
EKS was selected because the primary challenge is not only model training, but operating a shared ML platform with:
- different workload profiles
- custom GPU scheduling requirements
- stronger control over networking and workload isolation
- tighter cost optimization through Spot and MIG strategies

SageMaker would reduce operational burden, but it would also reduce infrastructure flexibility and make deeper platform-level optimization more difficult. For a platform team supporting multiple ML personas, EKS provides better long-term control.

## Networking Design
The platform uses a dedicated VPC with private subnets for all compute workloads. Only the ingress layer is exposed publicly. S3 and ECR are accessed through VPC endpoints so worker nodes do not require direct public internet access.

This design was chosen to:
- reduce attack surface
- improve governance over data movement
- keep training and inference traffic private
- support enterprise-style controls around access and auditability

## Compute Strategy
The compute model intentionally separates workload types:

### Training
- runs on Spot GPU nodes
- optimized for cost
- tolerant to interruption
- resumes from checkpoints stored in S3

### Inference
- runs on On-Demand GPU nodes
- optimized for predictable latency and availability
- horizontally scaled using HPA
- backed by Karpenter for node provisioning when capacity is needed

This separation is important because training and inference have fundamentally different reliability and cost profiles. Treating them as identical workloads is one of the most common design mistakes in ML infrastructure.

## GPU Utilization Strategy
GPU cost is the main economic constraint in modern ML platforms. This design reduces waste through:
- Spot usage for interruptible workloads
- dynamic provisioning through Karpenter
- optional NVIDIA MIG partitioning for small inference workloads
- separate capacity pools for training and inference

For smaller inference services, MIG allows multiple models to share a single A100/H100 GPU safely. This improves utilization significantly, though it introduces fixed partitioning trade-offs.

## Data Access Model
Training and model-serving workloads access S3 using IAM Roles for Service Accounts (IRSA). This ensures:
- no static credentials in code or containers
- least-privilege access to only required buckets
- clean separation of permissions between workloads

Data is encrypted at rest in S3 and expected to be transmitted over TLS in transit.

## CI/CD and MLOps Flow
1. A developer pushes code to GitHub
2. GitHub Actions builds and tags a container image
3. The image is pushed to Amazon ECR
4. Model metadata is tracked in MLflow
5. Kubernetes manifests are deployed to EKS
6. If deployment fails, rollback logic can restore the previous version

This flow improves consistency, auditability, and rollback capability compared with manually managed notebook-to-API workflows.

## Failure Handling
The design assumes failures will occur and includes mitigations:

### Spot interruption during training
Mitigation:
- periodic checkpointing to S3
- job restart from the latest checkpoint

### Pod or node failure during inference
Mitigation:
- Kubernetes rescheduling
- service-based traffic routing
- autoscaling across multiple replicas

### Bad model release
Mitigation:
- model versioning in MLflow
- CI/CD rollback path
- separation of model registration from inference rollout

## Cost Management
Main cost controls:
- Spot for training
- On-Demand only where reliability is required
- Karpenter to reduce idle nodes
- MIG to improve inference density
- workload separation to avoid overprovisioning expensive GPU capacity

Estimated monthly cost for the PoC profile:
- training GPU Spot: ~$180
- inference GPU On-Demand: ~$864
- storage/network overhead: ~$50
- total: ~$1,100/month

## Key Trade-offs
### Benefits
- strong control over compute and networking
- better long-term flexibility
- stronger GPU cost optimization
- suitable foundation for a shared ML platform

### Costs
- more Kubernetes operational complexity
- more moving parts than a fully managed ML-only service
- requires stronger platform engineering discipline

## Production Considerations (Beyond PoC)
This implementation is designed as a production-grade PoC and intentionally focuses on architectural correctness, workload separation, and cost-aware scaling patterns.

A full production rollout would additionally include:
- OIDC provider configuration for full IRSA integration
- Secrets management using AWS Secrets Manager or Vault
- Centralized logging (CloudWatch / OpenSearch)
- Metrics and alerting pipelines (Prometheus + Alertmanager)
- Blue/green or canary deployment strategy for model rollout
- Model quality monitoring and drift detection pipelines
- Multi-region inference deployment for latency and resilience
- Network policies for pod-level traffic control
- Fine-grained cost allocation tagging across teams and workloads

The design choices in this repository aim to ensure that these capabilities can be layered on without major architectural changes.

## Expected Bottlenecks at Scale
The primary scaling bottlenecks in this design are:

1. **GPU Availability**
   - GPU capacity is not always immediately available, especially Spot
   - Mitigation: fallback to On-Demand, pre-warmed node pools, or capacity reservation

2. **Node Provisioning Latency**
   - Karpenter improves provisioning speed, but node startup time still impacts scaling
   - Mitigation: buffer capacity for inference workloads

3. **Model Load Time**
   - Large models increase cold-start latency
   - Mitigation: model caching, warm pods, or multi-model serving strategies

4. **S3 Throughput for Training**
   - High-volume training jobs may be bottlenecked by data throughput
   - Mitigation: data sharding or caching strategies

These constraints informed the separation of training and inference workloads and the use of autoscaling strategies at both pod and node levels.

## Design Philosophy
This platform intentionally separates:
- **interruptible workloads (training)**
- **latency-sensitive workloads (inference)**

because they have fundamentally different:
- cost profiles
- scaling behavior
- failure tolerance

By aligning infrastructure strategy with workload characteristics, the design achieves both cost efficiency and production reliability without over-engineering either path.

## How to Run the IaC
```bash
cd terraform/envs/dev
terraform init
terraform plan
terraform apply
```

## Suggested Deployment Order
```bash
kubectl apply -f ../../k8s/mlflow/
kubectl apply -f ../../k8s/monitoring/
kubectl apply -f ../../k8s/autoscaling/
kubectl apply -f ../../k8s/inference/
kubectl apply -f ../../k8s/training/
```

## Repository Structure
```text
ml-platform-elite/
├── README.md
├── ARCHITECTURE.md
├── DECISIONS.md
├── diagrams/
│   └── architecture.png
├── terraform/
├── k8s/
├── ci-cd/
└── docs/
```

## Deliverables Included
- README explaining architecture and deployment flow
- Terraform folder containing IaC files
- architecture diagram in image format
- supporting documentation for trade-offs, risks, scaling, and cost strategy
