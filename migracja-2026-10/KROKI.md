# Przeprowadzka Mac → Linux: krok po kroku

Plan z uzasadnieniami i źródłami: `PLAN.md` obok. Skrypty: `~/dev/tmp/migracja/` (kopia: repo `dotfiles`,
katalog `migracja-2026-10/`).

## Co przygotować wcześniej

- [ ] **Pendrive na dane** ≥ 32 GB, sformatowany jako **exFAT** (czyta go i Mac, i Linux). Archiwum ma ok. 16 GB.
- [ ] **Drugi pendrive** ≥ 8 GB na instalator Ubuntu (zostanie wyczyszczony).
- [ ] Dostęp do **1Password** (tu zapiszesz hasło do archiwum).
- [ ] Logowania: **GitHub** (z 2FA), **Cloudflare**, **Google** (plimanowka@gmail.com), konto **Claude** (to, na którym
      będziesz pracować), **Tailscale** (załóż kontem Google albo GitHub).
- [ ] Telefon z aplikacją Claude i Authenticatorem.
- [ ] Czas: Mac ok. 1 h (głównie pakowanie), Linux ok. 3–4 h.

## A. Na Macu (przed przeprowadzką)

1. **Sesje zapisane** — zrobione 26.10 (tabela sesji niżej). Jeszcze w: IPTV Wilkowisko-Hub (dwie), dotfiles —
   napisz w każdej „zapisz stan w pliku stanu, commit i push”.
2. **Klucz age (najważniejsze!)** — odszyfrowuje wszystkie sekrety; dziś istnieje w jednej kopii:
   ```bash
   cat "$HOME/Library/Application Support/sops/age/keys.txt"
   ```
   Wydrukuj (jedna linia `AGE-SECRET-KEY-…`) i schowaj z dokumentami. Plus kopia zaszyfrowana hasłem na Drive:
   ```bash
   age -p -o ~/Desktop/age-key.txt.age "$HOME/Library/Application Support/sops/age/keys.txt"
   ```
   (wrzuć `age-key.txt.age` do Drive → `personal/narzedzia/`, hasło do 1Password).
3. **Drobne zaległości w gicie:**
   ```bash
   git -C ~/dev/plimanowka/wilkowisko-siec push
   ```
   - Dwa pliki Sofar w `wilkowisko-hub/research/energy/` są poza gitem i **nie jadą na pendrive** — dodaj je do repo
     (sesja Wachata HA ma o nie pytanie) albo skopiuj ręcznie.
   - `plimanowka-home`: commit `a14dad8` sesji wachata.pl jest tylko lokalnie — powiedz jej „publikuj” albo `git push`.
4. **Sprawdzenie, czy nic nie zostało:**
   ```bash
   bash ~/dev/tmp/migracja/inwentarz.sh
   ```
   Ma zostać tylko to, co świadomie zostawiasz (stare gałęzie, `~/dev/loopme`).
5. **Pakowanie na pendrive** (włóż pendrive na dane):
   ```bash
   bash ~/dev/tmp/migracja/na-usb.sh --rozmiar
   bash ~/dev/tmp/migracja/na-usb.sh /Volumes/NAZWA_PENDRIVE
   ```
   Podaj hasło dwa razy → **zapisz je od razu w 1Password**. Sprawdzenie:
   ```bash
   age -d /Volumes/NAZWA_PENDRIVE/mac-*.tar.age | tar -tf - | head
   ```
6. **MikroTik** — sprawdź wersję (Winbox/terminal): `/system resource print`. Jeśli starsza niż 6.49 → aktualizacja.

## B. Linux: instalacja systemu

1. Pobierz **Ubuntu Desktop LTS** (najnowsze wydanie LTS z ubuntu.com), nagraj na drugi pendrive (na Macu:
   balenaEtcher), zainstaluj. Użytkownik: **`pawellimanowka`**. Włącz automatyczne aktualizacje bezpieczeństwa.
