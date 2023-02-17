pipeline {
  agent { docker { image 'ace-minimal-build:12.0.7.0-alpine' } }
  parameters {
    /* These values would be better moved to a configuration file and provided by */
    /* the Config File Provider plugin (or equivalent), but this is good enough   */
    /* for a demo of ACE pipelines that isn't intended as a Jenkins tutorial.     */
    string(name: 'databaseName', defaultValue: 'BLUDB', description: 'JDBC database name')
    string(name: 'serverName',   defaultValue: '19af6446-6171-4641-8aba-9dcff8e1b6ff.c1ogj3sd0tgtu0lqde00.databases.appdomain.cloud', description: 'JDBC database host')
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
        sh "cat demo-infrastructure/TEAJDBC.policyxml | sed 's/DATABASE_NAME/${params.databaseName}/g' > /tmp/TEADJDBC.policyxml"
        sh "sed -i 's/SERVER_NAME/${params.serverName}/g' /tmp/TEADJDBC.policyxml"
        sh "sed -i 's/PORT_NUMBER/${params.portNumber}/g' /tmp/TEADJDBC.policyxml"
        
        sh  '''#!/bin/bash
            # Should alread have the projects unpacked
            export WORKDIR=$PWD/ace-server
            # Set HOME to somewhere writable by Maven
            export HOME=/tmp

            mkdir ${WORKDIR}/run/CTPolicies
            echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:policyProjectDescriptor xmlns="http://com.ibm.etools.mft.descriptor.base" xmlns:ns2="http://com.ibm.etools.mft.descriptor.policyProject"><references/></ns2:policyProjectDescriptor>' > ${WORKDIR}/run/CTPolicies/policy.descriptor
            cp /tmp/TEADJDBC.policyxml ${WORKDIR}/run/CTPolicies/
            mqsisetdbparms -w ${WORKDIR} -n jdbc::tea -u $CT_JDBC_USR -p $CT_JDBC_PSW
            sed -i "s/#policyProject: 'DefaultPolicies'/policyProject: 'CTPolicies'/g" ${WORKDIR}/server.conf.yaml

            rm -f */maven-reports/TEST*.xml
            ( cd TeaRESTApplication_ComponentTest && mvn --no-transfer-progress -Dct.work.directory=${WORKDIR} verify )
            '''
      }
      post {
        always {
            junit '**/maven-reports/TEST*.xml'
        }
      }
    }

    stage('Next stage BAR build') {
      steps {
        sh 'echo BAR'
      }
    }

    stage('Next stage deploy') {
      steps {
        
        sh  '''#!/bin/bash
            mqsideploy -i 10.0.0.2 -p 4414 -e default -a TeaSharedLibrary/tea-shlib.bar
            mqsideploy -i 10.0.0.2 -p 4414 -e default -a TeaRESTApplication/tea.bar
            '''
      }
    }

  }
  environment {
    CT_JDBC = credentials('CT_JDBC')
  }
}