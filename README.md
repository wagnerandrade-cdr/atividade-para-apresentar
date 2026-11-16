# Projeto DevOps — Vagrant e Ansible

## 1. Sobre o projeto

Projeto desenvolvido para a disciplina **Administração de Sistemas Abertos**, do IFPB, sob orientação do professor Leonidas Francisco de Lima Junior.

**Integrantes:**
- Wagner Marinho de Andrade Filho — 20242380004
- Wilson Fillipe do Nascimento Lima — 20251380021

O objetivo é criar uma infraestrutura Linux automatizada utilizando **Vagrant, VirtualBox e Ansible**, aplicando conceitos de DevOps e Infraestrutura como Código (IaC).

## 2. Infraestrutura

Foram configuradas quatro máquinas virtuais Debian 12 na rede `192.168.56.0/24`.

| Máquina | IP | Serviços |
|---|---|---|
| arq | 192.168.56.104 | DHCP, DNS, LVM e NFS |
| db | 192.168.56.121 | MariaDB e Autofs |
| app | 192.168.56.141 | Apache2 e Autofs |
| cli | DHCP (.50–.100) | Firefox, X11 e Autofs |

O Vagrant cria as máquinas virtuais e configura seus recursos. O Ansible automatiza a instalação de serviços, usuários, permissões, SSH e sincronização de horário com Chrony.

O servidor `arq` fornece DHCP e DNS, além de compartilhar arquivos via NFS. Os demais servidores acessam esse compartilhamento automaticamente utilizando Autofs.

## 3. Segurança SSH

O acesso remoto utiliza autenticação por chaves SSH:

1. As chaves são geradas no pc local com `preparar-chaves.sh`.
2. As chaves privadas permanecem no pc local.
3. O Ansible copia as chaves públicas para o `authorized_keys` dos usuários nas VMs.
4. O SSH valida as chaves e permite o acesso sem senha de login.

Também foram configurados o bloqueio de root e da autenticação por senha, acesso restrito aos grupos `vagrant` e `ifpb` e permissões sudo para o grupo `ifpb`.

## 4. Instalação e execução

**Pré-requisitos:** Linux, VirtualBox, Vagrant, Ansible, Python 3 e OpenSSH.

Na pasta principal do projeto, execute:

**1. Instalar as dependências do Ansible:**

```bash
ansible-galaxy collection install -r requirements.yml
```

**2. Gerar as chaves SSH:**

```bash
chmod +x preparar-chaves.sh
./preparar-chaves.sh
```

**3. Validar e iniciar as máquinas:**

```bash
vagrant validate
vagrant up arq
vagrant up db app cli
vagrant status
```

Antes de iniciar, confirme que o DHCP do VirtualBox está desativado na rede privada utilizada pelo projeto:

```bash
VBoxManage list dhcpservers
```

**4. Acessar uma máquina:**

```bash
vagrant ssh arq
```

Ou com a chave SSH:

```bash
ssh -i keys/wagner wagner@192.168.56.104
```

Para reexecutar as configurações após alterações:

```bash
vagrant provision
```

## 5. Testes de funcionamento

Verificar os principais serviços:

```bash
vagrant ssh arq -c "sudo pvs; sudo vgs; sudo lvs"
vagrant ssh arq -c "sudo exportfs -v"
vagrant ssh db -c "systemctl is-active mariadb"
vagrant ssh app -c "systemctl is-active apache2"
vagrant ssh cli -c "ls /var/nfs"
```

Testar DNS e a página web:

```bash
dig @192.168.56.104 app.wagner.wilson.devops
curl http://192.168.56.141
```

### Verificador do professor

Após configurar no notebook a resolução dos nomes `arq`, `app`, `db` e `cli` do domínio `wagner.wilson.devops`, execute na raiz do projeto:

```bash
python3 verificar.py wagner.wilson
```

Para salvar o resultado:

```bash
python3 verificar.py wagner.wilson 2>&1 | tee resultado-verificacao.txt
```

O script verifica SSH, usuários, Chrony, LVM, MariaDB, NFS e X11. Durante os testes, cria temporariamente um usuário `intruso` para conferir as restrições de acesso.

## 6. Aplicações práticas

O projeto demonstra a automação de servidores, gerenciamento de redes, compartilhamento de arquivos e segurança de acesso, conhecimentos aplicáveis em empresas, data centers, ambientes de desenvolvimento e infraestrutura em nuvem.

**Conclusão:** a utilização conjunta de Vagrant e Ansible permite criar, configurar e reproduzir ambientes Linux de maneira padronizada, automatizada e segura.

---

**IFPB — Administração de Sistemas Abertos — 2026.2**
