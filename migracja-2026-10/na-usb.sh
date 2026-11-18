#!/usr/bin/env bash
# Pakuje na USB to, czego nie ma na GitHubie: sekrety, konfigurację Claude i katalogi bez gita.
# Archiwum BEZ szyfrowania (Paweł 17.11: idzie siecią domową po SSH albo pendrive'em z ręki do ręki) — *.tar.
# Rozpakowanie na Linuksie: z-usb.sh.
#   bash na-usb.sh --rozmiar                          policz, ile zajmie (nic nie pakuje)
#   bash na-usb.sh stacjonarny:/mnt/data/przeprowadzka-2026-11   spakuj prosto na boks (tar przez ssh)
#   bash na-usb.sh /Volumes/USB                       spakuj na pendrive
#   bash na-usb.sh --rsync stacjonarny:/mnt/data/przeprowadzka-2026-11/mac
#                                                     kopia przyrostowa (rsync -R, ścieżki względem $HOME); można puszczać
#                                                     wielokrotnie — pierwszy raz hurtem, w dniu X tylko różnice (17.11)
# Wymaga: tar (i ssh dla wariantu host:katalog). Lista niżej — dopisz/usuń, zanim uruchomisz.
set -euo pipefail
cd "$HOME"

# Co pakujemy (ścieżki względem $HOME). Duże i wrażliwe katalogi osobno, żeby dało się je pominąć.
LISTA=(
  # konfiguracja Claude Code: instrukcje, reguły, skille, pamięć i transkrypty sesji, zadania cykliczne, wtyczki
  .claude/CLAUDE.md .claude/rules .claude/skills .claude/commands .claude/settings.json .claude/settings.local.json
  .claude/statusline-command.sh .claude/scheduled-tasks .claude/plugins .claude/projects
  # konto zamelduj (CLAUDE_CONFIG_DIR=~/.claude-zamelduj, od 27.10): transkrypty sesji zamelduj, skille; reszta to
  # dowiązania do ~/.claude (z-usb.sh przestawia je na Linuksa). ~/.claude-loopme zostaje na Macu jak dev/loopme.
  .claude-zamelduj .claude-plimanowka
  # skrzynka między sesjami: skrypt (hook UserPromptSubmit + serwer MCP) i baza SQLite — LOKALNA dla maszyny (17.11)
  .local/share/claude-skrzynka
  # sekrety i dostępy
  # klucz age (na Macu w Library!) odszyfrowuje sejf dotfiles/secrets i secrets/ zamelduj — JEDYNA kopia
  "Library/Application Support/sops/age"
  .ssh .gitconfig .config/rclone .config/zamelduj .config/plimanowka-ads .config/pinandfix .config/stripe .config/git .aws .config/gh
  # notatki i robocze
  dev/tasks dev/tmp dev/wachata-media dev/presentations
  # katalogi bez gita w ~/dev/plimanowka
  # personal/ NIE: jest aktualny na Drive (rclone copy, sesja personal 26.10) → na Linuksie rclone copy z Drive
  dev/plimanowka/experiments dev/plimanowka/vms
  # eagle-ai: dane dostępowe rejestratora (gitignored; eagle-ai docs/development/workstation-migration.md, 16.11)
  dev/plimanowka/eagle-ai/apps/edge-recorder/.local
)
# luźne pliki w ~/dev/plimanowka poza repozytoriami (SEKRETY-REKOMENDACJA.md, .gitconfig katalogu, karabiner-cfg.md…)
while IFS= read -r f; do LISTA+=("${f#"$HOME"/}"); done < <(find "$HOME/dev/plimanowka" -maxdepth 1 -type f ! -name .DS_Store)
# sekrety lokalne z repozytoriów (nie idą do gita)
while IFS= read -r f; do LISTA+=("${f#"$HOME"/}"); done < <(
  find "$HOME/dev/plimanowka" -maxdepth 5 -not -path '*/node_modules/*' -not -path '*/.claude/worktrees/*' \
    \( -name '.env.local' -o -name '.env' -o -name '*.tfvars' -o -name 'secrets.yaml' \) -type f 2>/dev/null)

# Pominięte świadomie (Paweł 26.10): dev/loopme — repozytoria firmowe zostają na Macu.

istnieje=(); for p in "${LISTA[@]}"; do [ -e "$p" ] && istnieje+=("$p"); done

if [ "${1:-}" = "--rozmiar" ]; then
  du -shc "${istnieje[@]}" 2>/dev/null | sort -h | tail -15; exit 0
fi
if [ "${1:-}" = "--rsync" ]; then
  cel=${2:?Podaj host:katalog}
  ssh "${cel%%:*}" "mkdir -p '${cel#*:}'"
  rsync -aR --delete --exclude='.claude/projects/-Users-pawellimanowka-dev-loopme*' --exclude='.claude-zamelduj/projects/-Users-pawellimanowka-dev-loopme*' \
    --exclude='.claude-plimanowka/projects/-Users-pawellimanowka-dev-loopme*' --exclude='.DS_Store' --exclude='__pycache__' --exclude='.ssh/id_ed25519_loopme*' \
    "${istnieje[@]}" "$cel/"
  echo "Gotowe: $cel (na boksie: bash z-usb.sh ${cel#*:})"; exit 0
fi
cel=${1:?Podaj cel: host:katalog albo katalog (np. /Volumes/USB)}
nazwa="mac-$(date +%Y%m%d-%H%M).tar"
pakuj() { tar -cf - --exclude='.claude/projects/-Users-pawellimanowka-dev-loopme*' --exclude='.claude-zamelduj/projects/-Users-pawellimanowka-dev-loopme*' \
  --exclude='.claude-plimanowka/projects/-Users-pawellimanowka-dev-loopme*' --exclude='.DS_Store' --exclude='__pycache__' --exclude='.ssh/id_ed25519_loopme*' "${istnieje[@]}"; }
if [[ $cel == *:* ]]; then
  host=${cel%%:*} kat=${cel#*:}
  echo "Pakuję ${#istnieje[@]} pozycji na $host:$kat/$nazwa (przez ssh)…"
  ssh "$host" "mkdir -p '$kat'"
  pakuj | ssh "$host" "cat > '$kat/$nazwa.czesc' && mv '$kat/$nazwa.czesc' '$kat/$nazwa' && ls -lh '$kat/$nazwa'"
  echo "Sprawdzenie: ssh $host \"tar -tf '$kat/$nazwa' | head\""
else
  echo "Pakuję ${#istnieje[@]} pozycji do $cel/$nazwa…"
  pakuj > "$cel/$nazwa.czesc" && mv "$cel/$nazwa.czesc" "$cel/$nazwa"
  ls -lh "$cel/$nazwa"
fi
