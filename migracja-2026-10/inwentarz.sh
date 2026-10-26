#!/usr/bin/env bash
# Spis przed przeprowadzką: co w ~/dev nie jest jeszcze na GitHubie. Tylko odczyt, niczego nie zmienia.
#   bash inwentarz.sh            raport na ekran
#   bash inwentarz.sh > raport.txt
set -uo pipefail
ROOTS=("$HOME/dev/plimanowka" "$HOME/dev/loopme")

repo_report() {
  local d=$1
  local remote dirty
  remote=$(git -C "$d" remote get-url origin 2>/dev/null || echo BRAK)
  dirty=$(git -C "$d" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  echo "== $d  (origin: $remote)"
  [ "$dirty" != 0 ] && { echo "   niezacommitowane pliki: $dirty"; git -C "$d" status --short | sed 's/^/     /' | head -15; }
  # gałęzie bez odpowiednika na serwerze albo z commitami przed nim (pomija gałęzie scalone do origin/main|master)
  git -C "$d" for-each-ref --format='%(refname:short)|%(upstream:short)|%(upstream:track)' refs/heads | while IFS='|' read -r b up track; do
    base=$(git -C "$d" rev-parse -q --verify origin/main >/dev/null && echo origin/main || echo origin/master)
    git -C "$d" merge-base --is-ancestor "$b" "$base" 2>/dev/null && continue
    if [ -z "$up" ] || [[ "$track" == *gone* ]]; then echo "   tylko lokalnie: $b ($(git -C "$d" log -1 --format='%cr: %s' "$b"))"
    elif [[ "$track" == *ahead* ]]; then echo "   niewypchnięte: $b $track"; fi
  done
}

for root in "${ROOTS[@]}"; do
  [ -d "$root" ] || continue
  for d in "$root"/*/; do
    d=${d%/}
    if git -C "$d" rev-parse --git-dir >/dev/null 2>&1; then
      # worktree dzieli gałęzie z repo głównym — raport tylko dla repo głównego plus brudne pliki worktree
      if [ -f "$d/.git" ]; then
        n=$(git -C "$d" status --porcelain | wc -l | tr -d ' ')
        [ "$n" != 0 ] && echo "== $d (worktree) niezacommitowane: $n"
      else
        repo_report "$d"
      fi
    else
      echo "== $d  BEZ GITA: $(du -sh "$d" 2>/dev/null | cut -f1) — kopiować ręcznie (na-usb.sh)"
    fi
  done
done

echo
echo "== Pliki poza gitem, potrzebne do pracy (sekrety lokalne):"
find "$HOME/dev/plimanowka" -maxdepth 5 -not -path '*/node_modules/*' -not -path '*/.claude/worktrees/*' \
  \( -name '.env.local' -o -name '.env' -o -name '*.tfvars' -o -name 'secrets.yaml' \) -type f 2>/dev/null | sed 's/^/   /'
