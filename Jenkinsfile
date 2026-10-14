pipeline {
    agent any

    parameters {
        choice(
            name: 'DEPLOYMENT_STRATEGY',
            choices: ['CI_ONLY', 'ROLLING_UPDATE', 'BLUE_GREEN'],
            description: 'Choose CI only or a Kubernetes deployment strategy'
        )
    }

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '734836384716'
        ECR_REPOSITORY = 'java-application'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG = "${BUILD_NUMBER}"
        IMAGE_URL = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"

        EKS_CLUSTER_NAME = 'devops-release-cluster'
        K8S_NAMESPACE = 'devops-production'

        APP_NAME = 'java-app'
        ACTIVE_SERVICE = 'java-app-active-service'
        INGRESS_NAME = 'java-app-ingress'

        KUBECONFIG = "${WORKSPACE}/.kubeconfig"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 45, unit: 'MINUTES')
        skipDefaultCheckout(false)
    }

    stages {

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eu
                    docker build -t "${IMAGE_URL}" .
                '''
            }
        }

        stage('Verify Docker Image') {
            steps {
                sh '''
                    set -eu
                    docker image inspect "${IMAGE_URL}" >/dev/null
                    echo "Docker image verified"
                '''
            }
        }

        stage('Authenticate to AWS ECR') {
            steps {
                sh '''
                    set -eu
                    aws ecr get-login-password \
                        --region "${AWS_REGION}" |
                    docker login \
                        --username AWS \
                        --password-stdin "${ECR_REGISTRY}"
                '''
            }
        }

        stage('Push Docker Image to Amazon ECR') {
            steps {
                sh '''
                    set -eu
                    docker push "${IMAGE_URL}"
                '''
            }
        }

        stage('Verify Image in ECR') {
            steps {
                sh '''
                    set -eu
                    aws ecr describe-images \
                        --repository-name "${ECR_REPOSITORY}" \
                        --image-ids "imageTag=${IMAGE_TAG}" \
                        --region "${AWS_REGION}" \
                        --query 'imageDetails[0].imageDigest' \
                        --output text
                '''
            }
        }

        stage('Deployment Preparation') {
            steps {
                echo "Strategy: ${params.DEPLOYMENT_STRATEGY}"
                echo "Image: ${env.IMAGE_URL}"
                echo "Cluster: ${env.EKS_CLUSTER_NAME}"
                echo "Namespace: ${env.K8S_NAMESPACE}"
            }
        }

        stage('Authenticate to Amazon EKS') {
            when {
                expression {
                    params.DEPLOYMENT_STRATEGY != 'CI_ONLY'
                }
            }

            steps {
                sh '''
                    set -eu
                    umask 077

                    aws sts get-caller-identity

                    aws eks update-kubeconfig \
                        --region "${AWS_REGION}" \
                        --name "${EKS_CLUSTER_NAME}" \
                        --kubeconfig "${KUBECONFIG}"

                    kubectl --request-timeout=20s cluster-info
                '''
            }
        }

        stage('Initialize Kubernetes Resources') {
            when {
                expression {
                    params.DEPLOYMENT_STRATEGY != 'CI_ONLY'
                }
            }

            steps {
                sh '''
                    set -eu

                    kubectl apply -f k8s/namespace.yaml

                    kubectl apply -f k8s/service-blue.yaml
                    kubectl apply -f k8s/service-green.yaml

                    if ! kubectl -n "${K8S_NAMESPACE}" \
                        get deployment java-app-blue >/dev/null 2>&1; then

                        kubectl apply -f k8s/deployment-blue.yaml
                        kubectl -n "${K8S_NAMESPACE}" \
                            set image deployment/java-app-blue \
                            java-app="${IMAGE_URL}"
                    fi

                    if ! kubectl -n "${K8S_NAMESPACE}" \
                        get deployment java-app-green >/dev/null 2>&1; then

                        kubectl apply -f k8s/deployment-green.yaml
                    fi

                    if ! kubectl -n "${K8S_NAMESPACE}" \
                        get service "${ACTIVE_SERVICE}" >/dev/null 2>&1; then

                        kubectl apply -f k8s/service-active.yaml
                    fi

                    kubectl apply -f k8s/ingress.yaml

                    kubectl -n "${K8S_NAMESPACE}" \
                        rollout status deployment/java-app-blue \
                        --timeout=300s
                '''
            }
        }

        stage('Detect Active Environment') {
            when {
                expression {
                    params.DEPLOYMENT_STRATEGY != 'CI_ONLY'
                }
            }

            steps {
                sh '''
                    set -eu

                    ACTIVE=$(kubectl -n "${K8S_NAMESPACE}" \
                        get service "${ACTIVE_SERVICE}" \
                        -o jsonpath='{.spec.selector.version}')

                    case "${ACTIVE}" in
                        blue|green)
                            echo "${ACTIVE}" > .active-before-release
                            echo "Active environment: ${ACTIVE}"
                            ;;
                        *)
                            echo "Invalid active environment: ${ACTIVE}"
                            exit 1
                            ;;
                    esac
                '''
            }
        }

        stage('Rolling Update') {
            when {
                expression {
                    params.DEPLOYMENT_STRATEGY == 'ROLLING_UPDATE'
                }
            }

            steps {
                sh '''
                    set -eu

                    ACTIVE=$(cat .active-before-release)
                    DEPLOYMENT="java-app-${ACTIVE}"

                    kubectl -n "${K8S_NAMESPACE}" \
                        rollout status deployment/"${DEPLOYMENT}" \
                        --timeout=300s

                    PREVIOUS_IMAGE=$(kubectl -n "${K8S_NAMESPACE}" \
                        get deployment "${DEPLOYMENT}" \
                        -o jsonpath='{.spec.template.spec.containers[?(@.name=="java-app")].image}')

                    printf '%s\\n' "${DEPLOYMENT}" > .rolling-deployment
                    printf '%s\\n' "${PREVIOUS_IMAGE}" > .rolling-previous-image

                    kubectl -n "${K8S_NAMESPACE}" \
                        set image deployment/"${DEPLOYMENT}" \
                        java-app="${IMAGE_URL}"

                    kubectl -n "${K8S_NAMESPACE}" \
                        rollout status deployment/"${DEPLOYMENT}" \
                        --timeout=300s
                '''
            }
        }

        stage('Prepare Blue Green Deployment') {
            when {
                expression {
                    params.DEPLOYMENT_STRATEGY == 'BLUE_GREEN'
                }
            }

            steps {
                sh '''
                    set -eu

                    ACTIVE=$(cat .active-before-release)

                    if [ "${ACTIVE}" = "blue" ]; then
                        TARGET="green"
                    else
                        TARGET="blue"
                    fi

                    echo "${TARGET}" > .release-target

                    DEPLOYMENT="java-app-${TARGET}"

                    echo "Active: ${ACTIVE}"
                    echo "Deploying inactive environment: ${TARGET}"

                    kubectl -n "${K8S_NAMESPACE}" \
                        set image deployment/"${DEPLOYMENT}" \
                        java-app="${IMAGE_URL}"

                    kubectl -n "${K8S_NAMESPACE}" \
                        scale deployment/"${DEPLOYMENT}" \
                        --replicas=2

                    kubectl -n "${K8S_NAMESPACE}" \
                        rollout status deployment/"${DEPLOYMENT}" \
                        --timeout=300s
                '''
            }
        }

        stage('Verify Inactive Environment') {
            when {
                expression {
                    params.DEPLOYMENT_STRATEGY == 'BLUE_GREEN'
                }
            }

            steps {
                sh '''
                    set -eu

                    TARGET=$(cat .release-target)

                    kubectl -n "${K8S_NAMESPACE}" \
                        wait pods \
                        -l "app=java-app,version=${TARGET}" \
                        --for=condition=Ready \
                        --timeout=180s

                    READY=$(kubectl -n "${K8S_NAMESPACE}" \
                        get deployment "java-app-${TARGET}" \
                        -o jsonpath='{.status.readyReplicas}')

                    test "${READY}" = "2"

                    kubectl -n "${K8S_NAMESPACE}" \
                        get pods -l "app=java-app,version=${TARGET}" -o wide

                    echo "Inactive environment readiness verified"
                '''
            }
        }

        stage('Approve Production Switch') {
            when {
                expression {
                    params.DEPLOYMENT_STRATEGY == 'BLUE_GREEN'
                }
            }

            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    input(
                        message: 'Green/Blue environment is ready. Switch production traffic?',
                        ok: 'Approve Traffic Switch'
                    )
                }
            }
        }

        stage('Switch Production Traffic') {
            when {
                expression {
                    params.DEPLOYMENT_STRATEGY == 'BLUE_GREEN'
                }
            }

            steps {
                sh '''
                    set -eu

                    TARGET=$(cat .release-target)

                    kubectl -n "${K8S_NAMESPACE}" \
                        patch service "${ACTIVE_SERVICE}" \
                        --type=merge \
                        -p "{\\"spec\\":{\\"selector\\":{\\"version\\":\\"${TARGET}\\"}}}"

                    echo "Production selector changed to ${TARGET}"
                '''
            }
        }

        stage('Verify Kubernetes Release') {
            when {
                expression {
                    params.DEPLOYMENT_STRATEGY != 'CI_ONLY'
                }
            }

            steps {
                sh '''
                    set -eu

                    ACTIVE=$(kubectl -n "${K8S_NAMESPACE}" \
                        get service "${ACTIVE_SERVICE}" \
                        -o jsonpath='{.spec.selector.version}')

                    kubectl -n "${K8S_NAMESPACE}" \
                        rollout status deployment/"java-app-${ACTIVE}" \
                        --timeout=300s

                    kubectl -n "${K8S_NAMESPACE}" \
                        wait pods \
                        -l "app=java-app,version=${ACTIVE}" \
                        --for=condition=Ready \
                        --timeout=180s

                    ACTUAL_IMAGE=$(kubectl -n "${K8S_NAMESPACE}" \
                        get deployment "java-app-${ACTIVE}" \
                        -o jsonpath='{.spec.template.spec.containers[?(@.name=="java-app")].image}')

                    test "${ACTUAL_IMAGE}" = "${IMAGE_URL}"

                    echo "Kubernetes release verified: ${ACTIVE}"
                '''
            }
        }

        stage('Verify ALB Targets') {
            when {
                expression {
                    params.DEPLOYMENT_STRATEGY != 'CI_ONLY'
                }
            }

            steps {
                sh '''
                    set -eu

                    ACTIVE=$(kubectl -n "${K8S_NAMESPACE}" \
                        get service "${ACTIVE_SERVICE}" \
                        -o jsonpath='{.spec.selector.version}')

                    echo "Waiting for ALB and healthy targets..."

                    SUCCESS=0

                    for ATTEMPT in $(seq 1 40); do

                        ALB_DNS=$(kubectl -n "${K8S_NAMESPACE}" \
                            get ingress "${INGRESS_NAME}" \
                            -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

                        if [ -z "${ALB_DNS}" ]; then
                            sleep 15
                            continue
                        fi

                        ALB_ARN=$(aws elbv2 describe-load-balancers \
                            --region "${AWS_REGION}" \
                            --query "LoadBalancers[?DNSName=='${ALB_DNS}'].LoadBalancerArn | [0]" \
                            --output text)

                        if [ -z "${ALB_ARN}" ] || [ "${ALB_ARN}" = "None" ]; then
                            sleep 15
                            continue
                        fi

                        TARGET_GROUPS=$(aws elbv2 describe-target-groups \
                            --load-balancer-arn "${ALB_ARN}" \
                            --region "${AWS_REGION}" \
                            --query 'TargetGroups[].TargetGroupArn' \
                            --output text)

                        POD_IPS=$(kubectl -n "${K8S_NAMESPACE}" \
                            get pods \
                            -l "app=java-app,version=${ACTIVE}" \
                            --field-selector=status.phase=Running \
                            -o jsonpath='{range .items[*]}{.status.podIP}{" "}{end}')

                        EXPECTED=$(printf '%s\\n' "${POD_IPS}" | wc -w)

                        if [ "${EXPECTED}" -lt 2 ]; then
                            sleep 15
                            continue
                        fi

                        for TG in ${TARGET_GROUPS}; do

                            HEALTHY_IPS=$(aws elbv2 describe-target-health \
                                --target-group-arn "${TG}" \
                                --region "${AWS_REGION}" \
                                --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`].Target.Id' \
                                --output text)

                            ALL_HEALTHY=1

                            for IP in ${POD_IPS}; do
                                if ! printf '%s\\n' "${HEALTHY_IPS}" | \
                                    tr '\\t' '\\n' | grep -Fxq "${IP}"; then
                                    ALL_HEALTHY=0
                                    break
                                fi
                            done

                            if [ "${ALL_HEALTHY}" -eq 1 ]; then
                                SUCCESS=1
                                break
                            fi
                        done

                        if [ "${SUCCESS}" -eq 1 ]; then
                            break
                        fi

                        echo "ALB targets not ready; attempt ${ATTEMPT}/40"
                        sleep 15
                    done

                    if [ "${SUCCESS}" -ne 1 ]; then
                        echo "ALB target health verification failed"
                        exit 1
                    fi

                    echo "ALB reports healthy targets for ${ACTIVE}"
                '''
            }
        }

        stage('Release Summary') {
            steps {
                echo "Build Number: ${env.BUILD_NUMBER}"
                echo "Docker Image: ${env.IMAGE_URL}"
                echo "Deployment Strategy: ${params.DEPLOYMENT_STRATEGY}"
                echo "Pipeline stages completed"
            }
        }
    }

    post {
        failure {
            script {
                if (params.DEPLOYMENT_STRATEGY == 'ROLLING_UPDATE') {
                    sh '''
                        if [ -f .rolling-deployment ] &&
                           [ -f .rolling-previous-image ] &&
                           [ -f "${KUBECONFIG}" ]; then

                            DEPLOYMENT=$(cat .rolling-deployment)
                            PREVIOUS_IMAGE=$(cat .rolling-previous-image)

                            echo "Attempting Rolling Update rollback..."

                            kubectl -n "${K8S_NAMESPACE}" \
                                set image deployment/"${DEPLOYMENT}" \
                                java-app="${PREVIOUS_IMAGE}" && \
                            kubectl -n "${K8S_NAMESPACE}" \
                                rollout status deployment/"${DEPLOYMENT}" \
                                --timeout=300s || \
                            echo "WARNING: Rolling rollback requires manual attention"
                        fi
                    '''
                }

                if (params.DEPLOYMENT_STRATEGY == 'BLUE_GREEN') {
                    sh '''
                        if [ -f .active-before-release ] &&
                           [ -f "${KUBECONFIG}" ]; then

                            PREVIOUS=$(cat .active-before-release)

                            echo "Attempting Blue/Green rollback to ${PREVIOUS}..."

                            kubectl -n "${K8S_NAMESPACE}" \
                                patch service "${ACTIVE_SERVICE}" \
                                --type=merge \
                                -p "{\\"spec\\":{\\"selector\\":{\\"version\\":\\"${PREVIOUS}\\"}}}" || \
                            echo "WARNING: Traffic rollback requires manual attention"
                        fi
                    '''
                }
            }

            echo 'Pipeline failed. Review deployment and rollback logs.'
        }

        aborted {
            echo 'Pipeline aborted. Check whether production traffic was changed.'
        }

        success {
            echo "Pipeline successful: ${env.IMAGE_URL}"
        }

        cleanup {
            sh '''
                rm -f .kubeconfig
                rm -f .active-before-release
                rm -f .release-target
                rm -f .rolling-deployment
                rm -f .rolling-previous-image
            '''
        }
    }
}
