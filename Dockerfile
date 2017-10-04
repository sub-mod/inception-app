FROM centos:latest

MAINTAINER Subin Modeel


USER root

ENV PATH=/workspace/node-lib/node/bin:$PATH \
    TINI_VERSION=v0.16.1 \
    NB_USER=nbuser \
    NB_UID=1011 \
    HOME=/home/$NB_USER \
    PATH=$HOME/.local/bin/:$PATH \
    LANGUAGE=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PYTHONIOENCODING=UTF-8

LABEL io.k8s.description="Inception tensorflow App." \
      io.k8s.display-name="Inception tensorflow App" \
      io.openshift.expose-services="8000:http"


RUN echo 'PS1="\u@\h:\w\\$ \[$(tput sgr0)\]"' >> /root/.bashrc \
    chgrp root /etc/passwd && \
    chgrp -R root /opt && \
    chmod -R ug+rwx /opt && \
    useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    usermod -g root $NB_USER && \
    echo -e "\nclean_requirements_on_remove=1" >> /etc/yum.conf && \
    yum -y install epel-release && \
    yum -y install tar xz zip unzip && \
    yum -y install yum-utils gcc curl wget openssh-clients bind-utils which openssl sudo python && \
    yum -y install python-pip python-devel && \
    wget -q https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -P /tmp && \
    wget -q https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc -P /tmp && \
    cd /tmp  && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 0527A9B7 && gpg --verify /tmp/tini.asc && \
    mv /tmp/tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini && \
    mkdir -p /workspace && \
    chmod 777 /usr/bin/pip && \
    chown $NB_UID:root /workspace 


ADD templates /workspace/templates
COPY main.py /workspace/
COPY requirements.txt /workspace/
COPY app.sh /workspace/

RUN pip install --upgrade pip && \
    cd /workspace/ && \
    pip install -r requirements.txt && \
    pip install tensorflow tensorflow-serving-api flask waitress && \
    chmod a+x /workspace/app.sh && \
    yum -y erase gcc python-devel cpp glibc-devel glibc-headers kernel-headers  && \
    rm -rf /var/cache/yum/*  && \
    rm -rf /root/.cache  && \
    package-cleanup --oldkernels --count=1 -y  && \
    rm -rf /var/cache/yum/*  && \
    yum -y clean all 

EXPOSE 8000
WORKDIR /workspace
ADD entrypoint /entrypoint
ENTRYPOINT ["/entrypoint"]
CMD ["/workspace/app.sh"]


# Switch to the user 
USER $NB_USER
