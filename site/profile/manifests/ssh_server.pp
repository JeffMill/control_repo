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
    key => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDfkBzNzbjLX0xDRKWTUa9JoIddmN4XIELtjzZ8JGU1rZzMDllVBs4iry8/fjZ4d9Qp7zSZSFeex1IXzx2N+GsfXk6uluBcI5QI68GpNOxHx3pBeIvt8n/vARz7avkueY5yXNV1wdcHYH3xGSTiz9tGi8XzaJ3CNDb21YvFuhITT1on5yTc3A71Ud+AWmsQcH0x5tMKcDuzy/62VZWFHaFU/zIgvihAOwSj0zLR8xDNN4dttHDo/kIcGwxnthOkf3qkMxNea5I8PW48DTESWqsTgqT9IszmhBANEoIPO0IS3fK6V2a9egTKl2z1r/MfOEFzPOZhLFhXWj7UGCQYNIq1'
    }
}
