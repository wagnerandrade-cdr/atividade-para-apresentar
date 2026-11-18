#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "$0")"

if [[ ${1:-} == --com-ansible ]]; then
    ansible-galaxy collection install -r requirements.yml
fi

umask 077
mkdir -p keys
chmod 700 keys

exec 9>keys/.lock
flock 9

for usuario in wagner wilson; do
    privada="keys/$usuario"
    publica="$privada.pub"

    if [[ ! -f "$privada" ]]; then
        if [[ -e "$publica" ]]; then
            printf 'Existe %s, mas falta sua chave privada %s.\n' "$publica" "$privada" >&2
            exit 1
        fi
        ssh-keygen -q -t ed25519 -N '' -C "$usuario@ifpb-devops" -f "$privada"
    fi

    chmod 600 "$privada"
    chave=$(ssh-keygen -y -P '' -f "$privada")
    if [[ -f "$publica" ]]; then
        if [[ $(awk 'NR == 1 { print $1, $2 }' "$publica") != $(awk '{ print $1, $2 }' <<< "$chave") ]]; then
            printf 'A chave pública %s não corresponde a %s.\n' "$publica" "$privada" >&2
            exit 1
        fi
    else
        printf '%s\n' "$chave" > "$publica"
    fi
    chmod 644 "$publica"
done
