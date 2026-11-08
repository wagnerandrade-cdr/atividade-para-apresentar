# Projeto 01 — Administração de Sistemas Abertos
## Infraestrutura de Servidores Linux com Vagrant e Ansible

**Instituição:** Instituto Federal da Paraíba (IFPB)  
**Disciplina:** Administração de Sistemas Abertos  
**Professor:** Leonidas Lima  
**Integrantes:** Wagner e Wilson  

---

## 1. Sobre o projeto

Este projeto tem como objetivo desenvolver e configurar uma infraestrutura de rede composta por máquinas virtuais Linux, utilizando as ferramentas Vagrant, VirtualBox e Ansible.

A proposta consiste em simular um ambiente de infraestrutura de TI semelhante ao utilizado em empresas e organizações, no qual diferentes servidores desempenham funções específicas e trabalham de forma integrada por meio de uma rede privada.

O ambiente é composto por quatro máquinas virtuais com Debian 12 (Bookworm), responsáveis pelos serviços de arquivos, banco de dados, aplicação web e estação cliente.

A criação e o gerenciamento das máquinas virtuais são realizados pelo Vagrant, enquanto a instalação dos pacotes, configuração dos serviços e administração dos sistemas são automatizadas por meio do Ansible.

Com essa estrutura, o projeto permite colocar em prática conhecimentos de administração de sistemas Linux, redes de computadores, virtualização, gerenciamento de armazenamento, compartilhamento de arquivos, serviços de rede, segurança e automação de infraestrutura.

## 2. Objetivos

Os principais objetivos do projeto são:

- Criar e administrar máquinas virtuais Linux utilizando Vagrant e VirtualBox.
- Configurar uma rede privada para comunicação entre os servidores.
- Implementar um serviço DHCP para distribuição automática de endereços IP.
- Configurar um servidor DNS utilizando Bind9.
- Implementar compartilhamento de arquivos por meio do NFS.
- Gerenciar discos e volumes lógicos utilizando LVM.
- Instalar e configurar um servidor de banco de dados MariaDB.
- Implementar um servidor web Apache2.
- Configurar montagem automática de diretórios compartilhados utilizando Autofs.
- Implementar autenticação e administração remota por SSH.
- Configurar sincronização de horário utilizando Chrony.
- Automatizar a configuração dos servidores utilizando playbooks Ansible.

## 3. Tecnologias utilizadas

| Tecnologia | Finalidade |
|---|---|
| Arch Linux | Sistema operacional da máquina hospedeira |
| Debian 12 | Sistema operacional das máquinas virtuais |
| VirtualBox | Plataforma de virtualização |
| Vagrant | Criação e gerenciamento das máquinas virtuais |
| Ansible | Automação e configuração dos servidores |
| DHCP | Distribuição automática de endereços IP |
| Bind9 | Serviço de resolução de nomes DNS |
| NFS | Compartilhamento de arquivos pela rede |
| LVM | Gerenciamento de armazenamento |
| MariaDB | Sistema gerenciador de banco de dados |
| Apache2 | Servidor web |
| Autofs | Montagem automática de sistemas de arquivos |
| OpenSSH | Administração e acesso remoto |
| Chrony | Sincronização de horário por NTP |

## 4. Arquitetura da infraestrutura

A infraestrutura utiliza uma rede privada na faixa `192.168.56.0/24`, permitindo a comunicação entre as máquinas virtuais.

O ambiente possui quatro servidores:

### 4.1. Servidor de arquivos — arq

O servidor `arq` é responsável pelos principais serviços de infraestrutura e armazenamento.

Serviços configurados:

- **DHCP:** distribui endereços IP automaticamente para as máquinas da rede.
- **DNS (Bind9):** realiza a resolução de nomes de domínio para endereços IP e também a resolução reversa.
- **NFS:** disponibiliza diretórios compartilhados para os demais servidores.
- **LVM:** organiza os discos virtuais em volumes lógicos para armazenamento.

O servidor utiliza três discos virtuais adicionais de 10 GB cada. Esses discos são agrupados em um Volume Group chamado `dados`, no qual é criado um Logical Volume de 15 GB chamado `ifpb`, formatado em EXT4 e montado no diretório `/dados`.

O compartilhamento NFS é disponibilizado em `/dados/nfs`.

### 4.2. Servidor de banco de dados — db

O servidor `db` é responsável pelo gerenciamento de bancos de dados.

Serviços configurados:

