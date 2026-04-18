# Scaling Strategy

## Inference
- HPA scales pods
- Karpenter adds nodes when pods cannot be scheduled
- On-Demand nodes back stable inference capacity

## Training
- queued jobs can run on Spot GPUs
- checkpoints protect progress
- jobs can resume after interruption

## Bottlenecks to monitor
- GPU availability
- model load time
- storage throughput
