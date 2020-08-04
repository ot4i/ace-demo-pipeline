# Docker images for build pipelines to use

- ace-jenkins-server is used for running the Jenkins pipeline for the demo application build.
- pipeline-travis-build is pulled in by Travis to run automatic ACE builds for branch PRs, etc.

ace-jenkins-server can be built and run locally (see README.md in that directory for details), but pipeline-travis-build has to 
be pushed to a registry that is visible to Travis.
