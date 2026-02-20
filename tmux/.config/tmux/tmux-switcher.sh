#!/usr/bin/env bash
# tmux-switcher — fzf picker for existing sessions and windows

selected=$(tmux list-windows -a -F "#{session_name}:#{window_index} #{window_name} (#{pane_current_command})" 2>/dev/null | fzf --reverse --prompt="switch > ")

if [[ -z $selected ]]; then
    exit 0
fi

target=$(echo "$selected" | awk '{print $1}')
tmux switch-client -t "$target"
