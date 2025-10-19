pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub') // Docker Hub credentials in Jenkins
        GITHUB_CREDENTIALS = 'github'                    // GitHub credentials in Jenkins
        IMAGE_NAME = 'phani051/my-site'                      // Docker Hub repo
        GIT_REPO = 'https://github.com/phani051/dockerlearning.git' // Replace with your repo
        BRANCH = 'main'
        NODE_OPTIONS = '--openssl-legacy-provider'            // For React build if needed
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
                script {
                    docker.build("${IMAGE_NAME}:${COMMIT_HASH}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', "${DOCKERHUB_CREDENTIALS}") {
                        docker.image("${IMAGE_NAME}:${COMMIT_HASH}").push()
                        docker.image("${IMAGE_NAME}:${COMMIT_HASH}").push('latest') // optional latest tag
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
