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
            mvn --no-transfer-progress -Dinstall.work.directory=$PWD/ace-server install
            ls -l /tmp/mvn-reports
            cp -r /tmp/mvn-reports .
            '''
        sh 'ls -l mvn-reports'
        junit 'mvn-reports/TEST*xml'
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
}