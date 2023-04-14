# Path
set path = (/sbin /bin /usr/sbin /usr/bin /usr/local/sbin /usr/local/bin)

# Limits
ulimit -S -c 0

# Unicode
setenv UTF8 `locale -m | grep -i utf | head -1`
setenv NCURSES_NO_UTF8_ACS 1
setenv MM_CHARSET UTF-8

# Localization
setenv LANG en_US.${UTF8}
setenv LC_MESSAGES en_US.${UTF8}
setenv LC_CTYPE en_US.${UTF8}
setenv LC_COLLATE C
setenv LC_ALL

# Applications
setenv PAGER  less
setenv P7ZIP `whereis -bq 7z 7zr 7za | head -1`
setenv EDITOR `whereis -bq nvim vim vi | head -1`

# Colors
setenv CLICOLOR 1
setenv LSCOLORS exfxcxdxbxegedabagacad

# Aliases
alias .. "cd .."

alias ls "ls -F"
alias lsa "ls -a"

alias ll "ls -lh -D '%F %H:%M'"
alias lla "ll -a"

alias 7z "${P7ZIP}"
alias vim "vim -p"
alias grep "grep --color=auto"
alias sudo "sudo "

alias tm "tmux -2"
alias ta "tm attach -t"
alias ts "tm new-session -s"
alias tl "tm list-sessions"

# Settings
if ($?prompt) then
  set filec
  set history = 1000
  set savehist = (1000 merge)
  set autolist = ambiguous
  set autoexpand
  set autorehash

  set prompt =
  if ($?TMUX) then
    set id = `echo $TMUX | cut -d , -f 3`
    set session = `tmux ls -F '#{session_id} #{session_name}' | awk -vv=$id '$1 == "$"v { print $2 }'`
    set prompt = "${prompt}%{\e[90m%}[%{\e[0m%}${session}%{\e[90m%}]%{\e[0m%} "
  endif
  if (`id -u` == "0") then
    set prompt = "${prompt}%{\e[31m%}%N%{\e[0m%}"
  else
    set prompt = "${prompt}%{\e[32m%}%N%{\e[0m%}"
  endif
  set prompt = "${prompt}@%{\e[32m%}%m%{\e[0m%}"
  set prompt = "${prompt} %{\e[34m%}%~%{\e[0m%} "

  if ($?tcsh) then
    bindkey -e
    bindkey -k up history-search-backward    # Up
    bindkey -k down history-search-forward   # Down
    bindkey "\e[5~" history-search-backward  # Page Up
    bindkey "\e[6~" history-search-forward   # Page Down
    bindkey "\e[1~" beginning-of-line        # Home
    bindkey "\e[7~" beginning-of-line        # Home (rxvt)
    bindkey "\e[4~" end-of-line              # End
    bindkey "\e[8~" end-of-line              # End (rxvt)
    bindkey "\e[2~" overwrite-mode           # Insert
    bindkey "\e[3~" delete-char              # Delete
    bindkey "\e[1;5D" backward-word          # Control + Left
    bindkey "\e[1;5C" forward-word           # Control + Right
    bindkey "\e[3;5~" delete-word            # Control + Delete
    bindkey "^_" backward-delete-word        # Control + Backspace
  endif
endif
