#!/usr/bin/env bash
# Linux: klonuje repozytoria z GitHuba i odtwarza katalogi sesji zamelduj (worktree) jak na Macu.
# Wymaga działającego ssh do GitHuba z aliasem github.com-plimanowka (klucze i ~/.ssh/config z USB).
#   bash odtworz-repo.sh
set -euo pipefail
mkdir -p "$HOME/dev/plimanowka" && cd "$HOME/dev/plimanowka"
GH=git@github.com-plimanowka:plimanowka

for r in zamelduj plimanowka-home dotfiles eagle-ai claude-homeassistant wilkowisko-hub wilkowisko-siec; do
  [ -d "$r" ] || git clone "$GH/$r.git" "$r"
done

# Katalogi stałych sesji zamelduj: katalog → gałąź (docs/sesje-rownolegle.md, tabela „Kto gdzie”)
cd zamelduj
while read -r dir br; do
  [ -d "../$dir" ] && continue
  git fetch -q origin "$br" 2>/dev/null && git worktree add "../$dir" "$br" || git worktree add -b "$br" "../$dir" origin/main
done <<'EOF'
zamelduj-ads ads
zamelduj-landing blog
zamelduj-inv inv
zamelduj-klienci klienci
zamelduj-agenci agenci-maska-notatek
zamelduj-pawel pawel
EOF
git worktree list

# Sekrety lokalne z poczekalni z-usb.sh (.env.local, terraform.tfvars, secrets.yaml) — na swoje miejsca, bez nadpisywania
POCZ="$HOME/.migracja-usb/dev/plimanowka"
if [ -d "$POCZ" ]; then
  cp -rn "$POCZ"/. "$HOME/dev/plimanowka/" && find "$POCZ" -type f | sed "s#$POCZ#  ~/dev/plimanowka#"
  echo "Sekrety skopiowane. Poczekalnię ~/.migracja-usb skasuj ręcznie, gdy wszystko działa."
fi
