# Vagrant specific
/bin/date > /etc/vagrant_box_build_time

# Add vagrant user
/usr/sbin/groupadd vagrant
/usr/sbin/useradd vagrant -g vagrant -G wheel
echo "vagrant"|/usr/bin/passwd --stdin vagrant
echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/vagrant
/bin/chmod 0440 /etc/sudoers.d/vagrant

# Installing vagrant keys
/bin/mkdir -pm 700 /home/vagrant/.ssh
/usr/bin/wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O /home/vagrant/.ssh/authorized_keys
/bin/chmod 0600 /home/vagrant/.ssh/authorized_keys
/bin/chown -R vagrant /home/vagrant/.ssh

# Customize the message of the day
echo 'Welcome to your Vagrant-built virtual machine.' > /etc/motd
