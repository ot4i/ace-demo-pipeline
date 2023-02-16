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
            
            if [ "$?" != "0" ]; then
                echo "testing failed"
                touch junit-failures-occurred
            fi
            # Test results have to be copied out of container temporary storage to be visible
            ls -l /tmp/mvn-reports
            cp -r /tmp/mvn-reports .
            /bin/true
            '''
        junit 'mvn-reports/TEST*xml'
        
        sh  '''#!/bin/bash
            if [ -f "junit-failures-occurred" ]; then
                echo "testing failed - forcing a failure"
                /bin/false
            else
                /bin/true
            fi
            '''
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