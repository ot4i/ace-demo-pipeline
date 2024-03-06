pipeline {
  agent { docker { 
    image 'cp.icr.io/cp/appc/ace:12.0.11.0-r1' 
    args '-e LICENSE=accept --entrypoint ""'
  } }
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

            export LICENSE=accept
            . /opt/ibm/ace-12/server/bin/mqsiprofile
        
            set -e # Fail on error - this must be done after the profile in case the container has the profile loaded already

            # Clean up just in case files have been left around
            rm -f */junit-reports/TEST*.xml
            rm -rf /tmp/test-work-dir

            echo ========================================================================
            echo Building application
            echo ========================================================================
            # Using --compile-maps-and-schemas for 12.0.11 and later . . . 
            ibmint package --input-path . --output-bar-file $PWD/tea-application-combined.bar --project TeaSharedLibraryJava --project TeaSharedLibrary --project TeaRESTApplication --compile-maps-and-schemas 

            echo ========================================================================
            echo Building unit tests
            echo ========================================================================
            # Create the unit test work directory
            mqsicreateworkdir /tmp/test-work-dir
            mqsibar -w /tmp/test-work-dir -a $PWD/tea-application-combined.bar 
            # Build just the unit tests
            ibmint deploy --input-path . --output-work-directory /tmp/test-work-dir --project TeaRESTApplication_UnitTest

            echo ========================================================================
            echo Running unit tests
            echo ========================================================================
            IntegrationServer -w /tmp/test-work-dir --no-nodejs --start-msgflows false --test-project TeaRESTApplication_UnitTest --test-junit-options --reports-dir=junit-reports
            '''

      }
      post {
        always {
            junit '**/junit-reports/TEST*.xml'
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
            export WORKDIR=/tmp/test-work-dir
            # Set HOME to somewhere writable by Maven
            export HOME=/tmp

            export LICENSE=accept
            . /opt/ibm/ace-12/server/bin/mqsiprofile
        
            set -e # Fail on error - this must be done after the profile in case the container has the profile loaded already

            mkdir ${WORKDIR}/run/CTPolicies
            echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:policyProjectDescriptor xmlns="http://com.ibm.etools.mft.descriptor.base" xmlns:ns2="http://com.ibm.etools.mft.descriptor.policyProject"><references/></ns2:policyProjectDescriptor>' > ${WORKDIR}/run/CTPolicies/policy.descriptor
            cp /tmp/TEAJDBC.policyxml ${WORKDIR}/run/CTPolicies/
            mqsisetdbparms -w ${WORKDIR} -n jdbc::tea -u $CT_JDBC_USR -p $CT_JDBC_PSW
            sed -i "s/#policyProject: 'DefaultPolicies'/policyProject: 'CTPolicies'/g" ${WORKDIR}/server.conf.yaml

            rm -f */junit-reports/TEST*.xml

            
            echo ========================================================================
            echo Building component tests
            echo ========================================================================
            
            # Build just the component tests
            ibmint deploy --input-path . --output-work-directory ${WORKDIR} --project TeaRESTApplication_ComponentTest

            echo ========================================================================
            echo Running component tests
            echo ========================================================================
            IntegrationServer -w ${WORKDIR} --no-nodejs --start-msgflows false --test-project TeaRESTApplication_ComponentTest --test-junit-options --reports-dir=junit-reports

            '''
      }
      post {
        always {
            junit '**/junit-reports/TEST*.xml'
        }
      }
    }

    stage('Next stage deploy') {
      steps {
        sh "bash -c \"export LICENSE=accept ; . /opt/ibm/ace-12/server/bin/mqsiprofile ; mqsideploy -i ${params.integrationNodeHost} -p ${params.integrationNodePort} -e ${params.integrationServerName} -a tea-application-combined.bar\""
      }
    }

  }
  environment {
    CT_JDBC = credentials('CT_JDBC')
  }
}
