# -*- mode: ruby -*-
# vi: set ft=ruby :

# ===== Dados do grupo =====
MATRICULA = "04"
NOME1     = "wagner"
NOME2     = "wilson"
DOMINIO   = "#{NOME1}.#{NOME2}.devops"

Vagrant.configure("2") do |config|
  # ===== Configuração geral =====
  config.vm.box = "debian/bookworm64"
  config.ssh.insert_key = false

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provider :virtualbox do |v|
    v.memory = 512
    v.linked_clone = true
    v.check_guest_additions = false
  end

  config.trigger.before :"Vagrant::Action::Builtin::WaitForCommunicator", type: :action do |t|
    t.warn = "Interrompe o servidor DHCP do VirtualBox"
    t.run  = { inline: "bash -c 'VBoxManage dhcpserver stop --netname HostInterfaceNetworking-vboxnet0 || true'" }
  end

  # ===== arq =====
  config.vm.define "arq" do |arq|
    arq.vm.hostname = "arq.#{DOMINIO}"
    arq.vm.network :private_network, ip: "192.168.56.1#{MATRICULA}"

    (0..2).each do |x|
      arq.vm.disk :disk, size: "10GB", name: "disk-#{x}"
    end

    arq.vm.provision "ansible_dhcp", type: "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.playbook = "playbooks/conf-dhcp.yml"
    end

    arq.vm.provision "ansible_geral", type: "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.playbook = "playbooks/conf-geral.yml"
    end

    arq.vm.provision "ansible_arq", type: "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.playbook = "playbooks/arq.yml"
    end
  end

  # ===== db =====
  config.vm.define "db" do |db|
    db.vm.hostname = "db.#{DOMINIO}"
    db.vm.network :private_network, mac: "0800273A00DB", type: "dhcp"

    db.vm.provision "ansible_geral", type: "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.playbook = "playbooks/conf-geral.yml"
    end

    db.vm.provision "ansible_db", type: "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.playbook = "playbooks/db.yml"
    end
  end

  # ===== app =====
  config.vm.define "app" do |app|
    app.vm.hostname = "app.#{DOMINIO}"
    app.vm.network :private_network, mac: "0800273A00A1", type: "dhcp"

    app.vm.provision "ansible_geral", type: "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.playbook = "playbooks/conf-geral.yml"
    end

    app.vm.provision "ansible_app", type: "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.playbook = "playbooks/app.yml"
    end
  end

  # ===== cli =====
  config.vm.define "cli" do |cli|
    cli.vm.hostname = "cli.#{DOMINIO}"
    cli.vm.network :private_network, type: "dhcp"

    cli.vm.provider :virtualbox do |v|
      v.memory = 1024
    end

    cli.vm.provision "ansible_geral", type: "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.playbook = "playbooks/conf-geral.yml"
    end

    cli.vm.provision "ansible_cli", type: "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.playbook = "playbooks/cli.yml"
    end
  end
end
