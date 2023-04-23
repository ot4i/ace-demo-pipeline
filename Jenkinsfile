pipeline {
  agent { docker { image 'ace-minimal-build:12.0.8.0-alpine' } }
  parameters {
    /* These values would be better moved to a configuration file and provided by */
    /* the Config File Provider plugin (or equivalent), but this is good enough   */
    /* for a demo of ACE pipelines that isn't intended as a Jenkins tutorial.     */
    string(name: 'databaseName', defaultValue: 'BLUDB', description: 'JDBC database name')
    string(name: 'serverName',   defaultValue: '19af6446-6171-4641-8aba-9dcff8e1b6ff.c1ogj3sd0tgtu0lqde00.databases.appdomain.cloud', description: 'JDBC database host')
    string(name: 'portNumber',   defaultValue: '30699', description: 'JDBC database port')
    string(name: 'integrationNodeHost',   defaultValue: '10.0.0.2', description: 'Integration node REST API host or IP address')
    string(name: 'integrationNodePort',   defaultValue: '4414', description: 'Integration node REST API port')
    string(name: 'integrationServerName',   defaultValue: 'default', description: 'Integration server name')
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
        sh "cat demo-infrastructure/TEAJDBC.policyxml | sed 's/DATABASE_NAME/${params.databaseName}/g' > /tmp/TEAJDBC.policyxml"
        sh "sed -i 's/SERVER_NAME/${params.serverName}/g' /tmp/TEAJDBC.policyxml"
        sh "sed -i 's/PORT_NUMBER/${params.portNumber}/g' /tmp/TEAJDBC.policyxml"
        
        sh  '''#!/bin/bash
            # Should alread have the projects unpacked
            export WORKDIR=$PWD/ace-server
            # Set HOME to somewhere writable by Maven
            export HOME=/tmp

            mkdir ${WORKDIR}/run/CTPolicies
            echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:policyProjectDescriptor xmlns="http://com.ibm.etools.mft.descriptor.base" xmlns:ns2="http://com.ibm.etools.mft.descriptor.policyProject"><references/></ns2:policyProjectDescriptor>' > ${WORKDIR}/run/CTPolicies/policy.descriptor
            cp /tmp/TEAJDBC.policyxml ${WORKDIR}/run/CTPolicies/
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
         sh  '''#!/bin/bash
            # Build a single BAR file that contains everything rather than deploying two BAR files.
            # Deploying two BAR files (one for the shared library and the other for the application)
            # would work, but would take longer on redeploys due to reloading the application on
            # each deploy.
            #
            # The Tekton pipeline doesn't have this issue because the application and library are
            # unpacked into a work directory in a container image in that pipeline, so there is no
            # deploy to a running server.
            mqsipackagebar -w $PWD -a tea-application-combined.bar -y TeaSharedLibrary -k TeaRESTApplication

            # Optional compile for XMLNSC, DFDL, and map resources. Useful as long as the target 
            # broker is the same OS, CPU, and installation including ifixes as the build system.
            # mqsibar --bar-file tea-application-combined.bar --compile
            '''
      }
    }

    stage('Next stage deploy') {
      steps {
        sh "bash -c \"mqsideploy -i ${params.integrationNodeHost} -p ${params.integrationNodePort} -e ${params.integrationServerName} -a tea-application-combined.bar\""
      }
    }

  }
  environment {
    CT_JDBC = credentials('CT_JDBC')
  }
}
