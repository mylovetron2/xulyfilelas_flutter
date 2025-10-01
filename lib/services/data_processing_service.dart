import 'dart:math';
import '../models/models.dart';

class DataProcessingService {
  // Chuyển đổi chuỗi thời gian thành giây (tương đương timeStringToSeconds trong C++)
  static int timeStringToSeconds(String timeStr) {
    List<String> parts = timeStr.split(':');
    if (parts.length != 4) {
      return 0; // hoặc xử lý lỗi
    }

    int days = int.tryParse(parts[0]) ?? 0;
    int hours = int.tryParse(parts[1]) ?? 0;
    int minutes = int.tryParse(parts[2]) ?? 0;
    int seconds = int.tryParse(parts[3]) ?? 0;

    return (days * 86400 + hours * 3600 + minutes * 60 + seconds) * 1000;
  }

  // Chuyển đổi giây thành chuỗi thời gian
  static String secondsToTimeString(int totalSeconds) {
    totalSeconds = totalSeconds ~/ 1000;
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // Phân tích xu hướng độ sâu bằng hồi quy tuyến tính
  static Map<String, dynamic> analyzeDepthTrend(List<double> depthList) {
    if (depthList.length <= 1) {
      return {'trend': 'KHÔNG ĐỔI', 'slope': 0.0, 'isIncreasing': true};
    }

    int n = depthList.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += depthList[i];
      sumXY += i * depthList[i];
      sumXX += i * i;
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    String trend;
    bool isIncreasing;

    if (slope > 0.0) {
      trend = 'TĂNG';
      isIncreasing = true;
    } else if (slope < 0.0) {
      trend = 'GIẢM';
      isIncreasing = false;
    } else {
      trend = 'KHÔNG ĐỔI';
      isIncreasing = true;
    }

    return {'trend': trend, 'slope': slope, 'isIncreasing': isIncreasing};
  }

  // Tạo dãy độ sâu đều và nội suy giá trị
  static Map<String, List<double>> createRegularDepthsWithInterpolation(
    List<double> dosauList,
  ) {
    if (dosauList.length <= 1) {
      return {'regularDepths': [], 'interpolatedValues': []};
    }

    List<double> regularDepths = [];
    List<double> interpolatedValues = [];

    double minDepth = dosauList.reduce(min);
    double maxDepth = dosauList.reduce(max);

    if (minDepth > maxDepth) {
      double temp = minDepth;
      minDepth = maxDepth;
      maxDepth = temp;
    }

    // Tạo dãy độ sâu đều với step 0.1
    for (double d = minDepth; d <= maxDepth + 1e-6; d += 0.1) {
      double dRound = (d * 1000).round() / 1000.0;
      regularDepths.add(dRound);
    }

    // Tạo map độ sâu gốc -> giá trị
    Map<double, double> depthToValue = {};
    for (double v in dosauList) {
      depthToValue[v] = v;
    }

    // Nội suy tuyến tính cho các độ sâu đều nếu thiếu
    for (double d in regularDepths) {
      if (depthToValue.containsKey(d)) {
        interpolatedValues.add(depthToValue[d]!);
      } else {
        // Tìm 2 điểm gần nhất để nội suy
        double d1 = minDepth, d2 = maxDepth;
        for (double v in dosauList) {
          if (v < d && v > d1) d1 = v;
          if (v > d && v < d2) d2 = v;
        }

        if (d1 == d2) {
          interpolatedValues.add(d1);
        } else {
          // Nội suy tuyến tính
          double v1 = d1, v2 = d2;
          double interp = v1 + (v2 - v1) * (d - d1) / (d2 - d1);
          interpolatedValues.add(interp);
        }
      }
    }

    return {
      'regularDepths': regularDepths,
      'interpolatedValues': interpolatedValues,
    };
  }

  // Xử lý blockList (tương đương xuLyBlocklist trong C++)
  static List<BlockData> processBlockList(List<BlockData> blocks) {
    print('=== PROCESSING BLOCK LIST ===');
    print('Input blocks: ${blocks.length}');

    if (blocks.isEmpty) return blocks;

    // Gom nhóm các block theo depth
    Map<double, List<BlockData>> groupedBlocks = {};

    for (BlockData block in blocks) {
      bool found = false;
      for (double key in groupedBlocks.keys) {
        if ((key - block.depth).abs() < 1e-9) {
          // So sánh double an toàn
          groupedBlocks[key]!.add(block);
          found = true;
          break;
        }
      }
      if (!found) {
        groupedBlocks[block.depth] = [block];
      }
    }

    List<BlockData> result = [];

    print('Grouped blocks count: ${groupedBlocks.length}');

    for (MapEntry<double, List<BlockData>> entry in groupedBlocks.entries) {
      List<BlockData> blockGroup = entry.value;

      if (blockGroup.isEmpty) continue;

      // Nếu chỉ có 1 block, giữ nguyên
      if (blockGroup.length == 1) {
        result.add(blockGroup.first);
        continue;
      }

      // Tính trung bình các block cùng depth
      int maxRow = 0;
      int maxCol = 0;

      for (BlockData b in blockGroup) {
        if (b.data.length > maxRow) maxRow = b.data.length;
        for (List<double> row in b.data) {
          if (row.length > maxCol) maxCol = row.length;
        }
      }

      List<List<double>> avgRows = [];

      for (int rowIdx = 0; rowIdx < maxRow; rowIdx++) {
        List<double> sumCol = List.filled(maxCol, 0.0);
        List<int> countCol = List.filled(maxCol, 0);

        for (BlockData b in blockGroup) {
          if (b.data.length > rowIdx) {
            List<double> row = b.data[rowIdx];
            for (int col = 0; col < row.length && col < maxCol; col++) {
              sumCol[col] += row[col];
              countCol[col]++;
            }
          }
        }

        List<double> avgCol = [];
        for (int col = 0; col < maxCol; col++) {
          if (countCol[col] > 0) {
            avgCol.add(sumCol[col] / countCol[col]);
          } else {
            avgCol.add(0.0);
          }
        }
        avgRows.add(avgCol);
      }

      BlockData newBlock = BlockData(
        index: entry.key,
        indexType: "DEPTH",
        data: avgRows,
      );
      result.add(newBlock);
    }

    // Xác định xu hướng độ sâu
    List<double> depthList = result.map((b) => b.depth).toList();
    Map<String, dynamic> trendAnalysis = analyzeDepthTrend(depthList);
    bool isDepthIncreasing = trendAnalysis['isIncreasing'];

    // Lọc các block theo xu hướng chính, loại bỏ block có độ sâu âm
    if (result.isNotEmpty) {
      List<BlockData> filtered = [];

      // Chỉ thêm block đầu tiên nếu depth >= 0
      if (result.first.depth >= 0) {
        filtered.add(result.first);
      }

      for (int i = 1; i < result.length; i++) {
        // Loại bỏ block có độ sâu âm
        if (result[i].depth < 0) continue;

        if (filtered.isEmpty) {
          filtered.add(result[i]);
          continue;
        }

        if (isDepthIncreasing) {
          if (result[i].depth >= filtered.last.depth) {
            filtered.add(result[i]);
          }
        } else {
          if (result[i].depth <= filtered.last.depth) {
            filtered.add(result[i]);
          }
        }
      }
      result = filtered;
    }

    print('After filtering: ${result.length} blocks');

    // Nội suy độ sâu nếu có khoảng trống lớn hơn 0.1 (step = 0.1)
    if (result.length > 1) {
      List<BlockData> interpolated = [];

      for (int i = 0; i < result.length - 1; i++) {
        BlockData b1 = result[i];
        BlockData b2 = result[i + 1];
        interpolated.add(b1);

        double d1 = b1.depth;
        double d2 = b2.depth;
        double step = (d2 > d1) ? 0.1 : -0.1;
        double nextDepth = d1 + step;

        // Chèn các giá trị nội suy giữa d1 và d2
        while ((step > 0 && nextDepth < d2 - 1e-6) ||
            (step < 0 && nextDepth > d2 + 1e-6)) {
          double interpDepth = (nextDepth * 1000).round() / 1000.0;

          // Nội suy từng giá trị trong data
          int rowCount = min(b1.data.length, b2.data.length);
          List<List<double>> interpData = [];

          for (int row = 0; row < rowCount; row++) {
            List<double> row1 = b1.data[row];
            List<double> row2 = b2.data[row];
            int colCount = min(row1.length, row2.length);
            List<double> interpRow = [];

            for (int col = 0; col < colCount; col++) {
              double v1 = row1[col];
              double v2 = row2[col];
              double t = (interpDepth - d1) / (d2 - d1);
              double vInterp = v1 + (v2 - v1) * t;
              interpRow.add(vInterp);
            }
            interpData.add(interpRow);
          }

          BlockData interpBlock = BlockData(
            index: interpDepth,
            indexType: "DEPTH",
            data: interpData,
          );
          interpolated.add(interpBlock);
          nextDepth += step;
        }
      }

      interpolated.add(result.last);
      result = interpolated;
    }

    print('Final processed blocks: ${result.length}');
    if (result.isNotEmpty) {
      print(
        'First depth: ${result.first.depth}, Last depth: ${result.last.depth}',
      );
    }

    return result;
  }
}
