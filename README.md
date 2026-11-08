# Projeto 01 — Infraestrutura com Vagrant e Ansible

**Instituição:** Instituto Federal da Paraíba (IFPB)  
**Disciplina:** Administração de Sistemas Abertos  
**Professor:** Leonidas Francisco de Lima Junior  
**Integrantes:**

- Wagner Marinho de Andrade Filho — matrícula `20242380004`
- Wilson Fillipe do Nascimento Lima — matrícula `20251380021`

## Objetivo

Provisionar uma pequena infraestrutura Linux com quatro máquinas virtuais Debian 12. O Vagrant cria as VMs no VirtualBox; playbooks Ansible instalam e configuram os serviços e as políticas comuns.

## Máquinas e serviços

| Máquina | Endereço | Função |
|---|---:|---|
| `arq` | `192.168.56.104` | DHCP, DNS Bind9, armazenamento LVM e compartilhamento NFS |
| `db` | `192.168.56.121` | MariaDB e montagem automática do NFS |
| `app` | `192.168.56.141` | Apache com a página do projeto e montagem automática do NFS |
| `cli` | DHCP | Firefox ESR, X11 e montagem automática do NFS |

Os endereços seguem a atividade: `arq` usa os dois últimos dígitos da matrícula de Wagner (`04`); `db`, os de Wilson (`21`); `app`, o último dígito de Wagner seguido pelo de Wilson (`41`). O cliente recebe um endereço dinâmico da faixa `192.168.56.50–100`.

### O que é configurado

- **Em todas as VMs:** atualização do sistema, fuso `America/Recife`, Chrony usando `pool.ntp.br`, usuários `wagner` e `wilson`, grupo `ifpb`, SSH por chave pública e sudo para o grupo.
- **`arq`:** DHCP autoritativo, DNS direto e reverso, VG `dados` nos três discos extras, LV `ifpb` de 15 GB em EXT4 montado em `/dados` e NFS em `/dados/nfs`.
- **`db`:** servidor MariaDB e Autofs para montar o NFS em `/var/nfs/dados`.
- **`app`:** Apache publica uma página com os dados da atividade; Autofs monta o NFS em `/var/nfs/dados`.
- **`cli`:** Firefox ESR, `xauth`, encaminhamento gráfico X11 no cliente SSH e Autofs para o NFS.

O NFS mapeia conexões remotas para `nfs-ifpb`. O MariaDB é instalado, mas a atividade não pede criar schema, tabelas ou usuários de banco.

## Arquivos principais

- `Vagrantfile`: define as quatro VMs, rede, discos e provisionamento.
- `hosts.ini` e `ansible.cfg`: inventário manual e configuração do Ansible.
- `playbooks/conf-geral.yml`: configurações comuns, usuários, SSH, sudo, Chrony e chaves.
- `playbooks/conf-dhcp.yml`: serviço e reservas DHCP.
- `playbooks/arq.yml`: LVM, NFS e DNS.
- `playbooks/db.yml`, `app.yml` e `cli.yml`: configurações específicas de cada máquina.
- `requirements.yml`: collections Ansible necessárias.
- `.gitignore`: impede versionar chaves privadas e arquivos locais do Vagrant.

## Pré-requisitos

- VirtualBox e Vagrant instalados.
- Ansible instalado no computador hospedeiro (em Linux ou WSL, se estiver usando Windows).
- Espaço em disco para as VMs e conexão à internet para baixar a imagem Debian e os pacotes.

Na pasta do projeto, instale as collections usadas pelos playbooks:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Como usar

Criar e provisionar as quatro máquinas:

```bash
vagrant up
```

Verificar o estado e acessar uma VM:

```bash
vagrant status
vagrant ssh arq
```

Para entrar em outra máquina, substitua `arq` por `db`, `app` ou `cli`. Para reaplicar as configurações:

```bash
vagrant provision
```

Comandos úteis:

```bash
vagrant halt       # desliga as VMs
vagrant up         # inicia ou cria as VMs
vagrant reload     # reinicia as VMs
vagrant destroy    # remove as VMs e seus discos
```

`vagrant destroy` apaga as máquinas virtuais e os discos associados. Use-o apenas quando quiser removê-las.

## Usar Ansible manualmente

O inventário contém os três servidores com IP fixo. Confira os hosts e a conexão:

```bash
ansible-inventory --graph
ansible servidores -m ping
```

Como os playbooks têm `hosts: all`, limite a execução à máquina correspondente. Exemplos:

```bash
ansible-playbook -i hosts.ini playbooks/conf-geral.yml --limit arq
ansible-playbook -i hosts.ini playbooks/arq.yml --limit arq
ansible-playbook -i hosts.ini playbooks/db.yml --limit db
ansible-playbook -i hosts.ini playbooks/app.yml --limit app
```

O IP de `cli` é dinâmico e não consta no `hosts.ini`. Para executar `cli.yml` manualmente, inclua no inventário o endereço DHCP atual da interface privada e use `--limit cli`. Durante `vagrant up`, o Vagrant fornece automaticamente o inventário de provisionamento.

## Acessar e conferir os serviços

- **Página Apache:** `http://192.168.56.141/`.
- **DNS:** consulte `arq.wagner.wilson.devops`, `db.wagner.wilson.devops` ou `app.wagner.wilson.devops` na rede privada. Do hospedeiro, consulte diretamente o DNS com `dig @192.168.56.104 app.wagner.wilson.devops`.
- **NFS:** em `db`, `app` e `cli`, acessar `/var/nfs/dados` aciona a montagem automática.
- **LVM:** no servidor `arq`, `sudo pvs`, `sudo vgs` e `sudo lvs` mostram os volumes configurados.
- **Serviços:** `systemctl status isc-dhcp-server bind9 nfs-kernel-server` em `arq`; `systemctl status mariadb` em `db`; `systemctl status apache2` em `app`.

## Observações

- O playbook LVM espera os discos adicionais `/dev/sdb`, `/dev/sdc` e `/dev/sdd` criados pelo Vagrant. Use-os somente para este laboratório; não aponte o playbook a discos com dados importantes.
- As chaves Ed25519 privadas ficam em `keys/`, no controlador Ansible, e estão excluídas do Git. Não as publique nem as compartilhe.
- O DHCP do VirtualBox é interrompido pelo gatilho do `Vagrantfile` para evitar conflito com o DHCP do laboratório.
- Para alterar nomes ou matrículas, atualize `Vagrantfile`, `playbooks/conf-dhcp.yml`, `playbooks/arq.yml` e os endereços correspondentes em `hosts.ini`.
