#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p keys
chmod 700 keys
for usuario in wagner wilson; do
  if [[ -e "keys/$usuario" && ! -f "keys/$usuario.pub" ]]; then
    ssh-keygen -y -f "keys/$usuario" > "keys/$usuario.pub"
  elif [[ ! -f "keys/$usuario" && -e "keys/$usuario.pub" ]]; then
    echo "ERRO: existe chave publica de $usuario sem a privada correspondente" >&2
    exit 1
  elif [[ ! -f "keys/$usuario" ]]; then
    ssh-keygen -t ed25519 -N '' -f "keys/$usuario" -C "$usuario@ifpb-devops"
  fi
  chmod 600 "keys/$usuario"
  chmod 644 "keys/$usuario.pub"
done
echo 'Chaves criadas no notebook Linux. As privadas ficam SOMENTE em keys/ no pc local.'
