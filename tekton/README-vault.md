# Using HashiCorp Vault

Vault can be used to store JDBC credentials used by the Tea application, with the credentials being
provided to the application by an in-memory volume mount from a sidecar container. The credentials
are read in using an ExternalCredentialsProviders script configured in server.conf.yaml.



## Initial Vault setup

The simplest way to use Vault is to install it in "dev" mode, which is insecure but works for the
purposes of a pipeline demo. See https://developer.hashicorp.com/vault/docs/platform/k8s/helm/run 
for details, with this page being a quick summary. 

Assuming a Kubernetes namespace of "vault", the install is as follows:
```
helm install -n vault vault hashicorp/vault --set "server.dev.enabled=true"
```
and the vault must then be configured. To do this, use `kubectl exec` to get into the Vault container:
```
kubectl exec -i -t -n vault vault-0 sh
```
Assuming the application container is running in the "default" namespace using a service account of 
"default", then the configuration commands once inside the container would be
```
vault kv put secret/tea type=jdbc username=<db2user> password=<db2password>
vault auth enable kubernetes
vault write auth/kubernetes/role/myapp bound_service_account_names=default bound_service_account_namespaces=default policies=app ttl=30s
vault write auth/kubernetes/config \
   token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
   kubernetes_host=https://${KUBERNETES_PORT_443_TCP_ADDR}:443 \
   kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
cat <<EOF > /home/vault/app-policy.hcl
path "secret*" {
  capabilities = ["read"]
}
EOF
vault policy write app /home/vault/app-policy.hcl
```

At this point, the vault should contain the correct secret and have correct permissions, so the
application container Deployment can be modified to add the Vault annotations:
```
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: 'true'
        vault.hashicorp.com/agent-inject-secret-tea: secret/tea
        vault.hashicorp.com/agent-inject-template-tea: |
          {{- with secret "secret/tea" -}}
          type={{ .Data.data.type }}
          username={{ .Data.data.username }}
          password={{ .Data.data.password }}
          {{- end }}
        vault.hashicorp.com/role: myapp
```
where the "role" must match the auth record created in the Vault container.

Once the containers have restarted, the Vault sidecar should connect successfully and provide
credentials in the /vault/secrets directory, with a single file called "tea" that contains the
necessary information:
```
tea-tekton-8497896f95-c9krg:/tmp/maven-output$ cat /vault/secrets/tea
type=jdbc
username=<db2user>
password=<db2password>
```

This file is detected by the [init-creds.sh](/demo-infrastructure/init-creds.sh) startup
script, and the server.conf.yaml file for the server is configured with a 
[script](/demo-infrastructure/read-hashicorp-creds.sh) to load the credentials:
```
Credentials:
  ExternalCredentialsProviders:
    TeaJDBCHashiCorp:
      loadAllCredentialsCommand: '/home/aceuser/ace-server/read-hashicorp-creds.sh'
      loadAllCredentialsFormat: 'yaml'
```
This load happens at startup time, and credentials are not reloaded if they change.
