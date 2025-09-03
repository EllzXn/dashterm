#!/bin/bash
set -euo pipefail

# Dashboard installer (improved version)
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
      sed -i "/$MARK_START/,/$MARK_END/d" "$f" 2>/dev/null || true
      # hapus pemanggilan neofetch / figlet yang standalone
      sed -i '/^\s*neofetch\s*$/d' "$f" 2>/dev/null || true
      sed -i '/^\s*figlet\s/d' "$f" 2>/dev/null || true
    fi
  done
}

# Deteksi package manager dan install dependencies
install_deps_if_missing() {
  local pkgs=(jq lolcat neofetch figlet curl pv)
  local need_update=0
  
  # Cek apakah ada package yang belum terinstall
  for cmd in "${pkgs[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      need_update=1
      break
    fi
  done
  
  if [[ $need_update -eq 1 ]]; then
    echo "🔧 Memeriksa & memasang dependensi (butuh root)..."
    
    # Deteksi distro dan package manager
    if command -v apt &>/dev/null; then
      # Debian/Ubuntu
      apt update -y
      apt install -y jq lolcat neofetch figlet curl pv lsb-release
    elif command -v yum &>/dev/null; then
      # RHEL/CentOS/Fedora (older)
      yum update -y
      yum install -y jq figlet curl pv redhat-lsb-core
      # Install neofetch dan lolcat dari EPEL atau manual
      yum install -y epel-release || true
      yum install -y neofetch || echo "⚠️ neofetch perlu diinstall manual"
      yum install -y lolcat || pip3 install lolcat 2>/dev/null || echo "⚠️ lolcat perlu diinstall manual"
    elif command -v dnf &>/dev/null; then
      # Fedora (newer)
      dnf update -y
      dnf install -y jq neofetch figlet curl pv redhat-lsb-core
      dnf install -y lolcat || pip3 install lolcat 2>/dev/null || echo "⚠️ lolcat perlu diinstall manual"
    elif command -v pacman &>/dev/null; then
      # Arch Linux
      pacman -Sy --noconfirm jq neofetch figlet curl pv lsb-release
      pacman -S --noconfirm lolcat || pip3 install lolcat 2>/dev/null || echo "⚠️ lolcat perlu diinstall manual"
    else
      echo "⚠️ Package manager tidak dikenali. Pastikan dependencies sudah terinstall:"
      echo "   jq, lolcat, neofetch, figlet, curl, pv, lsb-release"
    fi
  fi
}

# Deteksi informasi sistem dengan fallback
get_os_info() {
  local os_name="Unknown"
  local os_version="Unknown"
  
  if command -v lsb_release &>/dev/null; then
    os_name=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")
    os_version=$(lsb_release -r 2>/dev/null | cut -f2 || echo "Unknown")
  elif [[ -f /etc/os-release ]]; then
    source /etc/os-release
    os_name="${PRETTY_NAME:-$NAME}"
    os_version="${VERSION_ID:-Unknown}"
  elif [[ -f /etc/redhat-release ]]; then
    os_name=$(cat /etc/redhat-release)
    os_version="Unknown"
  elif [[ -f /etc/debian_version ]]; then
    os_name="Debian"
    os_version=$(cat /etc/debian_version)
  fi
  
  echo "$os_name|$os_version"
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
    if command -v hostnamectl &>/dev/null; then
      hostnamectl set-hostname "$newhost"
    else
      echo "$newhost" > /etc/hostname
      hostname "$newhost"
    fi
    echo -e "\e[1;32m✅ Hostname diubah menjadi: $newhost\e[0m"
  fi

  # cek internet
  if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null && ! ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
    echo -e "\e[1;31m⚠️ Tidak ada koneksi internet. Periksa jaringan.\e[0m"
    exit 1
  fi

  install_deps_if_missing

  # bersihkan pemanggilan lama
  clean_old

  # tambahkan block baru ke ~/.bashrc
  cat >> "$BASHRC_FILE" <<'EOF'
# >>> CUSTOM TERMINAL DASHBOARD >>>
# Hanya jalankan untuk interactive shells
case "$-" in
  *i*) ;;    # interactive
  *) return ;;
esac

