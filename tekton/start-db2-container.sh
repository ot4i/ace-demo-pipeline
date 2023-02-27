#!/bin/bash

export NS=default
export POD_NAME=db2-test-pod

kubectl get pods -n ${NS}

#echo "Checking for previous component test leftovers at " `date`
#kubectl get -n ${NS} Pod/${POD_NAME}
#if [ "$?" == "0" ]; then
#    echo "Found pod; deleting it at " `date`
#    kubectl delete -n ${NS} Pod/${POD_NAME}
#    for i in `seq 1 24`
#    do
#        podName=`kubectl get -n ${NS} -l app=${POD_NAME} pod -o name`
#        if [ "$podName" == "" ]; then
#            echo "Pods not running at " `date`
#            rc=0
#            break
#        else
#            echo "Found pod $podName at " `date`
#        fi
#        sleep 5
#    done
#    sleep 10
#else
#    echo "No pod found at " `date`
#fi
#
#echo "Creating DB2 container for component test at " `date`
#cat /mnt/c/Users/684084897/git/ace-demo-pipeline/tekton/db2-test-pod.yaml | sed 's/PASSWORD_REPLACEMENT_STRING/SecurePassw0rd/g' | kubectl apply -f -
#
#rc=1
#echo "Starting polling for database start at " `date`
#for i in `seq 1 120`
#do
#    kubectl logs -n ${NS} Pod/${POD_NAME} | tail -n 20  | grep "Setup has completed"
#    if [ "$?" == "0" ]; then
#        echo "Container is ready at " `date`
#        rc=0
#        break
#    fi
#    if [ $( expr $i % 6 ) == "0" ]; then
#	echo "Still waiting after" $( expr $i \* 5 ) "seconds . . ."
#    fi
#    sleep 5
#done
#
#if [ "$rc" == "1" ]; then
#    echo "Container start failed; giving up at " `date`
#    echo "Current logs from the pod:"
#    echo "----------------------------------------"
#    kubectl logs -n ${NS} Pod/${POD_NAME}
#    echo "----------------------------------------"
#    return 1
#fi




echo "Creating credentials in /work/jdbc at " `date`
podIP=$(kubectl get pod -n ${NS} ${POD_NAME} --template '{{.status.podIP}}')
echo "Found podIP $podIP"
mkdir -p /work/jdbc
echo db2inst1 > /work/jdbc/USERID
echo SecurePassw0rd > /work/jdbc/PASSWORD
echo TESTDB > /work/jdbc/databaseName # From pod yaml
echo $podIP > /work/jdbc/serverName
echo 50000 > /work/jdbc/portNumber # default

echo "Setting up auto-shutdown script at " `date`

scriptFile=$(mktemp)
cat <<EOF > $scriptFile
#!/bin/bash

# Create second script to shut the container down after 30 minutes

echo "#!/bin/bash"   > /tmp/timed-shutdown.sh
echo 'echo "### Sleeping for 1800 seconds" >> /proc/1/fd/1' >> /tmp/timed-shutdown.sh
echo "sleep 1800"   >> /tmp/timed-shutdown.sh
echo 'echo "### Sending SIGTERM to process 1" >> /proc/1/fd/1' >> /tmp/timed-shutdown.sh
echo "kill -TERM 1" >> /tmp/timed-shutdown.sh
chmod 775 /tmp/timed-shutdown.sh

echo "### Starting timed shutdown script" >> /proc/1/fd/1
cd /tmp
echo "" | nohup /tmp/timed-shutdown.sh > /dev/null 2>&1 &
echo "Timer script launched; exiting"
EOF

#cat $scriptFile
chmod 775 $scriptFile
kubectl cp $scriptFile ${NS}/${POD_NAME}:/tmp/shutdown-script.sh
# kubectl exec db2-test-pod -- /tmp/shutdown-script.sh
rm $scriptFile
