# DCA Master EA - Expert Advisor Quản lý DCA Nâng cao

## 🎯 Tổng quan

DCA Master EA là một Expert Advisor được viết bằng MQL5 cho MetaTrader 5, được thiết kế để tự động thực hiện chiến lược Dollar-Cost Averaging (DCA) nâng cao. Điểm đặc biệt của EA này là **không tự mở lệnh đầu tiên**, thay vào đó sẽ "nhận nuôi" các lệnh thủ công đã có trên biểu đồ.

## ✨ Tính năng chính

### 🔍 Tự động nhận diện lệnh gốc
- Quét tất cả lệnh đang mở trên biểu đồ
- Nhận nuôi các lệnh có `Magic Number = 0` và comment rỗng/không chứa tên bot
- Hỗ trợ quản lý nhiều chuỗi DCA đồng thời

### 📈 Logic DCA thông minh
- Tính toán giá trung bình của tất cả lệnh trong chuỗi
- Vào lệnh mới khi giá đạt ngưỡng đã định
- Tăng khối lượng theo hệ số nhân cho mỗi lệnh DCA
- Duy trì cùng TP/SL với lệnh gốc

### 🎛️ Quản lý chuỗi tự động
- Tự động dừng quản lý khi lệnh gốc bị đóng
- Theo dõi trạng thái real-time của từng chuỗi
- Dọn dẹp bộ nhớ tự động

## 🛠️ Cài đặt và Sử dụng

### 1. Cài đặt file

```
📁 MQL5/
├── 📁 Experts/
│   └── DCA_Master_EA.mq5
└── 📁 Include/
    ├── TradeUtils.mqh
    └── DCA_Core.mqh
```

### 2. Tham số cấu hình

| Tham số | Mô tả | Giá trị mặc định |
|---------|-------|------------------|
| `bot_name` | Tên bot (dùng trong comment) | "DCA_MASTER" |
| `distance_pips` | Khoảng cách giữa các lệnh DCA | 50 pips |
| `volume_multiplier` | Hệ số nhân khối lượng | 1.5 |
| `max_dca_orders` | Số lệnh DCA tối đa | 5 |
| `enable_info_panel` | Hiển thị panel thông tin | true |
| `enable_debug_log` | Bật log debug | false |

### 3. Cách sử dụng

1. **Cài đặt EA lên biểu đồ** với các tham số phù hợp
2. **Mở lệnh thủ công** (BUY/SELL) với:
   - Magic Number = 0
   - Comment để trống hoặc không chứa tên bot
   - Đặt TP/SL theo ý muốn
3. **EA sẽ tự động nhận nuôi** lệnh và bắt đầu tạo chuỗi DCA
4. **Theo dõi** qua panel thông tin hoặc log

## 📊 Cách thức hoạt động

### Quy trình nhận diện lệnh gốc:
```
┌─────────────────────┐
│  Quét tất cả lệnh   │
└─────────┬───────────┘
          │
┌─────────▼───────────┐
│ Magic = 0 AND       │
│ Comment rỗng?       │
└─────────┬───────────┘
          │ YES
┌─────────▼───────────┐
│  Tạo chuỗi DCA mới  │
└─────────────────────┘
```

### Logic tính giá DCA:
```
Giá TB hiện tại = Σ(Giá × Volume) / Σ(Volume)
Giá DCA tiếp theo = Giá TB ± (Khoảng cách × Point)
```

### Quy tắc khối lượng:
```
Volume DCA mới = Volume lệnh cuối × Hệ số nhân
```

## 🔧 Cấu trúc Code

### DCA_Core.mqh
- `struct DCAChain`: Cấu trúc lưu trữ thông tin chuỗi DCA
- `class DCAManager`: Lớp quản lý chính
  - `CheckForNewMasterOrders()`: Tìm lệnh gốc mới
  - `ManageActiveDCAChains()`: Quản lý chuỗi đang hoạt động
  - `CalculateNextEntryPrice()`: Tính giá vào lệnh tiếp theo
  - `PlaceNewDCAOrder()`: Đặt lệnh DCA mới

### DCA_Master_EA.mq5
- EA chính tích hợp DCAManager
- Giao diện người dùng với panel thông tin
- Xử lý sự kiện và debug

## 📈 Ví dụ thực tế

### Tình huống 1: Lệnh BUY
```
Lệnh gốc: BUY 0.10 XAUUSD @ 2000.00 (Magic=0, Comment="")
↓ EA nhận nuôi
DCA 1:    BUY 0.15 XAUUSD @ 1950.00 (Magic=123456, Comment="DCA_MASTER - Order #2")
DCA 2:    BUY 0.23 XAUUSD @ 1900.00 (Magic=123456, Comment="DCA_MASTER - Order #3")
```

### Tình huống 2: Nhiều chuỗi
```
Chuỗi A: BUY XAUUSD (3 lệnh) - Magic=111111
Chuỗi B: SELL EURUSD (2 lệnh) - Magic=222222
Chuỗi C: BUY GBPUSD (1 lệnh) - Magic=333333
```

## ⚠️ Lưu ý quan trọng

### Điều kiện nhận nuôi lệnh:
- ✅ Magic Number = 0
- ✅ Comment rỗng hoặc không chứa tên bot
- ✅ Cùng symbol với EA
- ❌ Đã được quản lý bởi EA khác

### Điều kiện dừng quản lý:
- Lệnh gốc bị đóng (TP/SL/thủ công)
- Đạt số lệnh DCA tối đa
- EA bị tắt

### Tối ưu hóa:
- Sử dụng khoảng cách phù hợp với volatility của symbol
- Hệ số nhân không quá lớn để tránh rủi ro
- Giới hạn số lệnh DCA hợp lý

## 🐛 Debug và Troubleshooting

### Panel thông tin:
- **Chuỗi DCA**: Số chuỗi đang quản lý
- **Debug Positions**: Xem tất cả lệnh trên biểu đồ
- **DCA Status**: Trạng thái chi tiết từng chuỗi

### Log quan trọng:
```
✅ Đã nhận quản lý lệnh gốc #123456
📊 Chuỗi #123456: Giá TB=2000.00, Lệnh tiếp theo=1950.00
✅ Đã đặt lệnh DCA #2 cho chuỗi #123456
⚠️ Lệnh gốc #123456 đã bị đóng. Ngừng quản lý chuỗi DCA.
```

## 🚀 Mở rộng

### Có thể tùy chỉnh:
- Logic tính giá DCA (theo % thay vì pip)
- Trailing stop cho chuỗi DCA
- Thông báo telegram
- Backup/restore trạng thái

### Tích hợp với:
- Các EA signal khác
- Trading view webhook
- Copy trading system

---
*Copyright 2025, BeoNguyen - EA được thiết kế để hỗ trợ trader quản lý DCA hiệu quả và an toàn.*