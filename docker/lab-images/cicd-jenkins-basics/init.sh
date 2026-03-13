#!/bin/bash
mkdir -p ~/jenkins-lab
cat > ~/jenkins-lab/Jenkinsfile << 'JF'
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building application...'
                sh 'echo build complete'
            }
        }
        stage('Test') {
            steps {
                echo 'Running tests...'
                // TODO: add actual test command
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying...'
                // TODO: add deploy steps
            }
        }
    }
}
JF
echo "Jenkinsfile created in ~/jenkins-lab/"
echo "Task: Complete the Test and Deploy stages"
