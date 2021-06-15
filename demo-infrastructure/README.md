# Infrastructure for ACE pipeline demo

Various applications, scripts, and Dockerfiles for the pipeline demo. These files are 
not specific to this application, and would normally reside elsewhere and be shared by 
multiple application projects, but the demo is more self-contained if we keep them here.

## Docker images

The docker directory contains build files for the docker image needed for the pipeline 
demo to work. The ace-minimal-build image runs in the pipeline to enable the building and
testing of applications, and can also be used in CI builds (github actions, TravisCI, etc).
