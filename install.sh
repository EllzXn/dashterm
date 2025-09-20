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
  done
  unset DASHBOARD_EXECUTED 2>/dev/null || true
}
install_neofetch_if_needed() {
  if command -v neofetch >/dev/null 2>&1; then return 0; fi
  if command -v apt-get >/dev/null 2>&1; then sudo apt-get update -qq && sudo apt-get install -y neofetch >/dev/null 2>&1 || true
  elif command -v dnf >/dev/null 2>&1; then sudo dnf install -y neofetch >/dev/null 2>&1 || true
  elif command -v yum >/dev/null 2>&1; then sudo yum install -y epel-release >/dev/null 2>&1 || true; sudo yum install -y neofetch >/dev/null 2>&1 || true
  elif command -v pacman >/dev/null 2>&1; then sudo pacman -Sy --noconfirm neofetch >/dev/null 2>&1 || true
  elif command -v zypper >/dev/null 2>&1; then sudo zypper install -y neofetch >/dev/null 2>&1 || true
  fi
}
prompt_userhost() {
  read -r -p "Tampilkan User@Host sebagai (mis. root@aka, kosong=otomatis): " WANT_UH || true
}
write_block() {
  [ -f "$BACKUP_FILE" ] || cp "$BASHRC_FILE" "$BACKUP_FILE" 2>/dev/null || touch "$BACKUP_FILE"
  touch "$BASHRC_FILE" 2>/dev/null || sudo -u "$TARGET_USER" touch "$BASHRC_FILE"
  cat >> "$BASHRC_FILE" <<DASHBOARD_EOF
$DASHBOARD_MARK
if [[ \$- == *i* ]] && [[ -z "\${DASHBOARD_EXECUTED:-}" ]]; then
  export DASHBOARD_EXECUTED=1
  export DASH_USERHOST="${WANT_UH:-}"
  printf '\033[2J\033[H'
  _has() { command -v "\$1" >/dev/null 2>&1; }
  _val() { local v="\$1"; [ -n "\$v" ] && printf "%s" "\$v" || printf "-"; }
  _pretty="Linux"
  _id="linux"
  if [ -f /etc/os-release ]; then . /etc/os-release 2>/dev/null || true; _pretty="\${PRETTY_NAME:-Linux}"; _id="\${ID:-linux}"; fi
  if _has neofetch; then
    if neofetch --help 2>/dev/null | grep -q "ascii_distro"; then
      neofetch --ascii_distro ubuntu_small --ascii --disable packages shell resolution de wm theme icons terminal cpu gpu memory disk battery localip publicip users uptime --stdout >/dev/null 2>&1 || true
      neofetch --ascii_distro ubuntu_small --ascii --disable packages shell resolution de wm theme icons terminal
    else
      neofetch --disable packages shell resolution de wm theme icons terminal
    fi
  fi
  uh="\${DASH_USERHOST:-\$(whoami 2>/dev/null || echo -n "-")@\$(hostname 2>/dev/null || echo -n "-")}"
  ip="\$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \\K\\S+' | head -1 || true)"; [ -n "\$ip" ] || ip="\$(hostname -I 2>/dev/null | awk '{print \$1}' || true)"
  kern="\$(uname -r 2>/dev/null || true)"
  bt="\$(who -b 2>/dev/null | awk '{print \$3, \$4}' || true)"; [ -n "\$bt" ] || bt="\$(uptime -s 2>/dev/null || true)"
  up="\$(uptime -p 2>/dev/null | sed 's/^up //' || true)"
  cpu="\$(grep -m1 '^model name' /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | sed 's/^[ \t]*//' || true)"
  cores="\$(nproc 2>/dev/null || true)"
  gpu=""; if _has lspci; then gpu="\$(lspci 2>/dev/null | grep -i 'vga\\|3d\\|display' | head -1 | cut -d':' -f3 | sed 's/^[ \t]*//' || true)"; fi
  ram="\$(free -h 2>/dev/null | awk '/^Mem:/ {print \$2}' || true)"
  disk="\$(df -h / 2>/dev/null | awk 'NR==2 {printf "%s / %s", \$3, \$2}' || true)"
  load="\$(awk '{print \$1","\$2","\$3}' /proc/loadavg 2>/dev/null || true)"
  dns="\$(awk '/^nameserver/ {printf "%s ", \$2}' /etc/resolv.conf 2>/dev/null | xargs || true)"
  echo "========================================"
  echo "User@Host    : \$(_val "\$uh")"
  echo "OS           : \$(_val "\$_pretty")"
  echo "Kernel       : \$(_val "\$kern")"
  echo "Login Time   : \$(date '+%A, %d %B %Y - %H:%M:%S')"
  echo "Boot Time    : \$(_val "\$bt")"
  echo "Uptime       : \$(_val "\$up")"
  echo "IP Address   : \$(_val "\$ip")"
  echo "CPU Model    : \$(_val "\$cpu")"
  echo "CPU Cores    : \$(_val "\$cores")"
  echo "GPU          : \$(_val "\$gpu")"
  echo "RAM Total    : \$(_val "\$ram")"
  echo "Disk Used    : \$(_val "\$disk")"
  echo "Load Average : \$(_val "\$load")"
  echo "DNS Servers  : \$(_val "\$dns")"
  echo "========================================"
fi
$DASHBOARD_MARK
DASHBOARD_EOF
}
main() {
  cleanup_all_traces
  install_neofetch_if_needed
  prompt_userhost
  write_block
  log "✅ Terpasang di $BASHRC_FILE"
  if [[ $- == *i* ]]; then exec bash; else log "Jalankan: source \"$BASHRC_FILE\""; fi
}
main
