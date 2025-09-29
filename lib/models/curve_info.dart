class CurveInfo {
  String mnemonic; // Tên viết tắt (ví dụ: DEPT.M)
  String unit; // Đơn vị (ví dụ: M, MS, V, ...)
  String value; // Giá trị (ví dụ: 86283000.000)
  String description; // Mô tả hoặc comment

  CurveInfo({
    this.mnemonic = '',
    this.unit = '',
    this.value = '',
    this.description = '',
  });

  // Convert from Map (for JSON serialization)
  factory CurveInfo.fromMap(Map<String, dynamic> map) {
    return CurveInfo(
      mnemonic: map['mnemonic'] ?? '',
      unit: map['unit'] ?? '',
      value: map['value'] ?? '',
      description: map['description'] ?? '',
    );
  }

  // Convert to Map (for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'mnemonic': mnemonic,
      'unit': unit,
      'value': value,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'CurveInfo(mnemonic: $mnemonic, unit: $unit, value: $value, description: $description)';
  }
}
