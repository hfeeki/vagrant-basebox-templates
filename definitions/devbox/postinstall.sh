# postinstall.sh created from Mitchell's official lucid32/64 baseboxes

# Apt-install various things necessary for Ruby, guest additions,
# etc., and remove optional things to trim down the machine.
function install_dependices {
	echo "start to install dependices ..."
	apt-get -y update
	apt-get -y upgrade
	apt-get -y install linux-headers-$(uname -r) build-essential
	apt-get -y install zlib1g-dev libssl-dev libreadline-gplv2-dev libyaml-dev
	apt-get -y install vim openssl
	apt-get -y install git-core bzr gcc bison gawk libc6-dev 
	apt-get -y install python-software-properties make mercurial
	apt-get -y install mongodb  
	apt-get clean
	echo "successed install dependices."
}
# Installing the virtualbox guest additions
function install_vbox_additions {
	echo "start to install vbox additions ..."
	apt-get -y install dkms
	VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
	cd /tmp
	wget http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
	mount -o loop VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
	sh /mnt/VBoxLinuxAdditions.run
	umount /mnt
	rm VBoxGuestAdditions_$VBOX_VERSION.iso
	echo "successed install vbox additions."
}
# Setup sudo to allow no-password sudo for "admin"
function add_user_groups {
	echo "start to add users:vagrant, puppet and group:admin, puppet ..."
	groupadd -r admin
	usermod -a -G admin vagrant
	cp /etc/sudoers /etc/sudoers.orig
	sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
	sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers
	# Add puppet user and group
	adduser --system --group --home /var/lib/puppet puppet
	echo "successed to add users and groups"
}
# Install Ruby from source in /opt so that users of Vagrant
# can install their own Rubies using packages or however.
function install_ruby_from_src {
	echo "start install ruby from src ..."
	wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p286.tar.gz
	tar xvzf ruby-1.9.3-p286.tar.gz
	cd ruby-1.9.3-p286
	./configure --prefix=/opt/ruby
	make
	make install
	cd ..
	rm -rf ruby-1.9.3-p286
	rm ruby-1.9.3-p286.tar.gz
	echo "successed to install ruby."
}
# Install RubyGems 1.8.24
function install_rubygems_from_src {
	echo "start to install rubygems ..."
	wget http://production.cf.rubygems.org/rubygems/rubygems-1.8.24.tgz
	tar xzf rubygems-1.8.24.tgz
	cd rubygems-1.8.24
	/opt/ruby/bin/ruby setup.rb
	cd ..
	rm -rf rubygems-1.8.24
	rm rubygems-1.8.24.tgz
	echo "successed to install rubygems."
}
# Installing chef & Puppet
function install_chef_puppet {
	echo "start to install chef and puppet ..."
	/opt/ruby/bin/gem install chef --no-ri --no-rdoc
	/opt/ruby/bin/gem install puppet --no-ri --no-rdoc
	echo "successed to install chef and puppet."
}
# Need conditionals around `mesg n` so that Chef doesn't throw
# `stdin: not a tty`
function make_chef_happy {	
	echo "start to make chef happy ..."
	sed -i '$d' /root/.profile
	cat << 'EOH' >> /root/.profile
if `tty -s`; then
  mesg n
fi
EOH
	echo "successed to make chef happy."
}
# Installing vagrant keys
function install_vagrant_keys {
	echo "start to install vagrant keys ..."
	mkdir /home/vagrant/.ssh
	chmod 700 /home/vagrant/.ssh
	cd /home/vagrant/.ssh
	wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
	chmod 600 /home/vagrant/.ssh/authorized_keys
	chown -R vagrant /home/vagrant/.ssh
	echo "successed to install vagrant keys."
}
function change_gem_source {	
	gem sources --remove https://rubygems.org/
	gem sources -a http://ruby.taobao.org/
	echo "changed gem sources."
}
# install go from hg
function install_go_from_src {
	echo "start to install golang from src ..."
	cd /home/vagrant
	hg clone -u release https://go.googlecode.com/hg/ go
	cd go/src
	./all.bash

	echo "export GOROOT=/home/vagrant/go" >> /home/vagrant/.bashrc
	echo "export GOARCH=amd64" >> /home/vagrant/.bashrc
	echo "export GOOS=linux" >> /home/vagrant/.bashrc
	echo "export GOBIN=$GOROOT/bin" >> /home/vagrant/.bashrc
	echo "export GOPATH=/home/vagrant/.go" >> /home/vagrant/.bashrc
	echo "export PATH=$PATH:$GOBIN:$GOPATH/bin" >> /home/vagrant/.bashrc
	echo "successed to install glang from src."
}
# install golang from ppa
function install_go_from_ppa {
	echo "start to install golang from ppa ..."
	apt-add-repository ppa:gophers/go
	apt-get update 
	apt-get install golang	
	echo "successed to install glang from ppa."
}
# install nodejs
function install_nodejs {
	echo "start to install nodejs from src ..."
	cd /home/vagrant 	
	git clone https://github.com/joyent/node.git
	cd node
	#git checkout v0.9.9
	./configure
	make
	make install
	echo "successed to install nodejs from src."
}
}
#############################################################################

date > /etc/vagrant_box_build_time

install_dependices

install_vbox_additions

add_user_groups

# Install NFS client
apt-get -y install nfs-common

install_ruby_from_src

install_rubygems_from_src

install_chef_puppet

# Add /opt/ruby/bin to the global path as the last resort so
# Ruby, RubyGems, and Chef/Puppet are visible
echo 'PATH=$PATH:/opt/ruby/bin/'> /etc/profile.d/vagrantruby.sh

make_chef_happy

install_vagrant_keys

change_gem_source

install_dependices

install_go_from_src

install_nodejs

###############################################################

# Remove items used for building, since they aren't needed anymore
apt-get -y remove linux-headers-$(uname -r) build-essential
apt-get -y autoremove

# Zero out the free space to save space in the final image:
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm /var/lib/dhcp3/*

# Make sure Udev doesn't block our network
# http://6.ptmc.org/?p=164
echo "cleaning up udev rules"
rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
echo "pre-up sleep 2" >> /etc/network/interfaces


exit
