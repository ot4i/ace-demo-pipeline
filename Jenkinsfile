pipeline {
  agent { docker { image 'ace-minimal-build:12.0.7.0-alpine' } }
  stages {
    stage('Build and UT') {
      steps {
        sh  '''#!/bin/bash
            env | sort
            mqsilist
            '''
      }
    }

    stage('Test DB interactions') {
      steps {
        sh 'echo CT'
      }
    }

    stage('Next stage BAR build') {
      steps {
        sh 'echo BAR'
      }
    }

    stage('Next stage deploy') {
      steps {
        sh 'echo deploy'
      }
    }

  }
}