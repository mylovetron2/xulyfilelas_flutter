# xulyfilelas_flutter

# Xử Lý File LAS - Flutter Version

## Giới thiệu

Đây là phiên bản Flutter của ứng dụng Xử Lý File LAS, được chuyển đổi từ version Qt/C++ gốc. Ứng dụng này cung cấp các chức năng xử lý file LAS và TXT trong lĩnh vực dầu khí.

## Chức năng chính

### 1. Xử lý và Tách File
- **Chọn file LAS**: Chọn file LAS đầu vào để xử lý
- **Chọn file TXT**: Chọn file TXT chứa dữ liệu độ sâu (TIME/DEPTH)
- **Tách file**: Merge dữ liệu TXT vào LAS và tạo file LAS mới
  - Đồng bộ dữ liệu độ sâu theo TIME
  - Loại bỏ block không khớp
  - Nội suy dữ liệu thiếu
  - Phân tích xu hướng độ sâu

### 2. Vẽ Biểu Đồ
- Hiển thị biểu đồ từ dữ liệu TXT
- Hỗ trợ zoom và pan
- Đảo trục Y (TIME/DEPTH)
- Tooltip hiển thị giá trị chi tiết

### 3. Chuyển Đổi File
- Chuyển đổi file LIS thành LAS (chức năng cơ bản)

## Cài đặt và Chạy

### Yêu cầu
- Flutter SDK >= 3.1.0
- Dart SDK >= 3.1.0

### Các bước cài đặt

1. **Clone hoặc copy project**
```bash
cd xulyfilelas_flutter
```

2. **Cài đặt dependencies**
```bash
flutter pub get
```

3. **Chạy ứng dụng**
```bash
flutter run
```

### Build cho production

**Windows:**
```bash
flutter build windows
```

**Android:**
```bash
flutter build apk
```

**iOS:**
```bash
flutter build ios
```

## So sánh với Version Qt/C++

| Chức năng | Qt/C++ | Flutter |
|-----------|---------|---------|
| File picker | QFileDialog | file_picker package |
| Progress dialog | QProgressDialog | CircularProgressIndicator |
| Charts | QtCharts | fl_chart |
| Message boxes | QMessageBox | AlertDialog |
| File operations | QFile, QTextStream | dart:io File |

## Ưu điểm của Flutter Version

1. **Cross-platform**: Chạy được trên Windows, macOS, Linux, Android, iOS
2. **Modern UI**: Giao diện Material Design hiện đại
3. **Hot reload**: Phát triển nhanh hơn
4. **Deployment**: Dễ dàng deploy lên mobile và web
