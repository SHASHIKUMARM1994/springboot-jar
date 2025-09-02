pipeline {
  agent any

  environment {
    AWS_ACCOUNT_ID = "908027415089"         // replace
    AWS_REGION     = "us-east-1"
    REPO_NAME      = "springboot"
    IMAGE_TAG      = "build-${BUILD_NUMBER}"
    ECR_URI        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}"
    FULL_IMAGE     = "${ECR_URI}:${IMAGE_TAG}"
    SONAR_SERVER   = "sonar"        // SonarQube server name in Jenkins config
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build') {
      steps {
        sh 'mvn -B -DskipTests package'
      }
    }

    stage('Test') {
      steps {
        sh 'mvn test'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv("${SONAR_SERVER}") {
          sh 'mvn sonar:sonar'
        }
      }
    }

    stage('Trivy Code Scan') {
      steps {
        sh 'trivy fs --exit-code 1 --severity HIGH,CRITICAL . || (echo "Trivy FS found issues"; exit 1)'
      }
    }

    stage('Docker Build') {
      steps {
        sh "docker build -t ${FULL_IMAGE} ."
      }
    }

    stage('Trivy Image Scan') {
      steps {
        sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${FULL_IMAGE} || (echo 'Image scan failed'; exit 1)"
      }
    }

    stage('Push to ECR') {
      steps {
        // If using Jenkins credentials as secret texts:
        withCredentials([
          string(credentialsId: 'aws_access_key', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'aws_secret_key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          sh '''
            export AWS_DEFAULT_REGION=${AWS_REGION}
            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI}
            docker push ${FULL_IMAGE}
          '''
        }
        // If using instance profile, remove withCredentials block and just run the aws login + push lines
      }
    }

    stage('Deploy to target (EC2 via SSH)') {
      steps {
        // Option A: Deploy to an EC2 host using SSH (needs credential id ec2-ssh-key)
        sshagent (credentials: ['ec2-ssh-key']) {
          sh """
            ssh -o StrictHostKeyChecking=no ubuntu@<TARGET_EC2_IP> '
              docker pull ${FULL_IMAGE} &&
              docker rm -f springboot || true &&
              docker run -d --name springboot -p 8080:8080 ${FULL_IMAGE}
            '
          """
        }
      }
    }

    /*
    // Option B: Deploy to ECS - uncomment & use if you have ECS
    stage('Deploy to ECS') {
      steps {
        sh """
          aws ecs update-service --cluster myCluster --service myService --force-new-deployment --region ${AWS_REGION}
        """
      }
    }
    */
  }

  post {
    always {
      echo "Pipeline finished: ${currentBuild.currentResult}"
    }
  }
}
