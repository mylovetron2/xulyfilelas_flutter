import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:convert';

class ChartScreen extends StatefulWidget {
  final String txtFilePath;

  const ChartScreen({super.key, required this.txtFilePath});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<FlSpot> chartData = [];
  bool isLoading = true;
  String errorMessage = '';
  bool isZoomMode = false;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    try {
      File txtFile = File(widget.txtFilePath);
      if (!await txtFile.exists()) {
        throw Exception('Không mở được file TXT!');
      }

      List<String> lines = await txtFile.readAsLines(encoding: utf8);
      List<double> xList = [];
      List<double> yList = [];
      int lineIdx = 0;

      for (String line in lines) {
        String trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        // Bỏ qua dòng tiêu đề và dòng đơn vị (2 dòng đầu)
        if (lineIdx < 2) {
          lineIdx++;
          continue;
        }

        List<String> parts = trimmedLine.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          double? x;

          // Thử parse cột 1 là số
          x = double.tryParse(parts[0]);

          if (x == null) {
            // Nếu không phải số, thử parse dạng thời gian d:hh:mm:ss hoặc hh:mm:ss
            List<String> timeParts = parts[0].split(':');
            int totalSeconds = 0;

            if (timeParts.length == 4) {
              int days = int.tryParse(timeParts[0]) ?? 0;
              int hours = int.tryParse(timeParts[1]) ?? 0;
              int minutes = int.tryParse(timeParts[2]) ?? 0;
              int seconds = int.tryParse(timeParts[3]) ?? 0;
              totalSeconds =
                  days * 86400 + hours * 3600 + minutes * 60 + seconds;
            } else if (timeParts.length == 3) {
              int hours = int.tryParse(timeParts[0]) ?? 0;
              int minutes = int.tryParse(timeParts[1]) ?? 0;
              int seconds = int.tryParse(timeParts[2]) ?? 0;
              totalSeconds = hours * 3600 + minutes * 60 + seconds;
            } else {
              print('Bỏ qua dòng không nhận diện được thời gian: $line');
              lineIdx++;
              continue;
            }
            x = totalSeconds.toDouble();
          }

          double? y = double.tryParse(parts[1]);

          if (y != null) {
            xList.add(x);
            yList.add(y);
          } else {
            print('Bỏ qua dòng không hợp lệ (không parse được số): $line');
          }
        } else {
          print('Bỏ qua dòng không đủ cột dữ liệu: $line');
        }
        lineIdx++;
      }

      if (xList.isEmpty || yList.isEmpty) {
        throw Exception('Không có dữ liệu hợp lệ để vẽ!');
      }

      // Tạo chart data với trục đảo ngược: giá trị là X, TIME/DEPTH là Y
      List<FlSpot> spots = [];
      for (int i = 0; i < xList.length; i++) {
        spots.add(
          FlSpot(yList[i], xList[i]),
        ); // Đổi trục: giá trị là X, TIME/DEPTH là Y
      }

      setState(() {
        chartData = spots;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biểu đồ dữ liệu TXT'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(isZoomMode ? Icons.pan_tool : Icons.zoom_in),
            onPressed: () {
              setState(() {
                isZoomMode = !isZoomMode;
              });
            },
            tooltip: isZoomMode ? 'Chuyển sang Pan' : 'Chuyển sang Zoom',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = '';
                chartData.clear();
              });
              _loadChartData();
            },
            tooltip: 'Reset Zoom',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Biểu đồ: ${widget.txtFilePath.split('/').last}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Lỗi: $errorMessage',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : _buildChart(),
            ),
            if (!isLoading && errorMessage.isEmpty)
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Điểm dữ liệu: ${chartData.length} | '
                  'Chế độ: ${isZoomMode ? "Zoom" : "Pan"}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (chartData.isEmpty) {
      return const Center(child: Text('Không có dữ liệu để hiển thị'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) {
            return const FlLine(color: Colors.grey, strokeWidth: 0.5);
          },
          getDrawingVerticalLine: (value) {
            return const FlLine(color: Colors.grey, strokeWidth: 0.5);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Cột 2 (Giá trị)'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: null,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Cột 1 (TIME hoặc DEPTH)'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: null,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: chartData,
            isCurved: false,
            color: Colors.blue,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  'X: ${barSpot.x.toStringAsFixed(2)}\nY: ${barSpot.y.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