- **MariaDB:** instalação e inicialização do sistema gerenciador de banco de dados.
- **NFS:** configuração do acesso ao diretório compartilhado disponibilizado pelo servidor `arq`.
- **Autofs:** montagem automática do compartilhamento de arquivos.

Essa estrutura permite que aplicações utilizem um servidor específico para armazenamento e gerenciamento de informações.

### 4.3. Servidor de aplicação — app

O servidor `app` é responsável pela hospedagem de páginas e aplicações web.

Serviços configurados:

- **Apache2:** instalação e inicialização do servidor web.
- **HTML:** criação automática de uma página inicial contendo informações sobre o projeto.
- **NFS:** acesso ao diretório compartilhado do servidor de arquivos.
- **Autofs:** montagem automática do compartilhamento remoto.

O Apache disponibiliza a página HTML por meio de requisições HTTP, permitindo que outros computadores da rede acessem o conteúdo pelo navegador.

### 4.4. Máquina cliente — cli

A máquina `cli` simula um computador utilizado por um usuário da infraestrutura.

Configurações realizadas:

- Instalação do Firefox ESR.
- Instalação e configuração do XAuth.
- Configuração de encaminhamento gráfico X11 pelo SSH.
- Instalação do Autofs.
- Configuração do acesso ao compartilhamento NFS.

Essa máquina permite realizar testes de conectividade e utilização dos serviços disponibilizados pelos servidores.

## 5. Configurações gerais dos servidores

O playbook `conf-geral.yml` realiza configurações comuns em todas as máquinas virtuais.

Entre as principais tarefas estão:

- Atualização da lista de pacotes do Debian.
- Instalação do Chrony, NFS Common e Sudo.
- Configuração do fuso horário `America/Recife`.
- Sincronização de horário utilizando `pool.ntp.br`.
- Criação do grupo `ifpb`.
- Criação dos usuários `wagner` e `wilson`.
- Configuração do serviço SSH.
- Autenticação utilizando chaves Ed25519.
- Desativação da autenticação SSH por senha.
- Bloqueio do acesso direto do usuário root.
- Configuração de permissões administrativas para o grupo `ifpb`.
- Exportação das chaves privadas geradas para o diretório local `keys`.

Essas configurações padronizam o ambiente e facilitam a administração das máquinas virtuais.

## 6. Estrutura dos arquivos do projeto

A organização dos arquivos é a seguinte:

```text
atividade-para-apresentar/

 Vagrantfile
 ansible.cfg
 hosts.ini

 keys/
    arq_wagner_id_ed25519
    arq_wilson_id_ed25519
    db_wagner_id_ed25519
    db_wilson_id_ed25519
    app_wagner_id_ed25519
    app_wilson_id_ed25519
    cli_wagner_id_ed25519
    cli_wilson_id_ed25519

    playbooks/
       conf-geral.yml
       conf-dhcp.yml
       arq.yml
       db.yml
       app.yml
       cli.yml
 ```

### Descrição dos arquivos

**Vagrantfile:** define as máquinas virtuais, o sistema operacional, a memória, os discos adicionais, os endereços de rede e os playbooks executados durante o provisionamento.

**ansible.cfg:** define as configurações gerais do Ansible. Neste projeto, determina o arquivo `hosts.ini` como inventário padrão.

**hosts.ini:** contém os grupos de servidores e seus respectivos endereços IP, além das informações de autenticação SSH utilizadas pelo Ansible.

**conf-geral.yml:** realiza as configurações comuns de todas as máquinas.

**conf-dhcp.yml:** instala e configura o servidor DHCP.

**arq.yml:** configura LVM, NFS e DNS no servidor de arquivos.

**db.yml:** instala e configura o MariaDB e o acesso NFS.

**app.yml:** instala o Apache2, cria a página HTML e configura o acesso NFS.

**cli.yml:** configura o cliente, o Firefox, o X11 e o acesso NFS.

**keys/:** armazena as chaves SSH geradas para os usuários durante a configuração dos servidores. Essas chaves devem ser protegidas e não devem ser disponibilizadas publicamente.

## 7. Pré-requisitos

Para executar o projeto, é necessário possuir:

- Sistema Linux compatível.
- VirtualBox instalado.
- Vagrant instalado.
- Ansible instalado na máquina hospedeira.
- Espaço disponível em disco para armazenar as máquinas virtuais.
- Conexão com a internet para baixar a imagem Debian e instalar os pacotes necessários.

No Arch Linux, os pacotes principais podem ser instalados com:

