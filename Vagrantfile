# -*- mode: ruby -*-
# vi: set ft=ruby :

require "open3"
require "shellwords"

dominio = "wagner.wilson.devops"
rede_privada = { netmask: "255.255.255.0" }
rede_privada[:name] = ENV["LAB_HOSTONLY_IF"] if ENV["LAB_HOSTONLY_IF"]
rede_dhcp = rede_privada.merge(type: "dhcp", ip: "192.168.56.1")
preparar_chaves = Shellwords.escape(File.expand_path("preparar-chaves.sh", __dir__))
registrar_host = File.expand_path("registrar-host-ssh.sh", __dir__)

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.ssh.insert_key = false
  config.vm.synced_folder ".", "/vagrant", disabled: true

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  config.vm.provider :virtualbox do |v|
    v.memory = 512
    v.linked_clone = true
    v.check_guest_additions = false
  end

  config.trigger.before :up, type: :command do |t|
    t.info = "Instalando as coleções Ansible e preparando as chaves SSH no hospedeiro"
    t.run = { inline: "bash #{preparar_chaves} --com-ansible" }
  end

  config.trigger.after :up do |t|
    t.info = "Registrando a identidade SSH da VM no hospedeiro"
    t.on_error = :continue
    t.ruby do |_env, machine|
      host = "#{machine.name}.#{dominio}"
      saida = String.new
      machine.communicate.execute("cat /etc/ssh/ssh_host_ed25519_key.pub") do |tipo, dados|
        saida << dados if tipo == :stdout
      end
      chaves = saida.lines.filter_map { |linha| linha[/^ssh-ed25519 [A-Za-z0-9+\/=]+/] }
      unless chaves.length == 1 && system("bash", registrar_host, host, chaves.first)
        raise "Falha ao registrar a identidade SSH de #{host}"
      end
    end
  end

  # Mesmo ponto do gatilho da Prática 05. Uma rede estática recém-criada
  # pode ainda não ter um servidor DHCP cadastrado no VirtualBox.
  config.trigger.before :"Vagrant::Action::Builtin::WaitForCommunicator", type: :action do |t|
    t.ruby do |_env, machine|
      info, status = Open3.capture2("VBoxManage", "showvminfo", machine.id, "--machinereadable")
      raise "Falha ao consultar a configuração da VM no VirtualBox" unless status.success?

      interface = info[/^hostonlyadapter2="([^"]+)"/, 1]
      raise "A VM não está ligada ao adaptador host-only esperado" unless interface

      servidores, status = Open3.capture2("VBoxManage", "list", "dhcpservers")
      raise "Falha ao listar servidores DHCP do VirtualBox" unless status.success?

      rede = "HostInterfaceNetworking-#{interface}"
      if servidores.lines.any? { |linha| linha.partition(":").last.strip == rede }
        machine.ui.info("Interrompendo o DHCP do VirtualBox em #{interface}")
        unless system("VBoxManage", "dhcpserver", "stop", "--interface", interface)
          raise "Falha ao interromper o DHCP do VirtualBox em #{interface}"
        end
      end
    end
  end

  # O VirtualBox sobe as VMs em ordem. arq precisa prover DNS e DHCP antes dos clientes.
  config.vm.define "arq" do |arq|
    arq.vm.hostname = "arq.#{dominio}"
    arq.vm.network :private_network, ip: "192.168.56.104", **rede_privada

    3.times do |i|
      arq.vm.disk :disk, size: "10GB", name: "disk-#{i}"
    end

    arq.vm.provision "ansible_arq", type: "ansible" do |ansible|
      ansible.playbook = "playbooks/arq.yml"
    end

    arq.vm.provision "ansible_dhcp", type: "ansible" do |ansible|
      ansible.playbook = "playbooks/conf-dhcp.yml"
    end
  end

  config.vm.define "db" do |db|
    db.vm.hostname = "db.#{dominio}"
    db.vm.network :private_network, mac: "0800273A00DB", **rede_dhcp
    db.vm.provision "ansible_db", type: "ansible" do |ansible|
      ansible.playbook = "playbooks/db.yml"
    end
  end

  config.vm.define "app" do |app|
    app.vm.hostname = "app.#{dominio}"
    app.vm.network :private_network, mac: "0800273A00A1", **rede_dhcp
    app.vm.provision "ansible_app", type: "ansible" do |ansible|
      ansible.playbook = "playbooks/app.yml"
    end
  end

  config.vm.define "cli" do |cli|
    cli.vm.hostname = "cli.#{dominio}"
    cli.vm.network :private_network, **rede_dhcp

    cli.vm.provider :virtualbox do |v|
      v.memory = 1024
    end

    cli.vm.provision "ansible_cli", type: "ansible" do |ansible|
      ansible.playbook = "playbooks/cli.yml"
    end
  end
end
