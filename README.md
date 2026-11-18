# Projeto 01 - DevOps com Vagrant e Ansible

**Instituição** Instituto Federal da Paraíba (IFPB)  
**Disciplina** Administração de Sistemas Abertos  
**Professor** Leonidas Francisco de Lima Junior

- Wagner Marinho de Andrade Filho, matrícula `20242380004`
- Wilson Fillipe do Nascimento Lima, matrícula `20251380021`

O Vagrant cria quatro VMs Debian 12 no VirtualBox. O Ansible configura o sistema e os serviços de cada máquina.

| VM | IP privado | Função |
|---|---|---|
| `arq` | `192.168.56.104` | DHCP, DNS, LVM e servidor NFS |
| `db` | `192.168.56.121`, reservado por MAC | MariaDB e cliente NFS |
| `app` | `192.168.56.141`, reservado por MAC | Apache e cliente NFS |
| `cli` | `192.168.56.50–100`, dinâmico | Firefox ESR, SSH com X11 e cliente NFS |

O final do IP de aplicação é `141` porque os últimos dígitos de Wagner e Wilson são `4` e `1`, nessa ordem. Os nomes usam o domínio `wagner.wilson.devops`.

## Subir o projeto no notebook Linux

Use uma pasta no sistema de arquivos do Linux. Tenha Vagrant 2.3 ou superior compatível com sua versão do VirtualBox, Ansible Core 2.14 ou superior, OpenSSH e `flock` (do pacote `util-linux`). O hospedeiro e as VMs precisam de internet para obter a box, as coleções Ansible e os pacotes Debian.

Execute o Vagrant como seu usuário normal a partir da pasta do projeto.

```bash
vagrant up
```

Antes de subir as VMs, o `vagrant up` instala no hospedeiro as coleções de `requirements.yml`, reaproveitando as versões compatíveis já instaladas, e gera ou reaproveita as chaves `keys/wagner` e `keys/wilson`. As chaves privadas ficam no notebook. O Ansible lê cada arquivo `.pub` e instala a chave no `authorized_keys` do usuário correspondente nas quatro VMs. A opção `config.ssh.insert_key = false` mantém a configuração exigida no PDF para o usuário de provisionamento `vagrant`.

O VirtualBox inicia `arq` primeiro, com IP estático, e o provisionamento deixa o DNS e o DHCP prontos antes da subida dos clientes. O gatilho da Prática 05 executa `VBoxManage dhcpserver stop --interface` na rede host-only ligada à VM antes de `WaitForCommunicator`, quando há um servidor DHCP do VirtualBox cadastrado nessa rede. O DHCP de `arq` anuncia a faixa `.50–.100`, o gateway `192.168.56.1`, o DNS `192.168.56.104` e os leases de 180 e 3600 segundos. A saída dos clientes à internet usa o adaptador NAT.

Ao terminar a subida de cada VM, o Vagrant lê sua chave pública de identificação SSH pela conexão que ele gerencia e registra o nome completo no `~/.ssh/known_hosts` do usuário do hospedeiro. Isso prepara o SSH usado pelo script de verificação do professor. A resolução dos nomes no hospedeiro continua dependendo do DNS ou do `/etc/hosts`, conforme explicado abaixo.

Se precisar selecionar uma interface host-only existente, confirme o nome e que ela usa `192.168.56.1/24` antes de exportar a variável.

```bash
VBoxManage list hostonlyifs
export LAB_HOSTONLY_IF=vboxnet0
```

Se uma tentativa anterior falhou, extraia o ZIP atualizado na mesma pasta do projeto e preserve `.vagrant/` e `keys/`. Rode `vagrant up --provision` para reaproveitar as VMs já criadas e repetir a configuração. Se o `grub-pc` estiver parcialmente configurado, o playbook tenta concluir a configuração antes de instalar os serviços.

Por padrão, o provisionamento atualiza o índice APT e instala os pacotes dos serviços. O upgrade geral solicitado no enunciado ficou opcional, para que você possa validar o laboratório antes de rodá-lo. Para executar essa etapa depois, use `LAB_APT_UPGRADE=1 vagrant up --provision`.

