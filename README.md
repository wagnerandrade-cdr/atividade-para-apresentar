# Projeto 01 — DevOps com Vagrant e Ansible (versão revisada)

Instituição: IFPB — Administração de Sistemas Abertos — Professor Leonidas Francisco de Lima Junior.

Equipe: Wagner Marinho de Andrade Filho (20242380004) e Wilson Fillipe do Nascimento Lima (20251380021).

## Estrutura e endereçamento

- `arq.wagner.wilson.devops`: 192.168.56.104 (IP estático, DHCP, Bind9, LVM, NFS)
- `db.wagner.wilson.devops`: 192.168.56.121 (reserva DHCP por MAC, MariaDB, Autofs)
- `app.wagner.wilson.devops`: 192.168.56.141 (reserva DHCP por MAC, Apache, Autofs)
- `cli.wagner.wilson.devops`: DHCP dinâmico de 192.168.56.50–100 (Firefox ESR, X11, Autofs)

O notebook Linux é o **hospedeiro/controlador**: ele cria as chaves privadas. As VMs recebem somente as chaves públicas em `/home/wagner/.ssh/authorized_keys` e `/home/wilson/.ssh/authorized_keys`.

## Preparação no notebook Linux

Instale VirtualBox, Vagrant, Ansible, OpenSSH, Python3 e plugins/collections compatíveis com sua distribuição. Na pasta do projeto:

```bash
ansible-galaxy collection install -r requirements.yml
./preparar-chaves.sh
vagrant validate
vagrant up arq
vagrant up db app cli
vagrant status
```

**Importante:** se o VirtualBox estiver servindo DHCP na rede host-only `vboxnet0`, desative-o para evitar dois servidores concorrentes. O Vagrantfile contém um gatilho que tenta pará-lo, mas usa `|| true`: ele não prova que o serviço foi desligado. Confirme com `VBoxManage list dhcpservers`. O nome da interface pode variar no notebook. A interface privada da VM `arq` foi definida como `eth1`; confira com `vagrant ssh arq -c 'ip -br a'`.

O `vagrant up arq` primeiro cria o servidor DHCP e, em seguida, os demais serviços. As outras VMs recebem IP pela rede host-only. Depois da primeira criação, para reaplicar alterações use `vagrant provision arq`, etc. **Não execute `vagrant destroy` nem reaproveite os três discos de LVM se contiverem dados importantes.**

## Autenticação SSH e script do professor

As chaves são geradas uma vez no notebook real em `keys/wagner` e `keys/wilson` (privadas) e `keys/wagner.pub` e `keys/wilson.pub` (públicas). Nunca publique as privadas no Git. A configuração comum distribui **somente as públicas** e bloqueia senha/root; sudo é NOPASSWD para `ifpb` a fim de permitir testes automatizados.

Do notebook Linux:

```bash
ssh -i keys/wagner wagner@192.168.56.104
ssh -i keys/wilson wilson@192.168.56.141
```

O script `verificar.py` deve ficar na **raiz deste projeto**, ao lado da pasta `keys/`. Use o arquivo enviado pelo professor, sem necessidade de editar. Ele exige DNS por hostname `arq/app/db/cli.wagner.wilson.devops` no notebook. O Bind9 fornece registros para arq, db e app; **não existe IP fixo para cli**, portanto obtenha seu IP com `vagrant ssh cli -c 'ip -4 -br address'` e configure a resolução no notebook (por DNS interno complementado por uma entrada de `/etc/hosts` para cli, ou outras configurações equivalentes). Para uma resolução imediata temporária, entradas no `/etc/hosts` do notebook para todos os quatro hosts também funcionam. Configure sem sobrescrever entradas existentes nem assumir que o IP DHCP de cli será permanente.

Com o ambiente gráfico X11 ativo no notebook (não usar uma sessão headless), dentro da raiz do projeto:

```bash
python3 verificar.py wagner.wilson |& tee resultado-verificacao.txt
```

O verificador do professor cria **temporariamente** o usuário `intruso` e tenta removê-lo; ele também cria arquivos em `/var/nfs`. Inspecione erros antes de repetir. Seu teste de bloqueio de senhas pode produzir falsos positivos se um agente SSH ou outra chave padrão estiver disponível. Teste explícito: `ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password wagner@192.168.56.104` deve ser recusado.

O script usa chaves `keys/wagner` e `keys/wilson`, grava diretamente em `/var/nfs/usuario.txt` (por isso Autofs usa montagem direta) e tenta abrir Firefox por SSH com `-X`; este último requer um servidor X funcional no notebook. A montagem Autofs `/-` mapeia **/var/nfs** para o NFS do arq.

## Verificações complementares (o script não cobre tudo)

```bash
vagrant status
vagrant ssh arq -c 'sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf'
vagrant ssh arq -c 'sudo named-checkconf -z'
vagrant ssh arq -c 'sudo pvs; sudo vgs; sudo lvs; findmnt /dados'
vagrant ssh arq -c 'sudo exportfs -v'
vagrant ssh db -c 'systemctl is-active mariadb'
vagrant ssh app -c 'systemctl is-active apache2'
vagrant ssh cli -c 'ls -la /var/nfs'
vagrant ssh cli -c 'getent hosts app.wagner.wilson.devops'
vagrant ssh db -c 'ip -4 -br addr'
vagrant ssh app -c 'ip -4 -br addr'
```

Para verificar NFS: no notebook execute `vagrant ssh app -c 'sudo -u wilson sh -c "echo teste > /var/nfs/wilson.txt"'`; no `arq`, confirme `stat -c '%U:%G %n' /dados/nfs/wilson.txt` => `nfs-ifpb:nfs-ifpb`. Testar que um usuário sem autenticação no NFS não consegue escrever **não equivale** a testar a identidade local: `all_squash` faz o mapeamento de todos os usuários remotos autorizados para `nfs-ifpb`, como solicitado.

## Arquivos e avaliação

`Vagrantfile`, `ansible.cfg`, `hosts.ini`, `requirements.yml`, `preparar-chaves.sh`, `playbooks/{conf-geral,conf-dhcp,arq,db,app,cli}.yml`. O trabalho cobre quatro VMs Debian Bookworm com linked clones, servidor arq com três discos adicionais de 10GB, VG dados, LV ifpb 15GB/ext4 em /dados, DHCP, Bind9, NFS, MariaDB, Apache, X11 e Autofs. A confirmação final exige executar os serviços no notebook Linux real; revisão estática não comprova o comportamento do VirtualBox, DHCP, encaminhamento X11 e montagem NFS.

## Mudanças principais em relação à versão recebida

IP do app corrigido para `.141` em todos os componentes; registro PTR do db corrigido para `.121`; hosts.ini corrigido; chaves privadas nunca geradas nas VMs nem copiadas das VMs para o hospedeiro; módulos de LVM idempotentes sem `wipefs`; NFS com `all_squash`, `anonuid/anongid` e sem `no_root_squash`; Autofs montando diretamente em `/var/nfs`; página HTML com matrículas completas; sudo sem senha para o verificador.
