# Setup and Deployment Guide

> **Cost warning:** These commands create billable AWS resources. The original EKS cluster and ALB have already been deleted. Do not execute provisioning commands just to read the documentation.

## Prerequisites
- AWS account, appropriate IAM permissions, AWS CLI, Docker, `kubectl`, and `eksctl`.
- A Jenkins agent with Docker and AWS CLI access, and `kubectl` access for deployment jobs.
- Amazon ECR repository named `java-application`.
- VPC and two subnets matching the IDs in `eks/eks-cluster.yaml`; those IDs are specific to the original lab and must be changed for another AWS account/VPC.
- AWS Load Balancer Controller configured in the EKS cluster for `ingressClassName: alb`. The controller was installed manually in the original lab, not via Helm.
- IAM authorization for ECR, EKS, and ALB operations. Use least-privilege policies outside a lab.

## Read-only source review
```bash
git clone https://github.com/Pruthviraj7733/devops-release-automation.git
cd devops-release-automation
cat Dockerfile
cat Jenkinsfile
ls -la k8s eks app
```

## Local image build (Docker required)
```bash
docker build -t java-application:local .
docker run --rm -p 9090:8080 java-application:local
# In another terminal:
curl -I http://localhost:9090/java-application/
```

## Provisioning (billable; optional)
```bash
# Inspect/edit eks/eks-cluster.yaml for your VPC, subnets, Kubernetes version and quotas.
eksctl create cluster -f eks/eks-cluster.yaml
aws eks update-kubeconfig --region ap-south-1 --name devops-release-cluster
kubectl get nodes
```

Install/configure AWS Load Balancer Controller according to the controller's official documentation **before** applying the ALB Ingress. Create the ECR repository and configure Jenkins permissions before running deployment stages.

## Apply Kubernetes manifests
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/service-blue.yaml
kubectl apply -f k8s/service-green.yaml
kubectl apply -f k8s/deployment-blue.yaml
kubectl apply -f k8s/deployment-green.yaml
kubectl apply -f k8s/service-active.yaml
kubectl apply -f k8s/ingress.yaml
kubectl -n devops-production get deploy,svc,ingress,pods
```
The checked-in deployment image references are lab-specific. Jenkins replaces the relevant deployment image with its new ECR image during releases.

## Verification
```bash
kubectl -n devops-production rollout status deployment/java-app-blue --timeout=300s
kubectl -n devops-production get pods -o wide
kubectl -n devops-production get svc java-app-active-service -o yaml
kubectl -n devops-production get ingress java-app-ingress
```
See [CI/CD pipeline](ci-cd-pipeline.md), [deployment strategies](rolling-update.md), and [cleanup](aws-cleanup.md).
