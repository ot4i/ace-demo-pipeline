# Travis Docker image

Used by .travis.yml in the root of this repo to run the ACE commands within a Travis build.

Built on top of ace-minimal:11.0.0.11-alpine (in a local registry and built from https://github.com/ot4i/ace-docker/tree/master/experimental/ace-minimal) but must be pushed to Artifactory (or registry of your choice) so Travis can pull it. Credentials stored in Travis itself as env vars, and pulled in via .travis.yml to use in a docker login command.