```bash
sudo pacman -Syu
sudo pacman -S vagrant virtualbox ansible
```

A instalação e configuração dos módulos do VirtualBox devem ser compatíveis com o kernel utilizado no sistema hospedeiro.

Verifique as instalações:

```bash
vagrant --version
VBoxManage --version
ansible --version
```

## 8. Como executar o projeto

### 8.1. Clonar ou obter os arquivos

Caso o projeto esteja disponível em um repositório Git:

```bash
git clone URL_DO_REPOSITORIO
```

Entre no diretório:

```bash
cd atividade-para-apresentar
```

Verifique os arquivos:

```bash
ls -la
```

### 8.2. Verificar a configuração do Vagrant

O arquivo `Vagrantfile` contém as definições das quatro máquinas virtuais.

Para verificar a configuração:

```bash
cat Vagrantfile
```

### 8.3. Criar e iniciar as máquinas virtuais

Execute:

```bash
vagrant up
```

Esse comando inicia o processo de criação das máquinas virtuais no VirtualBox, realiza a configuração de rede e executa os provisionadores definidos no Vagrantfile.

Na primeira execução, o Vagrant pode baixar a imagem Debian 12 e instalar os pacotes necessários.

### 8.4. Verificar o estado das máquinas

Para verificar se as máquinas foram iniciadas corretamente:

```bash
vagrant status
```

Para visualizar as máquinas no VirtualBox:

```bash
VBoxManage list runningvms
```

O estado esperado é que as quatro máquinas estejam em execução:

- arq
- db
- app
- cli

### 8.5. Acessar as máquinas virtuais

Para acessar cada máquina pelo terminal:

Servidor de arquivos:

```bash
vagrant ssh arq
```

Servidor de banco de dados:

```bash
vagrant ssh db
```

Servidor de aplicação:

```bash
vagrant ssh app
```

Máquina cliente:

```bash
vagrant ssh cli
```

Para sair da máquina virtual:

```bash
exit
```

### 8.6. Executar novamente o provisionamento

Caso seja necessário executar novamente as configurações do Ansible:

```bash
vagrant provision
```

Para provisionar apenas uma máquina:

```bash
vagrant provision arq
```

Também é possível executar um provisionador específico:

```bash
vagrant provision arq --provision-with ansible_arq
```

**Atenção:** o playbook `arq.yml` contém comandos `wipefs` que removem assinaturas de sistemas de arquivos dos discos adicionais. Antes de repetir o provisionamento, verifique os discos e seus dados. Não execute essa configuração em discos que contenham informações importantes.

## 9. Comandos para administrar o ambiente

Principais comandos do Vagrant:

| Comando | Função |
|---|---|
| `vagrant up` | Inicia as máquinas virtuais |
| `vagrant status` | Mostra o estado das máquinas |
| `vagrant halt` | Desliga as máquinas |
| `vagrant suspend` | Suspende as máquinas |
| `vagrant resume` | Retoma máquinas suspensas |
| `vagrant reload` | Reinicia as máquinas |
| `vagrant ssh arq` | Acessa o servidor arq |
| `vagrant provision` | Executa novamente os provisionadores |
| `vagrant destroy` | Remove as máquinas virtuais |
| `vagrant global-status` | Lista ambientes Vagrant conhecidos |

Para desligar todo o ambiente:

```bash
vagrant halt
```

Para iniciar novamente:

```bash
vagrant up
```

Para remover as máquinas virtuais:

```bash
vagrant destroy
```

O comando de destruição remove as máquinas virtuais e seus discos associados. Utilize-o somente quando desejar recriar o laboratório.

## 10. Como utilizar o Ansible manualmente

O Ansible permite executar comandos e playbooks remotamente nas máquinas virtuais.

Primeiro, verifique a versão:

```bash
ansible --version
```

Verifique os equipamentos reconhecidos pelo inventário:

```bash
ansible-inventory --list
```

Teste a conectividade SSH com os servidores:

```bash
ansible servidores -m ping
```

O resultado esperado é uma resposta `SUCCESS` para cada equipamento alcançado.

Para executar um playbook manualmente, utilize:

```bash
ansible-playbook -i hosts.ini playbooks/conf-geral.yml
```

Exemplos de execução:

```bash
ansible-playbook -i hosts.ini playbooks/arq.yml
```

```bash
ansible-playbook -i hosts.ini playbooks/db.yml
```

```bash
ansible-playbook -i hosts.ini playbooks/app.yml
```

