pipeline {
    agent any

    environment {
        GITHUB_CREDENTIALS = 'github'          // GitHub credentials ID
        IMAGE_NAME = 'phani051/my-site'        // Docker Hub repo
        GIT_REPO = 'https://github.com/phani051/dockerlearning.git'
        BRANCH = 'main'
        NODE_OPTIONS = '--openssl-legacy-provider'  // React build fix for Node 18+
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: "${BRANCH}", url: "${GIT_REPO}", credentialsId: "${GITHUB_CREDENTIALS}"
            }
        }

        stage('Get Commit Hash') {
            steps {
                script {
                    COMMIT_HASH = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    echo "Commit hash: ${COMMIT_HASH}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                // Build Docker image which will also run npm install and npm build inside Dockerfile
                sh """
                    docker build \
                        --build-arg NODE_OPTIONS='${NODE_OPTIONS}' \
                        -t ${IMAGE_NAME}:${COMMIT_HASH} .
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                // Securely use Docker Hub credentials without exposing them
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
                    sh """
                        echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_USERNAME --password-stdin
                        docker push ${IMAGE_NAME}:${COMMIT_HASH}
                        docker tag ${IMAGE_NAME}:${COMMIT_HASH} ${IMAGE_NAME}:latest
                        docker push ${IMAGE_NAME}:latest
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs() // Clean workspace after build
        }
    }
}
