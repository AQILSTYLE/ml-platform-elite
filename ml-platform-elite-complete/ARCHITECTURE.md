# Architecture Deep Dive

## 1. Platform Objective
The platform objective is to move from fragmented ML execution patterns to a repeatable, governed, and cost-aware operating model.

The design must support:
- distributed GPU training
- low-latency real-time inference
- workload isolation
- secure data access
- repeatable deployment workflows

## 2. Network Architecture
The platform uses a dedicated VPC with:
- private subnets for EKS worker nodes
- controlled public ingress only at the API/load balancer layer
- VPC endpoints for S3 and ECR
- restricted east-west communication via security groups

### Why this approach
This avoids exposing training or inference workers directly to the public internet and keeps data movement private wherever possible.

### Alternatives considered
#### Separate VPCs for training and inference
Pros:
- stronger hard isolation

Cons:
- more routing and peering complexity
- more operational overhead for a PoC

Decision:
A single VPC with strong subnet and policy isolation is the better balance for this design.

## 3. Compute Architecture
Amazon EKS is used as the common platform for both training and inference.

### Why EKS
- one control plane for ML workloads
- consistent deployment model
- full control over GPU scheduling
- better long-term extensibility than a managed ML-only stack

### Training capacity
Training uses Spot GPU nodes because:
- training jobs are fault tolerant
- cost reduction is significant
- interruption can be mitigated with checkpointing

### Inference capacity
Inference uses On-Demand GPU nodes because:
- latency matters more than raw cost
- production traffic requires predictability
- interruption creates user-facing impact

## 4. GPU Strategy
GPU resources are the most expensive part of the design, so utilization must be actively managed.

### Chosen approach
- separate GPU pools for training and inference
- use Karpenter to avoid idle overprovisioning
- use MIG for smaller inference workloads when appropriate

### Why MIG
Smaller inference services frequently underutilize a full GPU. MIG enables hardware-level partitioning so multiple workloads can share one physical GPU.

### Trade-off
MIG improves density and lowers cost, but partition sizes are fixed and some workloads still require a full GPU.

## 5. Data Access Design
Training and serving workloads access S3 using IRSA.

### Why IRSA
- removes the need for static credentials
- enforces least privilege at pod/workload level
- improves security and auditability

### Access pattern
- training reads datasets from the data bucket
- training writes model artifacts to the registry/model bucket
- inference retrieves model artifacts from controlled storage

## 6. CI/CD and MLOps
The deployment flow is designed to reduce manual operational steps.

### Flow
1. Source code is pushed to GitHub
2. GitHub Actions builds the container image
3. Image is pushed to ECR
4. Model version metadata is recorded in MLflow
5. Kubernetes manifests are applied to EKS
6. Rollback path remains available if deployment fails

### Why this matters
The previous operating model relied on notebooks and ad-hoc deployments. This design introduces:
- repeatability
- version control
- rollback capability
- traceability across training and deployment

## 7. Scaling Model
### Inference scaling
- HPA scales pods horizontally
- Karpenter provisions nodes when pods cannot be scheduled
- On-Demand nodes back stable inference traffic

### Training scaling
- jobs can scale through additional Spot-based GPU capacity
- burst demand can be queued
- checkpoints protect against lost progress

## 8. Failure Scenarios
### Spot interruption
Impact:
training pauses

Mitigation:
resume from the latest S3 checkpoint

### Node failure during inference
Impact:
pods on that node are lost

Mitigation:
service routing + multiple replicas + Kubernetes rescheduling

### Bad model rollout
Impact:
prediction quality or performance degrades

Mitigation:
rollback to the previous model/image version and maintain model version traceability in MLflow

## 9. Security Model
Security is treated as a design requirement, not a later add-on.

Controls include:
- private subnets
- least-privilege IAM
- IRSA for pod-level access
- encryption at rest and in transit
- auditability through AWS-native logging and trails

## 10. Main Risks
The main platform risks are:
- GPU cost waste through poor utilization
- operational complexity in Kubernetes
- Spot interruption for training
- model quality issues after deployment

These are mitigated through:
- MIG
- Karpenter
- checkpointing
- model versioning and rollback
