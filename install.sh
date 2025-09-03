#!/bin/bash
set -euo pipefail

# Dashboard installer (final fix)
BACKUP_FILE="$HOME/.bashrc.backup"
BASHRC_FILE="$HOME/.bashrc"
MARK_START="# >>> CUSTOM TERMINAL DASHBOARD >>>"
MARK_END="# <<< CUSTOM TERMINAL DASHBOARD <<<"
STARTUP_FILES=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")

# Bersihkan semua block dashboard lama + pemanggilan neofetch/figlet di semua startup files
clean_old() {
  for f in "${STARTUP_FILES[@]}"; do
    if [[ -f "$f" ]]; then
      # hapus block marker lama
      sed -i "/$MARK_START/,/$MARK_END/d" "$f" || true
      # hapus pemanggilan neofetch / figlet yang standalone
      sed -i '/\<neofetch\>/d' "$f" || true
      sed -i '/\<figlet\>/d' "$f" || true
    fi
  done
}

install_deps_if_missing() {
  local pkgs=(jq lolcat neofetch figlet curl pv lsb-release)
  local need_update=0
  for cmd in "${pkgs[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      need_update=1
      break
    fi
  done
  if [[ $need_update -eq 1 ]]; then
    echo "🔧 Memeriksa & memasang dependensi (butuh root)..."
    apt update -y
    for cmd in "${pkgs[@]}"; do
      if ! command -v "$cmd" &>/dev/null; then
        apt install -y "$cmd"
      fi
    done
  fi
}

install_dashboard() {
  clear
  echo -e "\e[1;36m=== Terminal Dashboard Installer ===\e[0m"
  # cek root
  if [[ "$EUID" -ne 0 ]]; then
    echo -e "\e[1;31m⚠️ Harap jalankan script dengan sudo atau sebagai root.\e[0m"
    exit 1
  fi

  # backup .bashrc (sekali)
  if [[ ! -f "$BACKUP_FILE" ]]; then
    cp "$BASHRC_FILE" "$BACKUP_FILE"
    echo -e "\e[1;33m📦 Backup .bashrc disimpan di: $BACKUP_FILE\e[0m"
  else
    echo -e "\e[1;33m📦 Backup .bashrc sudah ada: $BACKUP_FILE\e[0m"
  fi

  read -r -p "Masukkan hostname baru (kosongkan untuk skip): " newhost
  if [[ -n "$newhost" ]]; then
    hostnamectl set-hostname "$newhost"
    echo -e "\e[1;32m✅ Hostname diubah menjadi: $newhost\e[0m"
  fi

  # cek internet
  if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    echo -e "\e[1;31m⚠️ Tidak ada koneksi internet. Periksa jaringan.\e[0m"
    exit 1
  fi

  install_deps_if_missing

  # bersihkan pemanggilan lama
  clean_old

  # tambahkan block baru ke ~/.bashrc (gunakan single-quoted heredoc -> tulis literal)
  cat >> "$BASHRC_FILE" <<'EOF'
# >>> CUSTOM TERMINAL DASHBOARD >>>
# Hanya jalankan untuk interactive shells
case "$-" in
  *i*) ;;    # interactive
  *) return ;;
esac

# Bersihkan layar dan tampilkan neofetch satu kali
clear

# Panggil neofetch satu kali (disable field yang panjang agar logo tidak terganggu)
neofetch --ascii_distro ubuntu --ascii_colors 1 2 3 4 5 6 \
  --disable uptime packages shell resolution de wm theme icons terminal cpu gpu memory

# Judul user@host
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

gpuinfo=$(lspci | grep -i 'vga\|3d\|display' | cut -d ':' -f3 | xargs 2>/dev/null)
[[ -z "$gpuinfo" ]] && gpuinfo="Tidak terdeteksi"
echo -e "🎮 GPU Info     : $gpuinfo" | lolcat

echo -e "💾 RAM Total    : $(free -h | awk '/^Mem:/ {print $2}')" | lolcat
echo -e "📁 Disk Used    : $(df -h / | awk '$NF=="/" {printf "%s of %s", $3, $2}')" | lolcat
echo -e "⚙️ Load Average : $(uptime | awk -F'load average:' '{print $2}' | xargs)" | lolcat
echo -e "🌐 DNS Servers  : $(awk '/^nameserver/ {printf "%s ", $2}' /etc/resolv.conf | xargs)" | lolcat

quote=$(curl -sS https://api.quotable.io/random 2>/dev/null | jq -r '.content' 2>/dev/null || true)
[[ -z "$quote" ]] && quote="Tetap semangat dan jangan berhenti belajar."
echo -e "💡 Quote        : \"$quote\"" | lolcat
echo "==========================================" | lolcat
echo "===== terminal dashboard by aka =====" | lolcat
# <<< CUSTOM TERMINAL DASHBOARD <<<
EOF

  echo -e "\n\e[1;32m✅ Dashboard berhasil dipasang ke: $BASHRC_FILE\e[0m"
  echo -e "\e[1;36m🔄 Restarting shell (exec bash) agar perubahan aktif sekarang...\e[0m"
  exec bash
}

uninstall_dashboard() {
  clear
  echo -e "\e[1;31m=== Uninstall Terminal Dashboard ===\e[0m"

  if [[ -f "$BACKUP_FILE" ]]; then
    cp -f "$BACKUP_FILE" "$BASHRC_FILE"
    echo -e "\e[1;32m✅ Restore .bashrc dari backup: $BACKUP_FILE\e[0m"
  else
    # jika backup tidak ada, hapus block custom dari semua startup files
    for f in "${STARTUP_FILES[@]}"; do
      if [[ -f "$f" ]]; then
        sed -i "/$MARK_START/,/$MARK_END/d" "$f" || true
      fi
    done
    echo -e "\e[1;33m⚠️ Backup tidak ditemukan, block custom dihapus dari startup files.\e[0m"
  fi

  echo -e "\e[1;36mℹ️ Hostname tidak diubah oleh uninstaller.\e[0m"
  echo -e "\e[1;32m🔄 Restarting shell (exec bash)...\e[0m"
  exec bash
}

# ---- main menu ----
clear
cat <<'MENU'
╔══════════════════════════════════════════════════════╗
║                ⚡ Dashboard Manager                   ║
╚══════════════════════════════════════════════════════╝

1) Install Dashboard
2) Uninstall Dashboard (restore .bashrc jika ada backup)
3) Exit
MENU

read -r -p "Pilih opsi [1/2/3]: " opsi
case "$opsi" in
  1) install_dashboard ;;
  2) uninstall_dashboard ;;
  3) echo "Keluar..."; exit 0 ;;
  *) echo "Pilihan tidak valid."; exit 1 ;;
esac
