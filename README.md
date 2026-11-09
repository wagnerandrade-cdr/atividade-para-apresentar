# Projeto 01 — Infraestrutura com Vagrant e Ansible

**Instituição:** Instituto Federal da Paraíba (IFPB)  
**Disciplina:** Administração de Sistemas Abertos  
**Professor:** Leonidas Francisco de Lima Junior  
**Integrantes:**

- Wagner Marinho de Andrade Filho — matrícula `20242380004`
- Wilson Fillipe do Nascimento Lima — matrícula `20251380021`

## Objetivo

Provisionar uma infraestrutura com quatro máquinas Debian 12 no VirtualBox. O Vagrant cria as VMs e o Ansible instala e configura os serviços, a rede, o armazenamento e as políticas de acesso.

## Máquinas e funções

| Máquina | Endereço | Função |
|---|---:|---|
| `arq` | `192.168.56.104` | DHCP, DNS Bind9, armazenamento LVM e servidor NFS |
| `db` | `192.168.56.121` | MariaDB e montagem automática do NFS |
| `app` | `192.168.56.141` | Apache com a página do projeto e montagem automática do NFS |
| `cli` | DHCP, faixa `.50–.100` | Firefox ESR, X11 e montagem automática do NFS |

Os endereços estáticos seguem as matrículas: `arq` usa os dois últimos dígitos de Wagner (`04`); `db`, os dois últimos de Wilson (`21`); `app`, o último dígito de Wagner seguido pelo de Wilson (`41`).

### Integração dos serviços

- `arq` distribui endereços aos clientes e informa o DNS da rede. O Bind9 resolve os nomes `arq.wagner.wilson.devops`, `db.wagner.wilson.devops` e `app.wagner.wilson.devops`.
- Os três discos extras de `arq` formam o VG `dados`. O LV `ifpb`, de 15 GB em EXT4, é montado em `/dados`.
- O NFS compartilha `/dados/nfs` com a rede privada. As conexões remotas são mapeadas para o usuário `nfs-ifpb`.
- `db`, `app` e `cli` usam Autofs para montar o compartilhamento sob demanda em `/var/nfs/dados`.
- `app` publica uma página HTML com a identificação do projeto. `db` instala MariaDB; a atividade não solicita criar banco, tabelas ou usuários SQL.
- Todas as VMs recebem configurações comuns: update/upgrade, Chrony, fuso `America/Recife`, usuários `wagner` e `wilson`, grupo `ifpb`, autenticação SSH por chave e sudo para o grupo.

## Critérios de avaliação e evidências

