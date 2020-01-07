FROM jboss/keycloak:6.0.1

USER root
ENV pip_packages "ansible"

# Silence annoying subscription messages.
RUN echo "enabled=0" >> /etc/yum/pluginconf.d/subscription-manager.conf

# Install Ansible requirements.
RUN yum -y update; yum clean all;
RUN yum makecache \
 && yum -y install initscripts \
 && yum -y update \
 && yum -y install \
      hostname \
      python3 \
 && yum clean all

# Install Ansible via Pip.
RUN pip3 install $pip_packages

# Copy ansible scripts
RUN mkdir /opt/ansible
WORKDIR keycloak
COPY ansible /opt/ansible

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
COPY docker-assets/ansible-hosts/hosts /etc/ansible/.

## Copy docker-entrypoint main script
COPY container-assets/docker-entrypoint.sh /opt/jboss/tools

USER 1000

ENTRYPOINT [ "/opt/jboss/tools/docker-entrypoint.sh" ]