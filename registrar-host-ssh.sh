#!/usr/bin/env bash
set -euo pipefail

host=$1
chave=$2
tipo_ed25519='^ssh-ed25519 [A-Za-z0-9+/=]+$'
if [[ ! $host =~ ^(arq|app|db|cli)\.[a-z0-9.-]+\.devops$ || ! $chave =~ $tipo_ed25519 ]]; then
    printf 'Nome ou chave SSH inválida para o laboratório.\n' >&2
    exit 1
fi
printf '%s\n' "$chave" | ssh-keygen -lf - >/dev/null

umask 077
mkdir -p "$HOME/.ssh"
known_hosts="$HOME/.ssh/known_hosts"
exec 9>"$HOME/.ssh/.vagrant-devops-known-hosts.lock"
flock 9

if [[ -L $known_hosts ]]; then
    printf 'O arquivo %s é um link simbólico. Confira o registro de %s manualmente.\n' "$known_hosts" "$host" >&2
    exit 1
fi

temporario=$(mktemp "$HOME/.ssh/.vagrant-devops-known-hosts.XXXXXX")
trap 'rm -f -- "$temporario" "$temporario.old"' EXIT
if [[ -f $known_hosts ]]; then
    cat -- "$known_hosts" > "$temporario"
fi

if registros=$(ssh-keygen -F "$host" -f "$temporario"); then
    if ! awk -v host="$host" '!/^#/ && tolower($1) != host && $1 !~ /^\|1\|/ {exit 1}' <<< "$registros"; then
        printf 'O registro de %s está em uma regra compartilhada ou especial. Confira manualmente.\n' "$host" >&2
        exit 1
    fi
    if [[ $(awk '!/^#/ { print $2, $3 }' <<< "$registros") == "$chave" ]]; then
        exit 0
    fi
    ssh-keygen -R "$host" -f "$temporario" >/dev/null
fi

if [[ -s $temporario && $(tail -c 1 "$temporario" | wc -l) -eq 0 ]]; then
    printf '\n' >> "$temporario"
fi
printf '%s %s\n' "$host" "$chave" >> "$temporario"
mv -- "$temporario" "$known_hosts"
printf 'Identidade SSH registrada para %s\n' "$host"
