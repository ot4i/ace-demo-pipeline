# Copyright (c) 2020 Open Technologies for Integration
# Licensed under the MIT license (see LICENSE for details)

FROM jenkins/jenkins:lts

# This image is run by Jenkins in a Docker swarm (using ssh) and is used to
# run all of the Jenkins builds that implement the CI pipeline for this project.
#
# Starting from ace-full (which has the ACE install plus the aceuser created), 
# this image contains the Jenkins pre-reqs and also the IBM cloud tools; not 
# all stages are using the whole set of tools, but installing them all at once
# makes management easy.
#

# docker run --rm -ti -p 18080:8080 -p 40000:50000 -v /Development/tdolby/public-jenkins_home:/var/jenkins_home --privileged -v /var/run/docker.sock:/var/run/docker.sock ace-jenkins-server

LABEL "maintainer"="tdolby@uk.ibm.com"
USER root

# Prevent errors about having no terminal when using apt-get
ENV DEBIAN_FRONTEND noninteractive

ARG DOWNLOAD_URL=http://kenya.hursley.uk.ibm.com:52367/ace-11.0.0.9.tar.gz
ARG PRODUCT_VERSION=ace-11.0.0.9
ARG DOCKER_GID=1999

RUN dpkg --add-architecture i386 \
  && apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    apt-transport-https \
    bc \
    curl \
    ftp \
    maven \
    ant \
    git \
    gnupg-agent \
    iputils-ping \
    ksh \
    libxtst6 \
    lsb-release \
    locales \
    make \
    net-tools \
    nmap \
    openssh-server \
    patch \
    software-properties-common \
    sudo \
    telnet \
    tzdata \
    unzip \
    zip \
  && rm -rf /var/lib/apt/lists/*

ENV TZ=Europe/London

WORKDIR /

# Install the github commandline to enable release management.
RUN mkdir /tmp/hub && cd /tmp/hub \
    && curl -L https://github.com/github/hub/releases/download/v2.14.2/hub-linux-amd64-2.14.2.tgz | tar -xzf - \
    && /tmp/hub/hub-linux-amd64-2.14.2/install \
    && cd / && rm -rf /tmp/hub

# Ensure -v /var/run/docker.sock:/var/run/docker.sock will work
RUN groupadd -g ${DOCKER_GID} docker

# Download and install IBM cloud tools; must be run as root to install
# into /usr/local/bin and run before docker to avoid issues during the build.
RUN curl -sL https://ibm.biz/idt-installer -o /tmp/idt-installer.sh \
    && chmod 775 /tmp/idt-installer.sh \
    && bash /tmp/idt-installer.sh \
    && mkdir /usr/local/ibmcloud/plugins \
    && mv /root/.bluemix /usr/local/ibmcloud/plugins \
    && ln -s /usr/local/ibmcloud/plugins/.bluemix /root/.bluemix \
    && chown -R jenkins /usr/local/ibmcloud/plugins


# Install docker tools
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io \
    && echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && sudo usermod -a -G docker jenkins
    
# Install ACE and accept the license
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && mkdir /opt/ibm && echo Downloading package ${DOWNLOAD_URL} \
    && curl ${DOWNLOAD_URL} | tar zx --directory /opt/ibm \
    && mv /opt/ibm/${PRODUCT_VERSION} /opt/ibm/ace-11 \
    && /opt/ibm/ace-11/ace make registry global accept license silently \
    && usermod -a -G mqbrkrs jenkins

# mqsicreatebar prereqs; need to run "Xvfb -ac :99 &" and "export DISPLAY=:99"
RUN apt-get -y install libgtk2.0-0 libxtst6 xvfb

# The Jenkins home directory is normally a volume mount, so we link the
# previously-installed plugins into it.
RUN echo "ln -s /usr/local/ibmcloud/plugins/.bluemix /var/jenkins_home/.bluemix 2>/dev/null" > /etc/fix-idt-plugins.sh

ENV BASH_ENV=/etc/fix-idt-plugins.sh

USER jenkins
