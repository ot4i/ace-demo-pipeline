#!/bin/bash

# Aiming for something like
# 
# Credentials:
#   jdbc:
#     tea:
#       username: "USERNAME"
#       password: "PASSWORD"
#
# from files that look like
#
# type=jdbc
# username=USERNAME
# password=PASSWORD
#
# assuming container configuration as follows
#
#      annotations:
#        vault.hashicorp.com/agent-inject: "true"
#        vault.hashicorp.com/agent-inject-secret-tea: "secret/tea"
#        vault.hashicorp.com/agent-inject-template-tea: |
#          {{- with secret "secret/tea" -}}
#          type={{ .Data.data.type }}
#          username={{ .Data.data.username }}
#          password={{ .Data.data.password }}
#          {{- end }}
#

echo "---"
echo "Credentials:"

for credfile in /vault/secrets/*; do
    export CRED_NAME=$(basename $credfile)
    export CRED_TYPE=$(grep 'type=' $credfile | sed 's/type=//')
    echo "  $CRED_TYPE:"
    echo "    $CRED_NAME:"

    while IFS= read -r line
    do
	export CRED_COMPONENT=${line%%"="*}
	export CRED_VALUE=${line#*"="}
        echo "      $CRED_COMPONENT: '$CRED_VALUE'"
    done <<< $(cat $credfile | grep -v 'type=')
done
