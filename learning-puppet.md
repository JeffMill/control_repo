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

`r10k deploy environment --puppetfile`

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

`r10k deploy environment --puppetfile`

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

site.pp could include a classification to define a default class, e.g.

```ruby
node default {
  class { 'dev_environment':
    ensure => present,
  }
}
```

Could also use "include" keyword, e.g.

```ruby
node default {
  include dev_environment
}
node 'grace.puppet.vm' {
  include dev_environment
}
```

## PuppetForge

puppetforge is [here](https://forge.puppet.com) and contains pre-written reusable modules, e.g. [wsus_client](https://forge.puppet.com/modules/puppetlabs/wsus_client)

Different levels of modules: Supported, Partner, Approved, Community - define level of support.

### NGINX module

[This module](https://forge.puppet.com/modules/puppet/nginx) is for managing NGINX WWW service.

Supports multiple platforms (redhat, ubuntu) and accounts for platform differences.

Can be used with [Bolt](https://puppet.com/docs/bolt), an orchestration tool written by puppet - typically used for one-time, adhoc operations vs. the more typical puppet approach of managing system state. More details about Bolt later.

Can also be installed using r10k by putting a declaration in "Puppetfile":

```ruby
mod 'puppet-nginx', '3.0.0'
```

Also can install module manually using "puppet module".

Has link to a [quick start guide](https://github.com/voxpupuli/puppet-nginx/blob/master/docs/quickstart.md)

Modules have a module dependency chain. For example, nginx depends on puppetlabs/concat and puppetlabs/stdlib.

## Add NGINX module

In control_repo, click Add File > Create New File, name **Puppetfile** (capital "P")

```ruby
mod 'puppet/nginx', '1.0.0'
mod 'puppetlabs/concat'
mod 'puppetlabs/stdlib'
mod 'puppetlabs/translate'
```

Commit.

*Note that we're pinning to nginx v1.0.0 and specifying the dependent modules as well.*

## Create Profiles

**Profiles**: building block of configuration. Wrapper for subset of configuration. Limited to single unit of configuration.

**Roles**: Business role of a machine. One role per machine. Made up of profiles.

"Space is cheap. Confusion is expensive."

In control_repo root, click Add File > Create New File, name **site/profile/manifests/web.pp**:

```ruby
class profile::web {
  include nginx
}
```

Commit.

Create **app.pp** (in site/profile/manifests):

```ruby
class profile::app {
}
```

Commit.

Create **db.pp** (in site/profile/manifests):

```ruby
class profile::db {
}
```

Commit.

Create **base.pp** (in site/profile/manifests):

```ruby
class profile::base {
  user { 'admin':
    ensure => present,
  }
}
```

Commit.

## Group Profiles into Roles

(note "role" folder instead of "profile")

In control_repo root, click Add File > Create New File, name **site/role/manifests/app_server.pp**:

```ruby
class role::app_server {
  include profile::app
  include profile::base
  include profile::web
}
```

Commit.

Create **db_server.pp** (in site/role/manifests):

```ruby
class role::db_server {
  include profile::base
  include profile::db
}
```

Commit.

Create **master_server.pp** (in site/role/manifests):

```ruby
class role::master_server {
  include profile::base
}
```

Commit.

If features were to be added to all roles, we can just add to "base" profile.

To split "app" and "web" servers to  different machines, we could define two new roles that wrap just those profiles.

## Specify location of custom profiles

Create **environment.conf** (in root of control_repo):

```ini
modulepath = site:modules:$basemodulepath
```

**site**: where we created roles and profiles

**modules**: where r10k deploys forge modules

**$basemodulepath**: where puppet internal modules are stored.

Commit.

## Create node definition only for master, and give master_server role

Edit **manifests/site.pp**:

```ruby
node 'master.puppet.vm' {
  include role::master_server
}
```

Commit.

Note: A node only matches one node definition. There is no inheritance between node definitions.  With this specific node, master will now no longer match default.

## Manage Nodes

Rather than spin up additional VMs, "dockeragent" module can spin up simulated puppet nodes.

Installs docker on master and sets up containers that act as puppet nodes.

[Original version](https://forge.puppet.com/modules/pltraining/dockeragent) (not used in training)

[Forked version](https://forge.puppet.com/modules/samuelson/dockeragent)

Depends on puppetlabs/docker which depends on several modules (stdlib, translate, apt, powershell, reboot) - the latter two are Windows specific.  apt is debian specific.

In control_repo, edit **Puppetfile**, add:

```ruby
mod 'samuelson/dockeragent'
mod 'puppetlabs/docker'
```

(file already has stdlib and translate modules included from previous step)

Commit.

In control_repo root, click Add File > Create New File, name **site/profile/manifests/agent_nodes.pp**:

```ruby
class profile::agent_nodes {
  include dockeragent
  dockeragent::node {
    'web.puppet.vm':
  }
  dockeragent::node {
    'db.puppet.vm':
  }
}
```

This will create a "web" and a "db" node.

Commit.

Add profile to master_server role by editing **master_server.pp** (in site/role/manifests):

```ruby
  include profile::agent_nodes
```

Commit.

## Deploy

`r10k deploy environment --puppetfile`

`puppet agent --test`

*This will take a long time to run.*

I saw "Error: Could not find a suitable provider for docker_network" and tried again and it works.  Perhaps [this](https://github.com/puppetlabs/puppetlabs-docker/issues/703) issue?

## Expand site.pp


Match any node starting with node, using a regexp.

Edit **manifests/site.pp**:

```ruby
node /^web/ {
  include role::app_server
}

node /^db/ {
  include role::db_server
}
```

Commit.

Deploy on master:

`r10k deploy environment --puppetfile`

*No need to run puppet -- the code we changed only applies to web and db nodes.*

## Connect agents to master

### Connect web node to master

`puppet agent --test`

Log in to "web" node using docker:

`docker exec -it web.puppet.vm bash`

Run puppet agent:

`puppet agent --test`

Should get: "Couldn't fetch certificate from CA server; you might still need to sign this agent's certificate (web.puppet.vm)" as certificate isn't set.

`exit`

Sign cert on master:

`puppetserver ca list`
Shows all certs waiting signing.

`puppetserver ca sign --certname web.puppet.vm`
Sign the cert - can also use "--all"

Log into node again:

`docker exec -it web.puppet.vm bash`

`puppet agent --test`

`exit`

### Connect db node to master

Perform same steps as above, but use db.puppet.vm

## Orchestration

### MCollective package

Documentation is [here](https://puppet.com/docs/mcollective/currentl)

bundled with puppet (marrionette collective). can trigger puppet run or more complex scnearios.
pub-sub model.

Tolerant of spotty network connections

Can't guarantee that a machine received a message

### Ansible

Homepage is [here](https://www.ansible.com/)

Ansible uses SSH to connect to nodes.

Puppet for desired state, ansible for orchestration and procedural paths

### SSH in "for" loop

Connect to each in a loop

Puppet manages SSH keys.

Simple approach

### Puppet Bolt

Homepage is [here](https://puppet.com/docs/bolt)

Agent-less (uses SSH)

Not widely used yet - difficult to learn, other options have same functionality.

Made to integrate with puppet.  Can create bolt tasks that integrate with their module.

Can integrate with [PuppetDB](https://puppet.com/docs/puppetdb) - database for puppet managed systems

## Puppet Run

1. Agent launches "facter" to collect details about system
2. Sends to master
3. Master looks up details, creates catalog
4. Catalog defines what should occur on a device and in what order
5. Agent takes catalog, enforces changes on node (e.g. install software package, configure user)
6. Agent sends report of run to master
   1. metadata
   2. status
   3. events
   4. logs
   5. metrics of run

## Facter

Run `facter` on master

`facter timezone`

`facter fqdn`

`facter os`, `facter os.family`

These are facts that can be used in puppet code.

### Add to site.pp

Edit **/manifests/site.pp**, in node 'master.puppet.vm', add

```ruby
  file { '/root/README':
    ensure => file,
    content => "Welcome to ${fqdn}\n",
  }
```

Commit.

*Note that facts are just preset variables.*

Deploy and run code:

`r10k deploy environment --puppetfile`

`puppet agent --test`

`cat /root/README`

## Install SSH and add hosts

Generate SSH key pair on master:

`ssh-keygen` - leave keyphrase blank

`cat /root/.ssh/id_rsa.pub` - copy "middle" part

Create **site/profile/manifests/ssh_server.pp**:

```ruby
class profile::ssh_server {
  package { 'openssh-server':
    ensure => present,
  }
  service { 'sshd':
    ensure => 'running',
    enable => 'true',
  }
  ssh_authorized_key { 'root@master.puppet.vm':
    ensure => present,
    user => 'root',
    type => 'ssh-rsa',
    key => 'AAAAB...[paste key here]',
    }
}
```

Commit.

Add to base profile **site/profile/manifests/base.pp**:

```ruby
  include profile::ssh_server
```

Commit.

## Add host entries for nodes

*Note: In production, you'd use DNS.*

facter can get IP addresses of nodes.

`docker exec -it web.puppet.vm facter ipaddress`

`docker exec -it db.puppet.vm facter ipaddress`

Edit **site/profile/manifests/agent_nodes.pp**:

```ruby
  host { 'web.puppet.vm':
    ensure => present,
    ip => '[webip_address]',
  }
  host { 'db.puppet.vm':
    ensure => present,
    ip => '[db ip_address]',
  }
```

Commit.

Deploy and run code:

`r10k deploy environment --puppetfile`

`puppet agent --test`

`docker exec -it db.puppet.vm puppet agent --test`

"Notice: /Stage[main]/Profile::Ssh_server/Ssh_authorized_key[root@master.puppet.vm]/ensure: created"

`docker exec -it web.puppet.vm puppet agent --test`

## Log in

`ssh web.puppet.vm` now works!

