Vagrant.configure("2") do |config|
  config.vm.define "ubuntu" do |ubuntu|
    ubuntu.vm.box = "ubuntu/xenial64"
    ubuntu.vm.hostname = "builder"
    ubuntu.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbook.yml"
      ansible.galaxy_role_file = 'requirements.yml'
    end
    # NOTE: https://groups.google.com/forum/#!topic/vagrant-up/eZljy-bddoI
    #       This will remove the ubuntu-xenial-16.04-cloudimg-console.log file
    ubuntu.vm.provider "virtualbox" do |vb|
      vb.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
    end
    ubuntu.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 1
      vb.customize ['modifyvm', :id, '--nictype1', 'virtio']
    end
  end
end
