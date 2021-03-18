# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)

FROM tdolby/experimental:ace-minimal-11.0.0.11-alpine
#FROM ace-minimal:12.1289.0.0-alpine

#
# This image is used to run integration solutions in a cloud. Although this file is in
# a directory named scripts/preprod-container, the app images are normally tagged with
# the name of the application itself (such as tea-app) and an app version number.
#
# Starting from ace-minimal (which has the ACE install plus the aceuser created), this
# image contains the deployed BAR files for a given application as well as a script to
# read secrets and populate appropriate ACE configuration.
#

LABEL "maintainer"="tdolby@uk.ibm.com"
USER root
WORKDIR /

COPY deploy-bars.sh /tmp/
COPY init-creds.sh /tmp/
COPY TEAJDBC.policyxml /tmp/
COPY bars /tmp/

RUN chown aceuser /tmp/* && chmod 775 /tmp/*sh

# Kaniko seems to chmod this directory 755 by mistake in one of the COPY commands above
RUN chmod 1777 /tmp

USER aceuser

# We're in an internal pipeline
ENV LICENSE=accept

# Switch off the admin REST API for the server run, as we won't be deploying anything after start
RUN sed -i 's/#port: 7600/port: -1/g' /home/aceuser/ace-server/server.conf.yaml

RUN /tmp/deploy-bars.sh /tmp

# Set entrypoint to run the server
ENTRYPOINT ["bash", "-c", "/tmp/init-creds.sh && IntegrationServer -w /home/aceuser/ace-server --no-nodejs"]
