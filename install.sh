#!/bin/bash

set -e

BACKUP_FILE="$HOME/.bashrc.backup"
BASHRC_FILE="$HOME/.bashrc"
MARK_START="# >>> CUSTOM TERMINAL DASHBOARD >>>"
MARK_END="# <<< CUSTOM TERMINAL DASHBOARD <<<"

install_dashboard() {
  clear
  echo -e "\e[1;36m╔══════════════════════════════════════════════════════╗"
  echo -e "║           🚀 Terminal Dashboard Installer             ║"
  echo -e "╚══════════════════════════════════════════════════════╝\e[0m"
  echo ""

  # Pastikan script dijalankan sebagai root
  if [[ "$EUID" -ne 0 ]]; then
    echo -e "\e[1;31m⚠️ Harap jalankan script dengan sudo atau sebagai root.\e[0m"
    exit 1
  fi

  # Backup .bashrc sekali aja
  if [[ ! -f "$BACKUP_FILE" ]]; then
    cp "$BASHRC_FILE" "$BACKUP_FILE"
    echo -e "\e[1;33m📦 Backup .bashrc disimpan di $BACKUP_FILE\e[0m"
  fi

  # Ubah hostname (hanya saat install)
  read -p "Masukkan hostname baru (contoh: AkaServer): " newhost
  if [[ -n "$newhost" ]]; then
    hostnamectl set-hostname "$newhost"
    echo -e "\e[1;32m✅ Hostname berhasil diubah menjadi: $newhost\e[0m"
  fi

  # Cek koneksi internet
  if ! ping -c 1 google.com &> /dev/null; then
    echo -e "\e[1;31m⚠️ Tidak ada koneksi internet. Silakan cek jaringan Anda.\e[0m"
    exit 1
  fi

  # Cek dan instal dependensi
  for cmd in jq lolcat neofetch figlet curl pv lsb-release; do
    if ! command -v $cmd &> /dev/null; then
      echo "🔧 Menginstal $cmd ..."
      apt update -y &> /dev/null
      apt install -y $cmd &> /dev/null
    fi
  done

  # Hapus block lama kalau ada
  sed -i "/$MARK_START/,/$MARK_END/d" "$BASHRC_FILE"

  # Tambahkan konfigurasi baru (fixed neofetch)
  cat >> "$BASHRC_FILE" <<'EOF'
# >>> CUSTOM TERMINAL DASHBOARD >>>
clear
neofetch --ascii_distro ubuntu --ascii_colors 1 2 3 4 5 6 \
 --disable uptime packages shell resolution de wm theme icons terminal cpu gpu memory

figlet "$(whoami)@$(hostname)" | lolcat
echo "=========== VPS SYSTEM MONITOR ===========" | lolcat
echo -e "🕒 Login Time   : $(date '+%A, %d %B %Y - %H:%M:%S')" | lolcat
echo -e "📡 IP Address   : $(hostname -I | awk '{print $1}')" | lolcat
echo -e "📅 Booted Since : $(uptime -s)" | lolcat
echo -e "⏱️ Uptime       : $(uptime -p)" | lolcat
echo -e "🖥️ OS Name      : $(lsb_release -d | cut -f2)" | lolcat
echo -e "📦 OS Version   : $(lsb_release -r | cut -f2)" | lolcat
echo -e "👤 Username     : $(whoami)" | lolcat
echo -e "🧠 CPU Model    : $(lscpu | grep 'Model name' | cut -d ':' -f2 | xargs)" | lolcat
echo -e "🧮 CPU Cores    : $(nproc)" | lolcat
gpuinfo=$(lspci | grep -i 'vga\|3d\|display' | cut -d ':' -f3 | xargs)
[[ -z "$gpuinfo" ]] && gpuinfo="Tidak terdeteksi"
echo -e "🎮 GPU Info     : $gpuinfo" | lolcat
echo -e "💾 RAM Total    : $(free -h | grep Mem | awk '{print $2}')" | lolcat
echo -e "📁 Disk Used    : $(df -h / | awk '$NF=="/"{print $3 " of " $2}')" | lolcat
echo -e "⚙️ Load Average : $(uptime | awk -F'load average:' '{print $2}' | xargs)" | lolcat
echo -e "🌐 DNS Servers  : $(grep nameserver /etc/resolv.conf | awk '{print $2}' | xargs)" | lolcat

quote=$(curl -s https://api.quotable.io/random | jq -r '.content')
[[ -z "$quote" ]] && quote="Tetap semangat dan jangan berhenti belajar."
echo -e "💡 Quote        : \"$quote\"" | lolcat
echo "==========================================" | lolcat
echo "===== terminal dashboard by aka =====" | lolcat

# Tambahan fungsi
copilot() { ... }   # (fungsi tetap sama)
countdown() { ... } # (fungsi tetap sama)
smartscan() { ... } # (fungsi tetap sama)
alias scan="smartscan | lolcat"
# <<< CUSTOM TERMINAL DASHBOARD <<<
EOF

  echo -e "\e[1;32m✅ Dashboard berhasil di-install! Silakan buka ulang terminal.\e[0m"
}

uninstall_dashboard() {
  clear
  echo -e "\e[1;31m╔══════════════════════════════════════════════════════╗"
  echo -e "║           ❌ Terminal Dashboard Uninstaller           ║"
  echo -e "╚══════════════════════════════════════════════════════╝\e[0m"
  echo ""

  if [[ -f "$BACKUP_FILE" ]]; then
    cp "$BACKUP_FILE" "$BASHRC_FILE"
    echo -e "\e[1;32m✅ Dashboard dihapus dan .bashrc dipulihkan dari backup.\e[0m"
  else
    sed -i "/$MARK_START/,/$MARK_END/d" "$BASHRC_FILE"
    echo -e "\e[1;33m⚠️ Backup tidak ditemukan, block custom dihapus saja.\e[0m"
  fi

  echo -e "\e[1;36mℹ️ Hostname tetap seperti terakhir (tidak diubah).\e[0m"
}

# Menu utama
clear
echo -e "\e[1;36m╔══════════════════════════════════════════════════════╗"
echo -e "║                ⚡ Dashboard Manager                   ║"
echo -e "╚══════════════════════════════════════════════════════╝\e[0m"
echo ""
echo "1. Install Dashboard"
echo "2. Uninstall Dashboard"
echo "3. Keluar"
echo ""
read -p "Pilih opsi [1/2/3]: " opsi

case "$opsi" in
  1) install_dashboard ;;
  2) uninstall_dashboard ;;
  3) echo "Keluar..."; exit 0 ;;
  *) echo "Pilihan tidak valid." ;;
esac
