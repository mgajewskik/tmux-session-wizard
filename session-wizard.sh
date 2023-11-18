#!/usr/bin/env bash

ENHANCD_LOG="$HOME/.enhancd/enhancd.log"

__fzfcmd() {
  [ "$TMUX_PANE" != "" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ "$FZF_TMUX_OPTS" != "" ]; } &&
    echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

RESULT=$((tmux list-sessions -F "#{session_name}: #{session_windows} window(s)\
#{?session_grouped, (group ,}#{session_group}#{?session_grouped,),}\
#{?session_attached, (attached),}"; cat "$ENHANCD_LOG") | $(__fzfcmd) --reverse)
if [ "$RESULT" = "" ]; then
    exit 0
fi

# Get or create session
if [[ $RESULT == *":"* ]]; then
  # RESULT comes from list-sessions
  SESSION=$(echo "$RESULT" | awk '{print $1}')
  SESSION=${SESSION//:/}
else
  # RESULT is a path
  if [ -d "$RESULT" ]; then
      cd "$RESULT" || exit
  else
      sed -i "/$RESULT/d" "$ENHANCD_LOG"
  fi
  SESSION=$(echo "$RESULT" | sed "s|$HOME|~|g" | tr . - | tr ' ' - | tr ':' - | tr '[:upper:]' '[:lower:]')
  if ! tmux has-session -t="$SESSION" 2> /dev/null; then
    tmux new-session -d -s "$SESSION" -c "$RESULT"
  fi
fi

# Attach to session
if [ "$TMUX" = "" ]; then
  tmux attach -t "$SESSION"
else
  tmux switch-client -t "$SESSION"
fi