# Flag untuk mencegah pengulangan
if [[ -z "${DASHBOARD_LOADED:-}" ]]; then
  export DASHBOARD_LOADED=1
  
  # Bersihkan layar dan tampilkan dashboard
  clear

  # Function untuk mendapatkan info OS dengan fallback
  get_os_info() {
    local os_name="Unknown Linux"
    local os_version="Unknown"
    
    if command -v lsb_release &>/dev/null; then
      os_name=$(lsb_release -d 2>/dev/null | cut -f2- || echo "Unknown Linux")
      os_version=$(lsb_release -r 2>/dev/null | cut -f2 || echo "Unknown")
    elif [[ -f /etc/os-release ]]; then
      source /etc/os-release 2>/dev/null
      os_name="${PRETTY_NAME:-${NAME:-Unknown Linux}}"
      os_version="${VERSION_ID:-Unknown}"
    elif [[ -f /etc/redhat-release ]]; then
      os_name=$(cat /etc/redhat-release 2>/dev/null || echo "Red Hat Linux")
      os_version="Unknown"
    elif [[ -f /etc/debian_version ]]; then
      os_name="Debian GNU/Linux"
      os_version=$(cat /etc/debian_version 2>/dev/null || echo "Unknown")
    fi
    
    echo "$os_name|$os_version"
  }

  # Function untuk mendapatkan info CPU
  get_cpu_info() {
    if [[ -f /proc/cpuinfo ]]; then
      grep '^model name' /proc/cpuinfo | head -n1 | cut -d':' -f2 | xargs 2>/dev/null || echo "Unknown CPU"
    else
      echo "Unknown CPU"
    fi
  }

  # Function untuk mendapatkan info GPU
  get_gpu_info() {
    if command -v lspci &>/dev/null; then
      local gpu=$(lspci 2>/dev/null | grep -i 'vga\|3d\|display' | head -n1 | cut -d':' -f3 | xargs 2>/dev/null)
      [[ -n "$gpu" ]] && echo "$gpu" || echo "Tidak terdeteksi"
    else
      echo "Tidak terdeteksi"
    fi
  }

  # Function untuk mendapatkan DNS servers
  get_dns_servers() {
    if [[ -f /etc/resolv.conf ]]; then
      awk '/^nameserver/ {printf "%s ", $2}' /etc/resolv.conf 2>/dev/null | xargs || echo "Unknown"
    else
      echo "Unknown"
    fi
  }

  # Function untuk mendapatkan IP address
  get_ip_address() {
    # Coba berbagai metode untuk mendapatkan IP
    local ip=""
    if command -v hostname &>/dev/null; then
      ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    
    if [[ -z "$ip" ]] && command -v ip &>/dev/null; then
      ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -n1)
    fi
    
    if [[ -z "$ip" ]]; then
      ip=$(ifconfig 2>/dev/null | grep -oP 'inet \K192\.168\.\d+\.\d+' | head -n1)
    fi
    
    [[ -n "$ip" ]] && echo "$ip" || echo "Unknown"
  }

  # Tampilkan neofetch jika tersedia (dengan fallback ASCII art)
  if command -v neofetch &>/dev/null; then
    # Deteksi distro untuk logo yang tepat
    local distro_id=""
    if [[ -f /etc/os-release ]]; then
      distro_id=$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"')
    fi
    
    case "$distro_id" in
      ubuntu) neofetch --ascii_distro ubuntu ;;
      debian) neofetch --ascii_distro debian ;;
      centos|rhel) neofetch --ascii_distro centos ;;
      fedora) neofetch --ascii_distro fedora ;;
      arch) neofetch --ascii_distro arch ;;
      *) neofetch --ascii_distro linux ;;
    esac
  else
    # Fallback ASCII art jika neofetch tidak ada
    echo "
  _     _                  
 | |   (_)_ __  _   ___  __
 | |   | | '_ \| | | \ \/ /
 | |___| | | | | |_| |>  < 
 |_____|_|_| |_|\__,_/_/\_\ 
    "
  fi

  # Judul user@host
  if command -v figlet &>/dev/null && command -v lolcat &>/dev/null; then
    figlet "$(whoami)@$(hostname)" | lolcat
  else
    echo "=== $(whoami)@$(hostname) ==="
  fi

  # Informasi sistem
  local info_command="echo"
  if command -v lolcat &>/dev/null; then
    info_command="lolcat"
  fi

  echo "=========== VPS SYSTEM MONITOR ===========" | $info_command
  echo -e "🕒 Login Time   : $(date '+%A, %d %B %Y - %H:%M:%S')" | $info_command
  echo -e "📡 IP Address   : $(get_ip_address)" | $info_command
  
  if command -v uptime &>/dev/null; then
    echo -e "📅 Booted Since : $(uptime -s 2>/dev/null || echo 'Unknown')" | $info_command
    echo -e "⏱️ Uptime       : $(uptime -p 2>/dev/null || uptime 2>/dev/null | cut -d',' -f1 | cut -d' ' -f3-)" | $info_command
  fi
  
  # OS Info
  local os_info=$(get_os_info)
  echo -e "🖥️ OS Name      : ${os_info%|*}" | $info_command
  echo -e "📦 OS Version   : ${os_info#*|}" | $info_command
  
  echo -e "👤 Username     : $(whoami)" | $info_command
  echo -e "🧠 CPU Model    : $(get_cpu_info)" | $info_command
  echo -e "🧮 CPU Cores    : $(nproc 2>/dev/null || echo 'Unknown')" | $info_command
  echo -e "🎮 GPU Info     : $(get_gpu_info)" | $info_command
  
  if command -v free &>/dev/null; then
    echo -e "💾 RAM Total    : $(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo 'Unknown')" | $info_command
  fi
  
  if command -v df &>/dev/null; then
    echo -e "📁 Disk Used    : $(df -h / 2>/dev/null | awk '$NF=="/" {printf "%s of %s", $3, $2}' || echo 'Unknown')" | $info_command
  fi
  
  if command -v uptime &>/dev/null; then
    echo -e "⚙️ Load Average : $(uptime 2>/dev/null | awk -F'load average:' '{print $2}' | xargs || echo 'Unknown')" | $info_command
  fi
  
  echo -e "🌐 DNS Servers  : $(get_dns_servers)" | $info_command

  # Quote dengan fallback
  local quote=""
  if command -v curl &>/dev/null && command -v jq &>/dev/null; then
    quote=$(timeout 3 curl -sS https://api.quotable.io/random 2>/dev/null | jq -r '.content' 2>/dev/null || true)
  fi
  [[ -z "$quote" ]] && quote="Tetap semangat dan jangan berhenti belajar!"
  echo -e "💡 Quote        : \"$quote\"" | $info_command
  
  echo "==========================================" | $info_command
  echo "===== terminal dashboard by aka =====" | $info_command
fi
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
        sed -i "/$MARK_START/,/$MARK_END/d" "$f" 2>/dev/null || true
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
