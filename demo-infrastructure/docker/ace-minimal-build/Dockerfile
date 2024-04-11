# Copyright (c) 2022 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
ARG BASE_IMAGE=ace-minimal:12.0.11.0-alpine
FROM $BASE_IMAGE

#
# This image is run by Tekton in a build container to build the application and tests.
#
# Starting from ace-minimal (which has the ACE install plus the aceuser created), 
# this image contains only the parts needed for the build and unit test phase.
#

LABEL "maintainer"="trevor.dolby@ibm.com"
USER root

# For dev pipeline use we can accept the ACE license automatically
ENV LICENSE accept

# The standard Maven packages on most distros bring a lot of extra packages with
# them so we install Maven directly. 
RUN cd /tmp && \
    aria2c https://archive.apache.org/dist/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz && \
    cd /opt && \
    tar -xf /tmp/apache-maven-3.8.4-bin.tar.gz && \
    rm /tmp/apache-maven-3.8.4-bin.tar.gz && \
    ln -s /opt/apache-maven-3.8.4/bin/mvn /usr/local/bin/mvn

RUN echo "Adding curl for Alpine - may fail if the base is Ubuntu" ; apk add curl  || /bin/true

ENV TZ=Europe/London
WORKDIR /

# Patch OpenShift issues
RUN chgrp -R mqbrkrs /home/aceuser/ace-server
RUN chmod -R g+wx /home/aceuser/ace-server

# Patch Jenkins issues
RUN chmod -R ugo+rwx /var/mqsi

USER 1001

# Default command to run
ENTRYPOINT []
CMD ["/bin/bash"]
