<div align="center">

# Kubernetes — Complete Study Notes

### Architecture · Operations · Hands-on Practice · DevOps Interview Preparation

**10 written chapters • Practical commands • Practice checklists • Interview-level answers**

[Project Overview](../../README.md) · [CI/CD Architecture](../../docs/architecture.md) · [Project Troubleshooting](../../docs/troubleshooting.md)

</div>

---

## Learning Roadmap

| Chapter | Topic | Notes | Hands-on |
|---|---|---|---|
| 01 | [Kubernetes Architecture](01-kubernetes-architecture.md) | Written | Not yet verified |
| 02 | [Control Plane Components](02-control-plane.md) | Written | Not yet verified |
| 03 | [Worker Node Components](03-worker-node.md) | Written | Not yet verified |
| 04 | [Pods, ReplicaSets, Deployments](04-pods-and-deployments.md) | Written | Not yet verified |
| 05 | [Services, DNS, Networking, Ingress](05-services-and-networking.md) | Written | Not yet verified |
| 06 | [ConfigMaps and Secrets](06-configmaps-and-secrets.md) | Written | Not yet verified |
| 07 | [Persistent Volumes and PVCs](07-storage-pv-pvc.md) | Written | Not yet verified |
| 08 | [Scheduling, Resources, Autoscaling](08-scheduling-and-scaling.md) | Written | Not yet verified |
| 09 | [Security, ServiceAccounts, RBAC](09-security-and-rbac.md) | Written | Not yet verified |
| 10 | [Kubernetes Troubleshooting](10-troubleshooting.md) | Written | Not yet verified |

## How to Study

1. **Theory:** Read one chapter and write the key concepts in your notebook.
2. **Architecture:** Explain how its Kubernetes objects interact with the API server, controllers and worker nodes.
3. **Practical:** Run commands on a local or disposable practice cluster, checking permissions and costs first.
4. **Practice Tasks:** Complete the checkboxes only after personally verifying the result.
5. **Interview Answer:** Explain the topic clearly in 1–2 minutes without reading the sample answer.

## Lab and Implementation Boundaries

- The [project Jenkinsfile](../../Jenkinsfile) implements CI-only, rolling-update and blue/green release paths using Docker, Amazon ECR, Amazon EKS and Kubernetes manifests.
- **Study topics are broader than the implemented project.** HPA, ConfigMaps, Secrets, PV/PVC and RBAC manifests are covered for learning but are not implemented in the project's application configuration.
- The previous AWS EKS cluster and ALB were deleted after lab testing. Do not assume there is a running cloud cluster.
- The examples are educational and have not been executed as part of this documentation update.
- Do not commit credentials or incur cloud charges merely to follow the notes.

## Suggested Study Order

**Foundation:** 01–03 → **Workloads and Networking:** 04–05 → **Configuration and Storage:** 06–07 → **Operations:** 08–10.

---

[Back to Main Project](../../README.md)
