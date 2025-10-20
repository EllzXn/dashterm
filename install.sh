#!/bin/bash
set -euo pipefail
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6 2>/dev/null || printf "%s" "$HOME")"
BASHRC_FILE="$TARGET_HOME/.bashrc"
BACKUP_FILE="$TARGET_HOME/.bashrc.backup"
DASHBOARD_MARK="### TERMINAL_DASHBOARD_ACTIVE ###"
say() { printf "%b\n" "$1"; }
ask_userhost() {
  say "Masukkan tampilan User@Host yang diinginkan."
  say "Contoh: root@aka  (Enter untuk otomatis sesuai sistem)"
  read -r -p "User@Host: " WANT_UH || true
  if [ -n "${WANT_UH:-}" ] && ! printf "%s" "$WANT_UH" | grep -q "@"; then
    WANT_UH="$(whoami 2>/dev/null || echo "$TARGET_USER")@$WANT_UH"
  fi
}
install_fastfetch() {
  if command -v fastfetch >/dev/null 2>&1; then
    say "✓ Fastfetch sudah terpasang"
    return 0
  fi
  say "• Fastfetch belum ada, mencoba memasang..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq || true
    sudo apt-get install -y fastfetch >/dev/null 2>&1 || true
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y fastfetch >/dev/null 2>&1 || true
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y epel-release >/dev/null 2>&1 || true
    sudo yum install -y fastfetch >/dev/null 2>&1 || true
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm fastfetch >/dev/null 2>&1 || true
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y fastfetch >/dev/null 2>&1 || true
  fi
  if command -v fastfetch >/dev/null 2>&1; then
    say "✓ Fastfetch berhasil dipasang"
  else
    say "• Gagal memasang fastfetch via paket manager. Lanjut tanpa error."
  fi
}
cleanup_old_block() {
  say "• Memeriksa file target: $BASHRC_FILE"
  touch "$BASHRC_FILE" 2>/dev/null || sudo -u "$TARGET_USER" touch "$BASHRC_FILE"
  if [ -f "$BASHRC_FILE" ]; then
    if grep -q "^$DASHBOARD_MARK$" "$BASHRC_FILE"; then
      say "• Ditemukan skrip lama. Menghapus blok lama..."
      sed -i "/^$DASHBOARD_MARK$/,/^$DASHBOARD_MARK$/d" "$BASHRC_FILE" || true
      say "✓ Skrip lama berhasil dihapus"
    else
      say "• Tidak ada blok lama yang terdeteksi"
    fi
  fi
}
backup_once() {
  if [ ! -f "$BACKUP_FILE" ]; then
    cp "$BASHRC_FILE" "$BACKUP_FILE" 2>/dev/null || touch "$BACKUP_FILE"
    say "✓ Backup .bashrc dibuat: $BACKUP_FILE"
  else
    say "• Backup sebelumnya sudah ada: $BACKUP_FILE"
  fi
}
write_new_block() {
  say "• Menulis skrip dashboard baru ke $BASHRC_FILE"
  # $WANT_UH akan diekspansi di sini oleh installer
  # Variabel dengan \$ (seperti \$uh, \$ip) akan diekspansi saat .bashrc dijalankan
  cat >> "$BASHRC_FILE" <<DASHBOARD_EOF
$DASHBOARD_MARK
if [[ \$- == *i* ]] && [[ -z "\${DASHBOARD_EXECUTED:-}" ]]; then
  export DASHBOARD_EXECUTED=1
  export DASH_USERHOST="${WANT_UH:-}"
  printf '\033[2J\033[H'
  _has() { command -v "\$1" >/dev/null 2>&1; }
  _val() { local v="\$1"; [ -n "\$v" ] && printf "%s" "\$v" || printf "-"; }
  _pretty="Linux"
  if [ -f /etc/os-release ]; then . /etc/os-release 2>/dev/null || true; _pretty="\${PRETTY_NAME:-Linux}"; fi
  if _has fastfetch; then
    fastfetch --structure logo --logo kali 2>/dev/null || fastfetch --structure logo --logo kali_small 2>/dev/null || fastfetch --structure logo 2>/dev/null || true
  fi
  
  # Definisikan Warna (harus di-escape \\ agar ditulis literal ke file)
  C_BORDER="\\033[90m" # Abu-abu (Bright Black)
  C_LABEL="\\033[90m"  # Abu-abu
  C_VALUE="\\033[96m"  # Cyan Terang
  C_TIME="\\033[93m"   # Kuning Terang
  C_RESET="\\033[0m"   # Reset
  
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
  
  # Cetak dengan warna
  echo -e "\$C_BORDER========================================\$C_RESET"
  echo -e "\$C_LABELUser@Host    : \$C_VALUE\$(_val "\$uh")\$C_RESET"
  echo -e "\$C_LABELOS           : \$C_VALUE\$(_val "\$_pretty")\$C_RESET"
  echo -e "\$C_LABELKernel       : \$C_VALUE\$(_val "\$kern")\$C_RESET"
  echo -e "\$C_LABELLogin Time   : \$C_TIME\$(date '+%A, %d %B %Y - %H:%M:%S')\$C_RESET"
  echo -e "\$C_LABELBoot Time    : \$C_TIME\$(_val "\$bt")\$C_RESET"
  echo -e "\$C_LABELUptime       : \$C_TIME\$(_val "\$up")\$C_RESET"
  echo -e "\$C_LABELIP Address   : \$C_VALUE\$(_val "\$ip")\$C_RESET"
  echo -e "\$C_LABELCPU Model    : \$C_VALUE\$(_val "\$cpu")\$C_RESET"
  echo -e "\$C_LABELCPU Cores    : \$C_VALUE\$(_val "\$cores")\$C_RESET"
  echo -e "\$C_LABELGPU          : \$C_VALUE\$(_val "\$gpu")\$C_RESET"
  echo -e "\$C_LABELRAM Total    : \$C_VALUE\$(_val "\$ram")\$C_RESET"
  echo -e "\$C_LABELDisk Used    : \$C_VALUE\$(_val "\$disk")\$C_RESET"
  echo -e "\$C_LABELLoad Average : \$C_VALUE\$(_val "\$load")\$C_RESET"
  echo -e "\$C_LABELDNS Servers  : \$C_VALUE\$(_val "\$dns")\$C_RESET"
  echo -e "\$C_BORDER========================================\$C_RESET"
fi
$DASHBOARD_MARK
DASHBOARD_EOF
  say "✓ Penulisan selesai"
}
reload_terminal() {
  say "• Membersihkan layar dan memuat ulang shell agar perubahan terlihat"
  sleep 1
  clear || printf "\033[2J\033[H"
  if [[ $- == *i* ]]; then
    exec bash -l
  else
    say "Jalankan perintah ini untuk memuat ulang: source \"$BASHRC_FILE\""
  fi
}
say "=== Terminal Dashboard Installer (Mini Fastfetch) ==="
say "Langkah 1/5: Memeriksa dan membackup file (.bashrc)"
backup_once
say "Langkah 2/5: Membersihkan skrip lama bila ada"
cleanup_old_block
say "Langkah 3/5: Memasang dependensi fastfetch (mini) bila diperlukan"
install_fastfetch
say "Langkah 4/5: Mengatur tampilan User@Host"
ask_userhost
say "Langkah 5/5: Menulis skrip dashboard baru"
write_new_block
say "Selesai. Lokasi konfigurasi: $BASHRC_FILE"
reload_terminal
