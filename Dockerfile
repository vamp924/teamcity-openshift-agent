FROM --platform=amd64 registry.access.redhat.com/ubi8/ubi-minimal

ARG TEAMCITY_URL=http://84.201.174.166:8111

SHELL [ "/bin/bash", "-c" ]

# Install JRE and build tools
RUN microdnf install java-1.8.0-openjdk-headless hostname git curl tar unzip && \
    microdnf clean all
ENV JRE_HOME /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.262.b10-0.el8_2.x86_64/jre

COPY run-agent.sh /run-agent.sh
RUN curl -O ${TEAMCITY_URL}/update/buildAgentFull.zip && \
    unzip buildAgentFull.zip \
     -x *windows* \
     -x *macosx* \
     -x *solaris* \
     -x *.bat \
     -x *linux-x86-32* \
     -x *linux-ppc-64* \
     -d /opt/buildagent && \
    rm buildAgentFull.zip && \
    rm /opt/buildagent/conf/buildAgent.dist.properties && \
    printf "\
    # Required Agent Properties
    serverUrl=${TEAMCITY_URL}/ \n\
    name= \n\
    workDir=../work \n\
    tempDir=../temp \n\
    systemDir=../system \n\
    # Optional Agent Properties 
    authorizationToken= \n\
    # Custom Agent Properties
    tools.curl= \n\
    " > /opt/buildagent/conf/buildAgent.properties && \
    useradd -m buildagent && \
    chmod +x /opt/buildagent/bin/*.sh && \
    chmod +x /run-agent.sh && \
    mkdir -p /data/teamcity_agent/conf && \
    mkdir -p /opt/buildagent/work && \
    mkdir -p /opt/buildagent/system && \
    mkdir -p /opt/buildagent/temp && \
    mkdir -p /opt/buildagent/logs && \
    mkdir -p /opt/buildagent/tools && \
    chown -R buildagent:root /opt/buildagent && \
    chown buildagent:root /run-agent.sh && \
    chmod +x /opt/buildagent/bin/*.sh && \
    chmod -R g+u /opt && sync
ENV HOME=/opt/buildagent CONFIG_FILE=/opt/buildagent/conf/buildAgent.properties

# Add 'oc' binary
ARG OPENSHIFT_DOWNLOADS_URL=https://downloads-openshift-console.apps-crc.testing
RUN curl -k ${OPENSHIFT_DOWNLOADS_URL}/amd64/linux/oc.tar | tar -x -C /usr/local/bin && \
    chmod a+x /usr/local/bin/oc && \
    printf "\
    tools.openshiftOriginClient= \n\
    " >> $CONFIG_FILE

WORKDIR /opt/buildagent
USER buildagent
CMD [ "/run-agent.sh", "start" ]
