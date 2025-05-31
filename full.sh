#!/bin/bash

# X2NIOS Proxy Service Setup - Optimized Version with SOCKS5 and MTProto
# Version 3.6 - Continuous Proxy with Max Performance
# Tối ưu cho Telegram, chạy liên tục, bỏ giới hạn tài nguyên

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Header đẹp
show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║                X2NIOS Proxy Service Setup V1                  ║"
    echo "║                                                               ║"
    echo "║        ⚡ Max Performance - SOCKS5 & MTProto Support ⚡          ║"
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

# Kiểm tra cổng có đang sử dụng không
check_port() {
    local port=$1
    if netstat -tuln | grep -q ":${port}"; then
        echo -e "${RED}❌ Cổng $port đang được sử dụng!${NC}"
        echo -e "${YELLOW}💡 Hãy chọn cổng khác hoặc dừng tiến trình bằng lệnh:${NC}"
        echo -e "${YELLOW}   fuser -k ${port}/tcp${NC}"
        return 1
    fi
    return 0
}

# Tìm giao diện mạng chính
get_network_interface() {
    INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)
    if [[ -z "$INTERFACE" ]]; then
        echo -e "${RED}❌ Không tìm thấy giao diện mạng!${NC}"
        echo -e "${YELLOW}💡 Kiểm tra bằng lệnh: ip link${NC}"
        exit 1
    fi
    echo "$INTERFACE"
}

# Thu thập thông tin với validation
collect_user_input() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    CẤU HÌNH X2NIOS PROXY                      ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Username
    while true; do
        read -p "$(echo -e "${GREEN}👤 Username cho proxy ${YELLOW}[x2nios]${NC}: ")" PROXY_USER
        PROXY_USER=${PROXY_USER:-x2nios}
        [[ ${#PROXY_USER} -ge 3 ]] && break
        echo -e "${RED}❌ Username phải có ít nhất 3 ký tự!${NC}"
    done
    
    # Password (cho SOCKS5) hoặc Secret (cho MTProto)
    while true; do
        read -s -p "$(echo -e "${GREEN}🔒 Password/Secret cho proxy ${YELLOW}[123456789]${NC}: ")" PROXY_PASS
        echo ""
        PROXY_PASS=${PROXY_PASS:-123456789}
        [[ ${#PROXY_PASS} -ge 6 ]] && break
        echo -e "${RED}❌ Password/Secret phải có ít nhất 6 ký tự!${NC}"
    done
    
    # Port
    while true; do
        read -p "$(echo -e "${GREEN}🔌 Port cho proxy ${YELLOW}[1080]${NC}: ")" PROXY_PORT
        PROXY_PORT=${PROXY_PORT:-1080}
        if [[ "$PROXY_PORT" =~ ^[0-9]+$ ]] && [ "$PROXY_PORT" -ge 1 ] && [ "$PROXY_PORT" -le 65535 ]; then
            if check_port "$PROXY_PORT"; then
                break
            fi
        else
            echo -e "${RED}❌ Port không hợp lệ! Phải là số từ 1-65535.${NC}"
        fi
    done
    
    # Xác nhận
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                     XÁC NHẬN CẤU HÌNH                         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}📊 Username: ${YELLOW}$PROXY_USER${NC}"
    echo -e "${GREEN}📊 Password/Secret: ${YELLOW}$(echo $PROXY_PASS | sed 's/./*/g')${NC}"
    echo -e "${GREEN}📊 Port: ${YELLOW}$PROXY_PORT${NC}"
    echo -e "${GREEN}📊 Protocol: ${YELLOW}$PROXY_TYPE${NC}"
    echo ""
    
    while true; do
        read -p "$(echo -e "${GREEN}✅ Xác nhận cấu hình? ${YELLOW}(y/N)${NC}: ")" confirm
        case $confirm in
            [yY][eE][sS]|[yY]) export PROXY_USER PROXY_PASS PROXY_PORT PROXY_TYPE; return 0;;
            [nN][oO]|[nN]|"") return 1;;
            *) echo -e "${RED}❌ Vui lòng nhập y hoặc n${NC}";;
        esac
    done
}

# Menu chính
show_menu() {
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  CHỌN PHƯƠNG THỨC CÀI ĐẶT                     ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} ${GREEN}📝 SOCKS5 Setup${NC} - Cài đặt SOCKS5 proxy (khuyến nghị)"
    echo -e "${CYAN}2.${NC} ${GREEN}📡 MTProto Setup${NC} - Cài đặt MTProto proxy"
    echo -e "${CYAN}3.${NC} ${YELLOW}⚡ Quick Setup${NC} - Cấu hình mặc định nhanh (SOCKS5)"
    echo -e "${CYAN}4.${NC} ${RED}❌ Thoát${NC}"
    echo ""
}

