pipeline {
  agent any
  stages {
    stage('Build and UT') {
      steps {
        sh 'scripts/build-and-ut.sh'
        junit 'TeaTests/TEST*xml'
        sh 'scripts/force-failure-on-junit-fail.sh'
      }
    }

    stage('Test DB Interactions') {
      steps {
        sh 'scripts/component-test.sh'
      }
    }

    stage('Preprod BAR Build') {
      steps {
        sh 'scripts/preprod-bar-build.sh'
      }
    }

    stage('Preprod Deploy and Test') {
      steps {
        sh 'scripts/preprod-deploy-and-test.sh'
      }
    }

  }
  environment {
    CLASSPATH = """${sh(returnStdout: true, script: 'echo -n "$CLASSPATH:$MQSI_CLASSPATH"')}"""
    IBMCLOUD_APIKEY = credentials('IBMCLOUD_APIKEY')
    CT_JDBC = credentials('CT_JDBC')
  }
}