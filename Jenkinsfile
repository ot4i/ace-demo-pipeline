pipeline {
  agent { docker { 
    image 'cp.icr.io/cp/appc/ace:12.0.11.0-r1'
    /* image 'ace-minimal:12.0.11.0-alpine' */
    args '-e LICENSE=accept --entrypoint ""'
  } }
  parameters {
    /* These values would be better moved to a configuration file and provided by */
    /* the Config File Provider plugin (or equivalent), but this is good enough   */
    /* for a demo of ACE pipelines that isn't intended as a Jenkins tutorial.     */
    string(name: 'databaseName', defaultValue: 'BLUDB', description: 'JDBC database name')
    string(name: 'serverName',   defaultValue: '19af6446-6171-4641-8aba-9dcff8e1b6ff.c1ogj3sd0tgtu0lqde00.databases.appdomain.cloud', description: 'JDBC database host')
    string(name: 'portNumber',   defaultValue: '30699', description: 'JDBC database port')
    string(name: 'deployPrefix',   defaultValue: 'tdolby', description: 'ACEaaS artifact prefix')
    string(name: 'APPCON_ENDPOINT',   defaultValue: 'api.p-vir-c1.appconnect.automation.ibm.com', description: 'ACEaaS endpoint hostname')
    booleanParam(name: 'DEPLOY_CONFIGURATION', defaultValue: false, description: 'Create policies, runtime, etc')
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
        sh "echo ${params.APPCON_ENDPOINT} > /tmp/APPCON_ENDPOINT"
        sh "echo ${params.deployPrefix} > /tmp/deployPrefix"
        
        sh  '''#!/bin/bash
            # Set HOME to somewhere writable by Maven
            export HOME=/tmp

            export LICENSE=accept
            . /opt/ibm/ace-12/server/bin/mqsiprofile
        
            #set -e # Fail on error - this must be done after the profile in case the container has the profile loaded already

            echo "########################################################################"
            echo "# Acquiring token using API key"
            echo "########################################################################" && echo

            #curl --request POST \
            #  --url https://`cat /tmp/APPCON_ENDPOINT`/api/v1/tokens \
            #  --header "X-IBM-Client-Id: ${APPCON_CLIENT_ID}" \
            #  --header "X-IBM-Client-Secret: ${APPCON_CLIENT_SECRET}" \
            #  --header 'accept: application/json' \
            #  --header 'content-type: application/json' \
            #  --header "x-ibm-instance-id: ${APPCON_INSTANCE_ID}" \
            #  --data "{\\"apiKey\\": \\"${APPCON_API_KEY}\\"}" --output /tmp/token-output.txt
            cat /tmp/token-output.txt  | tr -d '{}"' | tr ',' '\n' | grep access_token | sed 's/access_token://g' > /tmp/APPCON_TOKEN

            #curl -X PUT https://`cat /tmp/APPCON_ENDPOINT`/api/v1/bar-files/`cat /tmp/deployPrefix`-tea-jenkins \
            #  -H "x-ibm-instance-id: ${APPCON_INSTANCE_ID}" -H "Content-Type: application/octet-stream" \
            #  -H "Accept: application/json" -H "X-IBM-Client-Id: ${APPCON_CLIENT_ID}" -H "authorization: Bearer `cat /tmp/APPCON_TOKEN`" \
            #  --data-binary @tea-application-combined.bar  --output /tmp/curl-output.txt
            
            # We will have exited if curl returned non-zero so the output should contain the BAR file name
            cat /tmp/curl-output.txt ; echo
            # This would be easier with jq but that's not available in most ACE images
            export BARURL=$(cat /tmp/curl-output.txt | tr -d '{}"' | tr ',' '\n' | grep url | sed 's/url://g')
            echo BARURL: $BARURL
            echo -n $BARURL > /tmp/BARURL.txt
            '''
      }
    }

    stage('Create configuration') {
      when {
        expression {
          def deployConfiguration=${params.DEPLOY_CONFIGURATION}
          return deployConfiguration != null && deployConfiguration == true
        }
      }

      steps {
        sh "echo ${params.APPCON_ENDPOINT} > /tmp/APPCON_ENDPOINT"
        sh "echo ${params.deployPrefix} > /tmp/deployPrefix"
        
        sh  '''#!/bin/bash
            # Set HOME to somewhere writable by Maven
            export HOME=/tmp

            export LICENSE=accept
            . /opt/ibm/ace-12/server/bin/mqsiprofile
        
            set -e # Fail on error - this must be done after the profile in case the container has the profile loaded already

            echo "########################################################################"
            echo "# "
            echo "########################################################################" && echo

            '''
      }
    }
                
  }
  environment {
    CT_JDBC = credentials('CT_JDBC')
    APPCON_INSTANCE_ID = credentials('APPCON_INSTANCE_ID')
    APPCON_CLIENT_ID = credentials('APPCON_CLIENT_ID')
    APPCON_CLIENT_SECRET = credentials('APPCON_CLIENT_SECRET')
    APPCON_API_KEY = credentials('APPCON_API_KEY')
  }
}
