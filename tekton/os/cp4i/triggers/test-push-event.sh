secret="testsecret"  # must match the `github-secret.secretToken` in your cluster
signature="sha256=$(openssl dgst -sha256 -hmac "$secret" webhook-payload.json | cut -d " " -f2)"

curl -k -X POST http://el-ace-ir-tekton-eventlistener-cp4i.apps.itz-550004yuns-e4sso61e.cp.fyre.ibm.com \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -H "X-Hub-Signature-256: $signature" \
  -H "X-GitHub-Delivery: 123e4567-e89b-12d3-a456-426614174000" \
  -d @webhook-payload.json
