# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)

FROM ace-minimal:11.0.0.9-ubuntu

#
# This image is run by Travis in a CI container, and is pulled each time.
#
# Starting from ace-minimal (which has the ACE install plus the aceuser created), 
# this image contains only the parts needed for the build and unit test phase.
#

LABEL "maintainer"="tdolby@uk.ibm.com"
USER root

# Prevent errors about having no terminal when using apt-get
ENV DEBIAN_FRONTEND noninteractive

# For dev pipeline use we can accept the ACE license automatically
ENV LICENSE accept

RUN dpkg --add-architecture i386 \
  && apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tzdata \
    unzip \
    zip \
  && rm -rf /var/lib/apt/lists/* \
  && cd /opt \
  && curl https://mirrors.ukfast.co.uk/sites/ftp.apache.org//ant/binaries/apache-ant-1.9.15-bin.tar.bz2 | tar -xjf - \
  && ln -s /opt/apache-ant-1.9.15/bin/ant /usr/bin/ant

ENV TZ=Europe/London
WORKDIR /

# Default command to run
ENTRYPOINT []
CMD ["/bin/bash"]
