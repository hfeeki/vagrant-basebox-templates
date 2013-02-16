# CentOS 6.2 with Chef installed via the Omnibus Installer
# See http://chrisadams.me.uk/2010/05/10/setting-up-a-centos-base-box-for-development-and-testing-with-vagrant/

date > /etc/vagrant_box_build_time

yum -y install gcc make gcc-c++ ruby zlib zlib-devel openssl-devel readline readline-devel sqlite-devel perl kernel-devel-2.6.32-220.el6.x86_64 libffi-devel patch

# Chef omnibus installer
curl -L http://opscode.com/chef/install.sh | bash

# Installing vagrant keys
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
curl -L -o authorized_keys https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
chown -R vagrant /home/vagrant/.ssh

# Installing the virtualbox guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
cd /tmp
curl -L -o VBoxGuestAdditions_$VBOX_VERSION.iso http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
mount -o loop VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt

rm VBoxGuestAdditions_$VBOX_VERSION.iso

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

# Install system-wide RVM + ruby 1.9.3 from source + bundler
echo "Installing rvm."
curl -L https://get.rvm.io | bash -s -- stable
echo -e "\n#####\n\nInstalling ruby 1.9.3-p194, this will run for a while with no output.\n\n#####\n"
(
cat <<'EOP'
  echo 'export rvm_gem_options="--no-rdoc --no-ri"' >> /etc/rvmrc
  source /etc/profile.d/rvm.sh
  rvm install 1.9.3-p194 > /tmp/rvm-install-1.9.3-p194.log
  rvm use 1.9.3-p194
  gem install bundler --no-rdoc --no-ri
  rvm reset
EOP
) | bash

echo -e "\nFilling drive with zeroes, this will take a while."
dd if=/dev/zero of=/tmp/clean || rm /tmp/clean

exit
