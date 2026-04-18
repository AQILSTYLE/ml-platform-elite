# GPU Partitioning with MIG

NVIDIA Multi-Instance GPU (MIG) allows a single A100 or H100 GPU to be split into multiple isolated slices.

## Why use it
Small inference models often do not need a full dedicated GPU. MIG allows multiple models to share one physical GPU safely.

## Benefits
- higher utilization
- better cost efficiency
- hardware-level isolation

## Trade-offs
- fixed partition sizes
- operational setup required
- some workloads still need full-GPU access
