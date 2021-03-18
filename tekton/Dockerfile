# Copyright (c) 2021 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)

FROM tdolby/experimental:ace-minimal-11.0.0.11-alpine

# Used for tekton and Maven containers

LABEL "maintainer"="tdolby@uk.ibm.com"
USER root
WORKDIR /tmp/maven-output

COPY ace-server /tmp/maven-output/ace-server/
RUN chown -R aceuser:mqbrkrs /tmp/* && \
    (cd /tmp/maven-output/ace-server && tar -cf - * ) | ( cd /home/aceuser/ace-server && tar -xf - ) && \
    chmod 775 /home/aceuser/ace-server/ace-startup-script.sh 

# Kaniko seems to chmod this directory 755 by mistake sometimes, which causes trouble later
RUN chmod 1777 /tmp

USER aceuser

# We're in an internal pipeline
ENV LICENSE=accept

# Set entrypoint to run the server
ENTRYPOINT ["bash", "-c", "/home/aceuser/ace-server/ace-startup-script.sh && IntegrationServer -w /home/aceuser/ace-server --admin-rest-api -1 --no-nodejs"]
