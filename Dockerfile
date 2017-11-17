FROM ubuntu:16.04
LABEL maintainer="Betacloud Solutions GmbH (https://www.betacloud-solutions.de)"

ARG REPOSITORY_VERSION
ARG VERSION

ARG PROJECT_REPOSITORY
ARG PROJECT_VERSION

ENV USER_ID ${USER_ID:-45000}
ENV GROUP_ID ${GROUP_ID:-45000}
ENV GROUP_ID_DOCKER ${GROUP_ID_DOCKER:-999}

ENV DEBIAN_FRONTEND noninteractive

USER root

ADD patches /patches

ADD files/tasks /ansible/tasks
ADD files/library /ansible/library

ADD files/playbooks/* /ansible/
ADD files/scripts/* /

ADD files/ansible.cfg /etc/ansible/ansible.cfg
ADD files/defaults.yml /ansible/group_vars/all/defaults.yml
ADD files/versions.yml /ansible/group_vars/all/versions.yml
ADD files/images-$VERSION.yml /ansible/group_vars/all/images-project.yml
ADD files/images.yml /ansible/group_vars/all/images.yml
ADD files/requirements.txt /requirements.txt
ADD files/requirements.yml /ansible/galaxy/requirements.yml

ADD files/dragon_sudoers /etc/sudoers.d/dragon_sudoers

# prepare repository & upgrade/install required packages

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         curl \
    && curl -L http://repository-1.osism.io/aptly.pub | apt-key add - \
    && echo "deb [arch=amd64] http://repository-1.osism.io/container-$REPOSITORY_VERSION/ xenial main" > /etc/apt/sources.list \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y  \
        git \
        libffi-dev \
        libssl-dev \
        libyaml-dev \
        patch \
        python-dev \
        python-pip \
        sudo \
        vim

# add user

RUN chmod 0440 /etc/sudoers.d/dragon_sudoers \
    && groupadd -g $GROUP_ID dragon \
    && groupadd -g $GROUP_ID_DOCKER docker \
    && useradd -g dragon -G docker -u $USER_ID -m -d /ansible dragon

# install required python packages

RUN pip install --upgrade pip \
    && pip install -r /requirements.txt

# install required ansible roles

RUN ansible-galaxy install -v -f -r /ansible/galaxy/requirements.yml -p /ansible/galaxy

# create required directories

# internal use only
RUN mkdir -p \
        /ansible \
        /ansible/action_plugins \
        /ansible/library \
        /ansible/roles \
        /ansible/tasks

# exportes as volumes
RUN mkdir -p \
        /ansible/cache \
        /ansible/logs \
        /ansible/secrets \
        /share

# prepare project repository

RUN git clone -b $PROJECT_VERSION $PROJECT_REPOSITORY /repository \
    && for patchfile in $(find /patches/$PROJECT_VERSION -name "*.patch"); do (echo $patchfile && cd /repository && patch --batch -p1) < $patchfile; done

# project specific instructions

RUN cp /repository/ansible/group_vars/all.yml /ansible/group_vars/all/defaults-kolla.yml \
    && pip install -r /repository/requirements.txt \
    && python /split-kolla-ansible-site.py \
    && cp -r /repository/ansible/action_plugins/* /ansible/action_plugins \
    && cp /repository/ansible/library/* /ansible/library \
    && cp -r /repository/ansible/roles /ansible/roles \
    && for playbook in $(find /repository/ansible -maxdepth 1 -name "*.yml"); do echo $playbook && cp $playbook /ansible/kolla-$(basename $playbook); done \
    && rm /split-kolla-ansible-site.py

# set correct permssions

RUN chown -R dragon: /ansible /share

# cleanup

RUN apt-get clean \
    && rm -rf \
      /patches \
      /requirements.txt \
      /tmp/* \
      /var/lib/apt/lists/* \
      /var/tmp/* \
      /repository

VOLUME ["/ansible/cache", "/ansible/logs", "/ansible/secrets", "/share"]

USER dragon
WORKDIR /ansible
