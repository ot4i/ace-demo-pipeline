#!/bin/bash

# Aiming for something like
#
# <?xml version="1.0" encoding="UTF-8"?>
# <credentials>
#   <credential credentialType="jdbc" credentialName="tea">
#     <username>USERNAME</username>
#     <password>PASSWORD</password>
#   </credential>
# </credentials>
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

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
echo "<credentials>"

for credfile in /vault/secrets/*; do
    export CRED_NAME=$(basename $credfile)
    export CRED_TYPE=$(grep 'type=' $credfile | sed 's/type=//')
    echo "  <credential credentialType=\"$CRED_TYPE\" credentialName=\"$CRED_NAME\">"

    while IFS= read -r line
    do
	export CRED_COMPONENT=${line%%"="*}
	export CRED_VALUE=${line#*"="}
        echo "    <$CRED_COMPONENT>$CRED_VALUE</$CRED_COMPONENT>"
    done <<< $(cat $credfile | grep -v 'type=')

    echo "  </credential>"
done
echo "</credentials>"
