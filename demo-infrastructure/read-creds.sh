#!/bin/bash

# Aiming for something like
# 
# Credentials:
#   jdbc:
#     tea:
#       username: "USERNAME"
#       password: "PASSWORD"
#     other:
#       username: "USERNAME1"
#       password: "PASSWORD1"
#   kafka:
#     tea:
#       username: "USERNAME2"
#       password: "PASnSWORD2"
#
# from files in subdirectories (one per Kube secret) that have contents like
#
# name tea
# type jdbc
# username USERNAME
# password PASSWORD
#
# created from Kube secrets that look like
#
# data:
#   name: dGVhCg==
#   type: amRiYwo=
#   username: VVNFUk5BTUUK
#   password: UEFTU1dPUkQK
#
# and are mounted under /app/secrets or wherever CREDSDIR points to.
#
# 


# Might not be any credentials
FirstCred=1
CredsDir=/app/secrets
if [ "$CREDSDIR" != "" ]; then
    CredsDir=${CREDSDIR}
fi

# Build up a set of files in a temporary directory, one file for
# each credential type found.
for creddir in ${CredsDir}/*; do
    # Make sure there's at least one match
    [ -e "${creddir}" ] || continue

    if [ "$FirstCred" == "1" ]; then
        FirstCred=0
	export TEMP_SECRETS_DIR=$(mktemp -d)
	mkdir -p $TEMP_SECRETS_DIR
    fi
    # find key information and create the file for this type on the first time through
    CRED_TYPE=$(cat $creddir/type)
    CRED_NAME=$(cat $creddir/name)
    export TEMP_SECRETS_FILE="${TEMP_SECRETS_DIR}/${CRED_TYPE}-snippet.yaml"
    if [ ! -e "${TEMP_SECRETS_FILE}" ]; then
	# Add the type in on the first credential of this type
	echo "  ${CRED_TYPE}:" >> ${TEMP_SECRETS_FILE}
    fi
    echo "    ${CRED_NAME}:" >> ${TEMP_SECRETS_FILE}
    # Add more fields here as needed
    # This set came from /opt/ace-13.0.1.0/common/schemas/Credentials/Credentials.xsd
    CRED_AUTHTYPE=$(cat $creddir/authType 2>/dev/null)
    CRED_ACCESSKEYID=$(cat $creddir/accessKeyId 2>/dev/null)
    CRED_ACCESSTOKEN=$(cat $creddir/accessToken 2>/dev/null)
    CRED_APIKEY=$(cat $creddir/apiKey 2>/dev/null)
    CRED_CLIENTEMAIL=$(cat $creddir/clientEmail 2>/dev/null)
    CRED_CLIENTID=$(cat $creddir/clientId 2>/dev/null)
    CRED_CLIENTSECRET=$(cat $creddir/clientSecret 2>/dev/null)
    CRED_PASSPHRASE=$(cat $creddir/passphrase 2>/dev/null)
    CRED_PASSWORD=$(cat $creddir/password 2>/dev/null)
    CRED_PUBLICKEY=$(cat $creddir/publicKey 2>/dev/null)
    CRED_PUBLICKEYID=$(cat $creddir/publicKeyId 2>/dev/null)
    CRED_PRIVATEKEY=$(cat $creddir/privateKey 2>/dev/null)
    CRED_PRIVATEKEYID=$(cat $creddir/privateKeyId 2>/dev/null)
    CRED_REFRESHTOKEN=$(cat $creddir/refreshToken 2>/dev/null)
    CRED_SECRETACCESSKEY=$(cat $creddir/secretAccessKey 2>/dev/null)
    CRED_SSHIDENTITYFILE=$(cat $creddir/sshIdentityFile 2>/dev/null)
    CRED_SSLPEERNAME=$(cat $creddir/sslPeerName 2>/dev/null)
    CRED_USERNAME=$(cat $creddir/username 2>/dev/null)
    CRED_WEBSPHEREUSERNAME=$(cat $creddir/websphereUsername 2>/dev/null)
    CRED_WEBSPHEREPASSWORD=$(cat $creddir/webspherePassword 2>/dev/null)
    if [ "${CRED_AUTHTYPE}" != "" ];          then echo "      authType: \"${CRED_AUTHTYPE}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_ACCESSKEYID}" != "" ];       then echo "      accessKeyId: \"${CRED_ACCESSKEYID}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_ACCESSTOKEN}" != "" ];       then echo "      accessToken: \"${CRED_ACCESSTOKEN}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_APIKEY}" != "" ];            then echo "      apiKey: \"${CRED_APIKEY}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_CLIENTEMAIL}" != "" ];       then echo "      clientEmail: \"${CRED_CLIENTEMAIL}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_CLIENTID}" != "" ];          then echo "      clientId: \"${CRED_CLIENTID}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_CLIENTSECRET}" != "" ];      then echo "      clientSecret: \"${CRED_CLIENTSECRET}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_PASSPHRASE}" != "" ];        then echo "      passphrase: \"${CRED_PASSPHRASE}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_PASSWORD}" != "" ];          then echo "      password: \"${CRED_PASSWORD}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_PUBLICKEY}" != "" ];         then echo "      publicKey: \"${CRED_PUBLICKEY}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_PUBLICKEYID}" != "" ];       then echo "      publicKeyId: \"${CRED_PUBLICKEYID}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_PRIVATEKEY}" != "" ];        then echo "      privateKey: \"${CRED_PRIVATEKEY}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_PRIVATEKEYID}" != "" ];      then echo "      privateKeyId: \"${CRED_PRIVATEKEYID}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_REFRESHTOKEN}" != "" ];      then echo "      refreshToken: \"${CRED_REFRESHTOKEN}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_SECRETACCESSKEY}" != "" ];   then echo "      secretAccessKey: \"${CRED_SECRETACCESSKEY}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_SSHIDENTITYFILE}" != "" ];   then echo "      sshIdentityFile: \"${CRED_SSHIDENTITYFILE}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_SSLPEERNAME}" != "" ];       then echo "      sslPeerName: \"${CRED_SSLPEERNAME}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_USERNAME}" != "" ];          then echo "      username: \"${CRED_USERNAME}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_WEBSPHEREUSERNAME}" != "" ]; then echo "      websphereUsername: \"${CRED_WEBSPHEREUSERNAME}\"" >> ${TEMP_SECRETS_FILE}; fi
    if [ "${CRED_WEBSPHEREPASSWORD}" != "" ]; then echo "      webspherePassword: \"${CRED_WEBSPHEREPASSWORD}\"" >> ${TEMP_SECRETS_FILE}; fi
done

# Print out the set of credentials found
if [ "$FirstCred" != "1" ]; then
    echo "---"
    echo "Credentials:"
    cat ${TEMP_SECRETS_DIR}/*.yaml
fi

# Remove copies
rm -rf ${TEMP_SECRETS_DIR}

