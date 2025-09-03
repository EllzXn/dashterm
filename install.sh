#!/bin/bash
set -euo pipefail

# Terminal Dashboard Installer - Complete Recode
# Prevents logo duplication and ensures accurate data

BACKUP_FILE="$HOME/.bashrc.backup"
BASHRC_FILE="$HOME/.bashrc"
PROFILE_FILE="$HOME/.profile"
BASH_PROFILE_FILE="$HOME/.bash_profile"
DASHBOARD_MARK="### TERMINAL_DASHBOARD_ACTIVE ###"

# Colors for output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Complete cleanup of all dashboard traces
cleanup_all_traces() {
    log_info "Membersihkan semua jejak dashboard lama..."
    
    # Files to clean
    local files=("$BASHRC_FILE" "$PROFILE_FILE" "$BASH_PROFILE_FILE")
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            # Remove dashboard marker lines
            sed -i "/$DASHBOARD_MARK/d" "$file" 2>/dev/null || true
            # Remove neofetch calls
            sed -i '/^[[:space:]]*neofetch/d' "$file" 2>/dev/null || true
            # Remove figlet calls with username/hostname
            sed -i '/^[[:space:]]*figlet.*whoami.*hostname/d' "$file" 2>/dev/null || true
            # Remove custom dashboard blocks
            sed -i '/# >>> CUSTOM TERMINAL DASHBOARD >>>/,/# <<< CUSTOM TERMINAL DASHBOARD <<</d' "$file" 2>/dev/null || true
        fi
    done
    
    # Remove environment variables
    unset DASHBOARD_SHOWN 2>/dev/null || true
    unset DASHBOARD_LOADED 2>/dev/null || true
}

# Detect package manager and install dependencies
install_dependencies() {
    log_info "Checking dan menginstall dependencies..."
    
    local deps_needed=()
    local commands=("curl" "jq" "figlet" "lolcat" "neofetch")
    
    # Check what's missing
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            deps_needed+=("$cmd")
        fi
    done
    
    if [[ ${#deps_needed[@]} -eq 0 ]]; then
        log_success "Semua dependencies sudah terinstall"
        return 0
    fi
    
    log_info "Installing: ${deps_needed[*]}"
    
    # Detect OS and package manager
    if command -v apt-get &>/dev/null; then
        # Debian/Ubuntu
        apt-get update -qq
        apt-get install -y curl jq figlet ruby-full neofetch
        gem install lolcat 2>/dev/null || {
            apt-get install -y lolcat 2>/dev/null || log_warning "lolcat gagal diinstall"
        }
    elif command -v yum &>/dev/null; then
        # RHEL/CentOS (old)
        yum install -y epel-release
        yum install -y curl jq figlet neofetch
        gem install lolcat 2>/dev/null || log_warning "lolcat perlu diinstall manual"
    elif command -v dnf &>/dev/null; then
        # Fedora/RHEL 8+
        dnf install -y curl jq figlet neofetch ruby rubygems
        gem install lolcat 2>/dev/null || log_warning "lolcat perlu diinstall manual"
    elif command -v pacman &>/dev/null; then
        # Arch Linux
        pacman -Sy --noconfirm curl jq figlet neofetch ruby
        gem install lolcat 2>/dev/null || log_warning "lolcat perlu diinstall manual"
    elif command -v zypper &>/dev/null; then
        # openSUSE
        zypper install -y curl jq figlet neofetch ruby
        gem install lolcat 2>/dev/null || log_warning "lolcat perlu diinstall manual"
    else
        log_error "Package manager tidak dikenali!"
        log_info "Silakan install manual: curl, jq, figlet, neofetch, lolcat"
        return 1
    fi
    
    log_success "Dependencies berhasil diinstall"
}

# Get system information with proper fallbacks
get_system_info() {
    local info_type="$1"
    
    case "$info_type" in
        "os_name")
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                echo "${PRETTY_NAME:-${NAME:-Unknown}}"
            elif command -v lsb_release &>/dev/null; then
                lsb_release -d 2>/dev/null | cut -f2- || echo "Unknown"
            elif [[ -f /etc/redhat-release ]]; then
                cat /etc/redhat-release
            elif [[ -f /etc/debian_version ]]; then
                echo "Debian $(cat /etc/debian_version)"
            else
                uname -s || echo "Unknown"
            fi
            ;;
        "os_version")
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                echo "${VERSION_ID:-${VERSION:-Unknown}}"
            elif command -v lsb_release &>/dev/null; then
                lsb_release -r 2>/dev/null | cut -f2 || echo "Unknown"
            else
                uname -r || echo "Unknown"
            fi
            ;;
        "ip_address")
            # Try multiple methods to get IP
            local ip=""
            ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1) ||
            ip=$(hostname -I 2>/dev/null | awk '{print $1}') ||
            ip=$(ifconfig 2>/dev/null | grep -oE 'inet [0-9.]+' | grep -v '127.0.0.1' | head -1 | awk '{print $2}') ||
            ip="Unknown"
            echo "$ip"
            ;;
        "cpu_model")
            grep '^model name' /proc/cpuinfo 2>/dev/null | head -1 | cut -d':' -f2 | sed 's/^[ \t]*//' || echo "Unknown"
            ;;
        "gpu_info")
            if command -v lspci &>/dev/null; then
                lspci 2>/dev/null | grep -i 'vga\|3d\|display' | head -1 | cut -d':' -f3 | sed 's/^[ \t]*//' || echo "Tidak terdeteksi"
            else
                echo "Tidak terdeteksi"
            fi
            ;;
        "memory_total")
            free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "Unknown"
            ;;
        "disk_usage")
            df -h / 2>/dev/null | awk 'NR==2 {printf "%s / %s", $3, $2}' || echo "Unknown"
            ;;
        "load_average")
            uptime 2>/dev/null | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//' || echo "Unknown"
            ;;
        "boot_time")
            who -b 2>/dev/null | awk '{print $3, $4}' || uptime -s 2>/dev/null || echo "Unknown"
            ;;
        "uptime")
            uptime -p 2>/dev/null || uptime 2>/dev/null | awk '{print $3, $4}' | sed 's/,//' || echo "Unknown"
            ;;
        "dns_servers")
            awk '/^nameserver/ {printf "%s ", $2}' /etc/resolv.conf 2>/dev/null | xargs || echo "Unknown"
            ;;
    esac
}

