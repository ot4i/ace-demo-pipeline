#!/bin/bash

if [ "$NS" == "" ]; then
    echo "Using default namespace"
    export NS=default
fi
export POD_NAME=db2-test-pod

rc=1
echo "Starting polling for database start at " `date`
for i in `seq 1 120`
do
    kubectl logs -n ${NS} Pod/${POD_NAME} | tail -n 20  | grep "Setup has completed"
    if [ "$?" == "0" ]; then
        echo "Container is ready at " `date`
        rc=0
        break
    fi
    if [ $( expr $i % 6 ) == "0" ]; then
	echo "Still waiting after" $( expr $i \* 5 ) "seconds . . ."
    fi
    sleep 5
done

if [ "$rc" == "1" ]; then
    echo "Database start failed; giving up at " `date`
    echo "Current logs from the pod:"
    echo "----------------------------------------"
    kubectl logs -n ${NS} Pod/${POD_NAME}
    echo "----------------------------------------"
    return 1
fi


echo "Creating credentials in /work/jdbc at " `date`
podIP=$(kubectl get pod -n ${NS} ${POD_NAME} --template '{{.status.podIP}}')
echo "Found podIP $podIP"
mkdir -p /work/jdbc
echo db2inst1 > /work/jdbc/USERID
echo SecurePassw0rd > /work/jdbc/PASSWORD
echo TESTDB > /work/jdbc/databaseName # From pod yaml
echo $podIP > /work/jdbc/serverName
echo 50000 > /work/jdbc/portNumber # default
