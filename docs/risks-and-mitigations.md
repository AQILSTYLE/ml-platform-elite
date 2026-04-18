# Risks and Mitigations

## Spot interruption
**Risk:** training jobs may stop unexpectedly  
**Mitigation:** periodic checkpoints to S3

## GPU underutilization
**Risk:** expensive GPUs sit idle  
**Mitigation:** MIG and autoscaling

## Operational complexity
**Risk:** Kubernetes increases management burden  
**Mitigation:** managed EKS, Terraform, CI/CD, observability

## Bad model release
**Risk:** degraded predictions in production  
**Mitigation:** MLflow versioning and rollback path
