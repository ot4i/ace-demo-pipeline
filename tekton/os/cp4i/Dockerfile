# Copyright (c) 2022 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)

#FROM tdolby/experimental:ace-minimal-11.0.0.11-alpine
ARG BASE_IMAGE=ace-server-prod:12.0.5.0-r1-lts
FROM $BASE_IMAGE

# Used for tekton and Maven containers

LABEL "maintainer"="trevor.dolby@ibm.com"

WORKDIR /tmp/maven-output

COPY ace-server /tmp/maven-output/ace-server/
RUN chown -R aceuser:mqbrkrs /tmp/* && \
    (cd /tmp/maven-output/ace-server && tar -cf - run/* ) | ( cd /home/aceuser/ace-server/run/ && tar -xf - )

# Kaniko seems to chmod this directory 755 by mistake sometimes, which causes trouble later
RUN chmod 1777 /tmp
