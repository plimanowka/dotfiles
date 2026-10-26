#!/usr/bin/env bash
# Linux: rozpakowuje archiwum z na-usb.sh do $HOME i przestawia ścieżki z Maca (/Users/pawellimanowka) na Linuksa.
#   bash z-usb.sh /media/$USER/USB/mac-RRRRMMDD-HHMM.tar.age
# Wymaga: age (sudo apt install age). Uruchom PRZED pierwszym `claude` (żeby nie powstały puste katalogi projektów).
set -euo pipefail
arch=${1:?Podaj plik .tar.age}
STARY=/Users/pawellimanowka
cd "$HOME"
# Rozpakowanie do poczekalni: sekrety repozytoriów (.env.local itp.) czekają tam, aż odtworz-repo.sh sklonuje repo
# (git clone nie wejdzie do niepustego katalogu). Reszta od razu trafia na miejsce.
POCZ="$HOME/.migracja-usb"; mkdir -p "$POCZ"
age -d "$arch" | tar -xf - -C "$POCZ"
for p in .claude .ssh .gitconfig .config .aws dev/tasks dev/tmp dev/wachata-media dev/presentations \
         dev/plimanowka/experiments dev/plimanowka/vms; do
  [ -e "$POCZ/$p" ] || continue
  mkdir -p "$(dirname "$p")"; cp -a "$POCZ/$p" "$(dirname "$p")/" && rm -rf "${POCZ:?}/$p"
done

# Klucz age: na Macu w ~/Library/Application Support, na Linuksie w ~/.config/sops/age
if [ -f "$POCZ/Library/Application Support/sops/age/keys.txt" ]; then
  mkdir -p .config/sops/age && mv -n "$POCZ/Library/Application Support/sops/age/keys.txt" .config/sops/age/keys.txt
fi

# 1) Katalogi projektów Claude mają w nazwie ścieżkę z kreskami zamiast „/”: -Users-pawellimanowka-… → -home-<user>-…
nowy=$(printf '%s' "$HOME" | sed 's#[^A-Za-z0-9]#-#g')
for d in .claude/projects/-Users-pawellimanowka-*; do
  [ -e "$d" ] || continue
  cel=".claude/projects/${nowy}${d#.claude/projects/-Users-pawellimanowka}"
  if [ -e "$cel" ]; then cp -rn "$d"/. "$cel"/ && rm -rf "$d"; else mv "$d" "$cel"; fi
done

# 2) Ścieżki zapisane w ustawieniach i zadaniach cyklicznych
grep -rl "$STARY" .claude/settings.json .claude/settings.local.json .claude/scheduled-tasks .claude/statusline-command.sh 2>/dev/null \
  | xargs -r sed -i "s#$STARY#$HOME#g"

# 3) Uprawnienia sekretów
chmod 700 .ssh && chmod 600 .ssh/* 2>/dev/null; chmod 644 .ssh/*.pub .ssh/known_hosts 2>/dev/null || true
chmod 600 .config/sops/age/keys.txt 2>/dev/null || true
echo "Gotowe. Dalej: odtworz-repo.sh, potem logowanie w Claude Desktop (/login w CLI)."
