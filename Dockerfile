FROM ubuntu:18.04
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

ADD overlays/$PROJECT_VERSION /overlays
ADD patches /patches

ADD files/tasks /ansible/tasks
ADD files/library /ansible/library

ADD files/playbooks/kolla-facts.yml /ansible/kolla-facts.yml
ADD files/playbooks/$VERSION/kolla-common.yml /ansible/kolla-common.yml

ADD files/scripts/split-kolla-ansible-site.py /split-kolla-ansible-site.py
ADD files/scripts/$VERSION/run.sh /run.sh

ADD files/ansible.cfg /etc/ansible/ansible.cfg
ADD files/defaults.yml /ansible/group_vars/all/defaults.yml
ADD files/versions.yml /ansible/group_vars/all/versions.yml
ADD files/images-$VERSION.yml /ansible/group_vars/all/images-project.yml
ADD files/images.yml /ansible/group_vars/all/images.yml
ADD files/requirements.txt /requirements.txt
ADD files/requirements.yml /ansible/galaxy/requirements.yml

ADD files/dragon_sudoers /etc/sudoers.d/dragon_sudoers

# upgrade/install required packages

RUN apt update \
    && apt upgrade -y \
    && apt install -y  \
        git \
        gnupg-agent \
        libffi-dev \
        libssl-dev \
        libyaml-dev \
        patch \
        python-dev \
        python-pip \
        rsync \
        sudo

# add user

RUN chmod 0440 /etc/sudoers.d/dragon_sudoers \
    && groupadd -g $GROUP_ID dragon \
    && groupadd -g $GROUP_ID_DOCKER docker \
    && useradd -g dragon -G docker -u $USER_ID -m -d /ansible dragon

# install required python packages

RUN pip install -r /requirements.txt

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

# install required ansible roles

RUN ansible-galaxy install -v -f -r /ansible/galaxy/requirements.yml -p /ansible/galaxy

# prepare project repository

RUN git clone -b $PROJECT_VERSION $PROJECT_REPOSITORY /repository \
    && for patchfile in $(find /patches/$PROJECT_VERSION -name "*.patch"); do \
        echo $patchfile; \
        ( cd /repository && patch --batch -p1 --dry-run ) < $patchfile || exit 1; \
        ( cd /repository && patch --batch -p1 ) < $patchfile; \
       done \
    && rsync -avz /overlays/ /repository/

# project specific instructions

RUN cp /repository/ansible/group_vars/all.yml /ansible/group_vars/all/defaults-kolla.yml \
    && pip install -r /repository/requirements.txt \
    && python /split-kolla-ansible-site.py \
    && cp -r /repository/ansible/action_plugins/* /ansible/action_plugins \
    && cp /repository/ansible/library/* /ansible/library \
    && cp -r /repository/ansible/roles/* /ansible/roles \
    && for playbook in $(find /repository/ansible -maxdepth 1 -name "*.yml"); do echo $playbook && cp $playbook /ansible/kolla-$(basename $playbook); done \
    && rm /split-kolla-ansible-site.py

# set correct permssions

RUN chown -R dragon: /ansible /share

# cleanup

RUN apt clean \
    && apt-get purge -y lib*-dev \
    && rm -rf \
      /overlays \
      /patches \
      /requirements.txt \
      /tmp/* \
      /var/lib/apt/lists/* \
      /var/tmp/*  \
      /usr/share/doc/* \
      /usr/share/man/*

VOLUME ["/ansible/cache", "/ansible/logs", "/ansible/secrets", "/share"]

USER dragon
WORKDIR /ansible
