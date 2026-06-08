# Shell aliases

# Colors for ls (macOS)
export CLICOLOR=1
export LSCOLORS="GxFxCxDxBxegedabagaced"

# ls aliases
alias ls="ls -G"
alias ll="ls -laG"
alias la="ls -A"
alias l="ls -CF"

# Editor — in the IntelliJ built-in terminal (JediTerm) route everything that
# honors $EDITOR/$VISUAL (git, claude ctrl-g, crontab, `edit`, ...) through IDEA;
# --wait blocks the shell until the buffer/tab is closed. Fall back to micro
# elsewhere, or if the Toolbox `idea` launcher isn't on PATH.
# Guard on the launcher's absolute path, not `command -v idea`: aliases.sh is
# sourced before ~/.config/shell/idea is appended to PATH, so a PATH lookup
# would fail on a fresh shell.
if [[ "$TERMINAL_EMULATOR" == "JetBrains-JediTerm" && -x "$HOME/.config/shell/idea/idea" ]]; then
    export EDITOR="idea --wait"
    export VISUAL="idea --wait"
else
    export EDITOR="micro"
    export VISUAL="micro"
fi
# ${=EDITOR} so zsh word-splits "idea --wait" into command + flag; zsh doesn't
# split unquoted parameter expansions by default, so a plain $EDITOR would be
# treated as one command name.
edit() { ${=EDITOR} "$@"; }

# ClaudeCode
alias ccusage="npx ccusage@latest"

# ZeroTier
alias ztr="zt-restart.sh"
