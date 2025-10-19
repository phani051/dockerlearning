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
                sh """
                    docker build \
                        --build-arg NODE_OPTIONS='${NODE_OPTIONS}' \
                        -t ${IMAGE_NAME}:${COMMIT_HASH} .
                """
            }
        }

        stage('Push & Run Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
                    sh """
                        # Login to Docker Hub
                        echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_USERNAME --password-stdin

                        # Push image with commit hash
                        docker push ${IMAGE_NAME}:${COMMIT_HASH}

                        # Tag as latest and push
                        docker tag ${IMAGE_NAME}:${COMMIT_HASH} ${IMAGE_NAME}:latest
                        docker push ${IMAGE_NAME}:latest

                        # Stop and remove previous container if exists
                        if [ \$(docker ps -q -f name=my-site-container) ]; then
                            docker stop my-site-container
                            docker rm my-site-container
                        fi

                        # Run new container on port 80
                        docker run -d --name my-site-container -p 3000:80 ${IMAGE_NAME}:${COMMIT_HASH}
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
