class BlockData {
  double index; // Có thể là depth hoặc time
  String indexType; // "DEPTH" hoặc "TIME"
  List<List<double>> data;

  BlockData({
    this.index = 0.0,
    this.indexType = "DEPTH",
    List<List<double>>? data,
  }) : data = data ?? [];

  // Getter for backward compatibility
  double get depth => index;
  set depth(double value) => index = value;

  // Convert from Map (for JSON serialization)
  factory BlockData.fromMap(Map<String, dynamic> map) {
    return BlockData(
      index: map['index']?.toDouble() ?? map['depth']?.toDouble() ?? 0.0,
      indexType: map['indexType'] ?? "DEPTH",
      data: List<List<double>>.from(
        map['data']?.map((x) => List<double>.from(x)) ?? [],
      ),
    );
  }

  // Convert to Map (for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'indexType': indexType,
      'depth': index, // For backward compatibility
      'data': data,
    };
  }

  @override
  String toString() =>
      'BlockData($indexType: $index, data: ${data.length} rows)';
}
