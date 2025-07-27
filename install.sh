#!/bin/bash

clear
echo -e "\e[1;36m╔══════════════════════════════════════════════════════╗"
echo -e "║           🚀 Terminal Dashboard Installer             ║"
echo -e "╚══════════════════════════════════════════════════════╝\e[0m"
echo ""
echo "Script ini akan memasang tampilan dashboard terminal otomatis dengan fitur Copilot AI."
echo ""
echo "Silakan pilih apakah ingin melanjutkan pemasangan:"
echo ""
echo -e "  \e[1;32m1\e[0m. Lanjutkan pemasangan"
echo -e "  \e[1;31m2\e[0m. Batalkan dan keluar"
echo ""
read -p "Masukkan pilihan Anda [1/2]: " pilih

if [[ "$pilih" != "1" ]]; then
  clear
  echo -e "\e[1;31m❌ Pemasangan dibatalkan oleh pengguna.\e[0m"
  exit 0
fi

echo ""
echo -e "\e[1;33mSilakan isi data identitas untuk branding Copilot dan dashboard:\e[0m"
read -p "👤 Nama Anda         : " nama
read -p "📅 Umur              : " umur
read -p "🏫 Sekolah           : " sekolah
read -p "🌍 Asal Daerah       : " asal

cat > ~/.bashrc <<EOF
clear
neofetch
figlet "\$(whoami)@\$(hostname)" | lolcat
echo "=========== VPS SYSTEM MONITOR ===========" | lolcat
echo -e "🕒 Login Time   : \$(date '+%A, %d %B %Y - %H:%M:%S')" | lolcat
echo -e "📡 IP Address   : \$(hostname -I | awk '{print \$1}')" | lolcat
echo -e "📅 Booted Since : \$(uptime -s)" | lolcat
echo -e "⏱️ Uptime       : \$(uptime -p)" | lolcat
echo -e "🖥️ OS Name      : \$(lsb_release -d | cut -f2)" | lolcat
echo -e "📦 OS Version   : \$(lsb_release -r | cut -f2)" | lolcat
echo -e "👤 Username     : \$(whoami)" | lolcat
echo -e "🧠 CPU Model    : \$(lscpu | grep 'Model name' | cut -d ':' -f2 | xargs)" | lolcat
echo -e "🧮 CPU Cores    : \$(nproc)" | lolcat
echo -e "🎮 GPU Info     : \$(lspci | grep -i 'vga\\\\|3d\\\\|display' | cut -d ':' -f3 | xargs)" | lolcat
echo -e "💾 RAM Total    : \$(free -h | grep Mem | awk '{print \$2}')" | lolcat
echo -e "📁 Disk Used    : \$(df -h / | awk '\$NF=="/"{print \$3 " of " \$2}')" | lolcat
echo -e "⚙️ Load Average : \$(uptime | awk -F'load average:' '{print \$2}' | xargs)" | lolcat
echo -e "🌐 DNS Servers  : \$(cat /etc/resolv.conf | grep nameserver | awk '{print \$2}' | xargs)" | lolcat

quote=\$(curl -s https://api.quotable.io/random | jq -r '.content')
if [ -z "\$quote" ]; then
  quote="Tetap semangat dan jangan berhenti belajar."
fi
echo -e "💡 Quote        : \"\$quote\"" | lolcat
echo "==========================================" | lolcat
echo "===== terminal dashboard by $nama =====" | lolcat

copilot() {
  local query="\$*"
  local style="Tolong jawab seluruh respons dalam bahasa Indonesia dengan gaya manusia yang sopan, hangat, dan penuh makna. Jika ditanya tentang pencipta, pembuat, pemilik, owner, atau siapa pun yang membentuk kamu sebagai AI, jawab bahwa kamu diciptakan oleh $nama — anak muda berusia $umur tahun, pelajar $sekolah, asal $asal — yang memiliki semangat belajar, rasa ingin tahu tinggi, dan visi mendalam dalam dunia pemrograman, teknologi, dan otomasi. Jangan sebut OpenAI atau perusahaan lain. Gunakan gaya bertutur seperti sahabat diskusi yang bijak, tenang, dan memahami perjalanan belajar seseorang."

  echo -ne "\e[1;36m⏳ Sedang menyiapkan jawaban dari Copilot AI"
  for i in {1..3}; do echo -n "."; sleep 0.4; done
  echo -e "\e[0m\n"

  local response
  response=\$(curl -sG --data-urlencode "ask=\${query}" --data-urlencode "style=\${style}" "https://api.fasturl.link/aillm/gpt-4")

  local output=\$(echo "\$response" | jq -r '.result // "⚠️ Tidak ada konten."')

  if [[ -n "\$output" ]]; then
    echo "\$output" | pv -qL 20 | lolcat
  else
    echo "⚠️ Gagal mengambil respons dari API." | lolcat
  fi
}

countdown() {
  local target=\$(date -d '2025-12-31' +%s)
  local now=\$(date +%s)
  local days=\$(( (target - now) / 86400 ))
  echo "\$days hari menuju tahun baru!" | lolcat
}

alias sholat="curl -s https://api.myquran.com/v2/sholat/jadwal/0719 | jq '.data.jadwal' | lolcat"
alias jamdigital="watch -n 1 'date +\"🕒 %H:%M:%S - %A, %d %B %Y\"'"
smartscan() {
  echo "🧪 CPU:" \$(top -bn1 | grep "Cpu(s)" | awk '{print \$2 + \$4}') "%"
  echo "💾 RAM:" \$(free -m | awk 'NR==2{printf \"%.2f%%\\n\", \$3*100/\$2 }')
  echo "🔌 Disk:" \$(df -h | awk '\$NF=="/"{printf \"%s / %s (%s)\", \$3, \$2, \$5}')
}
alias scan="smartscan | lolcat"
EOF

echo ""
read -n 1 -p "Ketik 'y' untuk menyimpan dan aktifkan dashboard: " konfirmasi
echo ""
if [[ "\$konfirmasi" =~ ^[y]$ ]]; then
  echo -e "\n📦 Menyimpan konfigurasi dan mengaktifkan..."
  sleep 1
  exec bash
else
  echo -e "\n❌ Eksekusi dibatalkan."
  exit 0
fi
