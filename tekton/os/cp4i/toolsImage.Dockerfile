FROM alpine:3.20

# Install base tools
RUN apk add --no-cache \
    git \
    curl \
    bash \
    jq \
    unzip \
    zip \
    ca-certificates \
    tar \
    libc6-compat

# Install yq (Go-based version, pinned release)
ENV YQ_VERSION=v4.44.3
RUN curl -L "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" -o /usr/bin/yq && \
    chmod +x /usr/bin/yq

# Install OpenShift CLI (oc) - also contains kubectl
ENV OC_VERSION=4.16.38
RUN curl -L "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux-${OC_VERSION}.tar.gz" -o oc.tar.gz && \
    tar -xzf oc.tar.gz -C /usr/local/bin && \
    rm -f oc.tar.gz

# Install crane v0.20.6
ENV CRANE_VERSION=v0.20.6
RUN curl -L "https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_Linux_x86_64.tar.gz" -o crane.tar.gz && \
    tar -xzf crane.tar.gz -C /usr/local/bin && \
    rm -f crane.tar.gz

# Default shell for interactive/local use
CMD ["/bin/bash"]
