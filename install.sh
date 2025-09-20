#!/bin/bash
set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6 2>/dev/null || echo "$HOME")"
BASHRC_FILE="$TARGET_HOME/.bashrc"
BACKUP_FILE="$TARGET_HOME/.bashrc.backup"
PROFILE_FILE="$TARGET_HOME/.profile"
BASH_PROFILE_FILE="$TARGET_HOME/.bash_profile"
DASHBOARD_MARK="### TERMINAL_DASHBOARD_ACTIVE ###"

log() { printf "%b\n" "$1"; }

cleanup_all_traces() {
  for file in "$BASHRC_FILE" "$PROFILE_FILE" "$BASH_PROFILE_FILE"; do
    [ -f "$file" ] || continue
    sed -i "/^$DASHBOARD_MARK$/,/^$DASHBOARD_MARK$/d" "$file" 2>/dev/null || true
    sed -i '/^[[:space:]]*neofetch/d' "$file" 2>/dev/null || true
    sed -i '/^[[:space:]]*figlet.*whoami.*hostname/d' "$file" 2>/dev/null || true
    sed -i '/# >>> CUSTOM TERMINAL DASHBOARD >>>/,/# <<< CUSTOM TERMINAL DASHBOARD <<</d' "$file" 2>/dev/null || true
  done
  unset DASHBOARD_SHOWN 2>/dev/null || true
  unset DASHBOARD_LOADED 2>/dev/null || true
}

install_block() {
  [ -f "$BACKUP_FILE" ] || cp "$BASHRC_FILE" "$BACKUP_FILE" 2>/dev/null || touch "$BACKUP_FILE"
  touch "$BASHRC_FILE" 2>/dev/null || sudo -u "$TARGET_USER" touch "$BASHRC_FILE"

  cat >> "$BASHRC_FILE" <<'DASHBOARD_EOF'
### TERMINAL_DASHBOARD_ACTIVE ###
if [[ $- == *i* ]] && [[ -z "${DASHBOARD_EXECUTED:-}" ]]; then
  export DASHBOARD_EXECUTED=1
  printf '\033[2J\033[H'

  _has() { command -v "$1" >/dev/null 2>&1; }
  _val() { local v="$1"; [ -n "$v" ] && printf "%s" "$v" || printf "-"; }

  _id="linux"
  if [ -f /etc/os-release ]; then
    . /etc/os-release 2>/dev/null || true
    _id="${ID:-linux}"
    _pretty="${PRETTY_NAME:-Linux}"
  else
    _pretty="$(uname -s 2>/dev/null || true)"
  fi

  colorize() { if _has lolcat; then lolcat; else cat; fi; }

  draw_logo() {
    case "$_id" in
      ubuntu)
        printf "%s\n" "  .--."
        printf "%s\n" " (    )  ubuntu"
        printf "%s\n" "  '--'"
        ;;
      *)
        printf "%s\n" "  ___"
        printf "%s\n" " ( _ )  term"
        printf "%s\n" " / _ \  dash"
        ;;
    esac
  }

  ip_addr() {
    local ip
    ip="$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1 || true)"
    [ -n "$ip" ] || ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
    _val "$ip"
  }

  cpu_model() {
    local m
    m="$(grep -m1 '^model name' /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | sed 's/^[ \t]*//' || true)"
    _val "$m"
  }

  gpu_info() {
    local g
    if _has lspci; then
      g="$(lspci 2>/dev/null | grep -i 'vga\|3d\|display' | head -1 | cut -d':' -f3 | sed 's/^[ \t]*//' || true)"
    fi
    _val "$g"
  }

  mem_total() {
    local m
    m="$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || true)"
    _val "$m"
  }

  disk_used() {
    local d
    d="$(df -h / 2>/dev/null | awk 'NR==2 {printf "%s / %s", $3, $2}' || true)"
    _val "$d"
  }

  load_avg() {
    local l
    l="$(awk '{print $1","$2","$3}' /proc/loadavg 2>/dev/null || true)"
    _val "$l"
  }

  boot_time() {
    local b
    b="$(who -b 2>/dev/null | awk '{print $3, $4}' || true)"
    [ -n "$b" ] || b="$(uptime -s 2>/dev/null || true)"
    _val "$b"
  }

  dns_servers() {
    local d
    d="$(awk '/^nameserver/ {printf "%s ", $2}' /etc/resolv.conf 2>/dev/null | xargs || true)"
    _val "$d"
  }

  uname_r() { _val "$(uname -r 2>/dev/null || true)"; }
  nproc_s() { local n; n="$(nproc 2>/dev/null || true)"; _val "$n"; }

  draw_logo | colorize
  {
    printf "========================================\n"
    printf "Login Time   : %s\n" "$(date '+%A, %d %B %Y - %H:%M:%S')"
    printf "User@Host    : %s\n" "$(printf "%s@%s" "$(whoami 2>/dev/null || echo -n "-")" "$(hostname 2>/dev/null || echo -n "-")")"
    printf "IP Address   : %s\n" "$(ip_addr)"
    printf "OS           : %s\n" "$(_val "$_pretty")"
    printf "Kernel       : %s\n" "$(uname_r)"
    printf "Boot Time    : %s\n" "$(boot_time)"
    printf "Uptime       : %s\n" "$(_val "$(uptime -p 2>/dev/null | sed 's/^up //')")"
    printf "CPU Model    : %s\n" "$(cpu_model)"
    printf "CPU Cores    : %s\n" "$(nproc_s)"
    printf "GPU          : %s\n" "$(gpu_info)"
    printf "RAM Total    : %s\n" "$(mem_total)"
    printf "Disk Used    : %s\n" "$(disk_used)"
    printf "Load Average : %s\n" "$(load_avg)"
    printf "DNS Servers  : %s\n" "$(dns_servers)"
    printf "========================================\n"
  } | colorize
fi
### TERMINAL_DASHBOARD_ACTIVE ###
DASHBOARD_EOF
}

main() {
  cleanup_all_traces
  install_block
  log "✅ Dashboard terpasang pada $BASHRC_FILE"
  if [[ $- == *i* ]]; then
    exec bash
  else
    log "Jalankan: source \"$BASHRC_FILE\""
  fi
}

main
