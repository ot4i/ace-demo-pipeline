# OpenShift GitOps Setup

1. Confirm the Image Exists and Is Accessible
Run the following to check the image is present:

```bash
oc -n cp4i get istag tea-tekton-cp4i:20250808143641-4c89668
```

If it doesn't exist, you’ll need to ensure the image was pushed successfully to that tag.

2. Grant Image Pull Permission to dev Namespace
You need to allow ServiceAccounts in dev to pull from cp4i.

Run this:

```bash
oc -n cp4i policy add-role-to-group \
  system:image-puller \
  system:serviceaccounts:dev
```

This lets all service accounts in dev pull from cp4i. This is common and safe within a controlled environment like CI/CD.

Alternatively, if you want to grant it only to a specific ServiceAccount (e.g., ArgoCD app controller or Tekton task), run:

```bash
oc -n cp4i policy add-role-to-user \
  system:image-puller \
  system:serviceaccount:dev:<serviceaccount-name>
```

You can find the actual SA by describing the pod:

```bash
oc -n dev get pod tea-argo-cp4i-ir-7c4d647c78-prdrn -o jsonpath='{.spec.serviceAccountName}'
```