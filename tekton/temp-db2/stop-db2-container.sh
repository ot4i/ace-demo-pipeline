#!/bin/bash

export NS=default
export POD_NAME=db2-test-pod

kubectl get pods -n ${NS}

echo "Checking for component test container at " `date`
kubectl get -n ${NS} Pod/${POD_NAME}
if [ "$?" == "0" ]; then
    echo "Found pod; deleting it at " `date`
    kubectl delete -n ${NS} Pod/${POD_NAME}
    for i in `seq 1 24`
    do
        podName=`kubectl get -n ${NS} -l app=${POD_NAME} pod -o name`
        if [ "$podName" == "" ]; then
            echo "Pods not running at " `date`
            rc=0
            break
        else
            echo "Found pod $podName at " `date`
        fi
        sleep 5
    done
else
    echo "No pod found at " `date`
fi