## Acessar por SSH e usar Ansible

```bash
vagrant ssh arq
ssh -i keys/wilson wilson@192.168.56.104
ansible-inventory --graph
ansible servidores -m ping
ansible-playbook playbooks/db.yml --limit db
```

Para executar o inventário manualmente em `cli`, obtenha seu IP com `vagrant ssh cli -c 'ip -4 -br address'` e adicione-o ao grupo `[cli]` do `hosts.ini`. Para testar X11, use `ssh -X -i keys/wilson wilson@IP_DA_CLI` em uma sessão gráfica no notebook. Na VM, abra `firefox-esr`.

O Bind9 resolve as zonas direta e reversa na rede privada e encaminha consultas externas a `1.1.1.1` e `8.8.8.8`. Os clientes usam o DNS de `arq`. Para testar o DNS diretamente a partir do notebook, use:

```bash
dig @192.168.56.104 app.wagner.wilson.devops +short
dig @192.168.56.104 -x 192.168.56.141 +short
```

Se quiser abrir os nomes diretamente no navegador ou no SSH do notebook mesmo sem configurar o DNS do adaptador, adicione as seguintes linhas ao `/etc/hosts` do notebook.

```text
192.168.56.104 arq.wagner.wilson.devops arq
192.168.56.121 db.wagner.wilson.devops db
192.168.56.141 app.wagner.wilson.devops app
```

## Testar os serviços

```bash
vagrant ssh db -c 'ip -4 -br address; sudo mariadb-admin ping'
vagrant ssh app -c 'ip -4 -br address; systemctl is-active apache2'
vagrant ssh cli -c 'ip -4 -br address; getent hosts arq.wagner.wilson.devops db.wagner.wilson.devops app.wagner.wilson.devops'
vagrant ssh arq -c 'sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf; sudo named-checkconf -z'
vagrant ssh arq -c 'sudo pvs; sudo vgs; sudo lvs; findmnt /dados'
curl -f http://192.168.56.141/
```

Para testar a escrita via NFS, faça uma operação em `/var/nfs` na VM cliente e confira o proprietário no servidor. Os três clientes montam o compartilhamento diretamente em `/var/nfs` sob demanda. Todos os acessos remotos são mapeados para `nfs-ifpb` e o servidor usa gravação síncrona.

```bash
vagrant ssh cli -c 'touch /var/nfs/teste-cli.txt; findmnt -T /var/nfs/teste-cli.txt'
vagrant ssh arq -c "stat -c '%U:%G %a %n' /dados/nfs/teste-cli.txt"
```

O arquivo deve pertencer a `nfs-ifpb:nfs-ifpb`. Os três discos adicionais de `arq` formam o VG `dados`. O LV `ifpb` tem 15 GiB, usa ext4 e é montado em `/dados` pelo `fstab`.

Para desligar o laboratório, execute `vagrant halt`. Se precisar restaurar o DHCP do VirtualBox para outro uso depois de desligar as VMs, execute `VBoxManage dhcpserver start --interface vboxnet0` com o nome da interface em uso.

## Arquivos

- `Vagrantfile` e `preparar-chaves.sh` definem a infraestrutura, o gatilho DHCP e a geração de chaves.
- `registrar-host-ssh.sh` registra as identidades SSH públicas das VMs no hospedeiro.
- `ansible.cfg`, `hosts.ini` e `requirements.yml` definem o inventário manual e as dependências.
- `playbooks/conf-geral.yml` aplica APT, Chrony, fuso, grupo, usuários, SSH e sudo.
- `playbooks/arq.yml` e `playbooks/conf-dhcp.yml` configuram LVM, NFS, DNS e DHCP no servidor de arquivos.
- `playbooks/db.yml`, `playbooks/app.yml` e `playbooks/cli.yml` configuram os serviços das outras VMs e compartilham as tarefas de montagem em `playbooks/autofs.yml`.
- `playbooks/vars-lab.yml` contém os endereços usados pelos playbooks.
- `.gitignore` exclui as chaves e os arquivos locais do Vagrant.