# Get inspirational quote with timeout
get_quote() {
    local quote=""
    if command -v curl &>/dev/null && command -v jq &>/dev/null; then
        quote=$(timeout 3 curl -s "https://api.quotable.io/random" 2>/dev/null | jq -r '.content' 2>/dev/null || echo "")
    fi
    
    if [[ -z "$quote" ]]; then
        local quotes=(
            "Kesuksesan adalah hasil dari persiapan yang baik, kerja keras, dan belajar dari kegagalan."
            "Jangan takut untuk memulai. Hal-hal besar dimulai dari langkah kecil."
            "Pengetahuan adalah investasi terbaik yang bisa kamu miliki."
            "Coding bukan hanya tentang menulis kode, tapi tentang menyelesaikan masalah."
            "Kegagalan adalah guru terbaik dalam perjalanan menuju kesuksesan."
        )
        quote="${quotes[$((RANDOM % ${#quotes[@]}))]}"
    fi
    
    echo "$quote"
}

install_dashboard() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🚀 Installing Dashboard           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "Script harus dijalankan dengan sudo atau sebagai root"
        exit 1
    fi
    
    # Create backup
    if [[ ! -f "$BACKUP_FILE" ]]; then
        cp "$BASHRC_FILE" "$BACKUP_FILE" 2>/dev/null || touch "$BACKUP_FILE"
        log_success "Backup .bashrc dibuat: $BACKUP_FILE"
    fi
    
    # Set hostname if requested
    read -r -p "Masukkan hostname baru (Enter untuk skip): " new_hostname
    if [[ -n "$new_hostname" ]]; then
        if command -v hostnamectl &>/dev/null; then
            hostnamectl set-hostname "$new_hostname"
        else
            echo "$new_hostname" > /etc/hostname
            hostname "$new_hostname" 2>/dev/null || true
        fi
        log_success "Hostname diubah ke: $new_hostname"
    fi
    
    # Test internet connection
    if ! timeout 5 ping -c 1 8.8.8.8 &>/dev/null; then
        log_warning "Tidak ada koneksi internet, melewati instalasi online dependencies"
    else
        install_dependencies
    fi
    
    # Clean any existing dashboard
    cleanup_all_traces
    
    # Create the dashboard script
    log_info "Membuat dashboard script..."
    
    # Add dashboard to .bashrc with single execution control
    cat >> "$BASHRC_FILE" << 'DASHBOARD_EOF'
