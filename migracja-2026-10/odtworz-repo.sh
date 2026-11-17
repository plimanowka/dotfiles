#!/usr/bin/env bash
# Linux: klonuje repozytoria z GitHuba i odtwarza katalogi sesji zamelduj (worktree) jak na Macu.
# Wymaga działającego ssh do GitHuba z aliasem github.com-plimanowka (klucze i ~/.ssh/config z USB).
#   bash odtworz-repo.sh
set -euo pipefail
mkdir -p "$HOME/dev/plimanowka" && cd "$HOME/dev/plimanowka"
GH=git@github.com-plimanowka:plimanowka

for r in zamelduj plimanowka-home dotfiles eagle-ai claude-homeassistant wilkowisko-hub wilkowisko-siec pinandfix; do
  [ -d "$r" ] || git clone "$GH/$r.git" "$r"
done

# Katalogi obszarów zamelduj (zamelduj-ads, -klienci, -pawel…) NIE są zakładane tutaj — zakłada je skill `obszar`
# przy pierwszej sesji danego obszaru (docs/obszary.md, od 17.11), razem z dowiązaniem pamięci i sekretów.

# Sekrety lokalne z poczekalni z-usb.sh (.env.local, terraform.tfvars, secrets.yaml) — na swoje miejsca, bez nadpisywania
POCZ="$HOME/.migracja-usb/dev/plimanowka"
if [ -d "$POCZ" ]; then
  # tylko do sklonowanych repozytoriów; sekrety starych worktree (zamelduj-p119-* itp.) to kopie z głównego checkoutu
  for d in "$POCZ"/*/; do r=$(basename "$d"); [ -d "$HOME/dev/plimanowka/$r/.git" ] || continue
    cp -rn "$d". "$HOME/dev/plimanowka/$r/" && find "$d" -type f | sed "s#$POCZ#  ~/dev/plimanowka#"; done
  echo "Sekrety skopiowane. Poczekalnię ~/.migracja-usb skasuj ręcznie, gdy wszystko działa."
fi
