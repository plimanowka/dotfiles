# Zmiana konta Claude — jak wznowić pracę (26.10.2026)

## Zanim się przelogujesz
1. Poczekaj chwilę na odpowiedzi sesji („czysto” + hash) — biuro wypisze, kto skończył.
2. W sesjach, których biuro nie wezwało (limit wiadomości), napisz sam: **„zapisz stan w pliku stanu, commit i push”**:
   IPTV Wilkowisko-Hub (dwie), dotfiles, ads-monorepo-2e, dsp-team-stuff-77.

**Stan trzech sesji leży na gałęziach otwartych PR-ów (#215, #216, #218), same dokumenty.** Na nowym koncie: albo
„scal #215, #216, #218” w sesji biura (po zielonym ci.sh), albo nowa sesja czyta plik z gałęzi (`gh pr checkout N`).

## Przelogowanie
- **Claude Desktop:** wyloguj się (menu konta / Settings) i zaloguj na drugie konto.
- **Terminal (`claude`):** `/logout`, potem `/login`.
- **Telefon (aplikacja Claude):** zaloguj na to samo nowe konto — inaczej nie zobaczysz sesji (Remote Control widzi tylko
  sesje swojego konta).
- **Konektory** (Gmail, Kalendarz, Drive, Slack) są przypięte do konta — na nowym podłącz je od nowa.

Rozmowy z obecnych sesji NIE przechodzą na nowe konto w sposób pewny. Pewne jest to, co w plikach i na GitHubie:
pamięć projektów (`~/.claude/projects/*/memory`), skille i reguły (`~/.claude/`) zostają na dysku dla każdego konta.

## Wznowienie (w każdym katalogu nowa sesja)
W Desktop: nowa sesja w katalogu → pierwsza wiadomość **`/resume`** (Twój skill: czyta plik stanu projektu, sprawdza git
i mówi, gdzie stanęliśmy).

| Sesja | Katalog | Plik stanu |
|---|---|---|
| zamelduj (produkt) | `~/dev/plimanowka/zamelduj` | `docs/next-steps.md` — **pauza 26.10 jest na gałęzi PR #216** (`next-steps-prod-2026-10-26`), nie na main |
| dla mnie (biuro) | `~/dev/plimanowka/zamelduj-pawel` | `docs/biuro-pawla.md` → sekcja „Stan biura” |
| GoogleAds | `zamelduj-ads` | `docs/business/stan-ads.md` |
| blog i marketing | `zamelduj-landing` | `docs/business/stan-blog.md` |
| inwestygacje | `zamelduj-inv` | `docs/stan-inwestygacje.md` |
| klienci | `zamelduj-klienci` | `docs/business/stan-klienci.md` |
| AI ops | `zamelduj-agenci` | `docs/research/2026-10-21-czat-z-systemem-managed-agents.md` §9.6 — **na gałęzi PR #218** (`agenci-stan-2`) |
| demo / kaskada ustawień (#177) | worktree `zamelduj/.claude/worktrees/demo-dom-pensjonat-f43740` | `docs/next-steps.md` („Kaskada ustawień”) + `wykonanie.md` §110 — **na gałęzi PR #215** |
| wachata.pl | `plimanowka-home` | `docs/next-steps.md` + `sites/wachata.pl/docs/zadania.md` (commit a14dad8 **tylko lokalnie**, push czeka na Twoje „publikuj”) |
| Wachata HA | `wilkowisko-hub` | `tasks/README.md` → „Stan sesji — 2026-10-26” |
| personal | `personal` | `docs/next-steps.md` (też na Drive) |

## Biuro po zmianie konta
Nowa sesja biura: `/resume`, potem **„załóż godzinny przegląd jak w docs/biuro-pawla.md, sekcja Rytuał”** — stary cron
zginął z poprzednią sesją. Sprawdź też w aplikacji, czy zadania cykliczne (poranna lista, mapa stanu, widoczność bloga)
działają na nowym koncie.

## Przeprowadzka na Linuksa
Plan i skrypty: `~/dev/tmp/migracja/` oraz kopia na GitHubie: repo `dotfiles`, katalog `migracja-2026-10/`.
