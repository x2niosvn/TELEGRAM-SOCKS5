# X2NIOS SOCKS5 SERVICE

**X2NIOS SOCKS5 SERVICE** là một script tự động thiết lập SOCKS5 proxy server sử dụng WireGuard để định tuyến lưu lượng mạng. Script này được thiết kế để chạy trên VPS Ubuntu, tích hợp `wgcf` (WireGuard Cloudflare WARP), `microsocks` (SOCKS5 proxy), và cấu hình firewall để tạo một proxy an toàn, đơn giản, dễ sử dụng.

---

## 🧩 Tính năng

- ✅ **Cài đặt tự động**: Thiết lập WireGuard, microsocks và định tuyến chỉ trong một lệnh.
- 🧑‍💻 **Giao diện thân thiện**: Hỗ trợ 2 chế độ:
  - **Interactive Setup**: Tùy chọn nhập username, password, port.
  - **Quick Setup**: Sử dụng cấu hình mặc định (username: `x2nios`, password: `123456789`, port: `1080`).
- 📊 **Quản lý dễ dàng**: Lệnh `x2nios-socks5-status` để kiểm tra trạng thái nhanh.
- 🔥 **Firewall tự động**: Mở cổng 22 (SSH) và cổng SOCKS5.
- 📁 **Log chi tiết**: Lưu tại `/var/log/x2nios_socks5_install.log`.

---

## 📋 Yêu cầu

- VPS chạy **Ubuntu 20.04** hoặc **22.04**.
- Quyền **root**.
- **Kết nối internet**.
- **curl** (sẽ được tự động cài nếu thiếu).

---

## 🚀 Hướng dẫn cài đặt

### Chạy script

#V1
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/x2niosvn/TELEGRAM-SOCKS5/main/install.sh)"
```
#V2
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/x2niosvn/TELEGRAM-SOCKS5/main/install_v2.sh)"
```

