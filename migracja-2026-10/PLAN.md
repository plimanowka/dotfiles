# Przeprowadzka z Maca na Linuksa (plan, 26.10.2026)

Wszystko poniżej sprawdzone w źródłach podanych przy punktach (strony otwarte 26.10.2026). Skrypty leżą obok,
w `~/dev/tmp/migracja/`.

## 0. Decyzje do podjęcia

| # | Decyzja | Rekomendacja |
|---|---|---|
| 1 | System na nowym komputerze | ✅ Paweł 26.10: **Ubuntu LTS z GNOME** — jedyny wybór z oficjalnym Claude Desktop (beta: Ubuntu 22.04+ / Debian 12+) i dojrzałym zdalnym pulpitem GNOME |
| 2 | Zdalny dostęp z internetu | ✅ Paweł 26.10: **Cloudflare Tunnel + Access** (bez otwierania portów na MikroTiku, ruch po HTTPS 443); zapas **Tailscale** |
| 3 | Subskrypcje | **Zostać na Max 20x + „usage credits” z limitem wydatków** zamiast 2× Max 5x (szczegóły §5) |
| 4 | Co z tego Maca przenieść poza GitHubem | ✅ Paweł 26.10: **wszystko oprócz `~/dev/loopme`** (zostaje na Macu) — także `wachata-media`, `vms` (Win98.utm + archiwa gier), nagrania kamer `dev/tmp/martis-wysoki-recordings` |
| 5 | Aplikacja do sesji na Linuksie | otwarte: Claude Desktop (beta) czy Orca (§7) |

## 1. Na Macu, przed wyjazdem

1. **Wszystkie sesje: commit i push** (jak w piątek — biuro roześle polecenie). Sesje zamelduj mają stan w swoich plikach.
2. **Co nie jest na GitHubie** — `bash inwentarz.sh` (tylko odczyt). Dziś pokazuje:
   - `wilkowisko-siec`: 2 commity niewypchnięte z `main` → `git -C ~/dev/plimanowka/wilkowisko-siec push`;
   - `plimanowka-home`: `sites/wachata.pl/docs/zadania.md` niezacommitowany (sesja wachata.pl);
   - `wilkowisko-hub`: 2 pliki z researchu energii poza gitem (dodać albo przenieść przez USB);
   - `eagle-ai`: 5 lokalnych gałęzi sprzed 4 mies. — na GitHubie już skasowane (pewnie scalone), do przejrzenia;
   - `zamelduj`: 9 starych lokalnych gałęzi ze szkicami bloga/strony — do przejrzenia, najpewniej zbędne.
