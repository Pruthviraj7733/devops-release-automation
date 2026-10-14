
pipeline {
    agent any

    parameters {
        choice(
            name: 'DEPLOYMENT_STRATEGY',
            choices: ['CI_ONLY', 'ROLLING_UPDATE', 'BLUE_GREEN'],
            description: 'Select the deployment strategy'
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
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -e
                    docker build -t "${IMAGE_URL}" .
                '''
            }
        }

        stage('Verify Docker Image') {
            steps {
                sh '''
                    set -e
                    docker image ls "${IMAGE_URL}"
                    test -n "$(docker image ls -q "${IMAGE_URL}")"
                    echo "Docker image verified successfully"
                '''
            }
        }

        stage('Authenticate to AWS ECR') {
            steps {
                sh '''
                    set -e
                    aws ecr get-login-password --region "${AWS_REGION}" | \
                    docker login --username AWS \
                    --password-stdin "${ECR_REGISTRY}"
                '''
            }
        }

        stage('Push Docker Image to Amazon ECR') {
            steps {
                sh '''
                    set -e
                    docker push "${IMAGE_URL}"
                '''
            }
        }

        stage('Verify Image in ECR') {
            steps {
                sh '''
                    set -e
                    aws ecr describe-images \
                        --repository-name "${ECR_REPOSITORY}" \
                        --image-ids "imageTag=${IMAGE_TAG}" \
                        --region "${AWS_REGION}"

                    echo "Docker image verified successfully in ECR"
                '''
            }
        }

        stage('Deployment Preparation') {
            steps {
                echo "Selected Strategy: ${params.DEPLOYMENT_STRATEGY}"
                echo "EKS Cluster: ${env.EKS_CLUSTER_NAME}"
                echo "Kubernetes Namespace: ${env.K8S_NAMESPACE}"
                echo "Image: ${env.IMAGE_URL}"
                echo "CD deployment is not enabled yet."
            }
        }
    }

    post {
        success {
            echo "Pipeline Successful: ${env.IMAGE_URL}"
        }

        failure {
            echo "Pipeline Failed. Check Console output"
        }
    }
}
