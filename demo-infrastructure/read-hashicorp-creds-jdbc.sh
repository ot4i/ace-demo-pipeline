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
echo "  jdbc:"
for credfile in /vault/secrets/*; do
    # YAML spacing is important - two spaces before the type, four in front 
    # of the name, and six for username/password/etc.
    echo "    $(basename $credfile):"
    # The original lines look like 'username=USERNAME' and we need to convert
    # to '      username: "USERNAME"' with sed. Also need to exclude "type".
    cat ${credfile} | tr -d '\r' | grep -v 'type=' | sed 's/=/: "/' | sed 's/^/      /' | sed 's/$/"/g'
done
