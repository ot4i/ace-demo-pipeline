# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
ARG BASE_IMAGE=ace-minimal:12.0.2.0-alpine
FROM $BASE_IMAGE

#
# This image is run by Travis in a CI container, and is pulled each time.
#
# Starting from ace-minimal (which has the ACE install plus the aceuser created), 
# this image contains only the parts needed for the build and unit test phase.
#

LABEL "maintainer"="tdolby@uk.ibm.com"
USER root

# For dev pipeline use we can accept the ACE license automatically
ENV LICENSE accept

# The standard Maven packages on most distros bring a lot of extra packages with
# them so we install Maven directly. 
RUN cd /opt && \
    curl -k https://dlcdn.apache.org/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz | tar -xzf - && \
    ln -s /opt/apache-maven-3.8.4/bin/mvn /usr/local/bin/mvn

ENV TZ=Europe/London
WORKDIR /

# Default command to run
ENTRYPOINT []
CMD ["/bin/bash"]
