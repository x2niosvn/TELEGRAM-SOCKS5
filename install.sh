#!/bin/bash

# X2NIOS SOCKS5 SERVICE Setup - All-in-One Script
# Version 2.2 - Single File Solution with Auto Generate Option
# Chỉ cần 1 file duy nhất để chạy trên VPS

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Hàm tạo random string
generate_random_string() {
    local length=$1
    cat /dev/urandom | tr -dc 'a-z0-9' | head -c $length
}

# Hàm tạo random password 9 số
generate_random_password() {
    cat /dev/urandom | tr -dc '0-9' | head -c 9
}

# Hàm tạo random port trong dải hợp lệ (1024-65535)
generate_random_port() {
    shuf -i 1024-65535 -n 1
}

# Header đẹp
show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║    🔥 X2NIOS SOCKS5 SERVICE Setup 🔥                        ║"
    echo "║                                                               ║"
    echo "║    ⚡ All-in-One Solution - Single File Script ⚡          ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Kiểm tra quyền root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ Script này cần chạy với quyền root!${NC}"
        echo -e "${YELLOW}💡 Sử dụng: sudo bash setup.sh${NC}"
        exit 1
    fi
}

# Auto Generate Setup
auto_generate_setup() {
    show_header
    echo -e "${YELLOW}⚡ Auto Generate Setup - Tự động tạo thông tin${NC}"
    echo ""
    
    SOCKS_USER="x2nios$(generate_random_string 6)"
    SOCKS_PASS=$(generate_random_password)
    SOCKS_PORT=$(generate_random_port)
    
    echo -e "${GREEN}👤 Username: ${YELLOW}$SOCKS_USER${NC}"
    echo -e "${GREEN}🔒 Password: ${YELLOW}$SOCKS_PASS${NC}"
    echo -e "${GREEN}🔌 Port: ${YELLOW}$SOCKS_PORT${NC}"
    echo ""
    
    read -p "$(echo -e "${GREEN}🚀 Xác nhận? ${YELLOW}(y/N)${NC}: ")" confirm
    if [[ "$confirm" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        export SOCKS_USER SOCKS_PASS SOCKS_PORT
        run_installation
    fi
}

# Quick Setup
quick_setup() {
    show_header
    echo -e "${YELLOW}⚡ Quick Setup - Cấu hình mặc định${NC}"
    echo ""
    echo -e "${GREEN}👤 Username: ${YELLOW}x2nios${NC}"
    echo -e "${GREEN}🔒 Password: ${YELLOW}123456789${NC}"
    echo -e "${GREEN}🔌 Port: ${YELLOW}1080${NC}"
    echo ""
    
    read -p "$(echo -e "${GREEN}🚀 Xác nhận? ${YELLOW}(y/N)${NC}: ")" confirm
    if [[ "$confirm" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        export SOCKS_USER="x2nios" SOCKS_PASS="123456789" SOCKS_PORT="1080"
        run_installation
    fi
}

# Menu chính
show_menu() {
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  CHỌN PHƯƠNG THỨC CÀI ĐẶT                    ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} ${YELLOW}⚡ Auto Generate Setup${NC} - Tự động tạo username/password/port"
    echo -e "${CYAN}2.${NC} ${YELLOW}⚡ Quick Setup${NC} - Cấu hình mặc định nhanh"
    echo -e "${CYAN}3.${NC} ${RED}❌ Thoát${NC}"
    echo ""
}

# Chạy cài đặt
run_installation() {
    echo -e "${GREEN}🚀 Bắt đầu cài đặt X2NIOS SOCKS5 SERVICE...${NC}"
    echo ""
    
    # Tạo log file
    LOG_FILE="/var/log/x2nios_socks5_install.log"
    
    # Function logging
    log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
    error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE"; exit 1; }
    
    log "=== BẮT ĐẦU CÀI ĐẶT ==="
    log "Username: $SOCKS_USER, Port: $SOCKS_PORT"
    
    # 1. Fix repository
    log "🔧 Fix repository..."
    cp /etc/apt/sources.list /etc/apt/sources.list.backup 2>/dev/null || true
    UBUNTU_VERSION=$(lsb_release -cs 2>/dev/null || echo "jammy")
    
    cat > /etc/apt/sources.list << EOF
deb http://archive.ubuntu.com/ubuntu/ $UBUNTU_VERSION main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $UBUNTU_VERSION-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $UBUNTU_VERSION-updates main restricted universe multiverse
EOF
    
    apt update -y || { sed -i 's/archive.ubuntu.com/vn.archive.ubuntu.com/g' /etc/apt/sources.list; apt update -y; }
    
    # 2. Cài đặt packages
    log "📦 Cài đặt packages..."
    apt install -y wget curl net-tools ufw wireguard build-essential --fix-missing || true
    
    # 3. Cài đặt wgcf
    if ! command -v wgcf &> /dev/null; then
        log "📥 Cài đặt wgcf..."
        curl -L -o /usr/local/bin/wgcf https://github.com/ViRb3/wgcf/releases/download/v2.2.26/wgcf_2.2.26_linux_amd64
        chmod +x /usr/local/bin/wgcf
    fi
    
    # 4. Cài đặt microsocks
    if ! command -v microsocks &> /dev/null; then
        log "📥 Cài đặt microsocks..."
        cd /tmp
        wget -O microsocks.tar.gz https://github.com/rofl0r/microsocks/archive/v1.0.3.tar.gz
        tar -xzf microsocks.tar.gz && cd microsocks-1.0.3
        make && cp microsocks /usr/local/bin/ && chmod +x /usr/local/bin/microsocks
        cd / && rm -rf /tmp/microsocks*
    fi
    
    # 5. Dừng services cũ
    log "🛑 Dừng services cũ..."
    systemctl stop wg-quick@wg0 2>/dev/null || true
    systemctl stop x2nios-routing 2>/dev/null || true
    systemctl stop microsocks 2>/dev/null || true
    ip link delete wg0 2>/dev/null || true
    
    # 6. Cấu hình WireGuard
    log "🔧 Cấu hình WireGuard..."
    cd /etc/wireguard
    rm -f wgcf-account.toml wgcf-profile.conf wg0.conf
    
    wgcf register --accept-tos || error "Không thể đăng ký WARP"
    wgcf generate || error "Không thể tạo profile"
    
    PRIVATE_KEY=$(grep "PrivateKey" wgcf-profile.conf | cut -d' ' -f3)
    ADDRESS=$(grep "Address" wgcf-profile.conf | cut -d' ' -f3 | cut -d',' -f1)
    PUBLIC_KEY=$(grep "PublicKey" wgcf-profile.conf | cut -d' ' -f3)
    ENDPOINT=$(grep "Endpoint" wgcf-profile.conf | cut -d' ' -f3)
    
    cat > wg0.conf << EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $ADDRESS
MTU = 1280

[Peer]
PublicKey = $PUBLIC_KEY
AllowedIPs = 149.154.160.0/20, 149.154.164.0/22, 149.154.168.0/22, 149.154.172.0/22, 91.108.4.0/22, 91.108.8.0/22, 91.108.12.0/22, 91.108.16.0/22, 91.108.20.0/22, 91.108.56.0/22, 95.161.64.0/20
Endpoint = $ENDPOINT
EOF
    
    # 7. Khởi động WireGuard
    log "🚀 Khởi động WireGuard..."
    systemctl start wg-quick@wg0 && systemctl enable wg-quick@wg0
    sleep 3
    
    # 8. Cấu hình routing
    log "🔧 Cấu hình routing..."
    echo "200 x2nios" >> /etc/iproute2/rt_tables 2>/dev/null || true
    
    cat > /usr/local/bin/x2nios-routing.sh << 'EOF'
#!/bin/bash
X2NIOS_CIDRS=("149.154.160.0/20" "149.154.164.0/22" "149.154.168.0/22" "149.154.172.0/22" "91.108.4.0/22" "91.108.8.0/22" "91.108.12.0/22" "91.108.16.0/22" "91.108.20.0/22" "91.108.56.0/22" "95.161.64.0/20")
case "$1" in
    start) for cidr in "${X2NIOS_CIDRS[@]}"; do ip rule add to $cidr table x2nios 2>/dev/null || true; ip route add $cidr dev wg0 table x2nios 2>/dev/null || true; done;;
    stop) ip rule flush table x2nios 2>/dev/null || true; ip route flush table x2nios 2>/dev/null || true;;
esac
EOF
    chmod +x /usr/local/bin/x2nios-routing.sh
    
    cat > /etc/systemd/system/x2nios-routing.service << 'EOF'
[Unit]
Description=X2NIOS Routing via WireGuard
After=wg-quick@wg0.service
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/x2nios-routing.sh start
ExecStop=/usr/local/bin/x2nios-routing.sh stop
[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload && systemctl enable x2nios-routing && systemctl start x2nios-routing
    
    # 9. Cấu hình SOCKS5
    log "🔧 Cấu hình SOCKS5..."
    cat > /usr/local/bin/microsocks-wrapper.sh << EOF
#!/bin/bash
exec /usr/local/bin/microsocks -i 0.0.0.0 -p ${SOCKS_PORT} -u ${SOCKS_USER} -P ${SOCKS_PASS}
EOF
    chmod +x /usr/local/bin/microsocks-wrapper.sh
    
    cat > /etc/systemd/system/microsocks.service << 'EOF'
[Unit]
Description=X2NIOS SOCKS5 proxy
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/microsocks-wrapper.sh
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload && systemctl enable microsocks && systemctl start microsocks
    
    # 10. Cấu hình firewall
    log "🔧 Cấu hình firewall..."
    ufw allow 22/tcp && ufw allow ${SOCKS_PORT}/tcp && ufw --force enable
    
    # 11. Tạo management scripts
    log "📝 Tạo management scripts..."
    cat > /usr/local/bin/x2nios-socks5-status << 'EOFSTATUS'
#!/bin/bash
echo "=== X2NIOS SOCKS5 SERVICE STATUS ==="
systemctl is-active wg-quick@wg0 && echo "✅ WireGuard: Running" || echo "❌ WireGuard: Stopped"
systemctl is-active microsocks && echo "✅ SOCKS5: Running" || echo "❌ SOCKS5: Stopped"
systemctl is-active x2nios-routing && echo "✅ Routing: Running" || echo "❌ Routing: Stopped"
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Unknown")
echo "📊 Public IP: $PUBLIC_IP"
EOFSTATUS
    chmod +x /usr/local/bin/x2nios-socks5-status
    
    sleep 5
    
    # 12. Hiển thị kết quả
    PUBLIC_IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
    echo ""
    log "=== ✅ CÀI ĐẶT HOÀN TẤT ==="
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                     THÔNG TIN X2NIOS SOCKS5                   ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}🌐 Host: ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${GREEN}🔌 Port: ${YELLOW}$SOCKS_PORT${NC}"
    echo -e "${GREEN}👤 Username: ${YELLOW}$SOCKS_USER${NC}"
    echo -e "${GREEN}🔒 Password: ${YELLOW}$SOCKS_PASS${NC}"
    echo -e "${GREEN}📱 Type: ${YELLOW}SOCKS5${NC}"
    echo ""
    echo -e "${BLUE}📱 Cấu hình SOCKS5:${NC}"
    echo -e "${BLUE}1. Mở ứng dụng cần dùng proxy${NC}"
    echo -e "${BLUE}2. Chọn SOCKS5 proxy${NC}"
    echo -e "${BLUE}3. Server: $PUBLIC_IP:$SOCKS_PORT${NC}"
    echo -e "${BLUE}4. Username: $SOCKS_USER${NC}"
    echo -e "${BLUE}5. Password: $SOCKS_PASS${NC}"
    echo ""
    echo -e "${GREEN}🔧 Quản lý:${NC}"
    echo -e "${GREEN}x2nios-socks5-status${NC} - Kiểm tra trạng thái"
    echo -e "${GREEN}systemctl restart microsocks${NC} - Restart SOCKS5"
    echo -e "${GREEN}systemctl restart wg-quick@wg0${NC} - Restart WireGuard"
    echo ""
    
    log "🎉 Hệ thống X2NIOS SOCKS5 đã sẵn sàng!"
}

# Main function
main() {
    show_header
    check_root
    
    while true; do
        show_menu
        read -p "$(echo -e "${GREEN}🎯 Lựa chọn [1-3]${NC}: ")" choice
        echo ""
        
        case $choice in
            1) auto_generate_setup; break;;
            2) quick_setup; break;;
            3) echo -e "${GREEN}👋 Tạm biệt!${NC}"; exit 0;;
            *) echo -e "${RED}❌ Lựa chọn không hợp lệ!${NC}"; sleep 1;;
        esac
    done
}

main "$@"
