# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)

FROM ace-minimal:11.0.0.11-ubuntu

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

# Weird conflicts between JVMs if we don't do this
RUN mv /opt/ibm/ace-11/server/bin/mqsiprofile /opt/ibm/ace-11/server/bin/mqsiprofile-

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tzdata \
    unzip \
    zip \
    maven \
  && rm -rf /var/lib/apt/lists/*

RUN mv /opt/ibm/ace-11/server/bin/mqsiprofile- /opt/ibm/ace-11/server/bin/mqsiprofile


ENV TZ=Europe/London
WORKDIR /

# Default command to run
ENTRYPOINT []
CMD ["/bin/bash"]
