# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)
ARG BASE_IMAGE=ace-minimal:12.0.4.0-ubuntu
FROM $BASE_IMAGE

#
# Image used during the pipeline run to build ACE solutions.
#
# Starting from ace-minimal (which has the ACE install plus the aceuser created), 
# this image contains only the parts needed for the build and unit test phase.
#
# For zLinux, we need to pull the IBM JDK from the download site.
#

LABEL "maintainer"="tdolby@uk.ibm.com"
USER root

# For dev pipeline use we can accept the ACE license automatically
ENV LICENSE accept

RUN cd /tmp && \
    curl -k http://public.dhe.ibm.com/ibmdl/export/pub/systems/cloud/runtimes/java/8.0.6.31/linux/s390x/ibm-java-sdk-8.0-6.31-s390x-archive.bin > ibm-java-sdk-8.0-6.31-s390x-archive.bin && \
    chmod 775 ibm-java-sdk-8.0-6.31-s390x-archive.bin && \
    (echo "4" ; sleep 5 ; echo "1" ; sleep 5 ; echo ; sleep 5 ; echo "/opt/ibm-java-s390x-80" ; sleep 5 ; echo "Y" ; sleep 5 ; echo ; sleep 5 ; echo ) | ./ibm-java-sdk-8.0-6.31-s390x-archive.bin

RUN ls -l /opt && ls -l /opt/ibm-java-s390x-80

# The standard Maven packages on most distros bring a lot of extra packages with
# them so we install Maven directly. 
RUN cd /opt && \
    curl -k https://apache.mirrors.nublue.co.uk/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz | tar -xzf - && \
    ln -s /opt/apache-maven-3.6.3/bin/mvn /usr/local/bin/mvn

ENV TZ=Europe/London
WORKDIR /

# Default command to run
ENTRYPOINT []
CMD ["/bin/bash"]
