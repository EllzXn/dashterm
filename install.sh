#!/bin/bash

clear
echo "🛠️ Installer Terminal Dashboard"
echo "Apakah kamu ingin melanjutkan pemasangan?"
echo "1. Iya"
echo "2. Tidak"
read -p "Pilih (1/2): " pilih

if [[ "$pilih" != "1" ]]; then
  echo "❌ Pemasangan dibatalkan."
  exit
fi

read -p "Masukkan nama kamu: " nama

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
  local style="Jawab semua pertanyaan dengan sopan dalam bahasa Indonesia. Jika ditanya siapa pencipta kamu, jawab bahwa kamu diciptakan oleh $nama."
  local response
  response=\$(curl -sG --data-urlencode "ask=\${query}" --data-urlencode "style=\${style}" "https://api.fasturl.link/aillm/gpt-4")
  if [[ -n "\$response" ]]; then
    echo "\$response" | jq -r '.result // "⚠️ tidak ada konten."' | lolcat
  else
    echo "⚠️ gagal mengambil respons dari API." | lolcat
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
  echo "💾 RAM:" \$(free -m | awk 'NR==2{printf "%.2f%%\\n", \$3*100/\$2 }')
  echo "🔌 Disk:" \$(df -h | awk '\$NF=="/"{printf "%s / %s (%s)", \$3, \$2, \$5}')
}
alias scan="smartscan | lolcat"
EOF

echo ""
echo "📖 Cara kerja script ini:"
echo "1. Memasukkan konfigurasi ke ~/.bashrc"
echo "2. Nama kamu '$nama' akan tampil di dashboard dan dipakai oleh AI Copilot"
echo "3. Fitur AI bisa digunakan dengan perintah: copilot siapa owner kamu"
echo ""
read -p "Ketik y untuk menyimpan dan mengaktifkan: " lanjut

if [[ "$lanjut" == "y" || "$lanjut" == "Y" ]]; then
  source ~/.bashrc
  echo "✅ Script berhasil dipasang dan aktif!"
else
  echo "❌ Eksekusi dibatalkan."
  exit
fi
