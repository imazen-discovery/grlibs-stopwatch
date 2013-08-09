# -*- mode: ruby -*-
# vi: set ft=ruby :

EXTRA_FOLDER=
  File.exists?("BUILD_DIR") ? IO.readlines("BUILD_DIR")[0].chomp : "";
EXTRA_MNT = "/vagrant-extra"

CORES=
  File.exists?("NUM_CORES") ? IO.readlines("NUM_CORES")[0].chomp : "1";

INSTALL_SCRIPT=<<EOF
apt-get update
apt-get install -y `egrep -v '^#'  /vagrant/package-deps.txt `
EOF

Vagrant.configure("2") do |config|
  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "precise32"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"

  # Install packages
  config.vm.provision :shell, :inline => INSTALL_SCRIPT

  # The third-party build dir has to be provided via the launch script.
  if EXTRA_FOLDER.size > 0
    config.vm.synced_folder EXTRA_FOLDER, EXTRA_MNT
  end

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--cpus", CORES]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]   # Needed for some AMD processors
  end
end