```bash
ansible-playbook -i hosts.ini playbooks/cli.yml
```

Como os playbooks utilizam `hosts: all`, ao executá-los manualmente é necessário limitar a execução ao grupo correto quando o inventário possuir vários servidores.

Exemplo:

```bash
ansible-playbook -i hosts.ini playbooks/arq.yml --limit arq
```

```bash
ansible-playbook -i hosts.ini playbooks/db.yml --limit db
```

```bash
ansible-playbook -i hosts.ini playbooks/app.yml --limit app
```

```bash
ansible-playbook -i hosts.ini playbooks/cli.yml --limit cli
```

Antes da execução manual, confira se os endereços IP do inventário correspondem aos endereços reais das máquinas.

## 11. Testes e validação dos serviços

Após iniciar e configurar as máquinas, é possível realizar testes para verificar o funcionamento da infraestrutura.

### 11.1. Verificar interfaces e endereços IP

Em cada máquina virtual:

```bash
ip addr
```

Ou:

```bash
ip -br addr
```

Para visualizar as rotas:

```bash
ip route
```

### 11.2. Testar a conectividade entre servidores

Exemplo, a partir da máquina cliente:

```bash
ping -c 4 192.168.56.104
```

Também é possível testar os outros servidores utilizando seus respectivos endereços IP.

### 11.3. Testar o DNS

Instale o utilitário DNS, caso necessário:

```bash
sudo apt install dnsutils
```

Consultar o servidor:

```bash
dig @192.168.56.104 app.wagner.wilson.devops
```

Consultar a resolução reversa:

```bash
dig @192.168.56.104 -x 192.168.56.104
```

Também é possível utilizar:

```bash
nslookup app.wagner.wilson.devops 192.168.56.104
```

### 11.4. Testar o servidor Apache

No servidor de aplicação:

```bash
sudo systemctl status apache2
```

Para testar localmente:

```bash
curl http://localhost
```

A partir de outra máquina, utilize o IP correto do servidor:

```bash
curl http://IP_DO_SERVIDOR_APP
```

Também é possível abrir o endereço IP no navegador.

### 11.5. Testar o MariaDB

No servidor de banco de dados:

```bash
sudo systemctl status mariadb
```

Para acessar o banco:

```bash
sudo mariadb
```

Dentro do MariaDB:

```sql
SHOW DATABASES;
```

Para sair:

```sql
EXIT;
```

### 11.6. Testar o NFS

No servidor de arquivos:

```bash
sudo systemctl status nfs-kernel-server
```

Verificar os compartilhamentos:

```bash
sudo exportfs -v
```

Nas máquinas clientes, acessar:

```bash
cd /var/nfs/dados
```

Verificar se o diretório foi montado:

```bash
findmnt
```

Para testar a gravação, crie um arquivo:

```bash
echo "Teste de compartilhamento NFS" | sudo tee /var/nfs/dados/teste.txt
```

Depois, verifique se o arquivo pode ser acessado pelas outras máquinas autorizadas.

### 11.7. Testar o LVM

No servidor `arq`, execute:

```bash
sudo pvs
```

Para visualizar os Volume Groups:

```bash
sudo vgs
```

Para visualizar os Logical Volumes:

```bash
sudo lvs
```

Para verificar os discos e partições:

```bash
lsblk
```

Para verificar os sistemas de arquivos montados:

```bash
df -h
```

### 11.8. Testar o Chrony

Em qualquer máquina configurada:

```bash
chronyc tracking
```

Para consultar os servidores de sincronização:

```bash
chronyc sources -v
```

### 11.9. Verificar o SSH

Verificar o serviço:

```bash
sudo systemctl status ssh
```

Consultar as configurações efetivas:

```bash
sudo sshd -T
```

Verificar os usuários criados:

```bash
getent passwd wagner
getent passwd wilson
```

Verificar o grupo:

```bash
getent group ifpb
```

## 12. Possíveis problemas e soluções

### Máquinas virtuais não iniciam

Verifique se o VirtualBox está instalado e se os módulos do kernel estão carregados.

```bash
VBoxManage list hostinfo
```

Confira também:

```bash
vagrant status
```

### Ansible não consegue acessar os servidores

Teste a conectividade:

```bash
ansible servidores -m ping
```

Verifique os endereços IP, o usuário SSH, o arquivo de chave privada e o estado das máquinas virtuais.

### Serviço DHCP não inicia

Verifique o nome da interface configurada:

```bash
ip -br link
```

Consulte o estado do serviço:

