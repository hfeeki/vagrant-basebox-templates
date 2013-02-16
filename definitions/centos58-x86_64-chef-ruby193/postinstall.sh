#http://chrisadams.me.uk/2010/05/10/setting-up-a-centos-base-box-for-development-and-testing-with-vagrant/

date > /etc/vagrant_box_build_time

fail()
{
  echo "FATAL: $*"
  exit 1
}

#kernel source is needed for vbox additions
yum -y install gcc bzip2 make kernel-devel-`uname -r`
#yum -y update
#yum -y upgrade

yum -y install gcc-c++ zlib-devel openssl-devel readline-devel sqlite3-devel git
yum -y erase gtk2 libX11 hicolor-icon-theme avahi freetype bitstream-vera-fonts
yum -y clean all

# Chef omnibus installer
curl -L http://opscode.com/chef/install.sh | bash

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
  gem install chef --no-rdoc --no-ri
  rvm reset
EOP
) | bash

#Installing vagrant keys
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chown -R vagrant /home/vagrant/.ssh

#Installing the virtualbox guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
cd /tmp
wget http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
mount -o loop VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt

rm VBoxGuestAdditions_$VBOX_VERSION.iso

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
sed -i "s/^\(.*env_keep = \"\)/\1PATH /" /etc/sudoers

echo -e "\nFilling drive with zeroes, this will take a while."
dd if=/dev/zero of=/tmp/clean || rm /tmp/clean

#poweroff -h

exit