| Critério | Como o projeto atende | Evidência para apresentar |
|---|---|---|
| Vagrant: configuração das VMs | `Vagrantfile` define Debian 12, VirtualBox, linked clones, 512 MB (1 GB para `cli`), guest additions desativado e três discos extras em `arq`. | Mostrar `Vagrantfile`, executar `vagrant status` e confirmar as quatro VMs. |
| Vagrant: gatilho do DHCP | O `Vagrantfile` tenta parar o DHCP do VirtualBox para deixar o DHCP de `arq` atender a rede privada. | Mostrar o bloco `config.trigger` e confirmar que os clientes recebem endereço do escopo do projeto. O gatilho usa a interface `vboxnet0`; confirme que esse nome corresponde à rede do computador da apresentação. |
| Vagrant: provisionamento automático | Cada VM tem provisionadores Ansible comuns e específicos. | Executar `vagrant up` até terminar sem falhas e mostrar `vagrant status`. A definição dos provisionadores existe; a execução bem-sucedida precisa ser demonstrada. |
| Ansible: organização | Os playbooks estão separados por configuração comum, DHCP, servidor de arquivos, banco, aplicação e cliente. `requirements.yml` declara as collections. | Mostrar `playbooks/`, `Vagrantfile` e executar `ansible-inventory --graph`. |
| Ansible: escopo funcional | Os playbooks configuram DHCP, DNS, LVM, NFS, MariaDB, Apache, Autofs, Chrony, SSH e sudo. | Executar os comandos da seção [Testes](#testes-da-infraestrutura) e mostrar os resultados nos respectivos servidores. |
| Ansible: execução sem erros | O playbook DHCP valida `/etc/dhcp/dhcpd.conf` instalado antes de reiniciar o serviço. As tarefas APT também repetem tentativas para tolerar falhas temporárias de rede. | Reexecutar `vagrant provision` e confirmar que as VMs e os serviços terminam sem falhas. Não considerar o critério comprovado até essa execução concluir. |
| Acesso por nomes | O DNS tem registros para `arq`, `db` e `app`; clientes recebem o IP do DNS pelo DHCP. | Testar `getent hosts` nas VMs. No computador hospedeiro, consultar o DNS diretamente ou configurar a resolução do adaptador privado; o Vagrant não altera automaticamente o DNS do hospedeiro. |
| Documentação e entregáveis | Este README identifica a equipe, disciplina e professor e descreve execução e validação. O repositório contém Vagrantfile, inventário, configuração e playbooks. | Mostrar o README e os arquivos listados na seção [Arquivos do projeto](#arquivos-do-projeto). |

## Arquivos do projeto

- `Vagrantfile`: definição das VMs, rede, discos e provisionadores.
- `ansible.cfg` e `hosts.ini`: configuração e inventário para Ansible manual.
- `requirements.yml`: collections Ansible necessárias.
- `playbooks/conf-geral.yml`: configurações comuns, usuários, SSH, chaves, Chrony e sudo.
- `playbooks/conf-dhcp.yml`: DHCP e reservas dos servidores `db` e `app`.
- `playbooks/arq.yml`: LVM, NFS e DNS.
- `playbooks/db.yml`, `playbooks/app.yml`, `playbooks/cli.yml`: serviços específicos de cada VM.
- `.gitignore`: exclui chaves privadas e arquivos locais do Vagrant.

## Pré-requisitos

- VirtualBox e Vagrant instalados.
- Ansible disponível no ambiente que executará o provisionamento.
- Conexão à internet para baixar a imagem Debian e instalar pacotes.
- Espaço em disco para as quatro VMs e os três discos extras de `arq`.

Instale as collections antes de provisionar:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Como executar

Na pasta do projeto, crie e provisione as máquinas:

```bash
vagrant up
```

Confira o estado e acesse uma VM:

```bash
vagrant status
vagrant ssh arq
```

Para repetir o provisionamento após uma falha ou alteração:

```bash
vagrant provision
```

As tarefas APT tentam novamente até quatro vezes, com intervalo de 15 segundos entre tentativas. Se a conexão cair por pouco tempo durante o update ou a instalação, o playbook tenta se recuperar. Se a rede continuar indisponível, restabeleça a conexão e execute `vagrant provision`; não é necessário entrar nas VMs para rodar `apt update` manualmente.

Também é possível administrar as VMs com:

```bash
vagrant halt       # desliga
vagrant up         # inicia ou cria
vagrant reload     # reinicia
vagrant destroy    # remove VMs e discos
```

`vagrant destroy` apaga as VMs e seus discos. Use-o somente se quiser remover o laboratório.

## Usar Ansible manualmente

O `hosts.ini` contém `arq`, `db` e `app`, cujos IPs são fixos. Verifique o inventário e a conexão:

```bash
ansible-inventory --graph
ansible servidores -m ping
```

Como os playbooks usam `hosts: all`, limite a execução ao grupo desejado:

```bash
ansible-playbook -i hosts.ini playbooks/conf-geral.yml --limit arq
ansible-playbook -i hosts.ini playbooks/arq.yml --limit arq
ansible-playbook -i hosts.ini playbooks/db.yml --limit db
ansible-playbook -i hosts.ini playbooks/app.yml --limit app
```

O IP de `cli` é dinâmico e não está no inventário manual. Para executar `cli.yml` manualmente, adicione o endereço DHCP atual ao `hosts.ini` e use `--limit cli`. No provisionamento normal, o Vagrant gera o inventário temporário.

## Testes da infraestrutura

Faça os testes após `vagrant up` concluir. Se o provisionamento DHCP falhar, corrija a causa e execute `vagrant provision arq` antes de testar os clientes.

### 1. Estado das VMs e endereços

No hospedeiro:

```bash
vagrant status
```

Dentro de `db` e `app`, confirme os IPs reservados:

```bash
vagrant ssh db -c "ip -4 -br address"
vagrant ssh app -c "ip -4 -br address"
```

Esperado: `db` em `192.168.56.121` e `app` em `192.168.56.141`. Em `cli`, confirme que o IP está entre `192.168.56.50` e `192.168.56.100`.

### 2. DHCP e serviços em `arq`

```bash
vagrant ssh arq -c "sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf"
vagrant ssh arq -c "systemctl is-active isc-dhcp-server bind9 nfs-kernel-server"
```

O primeiro comando deve indicar que a configuração DHCP é válida; o segundo deve retornar `active` para os serviços.

### 3. DNS a partir das máquinas virtuais

Em `cli`, `db` ou `app`, consulte os três nomes:

```bash
vagrant ssh cli -c "getent hosts arq.wagner.wilson.devops db.wagner.wilson.devops app.wagner.wilson.devops"
```

Esperado: `.104` para `arq`, `.121` para `db` e `.141` para `app`.

### 4. DNS a partir do hospedeiro

Consulte diretamente o DNS do laboratório:

```bash
dig @192.168.56.104 app.wagner.wilson.devops
```

Esse teste consulta o servidor Bind9. Para que programas do hospedeiro resolvam o nome sem `@192.168.56.104`, o DNS do adaptador de rede privada do hospedeiro precisa apontar para `192.168.56.104`; isso não é configurado automaticamente pelos playbooks.

### 5. Apache

Na VM `cli`, faça uma requisição pelo nome DNS. O retorno esperado é o código HTTP `200`:

```bash
vagrant ssh cli -c "python3 -c 'from urllib.request import urlopen; print(urlopen(\"http://app.wagner.wilson.devops/\").status)'"
```

No hospedeiro, teste pelo IP e, se o DNS do adaptador privado estiver configurado, também pelo nome:

```bash
curl -f http://192.168.56.141/
curl -f http://app.wagner.wilson.devops/
```

O conteúdo retornado deve identificar o projeto, a disciplina, o professor e os integrantes.

### 6. MariaDB

```bash
vagrant ssh db -c "systemctl is-active mariadb"
vagrant ssh db -c "sudo mariadb-admin ping"
```

O servidor deve responder que está ativo. O escopo do trabalho instala MariaDB, sem exigir schema ou dados.

### 7. NFS e Autofs

Na VM cliente, acessar o caminho aciona a montagem automática. Teste leitura e escrita:

```bash
vagrant ssh cli -c "ls -la /var/nfs/dados"
vagrant ssh cli -c "touch /var/nfs/dados/teste-cli.txt"
```

No servidor `arq`, confirme que o arquivo foi criado e pertence à identidade de serviço NFS:

```bash
vagrant ssh arq -c "stat -c '%U:%G %a %n' /dados/nfs/teste-cli.txt"
```

### 8. LVM e montagem persistente

No servidor `arq`:

```bash
vagrant ssh arq -c "sudo pvs; sudo vgs; sudo lvs; findmnt /dados"
```

Esperado: VG `dados`, LV `ifpb` com 15 GB, sistema EXT4 montado em `/dados`.

## Pontos importantes para a avaliação

- **Gatilho VirtualBox:** o `Vagrantfile` tenta parar o DHCP do VirtualBox na rede `vboxnet0`. O comando inclui `|| true`, portanto uma falha ao parar o serviço não interrompe o Vagrant; confirmem a rede e o DHCP do hospedeiro antes da apresentação.
- **Provisionamento:** a configuração automática está declarada, mas só uma execução completa de `vagrant up`/`vagrant provision` sem falhas comprova esse critério.
- **Acesso por hostname:** os clientes recebem o DNS interno por DHCP. No hospedeiro é preciso apontar o adaptador privado para o DNS `192.168.56.104` ou consultar explicitamente com `dig @192.168.56.104`.
- **SSH entre VMs:** as chaves privadas dos usuários ficam no hospedeiro; as VMs recebem somente as chaves públicas. Assim, o SSH por nome a partir do hospedeiro pode usar `keys/wagner_id_ed25519` ou `keys/wilson_id_ed25519`, mas o SSH autenticado entre VMs requer disponibilizar uma chave privada ou usar encaminhamento de agente. A resolução DNS por si só não comprova autenticação SSH.
- **LVM:** o playbook espera `/dev/sdb`, `/dev/sdc` e `/dev/sdd`, discos extras criados para `arq`. Use-os apenas no laboratório.
- **Chaves:** os arquivos privados em `keys/` são credenciais e estão excluídos do Git. Nunca os publique.

