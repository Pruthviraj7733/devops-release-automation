
pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '734836384716'
        ECR_REPOSITORY = 'java-application'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG = "${BUILD_NUMBER}"
        IMAGE_URL = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t "${IMAGE_URL}" .
                '''
            }
        }

        stage('Verify Docker Image') {
            steps {
                sh '''
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
                    docker push "${IMAGE_URL}"
                '''
            }
        }

        stage('Verify Image in ECR') {
            steps {
                sh '''
                    aws ecr describe-images \
                        --repository-name "${ECR_REPOSITORY}" \
                        --image-ids "imageTag=${IMAGE_TAG}" \
                        --region "${AWS_REGION}"
                '''
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
