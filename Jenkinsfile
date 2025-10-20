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
                echo "Building Docker image for commit ${COMMIT_HASH}..."
                sh """
                    docker build \
                        --build-arg NODE_OPTIONS='${NODE_OPTIONS}' \
                        -t ${IMAGE_NAME}:${COMMIT_HASH} .
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "Pushing Docker image to Docker Hub..."
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

        stage('Deploy to Docker Swarm') {
            steps {
                echo "Deploying Docker image to Swarm..."
                sh '''
                    # Initialize Swarm if not already initialized
                    docker info | grep -q "Swarm: active" || docker swarm init

                    SERVICE_NAME=my-site

                    # Check if service exists
                    if docker service ls --format '{{.Name}}' | grep -q "$SERVICE_NAME"; then
                        echo "Service already exists. Updating with latest image..."
                        docker service update --image ${IMAGE_NAME}:latest --force $SERVICE_NAME
                    else
                        echo "Creating new service..."
                        docker service create --name $SERVICE_NAME -p 3000:80 --replicas 4 ${IMAGE_NAME}:latest
                    fi
                '''
            }
        }

        stage('Cleanup Old Images') {
            steps {
                echo "Cleaning up old phani051/my-site images..."
                sh '''
                    USED_IMAGES=$(docker ps --format '{{.Image}}' | grep 'phani051/my-site' || true)
                    SERVICE_IMAGES=$(docker service ls --format '{{.Image}}' | grep 'phani051/my-site' || true)
                    KEEP_IMAGES=$(echo "$USED_IMAGES $SERVICE_IMAGES" | tr ' ' '\\n' | sort -u)

                    echo "Currently used images:"
                    echo "$KEEP_IMAGES"

                    ALL_IMAGES=$(docker images phani051/my-site --format '{{.ID}} {{.Repository}}:{{.Tag}}')

                    for IMAGE_ID in $(echo "$ALL_IMAGES" | awk '{print $1}'); do
                        IMAGE_TAG=$(echo "$ALL_IMAGES" | grep "$IMAGE_ID" | awk '{print $2}')
                        if ! echo "$KEEP_IMAGES" | grep -q "$IMAGE_TAG"; then
                            echo "Removing unused image: $IMAGE_TAG"
                            docker rmi -f "$IMAGE_ID" || true
                        fi
                    done
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful! The latest version is running in Docker Swarm."
        }
        failure {
            echo "❌ Deployment failed. Please check Jenkins logs for details."
        }
        always {
            cleanWs() // Clean workspace after build
        }
    }
}