2. Podstawy:
   ```bash
   sudo apt update && sudo apt install -y git gh age rclone curl tmux openssh-server
   ```
3. Narzędzia do zamelduj (Docker, Java, Node, OpenTofu, sops) — według `zamelduj/docs/dev-setup.md` (po kroku C2).

## C. Linux: dane i repozytoria

1. Włóż pendrive z archiwum:
   ```bash
   bash /media/$USER/NAZWA_PENDRIVE/…/z-usb.sh /media/$USER/NAZWA_PENDRIVE/mac-RRRRMMDD-HHMM.tar.age
   ```
   (skrypty są też w repo `dotfiles` — jeśli wygodniej, najpierw `gh auth login` i sklonuj dotfiles).
   Rozpakowuje konfigurację Claude, klucze ssh, klucz age, tokeny, `dev/tmp`, `wachata-media`, `vms`; przestawia
   ścieżki z `/Users/…` na `/home/…`.
2. Sprawdź SSH do GitHuba: `ssh -T git@github.com-plimanowka` (ma się przywitać). Potem:
   ```bash
   bash ~/dev/tmp/migracja/odtworz-repo.sh
   ```
   Klonuje repozytoria, zakłada katalogi sesji zamelduj, wkłada sekrety lokalne (`.env.local`, `terraform.tfvars`…).
3. `personal` z Google Drive:
   ```bash
   rclone copy gdrive-plimanowka:personal ~/dev/plimanowka/personal -P
   ```
   (konfiguracja rclone przyjechała z pendrive’em; jeśli token wygasł: `rclone config reconnect gdrive-plimanowka:`).
4. Teraz krok B3 (narzędzia) i próba: w `~/dev/plimanowka/zamelduj` uruchom testy jak w `docs/dev-setup.md`.

## D. Claude

1. **Claude Desktop** (beta na Linuksie):
   ```bash
   sudo curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc https://downloads.claude.ai/claude-desktop/key.asc
   echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" | sudo tee /etc/apt/sources.list.d/claude-desktop.list
   sudo apt update && sudo apt install claude-desktop
   ```
   Uruchom, zaloguj się. Gdyby przy każdym starcie kazał się logować — odblokuj keyring GNOME.
2. **Claude Code w terminalu** — instalacja według https://code.claude.com/docs/en/setup, potem `claude` → `/login`.
3. **Konektory** (Gmail, Kalendarz, Drive, Slack) — w ustawieniach konta Claude; **Claude in Chrome** — zainstaluj Chrome
   i rozszerzenie; **1Password** — aplikacja na Linuksa + rozszerzenie.
4. **Telefon:** aplikacja Claude zalogowana na to samo konto; w Desktop włącz „Connect new sessions to Remote Control”.
5. **Sesje** — w Desktop nowa sesja w każdym katalogu z tabeli niżej, pierwsza wiadomość `/resume`. **Zacznij od biura**:
   `/resume`, potem „scal #215, #216, #218” (stan trzech sesji leży na tych gałęziach) i „załóż godzinny przegląd jak
   w Rytuale”.
6. **Zadania cykliczne** — w Desktop załóż od nowa: poranna lista „Czeka na Pawła” (dni robocze 8:00), mapa stanu
   (pon 8:00), widoczność bloga (pon 9:00), przypomnienia 13.11 (klucz Anthropic dev, Widoczek sync). Treść każdego:
   `~/.claude/scheduled-tasks/<nazwa>/SKILL.md`.

## E. Zdalny dostęp z internetu

1. **Pulpit zdalny na Linuksie:** Ustawienia → System → Pulpit zdalny → **Zdalne logowanie** → włącz, ustaw login
   i hasło (inne niż do konta).
2. **Tailscale** (codzienna droga): na Linuksie `curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up`,
   na Macu aplikacja Tailscale z App Store, to samo konto. Pulpit: **Windows App** (Mac App Store) → Add PC → adres
   Tailscale Linuksa. SSH: `ssh pawellimanowka@<nazwa-w-tailscale>`.
