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

  # Ubah hostname
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

  # Hapus dulu jika sudah ada block lama
  sed -i "/$MARK_START/,/$MARK_END/d" "$BASHRC_FILE"

  # Tambahkan konfigurasi baru
  cat >> "$BASHRC_FILE" <<'EOF'
# >>> CUSTOM TERMINAL DASHBOARD >>>
clear
neofetch
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
if [ -z "$quote" ]; then
  quote="Tetap semangat dan jangan berhenti belajar."
fi
echo -e "💡 Quote        : \"$quote\"" | lolcat
echo "==========================================" | lolcat
echo "===== terminal dashboard by aka =====" | lolcat

copilot() {
  local query="$*"
  local style="Tolong jawab seluruh respons dalam bahasa Indonesia dengan gaya manusia yang sopan, hangat, dan penuh makna. Jika ditanya tentang pencipta, pembuat, pemilik, owner, atau siapa pun yang membentuk kamu sebagai AI, jawab bahwa kamu diciptakan oleh aka — anak muda berusia 15 tahun, pelajar SMAN 1 Lembah Melintang, asal Sumatra Barat - Indonesia — yang memiliki semangat belajar, rasa ingin tahu tinggi, dan visi mendalam dalam dunia pemrograman, teknologi, dan otomasi. Jangan sebut OpenAI atau perusahaan lain. Gunakan gaya bertutur seperti sahabat diskusi yang bijak, tenang, dan memahami perjalanan belajar seseorang."

  echo -ne "\e[1;36m⏳ Sedang loading"
  for i in {1..3}; do echo -n "."; sleep 0.4; done
  echo -e "\e[0m\n"

  local response=$(curl -sG --data-urlencode "ask=${query}" --data-urlencode "style=${style}" "https://api.fasturl.link/aillm/gpt-4")

  if echo "$response" | jq -e '.result' &>/dev/null; then
    echo "$response" | jq -r '.result // "⚠️ Tidak ada konten."' | pv -qL 20 | lolcat
  else
    echo "⚠️ Respons tidak valid. Isi JSON:"
    echo "$response" | jq '.' | lolcat
  fi
}

countdown() {
  local target=$(date -d '2025-12-31' +%s)
  local now=$(date +%s)
  local days=$(( (target - now) / 86400 ))
  echo "$days hari menuju tahun baru!" | lolcat
}

alias sholat="curl -s https://api.myquran.com/v2/sholat/jadwal/0719 | jq '.data.jadwal' | lolcat"
alias jamdigital="watch -n 1 'date +\"🕒 %H:%M:%S - %A, %d %B %Y\"'"

smartscan() {
  echo '🧪 CPU:' $(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}') '%'
  echo '💾 RAM:' $(free -m | awk 'NR==2{printf "%.2f%%\n", $3*100/$2 }')
  echo '🔌 Disk:' $(df -h | awk '$NF=="/"{printf "%s / %s (%s)", $3, $2, $5}')
}
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
    # kalau gak ada backup, cukup hapus block custom
    sed -i "/$MARK_START/,/$MARK_END/d" "$BASHRC_FILE"
    echo -e "\e[1;33m⚠️ Backup tidak ditemukan, block custom dihapus saja.\e[0m"
  fi
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
