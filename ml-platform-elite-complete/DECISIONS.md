# Key Architectural Decisions

## 1. EKS vs SageMaker

### Decision
EKS was chosen.

### Why
The primary requirement is not just model training. It is operating a shared ML platform that supports:
- heterogeneous workloads
- custom GPU scheduling
- stronger network and workload isolation
- deeper cost optimization

EKS provides more platform control than SageMaker and better supports a unified training + inference operating model.

### Pros
- stronger workload portability
- better control of GPU scheduling
- lower vendor lock-in
- one platform for both training and inference

### Cons
- higher operational complexity
- requires Kubernetes expertise
- more infrastructure responsibility

### When SageMaker would be better
SageMaker would be a better fit if:
- the team needed the fastest path to managed training/inference
- the organization wanted less platform ownership
- customization and deeper infrastructure control were less important

---

## 2. Spot for Training, On-Demand for Inference

### Decision
- training on Spot
- inference on On-Demand

### Why
Training is interruptible and can recover from checkpoints. Inference is user-facing and should prioritize predictability over maximum savings.

### Pros
- major training cost reduction
- stable inference behavior
- cleaner alignment between workload type and capacity type

### Cons
- Spot interruptions must be handled
- operating multiple capacity strategies adds complexity

### Mitigation
- checkpointing to S3
- restart logic for training
- separate capacity pools

---

## 3. MIG for Small Inference Workloads

### Decision
Use MIG where inference models are too small to justify a full dedicated GPU.

### Why
A common failure in ML platforms is paying for full GPUs that run mostly idle. MIG improves consolidation and raises effective GPU utilization.

### Pros
- better density
- lower cost per workload
- hardware-level isolation between slices

### Cons
- fixed partition sizes
- operational setup overhead
- not suitable for all workloads

### When not to use MIG
Do not use MIG when:
- one model genuinely needs the full GPU
- memory pressure is unpredictable
- maximum flexibility matters more than density

---

## 4. Karpenter vs Cluster Autoscaler

### Decision
Karpenter was chosen.

### Why
Karpenter provisions nodes faster and generally provides better packing behavior, which matters when working with expensive GPU nodes.

### Pros
- quicker scale-out
- better node right-sizing
- improved cost efficiency

### Cons
- newer ecosystem than Cluster Autoscaler
- extra platform component to manage

---

## 5. IRSA vs Static Credentials

### Decision
Use IRSA.

### Why
Static credentials in containers are a security weakness and harder to manage. IRSA allows workload-specific access without embedding secrets.

### Pros
- least privilege at workload level
- no embedded long-lived credentials
- better auditability

### Cons
- more setup than a simplistic shared-role model

---

## 6. Single VPC with Isolation vs Multiple VPCs

### Decision
Use one VPC with private subnet isolation for the PoC.

### Why
This provides a good balance of security and simplicity. Multiple VPCs would increase routing, peering, and operational complexity without adding enough value for the scope of this assignment.

### Pros
- simpler design
- easier to operate for a PoC
- still supports strong isolation controls

### Cons
- weaker hard-boundary isolation than a multi-VPC design
