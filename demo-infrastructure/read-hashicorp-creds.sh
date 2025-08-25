#!/bin/bash

# Aiming for YAML like
# 
# Credentials:
#   jdbc:
#     tea:
#       username: "USERNAME"
#       password: "PASSWORD"
#
# from files with contents like
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

# Create an associative array so we can sort by credential type.
declare -A CRED_TYPES
for credfile in /vault/secrets/*; do
    CRED_TYPE=$(grep 'type=' $credfile | tr -d '\r' | sed 's/type=//')
    CRED_TYPES[${CRED_TYPE}]="$(basename $credfile) ${CRED_TYPES[${CRED_TYPE}]}"
done

# CRED_TYPES now contains the list of credentials for each type
for credType in "${!CRED_TYPES[@]}"; do
    # YAML spacing is important - two spaces before the type, four in front 
    # of the name, and six for username/password/etc.
    echo "  $credType:"
    for credName in ${CRED_TYPES[$credType]}; do
        echo "    ${credName}:"
        # The original lines look like 'username=USERNAME' and we need to convert
        # to '      username: "USERNAME"' with sed. Also need to exclude "type".
        cat /vault/secrets/${credName} | tr -d '\r' | grep -v 'type=' | sed 's/=/: "/' | sed 's/^/      /' | sed 's/$/"/g'
    done
done
