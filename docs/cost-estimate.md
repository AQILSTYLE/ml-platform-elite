# Cost Estimate

## Estimated Monthly Cost
- Training GPU Spot: ~$180
- Inference GPU On-Demand: ~$864
- Storage and network overhead: ~$50

## Estimated Total
~$1,100 / month

## Main Cost Controls
- Spot instances for training
- MIG for higher inference density
- Karpenter to reduce idle node time
- Separation of training and inference pools
