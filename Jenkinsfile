pipeline {
  agent { docker { image 'ace-minimal-build:12.0.7.0-alpine' } }
  parameters {
    /* These values would be better moved to a configuration file and provided by */
    /* the Config File Provider plugin (or equivalent), but this is good enough   */
    /* for a demo of ACE pipelines that isn't intended as a Jenkins tutorial.     */
    string(name: 'databaseName', defaultValue: 'BLUDB', description: 'JDBC database name')
    string(name: 'serverName',   defaultValue: '19af6446-6171-4641-8aba-9dcff8e1b6ff.c1ogj3sd0tgtu0lqde00.databases.appdomain.clou', description: 'JDBC database host')
    string(name: 'portNumber',   defaultValue: '30699', description: 'JDBC database port')
  }
  stages {
    stage('Build and UT') {
      steps {
        sh  '''#!/bin/bash
            # Set HOME to somewhere writable by Maven
            export HOME=/tmp

            # Clean up just in case files have been left around
            rm -f */maven-reports/TEST*.xml
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
            echo Database credentials follow
            echo Username: $CT_JDBC_USR
            echo Password: $CT_JDBC_PSW
            echo Name: ${params.databaseName}
            echo Host: ${params.serverName}
            echo Port: ${params.portNumber}
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