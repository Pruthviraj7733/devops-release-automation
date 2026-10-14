# Chapter 09 — Security, ServiceAccounts and RBAC

**Learning path:** Theory → Architecture → Practical → Practice Tasks → Interview Answer

> Study material, not evidence of deployment in this repository. Run commands only against a disposable practice cluster. The project's EKS cluster and ALB were deleted after testing to prevent charges.

## 1. Theory

Authentication determines identity; authorization decides permissions; admission validates or mutates objects. RBAC Roles and RoleBindings are namespaced; ClusterRoles and ClusterRoleBindings can be cluster-scoped. ServiceAccounts provide workload identities. Apply least privilege, restrict privileged containers, set security contexts, use NetworkPolicies where enforced, and avoid static cloud credentials. On EKS, review IAM-to-Kubernetes access mappings and workload identity approaches.

## 2. Architecture and request flow

```mermaid
flowchart LR
  A[Developer or kubectl] --> B[Kubernetes API]
  B --> C[Desired State]
  C --> D[Controllers and Scheduler]
  D --> E[Worker Nodes and Pods]
  E --> F[Observe and Verify]
```

**Apply to this chapter:** Security, ServiceAccounts and RBAC fits into the API-driven desired-state model. Distinguish control-plane operations from the workload resources running on nodes.

## 3. Essential concepts

- **Desired state:** Declarative configuration stored through the Kubernetes API.
- **Actual state:** What is currently running; controllers work to reconcile differences.
- **Namespaces and labels:** Scope resources and identify selected workloads.
- **Operational verification:** Inspect resource status, events, logs and readiness instead of assuming success.
- **Project context:** Review the existing [Jenkinsfile](../../Jenkinsfile) and [Kubernetes manifests](../../k8s/) to distinguish implemented features from study-only topics.

## 4. Hands-on practical

Replace placeholders such as `<NODE_NAME>` with real names. Some commands require metrics-server, an appropriate cluster or permissions.

```bash
kubectl get serviceaccounts -A
kubectl get roles,rolebindings -A
kubectl get clusterroles | head
kubectl auth can-i get pods
kubectl auth can-i create deployments --namespace=default
```

**Safety:** Read commands before execution; creation/deletion examples should be run only in a dedicated practice environment. Cloud resources and storage may incur costs.

## 5. Practice tasks

- [ ] Summarize the theory in your notebook without copying the entire section.
- [ ] Write a read-only Role and RoleBinding for a practice namespace; explain why permissions should be tested with kubectl auth can-i. Avoid granting cluster-admin.
- [ ] Identify the relevant Kubernetes objects and their relationships.
- [ ] Explain one failure mode and the commands you would use to diagnose it.
- [ ] Describe what is implemented in this project versus what is only studied here.

## 6. Interview preparation

**Q: Role vs ClusterRole?**

**Sample answer:** Roles define permissions within one namespace, while ClusterRoles can define cluster-scoped permissions or reusable namespaced permissions. RoleBindings grant permissions in a namespace; ClusterRoleBindings grant them cluster-wide.

**Follow-up:** What output would you inspect to verify the behavior in a real cluster?

## 7. Revision checklist

- [ ] Explain the concept in under two minutes.
- [ ] Identify the Kubernetes API objects involved.
- [ ] Recall at least three practical commands.
- [ ] Explain a failure scenario and a verification step.

[Study Index](README.md) · [Project Overview](../../README.md) · [Project Documentation](../../docs/architecture.md)
