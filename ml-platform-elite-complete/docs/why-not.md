# Why Not Alternative Approaches

## Why not SageMaker-only
- less infrastructure control
- harder to optimize custom GPU scheduling
- potentially higher long-term cost at scale

## Why not serverless inference
- cold starts
- limited GPU control/support
- less predictable performance for real-time traffic

## Why not CPU-only inference
- not suitable for many modern deep learning models
- higher latency and poorer throughput