3. **USB** — `bash na-usb.sh --rozmiar`, potem `bash na-usb.sh /Volumes/<USB>`. Jedno archiwum szyfrowane hasłem
   (`age -p`), ok. 6 GB. **Hasło zapisz w 1Password**, nie na USB. Zawiera: `~/.claude` (instrukcje, reguły, skille,
   pamięć i transkrypty sesji, treść zadań cyklicznych), `~/.ssh`, `~/.gitconfig`, klucz age do `secrets/`, tokeny
   (`~/.config/zamelduj`, `~/.config/plimanowka-ads`, `~/.aws`, `~/.config/gh`), `dev/tasks`, `dev/tmp/biuro`,
   `experiments`, `vms`, `wachata-media`, cały `dev/tmp` i sekrety lokalne repozytoriów (`.env.local`, `.env`, `terraform.tfvars`, `secrets.yaml`).
   **`personal/` nie jedzie na pendrive** — jest aktualny na Drive (`gdrive-plimanowka:personal`, ręczny `rclone copy` po
   każdej zmianie, sprawdzone 26.10: 1753/1753 plików); na Linuksie: `rclone copy gdrive-plimanowka:personal
   ~/dev/plimanowka/personal` (konfiguracja rclone jedzie na pendrive). ⚠ **Klucz age** (`~/Library/Application
   Support/sops/age/keys.txt`) odszyfrowuje sejf `dotfiles/secrets` (w tym kody 2FA OVH) i `secrets/` zamelduj — istnieje
   w jednej kopii na tym Macu; jedzie na pendrive, a niezależnie: wydruk + kopia `age -p` na Drive (`~/dev/tasks/sekrety.md` pkt 1).
   **Nie zawiera danych logowania Claude** (na Macu są w pęku kluczy; na Linuksie logujesz się od nowa —
   [authentication](https://code.claude.com/docs/en/authentication)).
4. **Lista zadań cyklicznych** do odtworzenia: ich treść jest w `~/.claude/scheduled-tasks/*/SKILL.md`, ale harmonogram
   i folder nie ([desktop-scheduled-tasks](https://code.claude.com/docs/en/desktop-scheduled-tasks)). Dziś aktywne:
   `czeka-na-pawla-rano` (dni robocze 8:00), `mapa-stanu-zamelduj` (pon 8:00), `blog-widocznosc-tydzien` (pon 9:00),
   jednorazowe: klucz Anthropic dev 13.11, Widoczek sync 13.11. Godzinny przegląd biura to cron tej sesji — po
   przeprowadzce zakładam go od nowa.

## 2. Linux: instalacja

1. Ubuntu LTS (GNOME). Konto użytkownika `pawellimanowka` (krótsza zmiana ścieżek).
2. Claude Desktop z repozytorium apt Anthropic — [desktop-linux](https://code.claude.com/docs/en/desktop-linux):
   „Linux support for the Claude desktop app is in beta”; aktualizacje przez `apt upgrade`. Brakuje: sterowania
   komputerem, dyktowania, skrótu Quick Entry pod Waylandem. Logowanie trzyma w keyringu GNOME — przy zablokowanym
   keyringu loguje się przy każdym starcie (ważne przy logowaniu zdalnym, §3).
3. Narzędzia: git, gh, age, sops, Docker, Java 25 (toolchain z Gradle), Node, OpenTofu, cloudflared, tailscale.
   (Lista z repo zamelduj: `docs/dev-setup.md`.)
4. `bash z-usb.sh /media/$USER/<USB>/mac-….tar.age` — rozpakowuje do `$HOME`, przestawia nazwy katalogów projektów
   Claude (`-Users-pawellimanowka-…` → `-home-…`), poprawia ścieżki w ustawieniach. Uzasadnienie: nazwa katalogu
   projektu to ścieżka z „-” zamiast znaków niealfanumerycznych, a pamięć automatyczna jest „machine-local”
   ([sessions](https://code.claude.com/docs/en/sessions), [memory](https://code.claude.com/docs/en/memory)).
5. `bash odtworz-repo.sh` — klonuje repozytoria, odtwarza katalogi stałych sesji zamelduj (worktree) i wkłada sekrety
   lokalne na miejsce.
6. Logowanie: Claude Desktop, `claude` → `/login`; wtyczki zsynchronizowane z konta pobiorą się same; konektory
   (Gmail, Kalendarz, Drive, Slack) są przypięte do konta. Rozszerzenie Claude in Chrome działa na Linuksie
   ([chrome](https://code.claude.com/docs/en/chrome)). 1Password — do sprawdzenia na miejscu.
7. **Sesje:** stare rozmowy wznawia `claude --resume <id>` z dowolnego katalogu ([sessions](https://code.claude.com/docs/en/sessions)).
   Praktycznie: zakładamy sesje od nowa w tych samych katalogach (zamelduj, -ads, -landing, -inv, -klienci, -agenci,
   -pawel, plus eagle-ai, plimanowka-home, wilkowisko-*); każda czyta swój plik stanu z repo, a pamięć projektów
   przychodzi z USB.
8. Zadania cykliczne — założyć w aplikacji od nowa z treści `SKILL.md` (pkt 1.4).

## 3. Zdalny pulpit i SSH z internetu (bez otwierania portów)

**Serwer pulpitu: GNOME Remote Desktop, tryb „Remote Login”** — RDP od ekranu logowania GDM, więc działa też po
restarcie. „This feature is only available via the RDP protocol”; włączenie: Ustawienia → System → Pulpit zdalny →
Zdalne logowanie albo `grdctl --system rdp …` ([README gnome-remote-desktop](https://raw.githubusercontent.com/GNOME/gnome-remote-desktop/master/README.md)).
xrdp odpada: nie obsługuje Waylanda ([c-nergy, 07.2026](https://c-nergy.be/blog/?p=20454)).

**Droga główna: Cloudflare Tunnel + Access.**
- Tunel łączy się z domu na zewnątrz: „outbound-only connection” — na MikroTiku nic nie otwierasz
  ([CF RDP](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/use-cases/rdp/rdp-browser/)).
- ⚠ RDP **w przeglądarce** Cloudflare obsługuje tylko serwery Windows (to samo źródło). Do Linuksa: `cloudflared
  access rdp` na Macu i Windows App na `localhost:3389`
  ([CF RDP z cloudflared](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/use-cases/rdp/rdp-cloudflared-authentication/)).
- SSH: `ProxyCommand cloudflared access ssh --hostname %h`
  ([CF SSH](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/use-cases/ssh/ssh-cloudflared-authentication/)).
- Access: polityka „tylko Twój e-mail + MFA”. Plan Free: do 50 użytkowników, 0 zł
  ([cennik Zero Trust](https://www.cloudflare.com/plans/sase-zero-trust.md)).

**Zapas: Tailscale** — gdy UDP zablokowane, idzie przez przekaźniki DERP „at TCP port 443”, szyfrowane WireGuardem
([porty](https://tailscale.com/kb/1082/firewall-ports), [typy połączeń](https://tailscale.com/kb/1257/connection-types));
darmowy plan Personal ([cennik](https://tailscale.com/pricing)). Technicznie VPN, ale awaryjnie wygląda jak HTTPS.

**Gdyby na komputerze klienckim nie wolno było instalować Windows App / cloudflared (np. sprzęt firmowy) — sama przeglądarka:**
1. sesje Claude: Remote Control w claude.ai/code ([remote-control](https://code.claude.com/docs/en/remote-control)) — bez pulpitu;
2. terminal: SSH renderowane w przeglądarce przez Cloudflare Access;
3. pełny pulpit: Apache Guacamole (HTML5, RDP/VNC — [Guacamole](https://guacamole.apache.org/doc/gug/introduction.html))
   na Linuksie za Cloudflare Access; współpraca z GNOME RDP — do sprawdzenia na miejscu. (VNC w przeglądarce Cloudflare
   ma limit hasła 8 znaków — [CF VNC](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/use-cases/vnc-browser-rendering/).)

**Odradzam:** przekierowanie 3389 na MikroTiku (stale skanowane; sieci „tylko 443” i tak zablokują).

**MikroTik:** przy tej drodze bez zmian. Sprawdź `/system resource print`: gałąź 6.49 dostaje jeszcze poprawki
(6.49.22 z 21.09.2026), starsze nie ([endoflife.date](https://endoflife.date/routeros)) — jeśli masz < 6.49, zaktualizuj.

## 4. Claude z telefonu

Remote Control działa z Claude Code na Linuksie: `claude remote-control` (serwer do 32 sesji, `--spawn worktree` —
każda sesja we własnym worktree), `claude --remote-control` albo `/remote-control` w trwającej sesji. Wymaga planu
Pro/Max/Team/Enterprise, nie działa z kluczem API ([remote-control](https://code.claude.com/docs/en/remote-control)).
Proces musi żyć — na Linuksie uruchamiać w tmux/screen albo jako usługę; logind z `KillUserProcesses=yes` zabija
procesy po wylogowaniu ([desktop](https://code.claude.com/docs/en/desktop)). Sesje z Claude Desktop na Linuksie
mają przełącznik „Connect new sessions to Remote Control” jak na Macu (Linux nie jest na liście braków bety).

## 5. Subskrypcje: 2× Max 5x zamiast 1× Max 20x?

- Cena ta sama: Max 5x „$100 per month”, Max 20x „$200 per month”; limit odnawia się „every five hours” i jest
  limit tygodniowy ([Max plan](https://support.claude.com/en/articles/11049741-what-is-the-max-plan)).
- **W oknie 5-godzinnym 2× 5x = połowa 20x.** Przy wielu sesjach równoległych naraz to gorzej. W limicie tygodniowym
  w 2025 r. 20x dawał tylko ~1,7× tego co 5x (szacunki Anthropic za
  [TechCrunch](https://techcrunch.com/2025/07/28/anthropic-unveils-new-rate-limits-to-curb-claude-code-power-users/));
  czy proporcja dziś obowiązuje — niepotwierdzone.
- **Aplikacja Desktop obsługuje jedno konto naraz** ([zgłoszenie #36821](https://github.com/anthropics/claude-code/issues/36821),
  zamknięte „not planned”) → drugie konto praktycznie tylko w CLI: `CLAUDE_CONFIG_DIR=~/.claude-b claude`
  ([authentication](https://code.claude.com/docs/en/authentication)). Remote Control widzi tylko sesje swojego konta,
  więc telefon zalogowany na A nie zobaczy sesji z B.
- **Regulamin:** dwa konta same w sobie nie są zakazane (dokumentacja opisuje wiele kont, np. „work and personal”);
  przełączanie kont **po to, żeby obejść limity** to szara strefa — Usage Policy zakazuje obchodzenia „restrictions,
  or guardrails” ([AUP](https://www.anthropic.com/legal/aup)); w lutym 2026 były zgłoszenia banów kont mnożonych,
  Anthropic wskazywał na odsprzedawców.
- **Rekomendacja:** zostać na Max 20x i dokupywać „usage credits” po wyczerpaniu limitu, z miesięcznym limitem
  wydatków ([usage credits](https://support.claude.com/en/articles/12429409)). Jeśli jednak 2× 5x: podział **po
  projektach, nie po limitach** — konto A w Desktop dla zamelduj (+ telefon), konto B w CLI dla innych projektów
  (eagle-ai, wilkowisko, home); osobny `CLAUDE_CONFIG_DIR` dla B ze skopiowanymi `CLAUDE.md`/`rules`/`skills`.

## 6. Skille i zasady pracy

✅ **Decyzja 27.10:** konta równolegle przez `CLAUDE_CONFIG_DIR` — `claude-plimanowka`, `claude-zamelduj`,
`claude-loopme` (`dotfiles/shell/claude.sh`); `~/.claude` = Claude Desktop (docelowo konto plimanowka). Konta na
jednej maszynie dzielą reguły, skille, ustawienia, wtyczki i pamięć projektów przez dowiązania do `~/.claude`.
Między maszynami: `~/.claude` jest repo git (allowlista w `.gitignore`) → prywatne `plimanowka/claude-wow`, skill
`/wow-sync` (wybór, co udostępnić + promowanie lekcji z pamięci do reguł). Reguły z pracy mogą płynąć do repo
prywatnego (Paweł: akceptowalne). Na Linuksie: po `z-usb.sh` krok „New machine” z `~/.claude/skills/wow-sync/SKILL.md`.
`na-usb.sh` pomija `.claude/projects/-Users-pawellimanowka-dev-loopme*` (dane firmowe zostają na Macu).

Globalne: `~/.claude/CLAUDE.md`, `~/.claude/rules/`, `~/.claude/skills/`, `~/.claude/commands/`, `settings.json`
(przenosi `na-usb.sh`). Projektowe (`.claude/skills`, `CLAUDE.md` w repo) przychodzą z gitem. Wtyczki z marketplace
— zainstalować od nowa (`/plugin`), zsynchronizowane z konta pobiorą się same ([claude-directory](https://code.claude.com/docs/en/claude-directory)).
Docelowo warto trzymać `~/.claude/{CLAUDE.md,rules,skills,commands}` w repo `dotfiles` — następna przeprowadzka to
wtedy `git clone`.

## 7. Orca zamiast Claude Desktop? (pytanie Pawła 26.10)

[Orca](https://github.com/stablyai/orca) (MIT, ~106 tys. gwiazdek): „The AI Orchestrator” — wiele agentów naraz, każdy
w swoim worktree, wydania na Linuksa (AppImage), aplikacja na telefon, przełącznik kont Claude/Codex „without
re-logging in”. Uruchamia zwykłe CLI agenta („if it runs in a terminal, it runs in Orca”), więc pod spodem to ten sam
Claude Code.

- **Za:** stabilne wydanie na Linuksa (Desktop jest w becie), przełącznik kont pasuje do wariantu 2× Max 5x, widok wielu
  sesji w jednym oknie.
- **Przeciw:** to nakładka firmy trzeciej — tracimy funkcje aplikacji Claude: zadania cykliczne w aplikacji, panel
  przeglądarki, karty sesji pobocznych, „Linked sessions” (na nich stoi praca biura). Telefon: zamiast aplikacji Claude
  ich własna aplikacja (Remote Control z CLI i tak działa). Przełączanie kont podmienia dane logowania — przy zakazie
  używania tokenów subskrypcji poza Claude Code
  ([The Register, 02.2026](https://www.theregister.com/2026/02/20/anthropic_clarifies_ban_third_party_claude_access/))
  trzeba sprawdzić, czy Orca nie wychodzi poza oficjalne CLI — **nie zweryfikowano**.
- **Rekomendacja:** podstawą Claude Desktop (beta) + CLI; Orcę zainstalować obok na próbę, bez przenoszenia na nią biura.