# Quick Setup (mặc định SOCKS5)
quick_setup() {
    show_header
    echo -e "${YELLOW}⚡ Quick Setup - Cấu hình mặc định SOCKS5${NC}"
    echo ""
    echo -e "${GREEN}👤 Username: ${YELLOW}x2nios${NC}"
    echo -e "${GREEN}🔒 Password: ${YELLOW}123456789${NC}"
    echo -e "${GREEN}🔌 Port: ${YELLOW}1080${NC}"
    echo -e "${GREEN}📊 Protocol: ${YELLOW}SOCKS5${NC}"
    echo ""
    
    read -p "$(echo -e "${GREEN}🚀 Xác nhận? ${YELLOW}(y/N)${NC}: ")" confirm
    if [[ "$confirm" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        export PROXY_USER="x2nios" PROXY_PASS="123456789" PROXY_PORT="1080" PROXY_TYPE="socks5"
        run_installation
    fi
}

# Interactive Setup
interactive_setup() {
    show_header
    echo -e "${BLUE}📝 Interactive Setup - Cấu hình chi tiết${NC}"
    echo ""
    
    if collect_user_input; then
        run_installation
    else
        echo -e "${YELLOW}⚠️ Hủy bỏ cài đặt.${NC}"
    fi
}

# Hàm lấy thông tin kết nối
get_connections() {
    if [[ "$PROXY_TYPE" == "socks5" ]]; then
        netstat -tuln | grep ":${PROXY_PORT}" &> /dev/null && echo "✅ SOCKS5 đang lắng nghe trên port ${PROXY_PORT}" || echo "❌ Không có kết nối SOCKS5 trên port ${PROXY_PORT}"
        ss -tn | grep ":${PROXY_PORT}" | awk '{print "🔗 Kết nối: " $4 " -> " $5}' | sort -u
    else
        netstat -tuln | grep ":${PROXY_PORT}" &> /dev/null && echo "✅ MTProto đang lắng nghe trên port ${PROXY_PORT}" || echo "❌ Không có kết nối MTProto trên port ${PROXY_PORT}"
        ss -tn | grep ":${PROXY_PORT}" | awk '{print "🔗 Kết nối: " $4 " -> " $5}' | sort -u
    fi
}

# Cài đặt và cấu hình proxy
run_installation() {
    echo -e "${GREEN}🚀 Bắt đầu cài đặt X2NIOS ${PROXY_TYPE^^} Proxy...${NC}"
    echo ""
    
    # Tạo log file
    LOG_FILE="/var/log/x2nios_proxy_install.log"
    
    # Function logging
    log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
    error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE"; exit 1; }
    
    log "=== BẮT ĐẦU CÀI ĐẶT ==="
    log "Username: $PROXY_USER, Port: $PROXY_PORT, Protocol: $PROXY_TYPE"
    
    # 1. Cập nhật hệ thống và cài đặt packages
    log "📦 Cập nhật hệ thống và cài đặt packages..."
    apt update && apt upgrade -y
    apt install -y net-tools ufw curl || error "Không thể cài đặt packages cơ bản"
    
    if [[ "$PROXY_TYPE" == "socks5" ]]; then
        apt install -y dante-server || error "Không thể cài đặt Dante"
    else
        apt install -y python3 python3-pip git || error "Không thể cài đặt MTProto dependencies"
        pip3 install cryptography pyTelegramBotAPI || error "Không thể cài đặt Python packages"
    fi
    
    # 2. Dừng services cũ
    log "🛑 Dừng services cũ..."
    systemctl stop danted mtproto-proxy 2>/dev/null || true
    systemctl disable danted mtproto-proxy 2>/dev/null || true
    
    # 3. Lấy giao diện mạng
    INTERFACE=$(get_network_interface)
    log "🌐 Giao diện mạng: $INTERFACE"
    
    # 4. Tối ưu hệ thống cho 10 người dùng
    log "🔧 Tối ưu hệ thống cho VPS 1-1, 10 người dùng..."
    sysctl -w net.core.somaxconn=1024
    sysctl -w net.ipv4.ip_local_port_range="1024 65535"
    sysctl -w net.ipv4.tcp_tw_reuse=1
    sysctl -w net.ipv4.tcp_fin_timeout=15
    sysctl -w net.core.rmem_max=1048576
    sysctl -w net.core.wmem_max=1048576
    echo "root soft nofile 32768" >> /etc/security/limits.conf
    echo "root hard nofile 32768" >> /etc/security/limits.conf
    echo "* soft nofile 32768" >> /etc/security/limits.conf
    echo "* hard nofile 32768" >> /etc/security/limits.conf
    
    # 5. Cấu hình proxy
    log "🔧 Cấu hình ${PROXY_TYPE^^}..."
    if [[ "$PROXY_TYPE" == "socks5" ]]; then
        # Cấu hình Dante SOCKS5
        cat > /etc/danted.conf << EOF
logoutput: /var/log/danted.log
internal: 0.0.0.0 port = ${PROXY_PORT}
external: ${INTERFACE}
method: username
user.privileged: root
user.unprivileged: nobody
clientmethod: none
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: connect disconnect error
}
EOF
        # Tạo user cho SOCKS5
        useradd -r -s /bin/false ${PROXY_USER} 2>/dev/null || true
        echo "${PROXY_USER}:${PROXY_PASS}" | chpasswd || error "Không thể tạo user SOCKS5"
        
        # Cấu hình systemd cho Dante
        cat > /etc/systemd/system/danted.service << EOF
[Unit]
Description=X2NIOS SOCKS5 Proxy (Dante)
After=network.target
[Service]
Type=simple
ExecStart=/usr/sbin/danted -D
Restart=always
RestartSec=1
LimitNOFILE=1048576
LimitNPROC=unlimited
[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable danted
        systemctl start danted || error "Không thể khởi động Dante. Kiểm tra log: /var/log/danted.log"
    else
        # Cấu hình MTProto
        log "📥 Cài đặt mtproto-proxy..."
        cd /opt
        git clone https://github.com/TelegramMessenger/MTProxy.git || error "Không thể clone MTProto repository"
        cd MTProxy
        make || error "Không thể biên dịch MTProto"
        cp objs/bin/mtproto-proxy /usr/local/bin/ || error "Không thể copy MTProto binary"
        
        # Tạo secret cho MTProto
        SECRET=$(echo -n ${PROXY_PASS} | xxd -ps -c 256)
        
        # Cấu hình systemd cho MTProto
        cat > /etc/systemd/system/mtproto-proxy.service << EOF
[Unit]
Description=X2NIOS MTProto Proxy
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/mtproto-proxy -u nobody -p ${PROXY_PORT} -H 0.0.0.0 -S ${SECRET} --nat-info 0.0.0.0:${PUBLIC_IP}
Restart=always
RestartSec=1
LimitNOFILE=1048576
LimitNPROC=unlimited
[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable mtproto-proxy
        systemctl start mtproto-proxy || error "Không thể khởi động MTProto"
    fi
    
    # 6. Cấu hình firewall
    log "🔧 Cấu hình firewall..."
    ufw allow 22/tcp
    ufw allow ${PROXY_PORT}/tcp
    ufw --force enable
    
    # 7. Tạo script quản lý trạng thái
    log "📝 Tạo script quản lý trạng thái..."
    cat > /usr/local/bin/x2nios_proxy_status << 'EOF'
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                   X2NIOS PROXY STATUS                         ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Kiểm tra trạng thái service
echo -e "${GREEN}=== Trạng thái dịch vụ ==="
if [ -f /etc/systemd/system/danted.service ]; then
    systemctl is-active danted &>/dev/null && echo -e "${GREEN}✅ SOCKS5: Running${NC}" || { echo -e "${RED}❌ SOCKS5: Stopped${NC}"; echo -e "${YELLOW}💡 Kiểm tra log: cat /var/log/danted.log${NC}"; echo -e "${YELLOW}💡 Thử khởi động lại: systemctl restart danted${NC}"; }
fi
if [ -f /etc/systemd/system/mtproto-proxy.service ]; then
    systemctl is-active mtproto-proxy &>/dev/null && echo -e "${GREEN}✅ MTProto: Running${NC}" || echo -e "${RED}❌ MTProto: Stopped${NC}"
fi

# Thông tin IP
PUBLIC_IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
echo -e "${GREEN}🌐 Public IP: ${YELLOW}$PUBLIC_IP${NC}"

# Thông tin kết nối
echo -e "${GREEN}=== Kết nối Proxy ==="
/usr/local/bin/x2nios_proxy_status_internal

echo ""
echo -e "${CYAN}🔧 Quản lý:${NC}"
[ -f /etc/systemd/system/danted.service ] && echo -e "${CYAN}systemctl restart danted${NC} - Restart SOCKS5"
[ -f /etc/systemd/system/mtproto-proxy.service ] && echo -e "${CYAN}systemctl restart mtproto-proxy${NC} - Restart MTProto"
echo -e "${CYAN}x2nios_proxy_status${NC} - Kiểm tra trạng thái"
echo -e "${CYAN}x2nios_proxy_config${NC} - Mở lại menu cấu hình"
EOF

    cat > /usr/local/bin/x2nios_proxy_status_internal << EOF
#!/bin/bash
PROXY_PORT=${PROXY_PORT}
PROXY_TYPE=${PROXY_TYPE}
if [[ "\$PROXY_TYPE" == "socks5" ]]; then
    netstat -tuln | grep ":\${PROXY_PORT}" &> /dev/null && echo "✅ SOCKS5 đang lắng nghe trên port \${PROXY_PORT}" || echo "❌ Không có kết nối SOCKS5 trên port \${PROXY_PORT}"
    ss -tn | grep ":\${PROXY_PORT}" | awk '{print "🔗 Kết nối: " \$4 " -> " \$5}' | sort -u
else
    netstat -tuln | grep ":\${PROXY_PORT}" &> /dev/null && echo "✅ MTProto đang lắng nghe trên port \${PROXY_PORT}" || echo "❌ Không có kết nối MTProto trên port \${PROXY_PORT}"
    ss -tn | grep ":\${PROXY_PORT}" | awk '{print "🔗 Kết nối: " \$4 " -> " \$5}' | sort -u
fi
EOF

    # 8. Tạo script gọi lại menu
    log "📝 Tạo script gọi lại menu cấu hình..."
    cat > /usr/local/bin/x2nios_proxy_config << EOF
#!/bin/bash
bash $0
EOF
    chmod +x /usr/local/bin/x2nios_proxy_config
    chmod +x /usr/local/bin/x2nios_proxy_status
    chmod +x /usr/local/bin/x2nios_proxy_status_internal
    
    # 9. Hiển thị kết quả
    PUBLIC_IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
    echo ""
    log "=== ✅ CÀI ĐẶT HOÀN TẤT ==="
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                     THÔNG TIN X2NIOS PROXY                    ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}🌐 Host: ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${GREEN}🔌 Port: ${YELLOW}$PROXY_PORT${NC}"
    echo -e "${GREEN}👤 Username: ${YELLOW}$PROXY_USER${NC}"
    if [[ "$PROXY_TYPE" == "socks5" ]]; then
        echo -e "${GREEN}🔒 Password: ${YELLOW}$PROXY_PASS${NC}"
    else
        echo -e "${GREEN}🔒 Secret: ${YELLOW}$PROXY_PASS${NC}"
    fi
    echo -e "${GREEN}📱 Type: ${YELLOW}${PROXY_TYPE^^}${NC}"
    echo ""
    echo -e "${BLUE}📱 Cấu hình ${PROXY_TYPE^^}:${NC}"
    if [[ "$PROXY_TYPE" == "socks5" ]]; then
        echo -e "${BLUE}1. Mở ứng dụng cần dùng proxy${NC}"
        echo -e "${BLUE}2. Chọn SOCKS5 proxy${NC}"
        echo -e "${BLUE}3. Server: $PUBLIC_IP:$PROXY_PORT${NC}"
        echo -e "${BLUE}4. Username: $PROXY_USER${NC}"
        echo -e "${BLUE}5. Password: $PROXY_PASS${NC}"
    else
        echo -e "${BLUE}1. Mở Telegram hoặc ứng dụng hỗ trợ MTProto${NC}"
        echo -e "${BLUE}2. Thêm proxy mới${NC}"
        echo -e "${BLUE}3. Server: $PUBLIC_IP:$PROXY_PORT${NC}"
        echo -e "${BLUE}4. Secret: $PROXY_PASS${NC}"
    fi
    echo ""
    echo -e "${GREEN}🔧 Quản lý:${NC}"
    echo -e "${GREEN}x2nios_proxy_status${NC} - Kiểm tra trạng thái"
    echo -e "${GREEN}x2nios_proxy_config${NC} - Mở lại menu cấu hình"
    if [[ "$PROXY_TYPE" == "socks5" ]]; then
        echo -e "${GREEN}systemctl restart danted${NC} - Restart SOCKS5"
    else
        echo -e "${GREEN}systemctl restart mtproto-proxy${NC} - Restart MTProto"
    fi
    echo ""
    
    log "🎉 Hệ thống X2NIOS ${PROXY_TYPE^^} đã sẵn sàng!"
}

# Main function
main() {
    show_header
    check_root
    
    while true; do
        show_menu
        read -p "$(echo -e "${GREEN}🎯 Lựa chọn [1-4]${NC}: ")" choice
        echo ""
        
        case $choice in
            1) export PROXY_TYPE="socks5"; interactive_setup; break;;
            2) export PROXY_TYPE="mtproto"; interactive_setup; break;;
            3) quick_setup; break;;
            4) echo -e "${GREEN}👋 Tạm biệt!${NC}"; exit 0;;
            *) echo -e "${RED}❌ Lựa chọn không hợp lệ!${NC}"; sleep 1;;
        esac
    done
}

main "$@"
