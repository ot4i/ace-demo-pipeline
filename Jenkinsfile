pipeline {
  agent { docker { image 'ace-minimal-build:12.0.7.0-alpine' } }
  stages {
    stage('Build and UT') {
      steps {
        sh  '''#!/bin/bash
            export HOME=/tmp
            env | sort
            mqsilist
            id
            rm -f junit-failures-occurred
            rm -rf $PWD/ace-server

            mvn --no-transfer-progress -Dinstall.work.directory=$PWD/ace-server install
            '''

      }
      post {
        always {
            junit '**/maven-reports/TEST*.xml'
        }
      }
    }

    stage('Test DB interactions') {
      steps {
        sh  '''#!/bin/bash
            echo CT
            env | sort
            mqsilist
            pwd
            ls -l 
            df -k
            '''
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
  environment {
    CT_JDBC = credentials('CT_JDBC')
  }
}