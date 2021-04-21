# LinkedIn Learning - Learning Puppet

LinkedIn Learning:

* [Log into LinkedIn Learning](https://aka.ms/mslibrary/LILearning)
* [Learning Puppet course](https://www.linkedin.com/learning/learning-puppet/)

## Install Vagrant

Vagrant is a software application that creates an operating system environment using virtualization technology.

Adapted from:

* [How to Install Vagrant on Ubuntu 20.04](https://linuxize.com/post/how-to-install-vagrant-on-ubuntu-20-04)
* [Enable Hyper-V and Install Vagrant on Windows 10](https://computingforgeeks.com/enable-hyper-v-and-install-vagrant-in-windows)

[vagrant box catalog](https://app.vagrantup.com/boxes/search) includes:

* All [hyperv](https://app.vagrantup.com/boxes/search?provider=hyperv) provider
* "puppetlabs" - Pre-configured for Puppet
* ["generic/ubuntu1804"](https://app.vagrantup.com/ubuntu/boxes/bionic64)

Install from [Vagrant](https://www.vagrantup.com/downloads)

## Configure Hyper-V to allow non-admin management

*By default, Hyper-V only allows administrator to perform management tasks. This will allow a specific account to also perform Hyper-V management.*

Start > Control Panel > Administration Tools > Computer Management

System Tools > Local Users and Groups > Groups

Double-click Hyper-V Administrators

Click Add

add your domain account, e.g. redmond\jeffmill

Sign out and back in.

### Vagrant example: Create an Ubuntu 18.04 VM

*If you didn't follow "configure hyper-v to allow non-admin management", you'll need to run these steps in an elevated CMD prompt.*

`vagrant box add generic/ubuntu1804`
    Choose "hyperv"

`md ubuntu1804 & cd ubuntu1804`

`vagrant init generic/ubuntu1804`
    This will create a Vagrantfile in current directory

`cd my-vagrant-project`

`vagrant up [--provider hyperv]`
    Will create a Hyper-V VM
    Choose "default switch"

## Vagrant commands

### Connect to VM

`vagrant ssh`

### Stop VM

`vagrant halt`

### Delete VM

`vagrant destroy`

## Create a VM for Vagrant

*If you didn't follow "configure hyper-v to allow non-admin management", you'll need to run these steps in an elevated CMD prompt.*

Using Centos/7 (free version of RedHat Enterprise Linux)

`md master & cd master`

`vagrant init generic/centos7`

Vagrantfile should read:

```ruby
# -*- mode: ruby -*-
Vagrant.configure("2") do |config|
  config.vm.box = "generic/centos7"
end
```

modify to read:

```ruby
# -*- mode: ruby -*-
CPUS="2"
MEMORY="1024"

Vagrant.configure("2") do |config|

  config.vm.box = "centos/7"
  config.vm.hostname = "master.puppet.vm"

  # https://www.vagrantup.com/docs/providers/hyperv/configuration
  config.vm.provider "hyperv" do |v|
    v.vmname = "master.puppet.vm"
    v.memory = MEMORY
    v.cpus = CPUS
  end
end
```

vagrant up [--provider hyperv]

Choose "Default Switch" if prompted.

## SSH into VM

`vagrant ssh`

## Switch to root user

Avoid having to specify sudo each time, as puppet commands require root access.

`sudo su -`

## Install a puppet master

`rpm -Uvh https://yum.puppet.com/puppet6-release-el-7.noarch.rpm`

`yum install -y puppetserver nano`

`nano /etc/sysconfig/puppetserver`

Change: `JAVA_ARGS="-Xms2g -Xmx2g` to `JAVA_ARGS="-Xms512m -Xmx512m`

`systemctl start puppetserver`

`systemctl status puppetserver`

`systemctl enable puppetserver`
(Start puppetserver by default)

`nano /etc/puppetlabs/puppet/puppet.conf`

Add new section with hostname of this machine:

```ini
[agent]
server = master.puppet.vm
```

Verify agent:

`puppet agent --test`

## Set up a control repo

Go to [GitHub](https://github.com)

New repository > control_repo (make it public)

[x] Initialize this repo with a README

To avoid confusion, change name from "main" to "production":

Settings > Branches > main. Click pencil, change to "production"

Code > README.md, pencil, make changes.
Click "Commit changes"

My github repo is [here](https://github.com/JeffMill/control_repo)

## Setup r10k

r10k is a code management tool that allows you to manage your environment configurations (such as production, testing, and development) in a source control repository.

This tutorial uses r10k to download contents of a git repo (control_repo, created above) to /etc/puppetlabs/code/environments, which is where puppet retrieves its commands from.

`yum install -y git`

`nano ~/.bash_profile`

add internal version of Ruby and Gem used by Ruby server:

`PATH=$PATH:/opt/puppetlabs/puppet/bin`

`source ~/.bash_profile`

Install tool to deploy puppetcode from github onto server:

`gem install r10k`

`mkdir /etc/puppetlabs/r10k`

`nano /etc/puppetlabs/r10k/r10k.yaml`

```yaml
---
:cachedir: '/var/cache/r10k'

:sources:
    :my-org:
        remote: 'https://github.com/JeffMill/control_repo.git'
        basedir: '/etc/puppetlabs/code/environments'
```

`r10k deploy environment -p`

`cat /etc/puppetlabs/code/environments/production/README.md`

## Manage a file in site.pp

github: Add file > Create New File

control_repo/manifests/site.pp

```ruby
node default {
  file { '/root/README' :
    ensure  => file,
  }
}
```

Click "Commit New File"

`r10k deploy environment -p`

`ls /etc/puppetlabs/code/environments/production/manifests`

`ls -l /root/README`

`puppet agent --test`

edit site.pp, and under "ensure => file," add:

```ruby
    content => 'This is a readme',
    owner   => 'root',
```

*Ensure you're running as root.*

`puppet agent --test`

`ls -l /root/README`

Running "puppet agent --test" again wont do anything, as nothing has changed.

You can't have duplicate resources (e.g. same filename) in a given node.

## Classes

Classes include a resource by name.

### Example

Given user grace, ensure account is present, has root access, vim is installed, and vim config file is set up.

```ruby
class dev_environment {
  user { 'grace':
    ensure => present,
    manage_home => true,
    group => ['wheel'],
  }
  package { 'vim':
    ensure => present,
  }
  file { '/home/grace/.vimrc':
    ensure => file,
    source => 'puppet:///modules/dev_environment/vimrc',
  }
}
```
