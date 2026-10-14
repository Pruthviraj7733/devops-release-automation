# Chapter 02 — Control Plane Components

**Learning path:** Theory → Architecture → Practical → Practice Tasks → Interview Answer

> Study material, not evidence of deployment in this repository. Run commands only against a disposable practice cluster. The project's EKS cluster and ALB were deleted after testing to prevent charges.

## 1. Theory

The API server authenticates, authorizes and admits API requests; etcd stores cluster state; the scheduler binds unscheduled Pods to Nodes; controllers reconcile desired state. On EKS the managed control plane is operated by AWS.

## 2. Architecture and request flow

```mermaid
flowchart LR
  A[Developer or kubectl] --> B[Kubernetes API]
  B --> C[Desired State]
  C --> D[Controllers and Scheduler]
  D --> E[Worker Nodes and Pods]
  E --> F[Observe and Verify]
```

**Apply to this chapter:** Control Plane Components fits into the API-driven desired-state model. Distinguish control-plane operations from the workload resources running on nodes.

## 3. Essential concepts

- **Desired state:** Declarative configuration stored through the Kubernetes API.
- **Actual state:** What is currently running; controllers work to reconcile differences.
- **Namespaces and labels:** Scope resources and identify selected workloads.
- **Operational verification:** Inspect resource status, events, logs and readiness instead of assuming success.
- **Project context:** Review the existing [Jenkinsfile](../../Jenkinsfile) and [Kubernetes manifests](../../k8s/) to distinguish implemented features from study-only topics.

## 4. Hands-on practical

Replace placeholders such as `<NODE_NAME>` with real names. Some commands require metrics-server, an appropriate cluster or permissions.

```bash
kubectl get --raw /readyz
kubectl get --raw /livez
kubectl get --raw /api
kubectl get events -A --sort-by=.metadata.creationTimestamp
```

**Safety:** Read commands before execution; creation/deletion examples should be run only in a dedicated practice environment. Cloud resources and storage may incur costs.

## 5. Practice tasks

- [ ] Summarize the theory in your notebook without copying the entire section.
- [ ] Trace kubectl → API server → etcd → controllers → scheduler. Explain RBAC authorization versus admission control.
- [ ] Identify the relevant Kubernetes objects and their relationships.
- [ ] Explain one failure mode and the commands you would use to diagnose it.
- [ ] Describe what is implemented in this project versus what is only studied here.

## 6. Interview preparation

**Q: What happens if the scheduler is unavailable?**

**Sample answer:** Existing Pods may keep running, but new unscheduled Pods cannot be placed until scheduling resumes. The API server is the cluster entry point; etcd holds persistent state; controllers continually reconcile resources. In EKS, the control plane is managed by AWS.

**Follow-up:** What output would you inspect to verify the behavior in a real cluster?

## 7. Revision checklist

- [ ] Explain the concept in under two minutes.
- [ ] Identify the Kubernetes API objects involved.
- [ ] Recall at least three practical commands.
- [ ] Explain a failure scenario and a verification step.

[Study Index](README.md) · [Project Overview](../../README.md) · [Project Documentation](../../docs/architecture.md)
