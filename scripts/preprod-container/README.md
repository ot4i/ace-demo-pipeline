# Docker image build file for the Tea application

This image is based on the ACE minimal Alpine container in order to be small enough to fit
into the IBM Container Registry free tier.

- deploy-bars.sh is used during the image build process to deploy the application BAR file
- TEAJDBC.policyxml is a template policy file with substitution strings that can be replaced at container start time (frying)
- init-creds.sh reads the database credentials from a Kubernetes secret and updates both the setdbparms information for the server and also the JDBC policy.

The resulting image can be run locally or pushed into the registry to be run from a Kubernetes cluster.
