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

        stage('Push Docker Image') {
            steps {
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
                script {
                    // Ensure Docker Swarm is active
                    def swarmStatus = sh(script: "docker info --format '{{.Swarm.LocalNodeState}}'", returnStdout: true).trim()
                    if (swarmStatus != 'active') {
                        echo 'Docker Swarm not active — initializing...'
                        sh 'docker swarm init || true'
                    }

                    // Check if service exists
                    def serviceExists = sh(
                        script: "docker service ls --format '{{.Name}}' | grep -w my-site || true",
                        returnStdout: true
                    ).trim()

                    if (serviceExists == 'my-site') {
                        echo "Updating existing Swarm service..."
                        sh "docker service update --image ${IMAGE_NAME}:latest my-site"
                    } else {
                        echo 'Creating new Swarm service...'
                        sh """
                            docker service create \
                                --name my-site \
                                --publish 3000:80 \
                                --replicas 2 \
                                ${IMAGE_NAME}:latest
                        """
                    }
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
 