```bash
sudo systemctl status isc-dhcp-server
```

Consulte os logs:

```bash
sudo journalctl -u isc-dhcp-server -n 50
```

O arquivo `conf-dhcp.yml` configura a interface `eth1`, portanto ela precisa existir e corresponder à interface da rede privada.

### Servidor DNS apresenta problemas

Verifique o serviço:

```bash
sudo systemctl status named
```

Valide as configurações:

```bash
sudo named-checkconf
```

Verifique os arquivos de zona:

```bash
sudo named-checkzone wagner.wilson.devops /etc/bind/db.wagner.wilson.devops
```

### Apache não apresenta a página

Verifique o serviço:

```bash
sudo systemctl status apache2
```

Verifique o arquivo HTML:

```bash
cat /var/www/html/index.html
```

Consulte os logs:

```bash
sudo journalctl -u apache2 -n 50
```

### NFS não monta o compartilhamento

Verifique se o servidor está ativo:

```bash
sudo systemctl status nfs-kernel-server
```

Confira as exportações:

```bash
sudo exportfs -v
```

Verifique a configuração do Autofs:

```bash
cat /etc/auto.master
cat /etc/auto.nfs
```

Reinicie o serviço:

```bash
sudo systemctl restart autofs
```

## 13. Observações importantes sobre os endereços IP

Os arquivos de configuração devem utilizar endereços IP consistentes para que o DHCP, o DNS, o inventário Ansible e as máquinas virtuais funcionem corretamente.

Na versão dos arquivos utilizada como base para este projeto, foram identificadas algumas divergências:

- O DHCP reserva o endereço `192.168.56.122` para o servidor `db`, mas o `hosts.ini` apresenta `192.168.56.105`.
- O DNS utiliza `192.168.56.121` como endereço do banco de dados em uma variável, enquanto a zona reversa e o DHCP utilizam `192.168.56.122`.
- O DHCP reserva `192.168.56.124` para `app`, enquanto o inventário apresenta `192.168.56.51` e `192.168.56.52`.
- O inventário não apresenta um grupo específico para a máquina `cli`.

Antes de executar o Ansible manualmente, essas configurações devem ser conferidas e alinhadas aos endereços realmente atribuídos pelo Vagrant e pelo DHCP.

A configuração de rede também deve ser verificada para evitar conflitos com outros servidores DHCP existentes no computador hospedeiro.

**Atenção:** os comandos de LVM presentes no `arq.yml` limpam assinaturas dos discos adicionais e recriam volumes. Não utilize esse playbook em discos que contenham dados importantes.

As configurações de permissões NFS e autenticação também devem ser revisadas antes de qualquer utilização em ambiente de produção.

## 14. Aplicações práticas

Os conhecimentos desenvolvidos neste projeto podem ser aplicados em diferentes cenários profissionais:

- Administração de servidores Linux em empresas.
- Configuração e manutenção de redes corporativas.
- Implantação de serviços DHCP e DNS.
- Compartilhamento centralizado de arquivos.
- Gerenciamento de armazenamento em servidores.
- Hospedagem de aplicações web.
- Administração de bancos de dados.
- Controle de acesso e autenticação remota.
- Automação de tarefas administrativas com Ansible.
- Criação de ambientes de desenvolvimento e testes com Vagrant.
- Preparação de infraestruturas para ambientes de computação em nuvem.

O projeto também demonstra como diferentes serviços podem trabalhar em conjunto para formar uma infraestrutura organizada, automatizada e administrável.

## 15. Conclusão

O desenvolvimento deste projeto possibilita aplicar na prática os principais conceitos estudados na disciplina Administração de Sistemas Abertos.

Por meio do Vagrant e do VirtualBox, foi possível estruturar um ambiente virtual composto por diferentes servidores Linux. Com o Ansible, foram automatizadas as tarefas de instalação, configuração e gerenciamento dos serviços.

A integração entre DHCP, DNS, NFS, LVM, MariaDB, Apache, SSH e Chrony permite compreender melhor o funcionamento de uma infraestrutura de TI e a importância da comunicação entre os diferentes componentes de uma rede.

Além do aprendizado técnico, o projeto demonstra a importância da automação na administração de sistemas, reduzindo tarefas manuais, padronizando configurações e facilitando a manutenção dos servidores.

Dessa forma, a atividade contribui para o desenvolvimento de habilidades fundamentais nas áreas de redes de computadores, administração de sistemas Linux, infraestrutura de TI e DevOps.