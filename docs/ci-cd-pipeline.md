# Jenkins CI/CD Pipeline

The root [Jenkinsfile](../Jenkinsfile) is the authoritative implementation. It exposes three `DEPLOYMENT_STRATEGY` choices: `CI_ONLY`, `ROLLING_UPDATE`, and `BLUE_GREEN`.

## Common stages
1. Build the image using `docker build`.
2. Verify the image with `docker image inspect`.
3. Authenticate to Amazon ECR using `aws ecr get-login-password`.
4. Push the build-number-tagged image to ECR.
5. Verify the image digest in ECR.
6. Record deployment preparation details.

The Jenkins job uses GitHub integration/webhook triggering in the tested setup. Jenkins checkout behavior is managed by the job/pipeline SCM configuration.

**Important:** The current pipeline does not execute `mvn package`, automated unit tests, SonarQube, Trivy, or Helm. The Dockerfile packages `index.jsp` into a WAR with the JDK `jar` utility. These integrations are possible future enhancements, not implemented stages.

## Deployment-only stages
For `ROLLING_UPDATE` or `BLUE_GREEN`, Jenkins creates a workspace-local kubeconfig, applies initial Kubernetes resources, detects the active environment, runs the selected strategy, verifies the deployment image and readiness, and checks ALB target health.

## Blue/Green approval
Before switching traffic, the pipeline waits for an operator's approval (10-minute timeout). It patches the stable Service selector after approval.

## Failure handling
The Jenkinsfile has a `post { failure { ... } }` block for strategy-specific rollback and a `post { cleanup { ... } }` block that removes temporary files **after** post-build handling. The rollback implementation logs a warning if its attempted recovery fails; manual verification remains necessary.

## Build examples
In Jenkins, choose **Build with Parameters** and select:
- `CI_ONLY` to build/push without Kubernetes access.
- `ROLLING_UPDATE` to update the currently active Deployment.
- `BLUE_GREEN` to prepare the inactive environment, request approval, and switch production Service routing.

The AWS cluster was deleted after testing; deployment modes require a provisioned cluster and will not work until infrastructure is recreated.
