# -*- mode: ruby -*-
# vi: set ft=ruby:fdm=marker

# Options {{{
#
APP_HOST = "#{ENV['VM_HOST'] || '44.44.44.44'}"
APP_HOST_NAME = "#{ENV['VM_HOST_NAME'] || 'vagrant.lpgenerator.ru'}"
APP_VM_NAME = "#{ENV['VM_NAME'] || 'lpg-ws'}"
APP_MEMORY = "#{ENV['VM_MEMORY'] || '1024'}"
APP_CPUS = "#{ENV['VM_CPUS'] || '1'}"
#
# }}}


# Vagrant 2.0.x {{{
#
Vagrant.configure("2") do |config|

    config.vm.box = "ubuntu/trusty64"
    config.vm.box_check_update = true
    config.vm.post_up_message = "Box URL is http://vagrant.lpgenerator.ru/"

    config.vm.synced_folder "./", "/vagrant", id: "vagrant-root"

    config.vm.provision :shell, :path => ".deploy/ansible/bootstrap.sh"
    config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

    # Set hostname
    config.vm.hostname = APP_HOST_NAME

    # Configure network
    config.vm.network :private_network, ip: APP_HOST
    config.vm.network :forwarded_port, guest: 8000, host: 8001
    config.vm.network :forwarded_port, guest: 6379, host: 7379

    # SSH forward
    config.ssh.forward_agent = true

    # Configure VirtualBox
    config.vm.provider :virtualbox do |vb|
        vb.gui = false
        vb.name = APP_VM_NAME
        vb.customize ["modifyvm", :id, "--memory", APP_MEMORY]
        vb.customize ["modifyvm", :id, "--name", APP_HOST_NAME]
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
        vb.customize ["modifyvm", :id, "--ioapic", "on"]
        vb.customize ["modifyvm", :id, "--cpus", APP_CPUS]
    end

    # Configure Parallels Desktop
    config.vm.provider :parallels do |vb|
        vb.check_guest_tools = true
        vb.update_guest_tools = true
        vb.optimize_power_consumption = true
        vb.memory = APP_MEMORY
        vb.cpus = APP_CPUS
        vb.name = APP_VM_NAME
        vb.customize ["set", :id, "--device-set", "cdrom0", "--disconnect"]
    end

    config.vm.provider "parallels" do |v, override|
        override.vm.box = "parallels/ubuntu-14.04"
    end

end
#
# }}}
