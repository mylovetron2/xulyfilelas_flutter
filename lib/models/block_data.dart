class BlockData {
  double depth;
  List<List<double>> data;

  BlockData({this.depth = 0.0, List<List<double>>? data}) : data = data ?? [];

  // Convert from Map (for JSON serialization)
  factory BlockData.fromMap(Map<String, dynamic> map) {
    return BlockData(
      depth: map['depth']?.toDouble() ?? 0.0,
      data: List<List<double>>.from(
        map['data']?.map((x) => List<double>.from(x)) ?? [],
      ),
    );
  }

  // Convert to Map (for JSON serialization)
  Map<String, dynamic> toMap() {
    return {'depth': depth, 'data': data};
  }

  @override
  String toString() => 'BlockData(depth: $depth, data: ${data.length} rows)';
}
