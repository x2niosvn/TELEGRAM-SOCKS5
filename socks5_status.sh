#!/bin/bash

# Script giám sát lưu lượng truy cập và thiết bị sử dụng SOCKS5 theo thời gian thực
# X2NIOS SOCKS5 Traffic & Device Monitor
# Version 1.0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Header
show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║    🔥 X2NIOS SOCKS5 Traffic & Device Monitor 🔥             ║"
    echo "║                                                               ║"
    echo "║    ⚡ Realtime Network Usage and Device Tracking ⚡         ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Kiểm tra quyền root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ Script này cần chạy với quyền root!${NC}"
        echo -e "${YELLOW}💡 Sử dụng: sudo bash monitor.sh${NC}"
        exit 1
    fi
}

# Cài đặt các công cụ cần thiết
install_tools() {
    echo -e "${GREEN}📦 Kiểm tra và cài đặt các công cụ cần thiết...${NC}"
    apt update
    apt install -y iftop nload vnstat net-tools iproute2 bc
    if ! command -v iftop &> /dev/null || ! command -v nload &> /dev/null || ! command -v vnstat &> /dev/null; then
        echo -e "${RED}❌ Lỗi cài đặt công cụ. Vui lòng kiểm tra kết nối mạng hoặc repository!${NC}"
        exit 1
    fi
    # Kích hoạt vnstat
    systemctl enable vnstat
    systemctl start vnstat
    echo -e "${GREEN}✅ Đã cài đặt công cụ!${NC}"
}

# Lấy interface mạng chính
get_network_interface() {
    INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)
    if [ -z "$INTERFACE" ]; then
        echo -e "${RED}❌ Không tìm thấy interface mạng!${NC}"
        exit 1
    fi
    echo -e "${GREEN}📡 Interface mạng: ${YELLOW}$INTERFACE${NC}"
}

# Theo dõi lưu lượng mạng theo thời gian thực với iftop
monitor_traffic_iftop() {
    echo -e "${GREEN}🚀 Theo dõi lưu lượng mạng theo thời gian thực (iftop)...${NC}"
    echo -e "${YELLOW}💡 Nhấn 'q' để thoát${NC}"
    iftop -i "$INTERFACE" -P
}

# Theo dõi lưu lượng mạng với nload
monitor_traffic_nload() {
    echo -e "${GREEN}🚀 Theo dõi lưu lượng mạng theo thời gian thực (nload)...${NC}"
    echo -e "${YELLOW}💡 Nhấn 'q' để thoát${NC}"
    nload "$INTERFACE"
}

# Hiển thị thống kê lưu lượng với vnstat
show_vnstat_stats() {
    echo -e "${GREEN}📊 Thống kê lưu lượng mạng (vnstat):${NC}"
    echo -e "${CYAN}1. Tổng quan ngày${NC}"
    vnstat -i "$INTERFACE" -d
    echo ""
    echo -e "${CYAN}2. Tổng quan tháng${NC}"
    vnstat -i "$INTERFACE" -m
    echo ""
    echo -e "${CYAN}3. Top 10 ngày sử dụng nhiều nhất${NC}"
    vnstat -i "$INTERFACE" -t
}

# Theo dõi các thiết bị kết nối SOCKS5
monitor_devices() {
    SOCKS_PORT=$(systemctl cat microsocks | grep -oP '(?<= -p )\d+')
    if [ -z "$SOCKS_PORT" ]; then
        SOCKS_PORT=1080
        echo -e "${YELLOW}⚠️ Không tìm thấy port SOCKS5, sử dụng mặc định: $SOCKS_PORT${NC}"
    fi
    echo -e "${GREEN}🔍 Theo dõi các thiết bị kết nối SOCKS5 (Port: $SOCKS_PORT) theo thời gian thực...${NC}"
    echo -e "${YELLOW}💡 Nhấn Ctrl+C để thoát${NC}"
    while true; do
        clear
        echo -e "${CYAN}📅 Thời gian: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo -e "${GREEN}📋 Các kết nối SOCKS5 hiện tại:${NC}"
        echo "---------------------------------------------------"
        ss -tn | grep ":$SOCKS_PORT" | awk '{
            print "Client IP: " $4 " | Server IP: " $3 " | State: " $1
        }'
        echo "---------------------------------------------------"
        sleep 2
    done
}

# Tính toán lưu lượng sử dụng hiện tại
calculate_bandwidth() {
    echo -e "${GREEN}📏 Tính toán băng thông sử dụng hiện tại...${NC}"
    RX1=$(cat /sys/class/net/"$INTERFACE"/statistics/rx_bytes)
    TX1=$(cat /sys/class/net/"$INTERFACE"/statistics/tx_bytes)
    sleep 1
    RX2=$(cat /sys/class/net/"$INTERFACE"/statistics/rx_bytes)
    TX2=$(cat /sys/class/net/"$INTERFACE"/statistics/tx_bytes)
    
    RX_RATE=$(( (RX2 - RX1) * 8 / 1000 )) # Kbps
    TX_RATE=$(( (TX2 - TX1) * 8 / 1000 )) # Kbps
    
    RX_RATE_MB=$(echo "scale=2; $RX_RATE / 1000" | bc)
    TX_RATE_MB=$(echo "scale=2; $TX_RATE / 1000" | bc)
    
    echo -e "${CYAN}⬇️ Download: ${YELLOW}${RX_RATE_MB} Mbps${NC}"
    echo -e "${CYAN}⬆️ Upload: ${YELLOW}${TX_RATE_MB} Mbps${NC}"
}

# Menu chính
show_menu() {
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║             X2NIOS SOCKS5 TRAFFIC & DEVICE MONITOR            ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} ${GREEN}📊 Theo dõi lưu lượng realtime (iftop)${NC}"
    echo -e "${CYAN}2.${NC} ${GREEN}📈 Theo dõi lưu lượng realtime (nload)${NC}"
    echo -e "${CYAN}3.${NC} ${GREEN}📅 Thống kê lưu lượng (vnstat)${NC}"
    echo -e "${CYAN}4.${NC} ${GREEN}🔍 Theo dõi thiết bị kết nối SOCKS5${NC}"
    echo -e "${CYAN}5.${NC} ${GREEN}📏 Tính toán băng thông hiện tại${NC}"
    echo -e "${CYAN}6.${NC} ${RED}❌ Thoát${NC}"
    echo ""
}

# Main function
main() {
    show_header
    check_root
    install_tools
    get_network_interface
    
    while true; do
        show_menu
        read -p "$(echo -e "${GREEN}🎯 Lựa chọn [1-6]${NC}: ")" choice
        echo ""
        
        case $choice in
            1) monitor_traffic_iftop;;
            2) monitor_traffic_nload;;
            3) show_vnstat_stats;;
            4) monitor_devices;;
            5) calculate_bandwidth;;
            6) echo -e "${GREEN}👋 Tạm biệt!${NC}"; exit 0;;
            *) echo -e "${RED}❌ Lựa chọn không hợp lệ!${NC}"; sleep 1;;
        esac
        echo ""
        read -p "$(echo -e "${GREEN}⏎ Nhấn Enter để tiếp tục...${NC}")"
    done
}

main "$@"
