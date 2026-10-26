#!/usr/bin/env bash
# Pakuje na USB to, czego nie ma na GitHubie: sekrety, konfigurację Claude i katalogi bez gita.
# Archiwum jest SZYFROWANE hasłem (age -p) — na USB leży tylko *.tar.age. Rozpakowanie na Linuksie: z-usb.sh.
#   bash na-usb.sh --rozmiar              policz, ile zajmie (nic nie pakuje)
#   bash na-usb.sh /Volumes/USB           spakuj i zaszyfruj na USB (zapyta o hasło dwa razy)
# Wymaga: age (brew install age), tar. Lista niżej — dopisz/usuń, zanim uruchomisz.
set -euo pipefail
cd "$HOME"

# Co pakujemy (ścieżki względem $HOME). Duże i wrażliwe katalogi osobno, żeby dało się je pominąć.
LISTA=(
  # konfiguracja Claude Code: instrukcje, reguły, skille, pamięć i transkrypty sesji, zadania cykliczne, wtyczki
  .claude/CLAUDE.md .claude/rules .claude/skills .claude/commands .claude/settings.json .claude/settings.local.json
  .claude/statusline-command.sh .claude/scheduled-tasks .claude/plugins .claude/projects
  # sekrety i dostępy
  # klucz age (na Macu w Library!) odszyfrowuje sejf dotfiles/secrets i secrets/ zamelduj — JEDYNA kopia
  "Library/Application Support/sops/age"
  .ssh .gitconfig .config/rclone .config/zamelduj .config/plimanowka-ads .aws .config/gh
  # notatki i robocze
  dev/tasks dev/tmp dev/wachata-media dev/presentations
  # katalogi bez gita w ~/dev/plimanowka
  # personal/ NIE: jest aktualny na Drive (rclone copy, sesja personal 26.10) → na Linuksie rclone copy z Drive
  dev/plimanowka/experiments dev/plimanowka/vms
)
# sekrety lokalne z repozytoriów (nie idą do gita)
while IFS= read -r f; do LISTA+=("${f#"$HOME"/}"); done < <(
  find "$HOME/dev/plimanowka" -maxdepth 5 -not -path '*/node_modules/*' -not -path '*/.claude/worktrees/*' \
    \( -name '.env.local' -o -name '.env' -o -name '*.tfvars' -o -name 'secrets.yaml' \) -type f 2>/dev/null)

# Pominięte świadomie (Paweł 26.10): dev/loopme — repozytoria firmowe zostają na Macu.

istnieje=(); for p in "${LISTA[@]}"; do [ -e "$p" ] && istnieje+=("$p"); done

if [ "${1:-}" = "--rozmiar" ]; then
  du -shc "${istnieje[@]}" 2>/dev/null | sort -h | tail -15; exit 0
fi
cel=${1:?Podaj katalog docelowy, np. /Volumes/USB}
command -v age >/dev/null || { echo "brak age: brew install age" >&2; exit 1; }
plik="$cel/mac-$(date +%Y%m%d-%H%M).tar.age"
echo "Pakuję ${#istnieje[@]} pozycji do $plik — podaj hasło (zapisz je w 1Password):"
tar -cf - --exclude='.DS_Store' --exclude='__pycache__' "${istnieje[@]}" | age -p -o "$plik"
ls -lh "$plik"
echo "Sprawdzenie: age -d \"$plik\" | tar -tf - | head"