### TERMINAL_DASHBOARD_ACTIVE ###
# Terminal Dashboard - Single execution per session
if [[ $- == *i* ]] && [[ -z "${DASHBOARD_EXECUTED:-}" ]]; then
    export DASHBOARD_EXECUTED=1
    
    # Clear screen completely
    printf '\033[2J\033[H'
    
    # System info functions
    get_sys_info() {
        case "$1" in
            "os_name")
                if [[ -f /etc/os-release ]]; then
                    source /etc/os-release 2>/dev/null
                    echo "${PRETTY_NAME:-${NAME:-Unknown Linux}}"
                else
                    echo "Unknown Linux"
                fi
                ;;
            "os_version")
                if [[ -f /etc/os-release ]]; then
                    source /etc/os-release 2>/dev/null
                    echo "${VERSION_ID:-${VERSION:-Unknown}}"
                else
                    uname -r 2>/dev/null || echo "Unknown"
                fi
                ;;
            "ip_addr")
                ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1 || \
                hostname -I 2>/dev/null | awk '{print $1}' || \
                echo "Unknown"
                ;;
            "cpu_model")
                grep '^model name' /proc/cpuinfo 2>/dev/null | head -1 | cut -d':' -f2 | xargs || echo "Unknown CPU"
                ;;
            "gpu_info")
                lspci 2>/dev/null | grep -i 'vga\|3d\|display' | head -1 | cut -d':' -f3 | xargs 2>/dev/null || echo "Tidak terdeteksi"
                ;;
        esac
    }
    
    # Color output function
    colorize() {
        if command -v lolcat &>/dev/null; then
            lolcat
        else
            cat
        fi
    }
    
    # Display neofetch ONLY ONCE with proper distro detection
    if command -v neofetch &>/dev/null; then
        # Detect distro for appropriate logo
        if [[ -f /etc/os-release ]]; then
            source /etc/os-release 2>/dev/null
            distro_id="${ID:-linux}"
        else
            distro_id="linux"
        fi
        
        # Show neofetch with detected distro, minimal info to prevent duplication
        neofetch --ascii_distro "$distro_id" \
                 --disable packages shell resolution de wm theme icons terminal \
                 --cpu_temp off --gpu_brand off --refresh_rate off
    else
        # Fallback ASCII if neofetch not available
        echo "    ___    _____ _____ "
        echo "   /   |  / ___//  _/ "
        echo "  / /| |  \__ \ / /   "
        echo " / ___ | ___/ // /    "
        echo "/_/  |_|/____/___/    "
        echo ""
    fi
    
    # Display hostname with figlet
    if command -v figlet &>/dev/null; then
        figlet "$(whoami)@$(hostname)" | colorize
    else
        echo "=== $(whoami)@$(hostname) ===" | colorize
    fi
    
    # System information display
    {
        echo "============ SYSTEM MONITOR ============"
        echo "🕒 Login Time   : $(date '+%A, %d %B %Y - %H:%M:%S')"
        echo "📡 IP Address   : $(get_sys_info ip_addr)"
        echo "📅 Boot Time    : $(who -b 2>/dev/null | awk '{print $3, $4}' || uptime -s 2>/dev/null || echo 'Unknown')"
        echo "⏱️  Uptime       : $(uptime -p 2>/dev/null || uptime 2>/dev/null | awk '{print $3, $4}' | sed 's/,//' || echo 'Unknown')"
        echo "🖥️  OS Name      : $(get_sys_info os_name)"
        echo "📦 OS Version   : $(get_sys_info os_version)"
        echo "👤 Username     : $(whoami)"
        echo "🧠 CPU Model    : $(get_sys_info cpu_model)"
        echo "🧮 CPU Cores    : $(nproc 2>/dev/null || echo 'Unknown')"
        echo "🎮 GPU Info     : $(get_sys_info gpu_info)"
        echo "💾 RAM Total    : $(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo 'Unknown')"
        echo "📁 Disk Used    : $(df -h / 2>/dev/null | awk 'NR==2 {printf "%s / %s", $3, $2}' || echo 'Unknown')"
        echo "⚙️  Load Average : $(uptime 2>/dev/null | awk -F'load average:' '{print $2}' | xargs || echo 'Unknown')"
        echo "🌐 DNS Servers  : $(awk '/^nameserver/ {printf "%s ", $2}' /etc/resolv.conf 2>/dev/null | xargs || echo 'Unknown')"
        
        # Get quote with fallback
        quote=""
        if command -v curl &>/dev/null && command -v jq &>/dev/null; then
            quote=$(timeout 2 curl -s https://api.quotable.io/random 2>/dev/null | jq -r '.content' 2>/dev/null || echo "")
        fi
        [[ -z "$quote" ]] && quote="Tetap semangat dan jangan pernah berhenti belajar!"
        
        echo "💡 Quote        : \"$quote\""
        echo "========================================"
        echo "===== Terminal Dashboard by AKA ======"
    } | colorize
    
fi
### TERMINAL_DASHBOARD_ACTIVE ###
DASHBOARD_EOF

    log_success "Dashboard berhasil diinstall!"
    log_info "Restart shell untuk melihat dashboard..."
    
    # Restart shell
    exec bash
}

uninstall_dashboard() {
    clear
    echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
    echo -e "${RED}║       🗑️  Uninstalling Dashboard        ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
    
    cleanup_all_traces
    
    # Restore from backup if available
    if [[ -f "$BACKUP_FILE" ]]; then
        cp "$BACKUP_FILE" "$BASHRC_FILE"
        log_success "Restored from backup: $BACKUP_FILE"
    else
        log_warning "No backup found, custom blocks removed"
    fi
    
    log_success "Dashboard uninstalled successfully!"
    exec bash
}

# Main menu
main_menu() {
    clear
    cat << 'MENU'
╔════════════════════════════════════════════════════╗
║               ⚡ Terminal Dashboard                 ║
║                   Manager v2.0                     ║
╚════════════════════════════════════════════════════╝

1️⃣  Install Dashboard
2️⃣  Uninstall Dashboard  
3️⃣  Exit

MENU

    read -r -p "Pilih opsi [1-3]: " choice
    
    case "$choice" in
        1) install_dashboard ;;
        2) uninstall_dashboard ;;  
        3) echo "Keluar..." && exit 0 ;;
        *) 
            log_error "Pilihan tidak valid!"
            sleep 1
            main_menu
            ;;
    esac
}

# Run main menu
main_menu
