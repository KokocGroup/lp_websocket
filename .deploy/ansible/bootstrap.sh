#!/usr/bin/env bash

UBUNTU_VERSION="`cat /etc/lsb-release |grep DISTRIB_RELEASE|cut -d'=' -f2`"

if [ "$UBUNTU_VERSION" != "14.04" ]; then
    echo "This ubuntu version is not supported!"
    exit 1
fi

if [ -z "`which ansible`" ]; then
    sudo apt-get update
    sudo apt-get install -y python-software-properties software-properties-common
    sudo add-apt-repository -y ppa:rquillo/ansible
    sudo apt-get update
    sudo apt-get install -y screen ansible
    ln -sf /bin/bash /bin/sh
fi

sudo -u vagrant -H ansible-playbook /vagrant/.deploy/ansible/.ansible.yml -i localhost, --connection=local