3. **Cloudflare Tunnel + Access** (gdy Tailscale nie przejdzie):
   - Cloudflare → Zero Trust → Networks → Tunnels → Create tunnel → skopiuj komendę instalacji `cloudflared`
     i wykonaj na Linuksie;
   - w tunelu dodaj: `rdp.zamelduj.pl` → `rdp://localhost:3389`, `ssh.zamelduj.pl` → `ssh://localhost:22`
     (domena dowolna z Twoich);
   - Access → Applications → dodaj obie nazwy, polityka: tylko Twój e-mail;
   - na Macu: `brew install cloudflared`, potem `cloudflared access rdp --hostname rdp.zamelduj.pl --url rdp://localhost:3389`
     i w Windows App łącz z `localhost:3389`.
4. **Na MikroTiku nic nie otwierasz.**
5. **Test z telefonu na hotspocie** (inna sieć): pulpit przez Tailscale, potem przez Cloudflare, i sesja Claude na
   claude.ai/code.

## F. Sprzątanie

- Po tygodniu działania: `rm -rf ~/.migracja-usb` na Linuksie; archiwum na pendrive zostaw w szufladzie jako kopię.
- Mac: zostaje z `~/dev/loopme`; resztę możesz skasować dopiero po teście z punktu E5.

## Tabela sesji (do odtworzenia w Desktop na Linuksie)

| Sesja | Katalog roboczy | Dodatkowe katalogi | Start | Uwagi |
|---|---|---|---|---|
| zamelduj.pl - dla mnie (biuro) — **pierwsza** | `~/dev/plimanowka/zamelduj-pawel` | `~/dev/plimanowka/plimanowka-home`, `~/dev/tmp` | `/resume` → „scal #215, #216, #218” → „załóż godzinny przegląd jak w Rytuale” | `docs/biuro-pawla.md` → „Stan biura” |
| zamelduj.pl (produkt) | `~/dev/plimanowka/zamelduj` | `plimanowka-home`, `~/dev/tmp` | `/resume` | `docs/next-steps.md` (po scaleniu #216) |
| zamelduj.pl - GoogleAds | `~/dev/plimanowka/zamelduj-ads` | `~/dev/plimanowka/zamelduj-landing` | `/resume` | pyta o ustalenia z rozmowy z Google; #217 |
| zamelduj.pl - blog i marketing | `~/dev/plimanowka/zamelduj-landing` | — | `/resume` | |
| zamelduj.pl - inwestygacje | `~/dev/plimanowka/zamelduj-inv` | — | `/resume` | |
| zamelduj.pl - klienci | `~/dev/plimanowka/zamelduj-klienci` | — | `/resume` → „załóż sprawdzanie Gmaila co 30 min” | #146 Pani Ewa nie wyszło |
| zamelduj.pl - AI ops | `~/dev/plimanowka/zamelduj-agenci` | `~/dev/tmp` | `/resume` | stan po scaleniu #218 |
| Demo / kaskada ustawień (#177) | `~/dev/plimanowka/zamelduj` (sesja z worktree) | `plimanowka-home`, `~/dev/tmp` | `/resume` | po scaleniu #215; plan §110 od E0 |
| wachata.pl | `~/dev/plimanowka/plimanowka-home` | — | `/resume` | commit a14dad8 był tylko lokalnie na Macu — przed przeprowadzką „publikuj” albo push |
| Wachata HA | `~/dev/plimanowka/claude-homeassistant` | — | `/resume` | stan w `wilkowisko-hub/tasks/README.md` |
| personal | `~/dev/plimanowka/personal` | `plimanowka-home` | `/resume` | |
| IPTV Wilkowisko-Hub | `~/dev/plimanowka/wilkowisko-hub` | — | `/resume` | |
| dotfiles | `~/dev/plimanowka/dotfiles` | — | `/resume` | |
