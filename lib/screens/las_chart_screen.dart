import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import 'curve_settings_screen.dart';

class LasChartScreen extends StatefulWidget {
  final List<BlockData> blockList;
  final List<String> parameterNames;
  final List<String> parameterUnits;
  final List<String> parameterDescriptions;
  final List<CurveInfo> curveInfoList;

  const LasChartScreen({
    super.key,
    required this.blockList,
    required this.parameterNames,
    required this.parameterUnits,
    required this.parameterDescriptions,
    required this.curveInfoList,
  });

  @override
  State<LasChartScreen> createState() => _LasChartScreenState();
}

class _LasChartScreenState extends State<LasChartScreen> {
  // Curve display settings
  Map<int, bool> curveVisibility = {};
  Map<int, Color> curveColors = {};
  Map<int, double> curveWidths = {};
  Map<int, double> curveMinValues = {};
  Map<int, double> curveMaxValues = {};

  // Chart settings
  bool showGrid = true;
  bool showTooltip = false;

  @override
  void initState() {
    super.initState();
    _initializeCurveSettings();
  }

  void _initializeCurveSettings() {
    // Khởi tạo settings cho từng curve (bỏ qua curve đầu tiên vì đó là index)
    for (int i = 1; i < widget.curveInfoList.length; i++) {
      // Start from 1
      curveVisibility[i] = i <= 5; // Hiển thị 5 curve đầu tiên
      curveColors[i] = _getDefaultColor(i);
      curveWidths[i] = 2.0;

      // Tính min/max values cho curve
      List<double> values = [];
      int dataIndex = i - 1; // Map từ curveInfoList index sang block.data index
      for (var block in widget.blockList) {
        if (dataIndex >= 0 &&
            dataIndex < block.data.length &&
            block.data[dataIndex].isNotEmpty) {
          values.add(block.data[dataIndex][0]);
        }
      }

      if (values.isNotEmpty) {
        curveMinValues[i] = values.reduce((a, b) => a < b ? a : b);
        curveMaxValues[i] = values.reduce((a, b) => a > b ? a : b);
      } else {
        curveMinValues[i] = 0.0;
        curveMaxValues[i] = 100.0;
      }
    }
  }

  Color _getDefaultColor(int index) {
    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đồ Thị LAS'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _openCurveSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Cài đặt Curves',
          ),
          IconButton(
            onPressed: () => setState(() => showGrid = !showGrid),
            icon: Icon(showGrid ? Icons.grid_on : Icons.grid_off),
            tooltip: 'Hiển thị lưới',
          ),
        ],
      ),
      body: widget.blockList.isEmpty
          ? const Center(child: Text('Không có dữ liệu để hiển thị'))
          : Column(
              children: [
                // Chart info bar
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Text('Số điểm dữ liệu: ${widget.blockList.length}'),
                      const SizedBox(width: 16),
                      Text('${_getIndexTypeLabel()}: ${_getIndexRange()}'),
                      const SizedBox(width: 16),
                      Text(
                        'Curves hiển thị: ${curveVisibility.values.where((v) => v).length}',
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _resetView,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset View'),
                      ),
                    ],
                  ),
                ),

                // Chart
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: showGrid),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                            axisNameWidget: Text(
                              _getIndexTypeLabel(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(0),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                            axisNameWidget: const Text(
                              'Values',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: _buildLineBarsData(),
                        lineTouchData: LineTouchData(enabled: showTooltip),
                      ),
                    ),
                  ),
                ),

                // Legend
                Container(
                  height: 100,
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        widget.curveInfoList.length - 1, // Skip index curve
                    itemBuilder: (context, index) {
                      int curveIndex =
                          index + 1; // Skip index curve (start from 1)
                      if (curveVisibility[curveIndex] != true)
                        return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 3,
                                  color: curveColors[curveIndex],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.curveInfoList[curveIndex].mnemonic,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              widget.curveInfoList[curveIndex].unit,
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              widget.curveInfoList[curveIndex].description,
                              style: const TextStyle(fontSize: 8),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    List<LineChartBarData> lineBars = [];

    for (
      int curveIndex = 1; // Start from 1 to skip index curve
      curveIndex < widget.curveInfoList.length;
      curveIndex++
    ) {
      if (curveVisibility[curveIndex] != true) continue;

      List<FlSpot> spots = [];
      int dataIndex =
          curveIndex - 1; // Map từ curveInfoList index sang block.data index

      for (
        int blockIndex = 0;
        blockIndex < widget.blockList.length;
        blockIndex++
      ) {
        var block = widget.blockList[blockIndex];
        if (dataIndex >= 0 &&
            dataIndex < block.data.length &&
            block.data[dataIndex].isNotEmpty) {
          double value = block.data[dataIndex][0];

          // Normalize value theo min/max của curve
          double normalizedValue = _normalizeValue(
            value,
            curveMinValues[curveIndex]!,
            curveMaxValues[curveIndex]!,
            curveIndex,
          );

          spots.add(FlSpot(normalizedValue, block.index));
        }
      }

      if (spots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: spots,
            color: curveColors[curveIndex],
            barWidth: curveWidths[curveIndex]!,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    }

    return lineBars;
  }

  double _normalizeValue(double value, double min, double max, int curveIndex) {
    if (max == min) return 0.0;

    // Normalize về range 0-100 cho mỗi curve với offset
    double normalized = ((value - min) / (max - min)) * 100;
    return normalized + (curveIndex * 120); // Offset mỗi curve 120 đơn vị
  }

  void _openCurveSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CurveSettingsScreen(
          curveInfoList: widget.curveInfoList,
          curveVisibility: curveVisibility,
          curveColors: curveColors,
          curveWidths: curveWidths,
          curveMinValues: curveMinValues,
          curveMaxValues: curveMaxValues,
          onSettingsChanged:
              (visibility, colors, widths, minValues, maxValues) {
                setState(() {
                  curveVisibility = visibility;
                  curveColors = colors;
                  curveWidths = widths;
                  curveMinValues = minValues;
                  curveMaxValues = maxValues;
                });
              },
        ),
      ),
    );
  }

  void _resetView() {
    setState(() {
      _initializeCurveSettings();
      showGrid = true;
      showTooltip = false;
    });
  }

  String _getIndexTypeLabel() {
    if (widget.blockList.isEmpty) return 'Index';
    return widget.blockList.first.indexType == 'TIME' ? 'Time' : 'Depth';
  }

  String _getIndexRange() {
    if (widget.blockList.isEmpty) return '';
    double min = widget.blockList.first.index;
    double max = widget.blockList.last.index;
    String unit = widget.blockList.first.indexType == 'TIME' ? 's' : 'm';
    return '${min.toStringAsFixed(2)} - ${max.toStringAsFixed(2)} $unit';
  }
}
