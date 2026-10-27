#!/usr/bin/env bash
set -euo pipefail

# Gera listas minúsculas, fictícias e destinadas somente ao laboratório local.
# Não adicione credenciais reais, vazadas ou de terceiros.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cat > "$ROOT_DIR/wordlists/usuarios-lab.txt" <<'LIST'
labuser
labtest
LIST
cat > "$ROOT_DIR/wordlists/senhas-lab.txt" <<'LIST'
SenhaIncorreta!2026
TreinoLab!2026
LIST
printf 'Listas sintéticas atualizadas em %s/wordlists\n' "$ROOT_DIR"
