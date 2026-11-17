#!/usr/bin/env bash
# Linux: rozpakowuje archiwum z na-usb.sh do $HOME i przestawia ścieżki z Maca (/Users/pawellimanowka) na Linuksa.
#   bash z-usb.sh /mnt/data/przeprowadzka-2026-11/mac-RRRRMMDD-HHMM.tar   (stare archiwa *.tar.age też)
# Wymaga: tar (age tylko dla *.tar.age). Uruchom PRZED pierwszym `claude` (żeby nie powstały puste katalogi projektów).
set -euo pipefail
arch=${1:?Podaj katalog z na-usb.sh --rsync albo plik .tar / .tar.age}
STARY=/Users/pawellimanowka
cd "$HOME"
# Rozpakowanie do poczekalni: sekrety repozytoriów (.env.local itp.) czekają tam, aż odtworz-repo.sh sklonuje repo
# (git clone nie wejdzie do niepustego katalogu). Reszta od razu trafia na miejsce.
POCZ="$HOME/.migracja-usb"; mkdir -p "$POCZ"
if [ -d "$arch" ]; then rsync -a "$arch"/ "$POCZ"/   # katalog z na-usb.sh --rsync
elif [[ $arch == *.age ]]; then age -d "$arch" | tar -xf - -C "$POCZ"; else tar -xf "$arch" -C "$POCZ"; fi
for p in .claude .claude-zamelduj .claude-plimanowka .ssh .gitconfig .config .aws dev/tasks dev/tmp dev/wachata-media dev/presentations \
         dev/plimanowka/experiments dev/plimanowka/vms; do
  [ -e "$POCZ/$p" ] || continue
  mkdir -p "$(dirname "$p")"; cp -a "$POCZ/$p" "$(dirname "$p")/" && rm -rf "${POCZ:?}/$p"
done

# Luźne pliki z ~/dev/plimanowka (poza repozytoriami) — od razu na miejsce; podkatalogi repo czekają na odtworz-repo.sh.
mkdir -p dev/plimanowka
find "$POCZ/dev/plimanowka" -maxdepth 1 -type f -exec mv -n {} dev/plimanowka/ \; 2>/dev/null || true

# Klucz age: na Macu w ~/Library/Application Support, na Linuksie w ~/.config/sops/age
if [ -f "$POCZ/Library/Application Support/sops/age/keys.txt" ]; then
  mkdir -p .config/sops/age && mv -n "$POCZ/Library/Application Support/sops/age/keys.txt" .config/sops/age/keys.txt
fi

# 1) Katalogi projektów Claude mają w nazwie ścieżkę z kreskami zamiast „/”: -Users-pawellimanowka-… → -home-<user>-…
nowy=$(printf '%s' "$HOME" | sed 's#[^A-Za-z0-9]#-#g')
for k in .claude .claude-zamelduj .claude-plimanowka; do
  for d in "$k"/projects/-Users-pawellimanowka-*; do
    [ -e "$d" ] || [ -L "$d" ] || continue
    cel="$k/projects/${nowy}${d#"$k"/projects/-Users-pawellimanowka}"
    if [ -e "$cel" ]; then cp -rn "$d"/. "$cel"/ && rm -rf "$d"; else mv "$d" "$cel"; fi
  done
done
# 1b) Dowiązania z bezwzględną ścieżką Maca — w ~/.claude-zamelduj (wspólne reguły, skille, pamięć) i w ~/.claude/projects
#     (pamięć katalogów obszarów → pamięć głównego checkoutu, 17.11) — przestawić cel na nowy $HOME i nowe nazwy.
find .claude-zamelduj .claude-plimanowka .claude/projects -type l 2>/dev/null | while IFS= read -r l; do
  t=$(readlink "$l"); n=$(printf '%s' "$t" | sed "s#-Users-pawellimanowka#$nowy#g; s#$STARY#$HOME#g")
  [ "$t" = "$n" ] || ln -sfn "$n" "$l"
done

# 2) Ścieżki zapisane w ustawieniach i zadaniach cyklicznych
grep -rl "$STARY" .claude/settings.json .claude/settings.local.json .claude/scheduled-tasks .claude/statusline-command.sh .claude-zamelduj/CLAUDE.md 2>/dev/null \
  | xargs -r sed -i "s#$STARY#$HOME#g"

# 3) Uprawnienia sekretów
chmod 700 .ssh && chmod 600 .ssh/* 2>/dev/null; chmod 644 .ssh/*.pub .ssh/known_hosts 2>/dev/null || true
# ~/.ssh/config z Maca ma `UseKeychain yes` — OpenSSH na Linuksie odrzuca nieznaną opcję i ssh nie działa wcale
grep -qi "^IgnoreUnknown" .ssh/config 2>/dev/null || sed -i "1i IgnoreUnknown UseKeychain" .ssh/config
chmod 600 .config/sops/age/keys.txt 2>/dev/null || true
echo "Gotowe. Dalej: odtworz-repo.sh, potem logowanie w Claude Desktop (/login w CLI)."
