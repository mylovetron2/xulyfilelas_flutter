import 'dart:io';
import 'dart:convert';
import 'dart:math';
import '../models/models.dart';

class FileService {
  // Đọc file TXT (tương đương readTXT trong C++)
  static Future<Map<String, dynamic>> readTXT(String txtPath) async {
    List<String> headerList = [];
    List<String> unitList = [];
    List<List<String>> dataRows = [];

    try {
      File txtFile = File(txtPath);
      if (!await txtFile.exists()) {
        throw Exception('Không mở được file TXT!');
      }

      List<String> lines = await txtFile.readAsLines(encoding: utf8);

      bool foundHeader = false;
      bool foundUnit = false;

      for (String line in lines) {
        String trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        // Bỏ qua dòng ngày tháng hoặc dòng tiêu đề phụ
        if (trimmedLine.toLowerCase().contains('- time - recorder') ||
            trimmedLine.toLowerCase().contains('depth') ||
            trimmedLine.toLowerCase().contains('logging') ||
            trimmedLine.toLowerCase().contains('vietsovpetro') ||
            trimmedLine.toLowerCase().contains('recorder') ||
            RegExp(r'^\d{1,2}/\d{1,2}/\d{4}').hasMatch(trimmedLine)) {
          continue;
        }

        List<String> parts = trimmedLine.split(RegExp(r'\s+'));

        // Nhận diện dòng header (TIME DEPT ...)
        if (!foundHeader &&
            parts.isNotEmpty &&
            (parts[0].toUpperCase() == 'TIME' ||
                parts[0].toUpperCase() == 'DEPTH')) {
          headerList = parts;
          foundHeader = true;
          continue;
        }

        // Nhận diện dòng đơn vị (nếu có)
        if (foundHeader &&
            !foundUnit &&
            parts.isNotEmpty &&
            (parts[0].contains(':') ||
                parts[0].contains('M') ||
                parts[0].contains('S'))) {
          unitList = parts;
          foundUnit = true;
          continue;
        }

        // Nhận diện dòng dữ liệu bắt đầu bằng TIME hợp lệ (0:00:00:01 ...)
        if (parts.isNotEmpty &&
            RegExp(r'^\d+:\d{2}:\d{2}:\d{2}$').hasMatch(parts[0])) {
          dataRows.add(parts);
        }
      }

      // Chuyển đổi TIME sang giây cho từng dòng dữ liệu
      for (List<String> row in dataRows) {
        if (row.isNotEmpty) {
          String timeStr = row[0];
          List<String> timeParts = timeStr.split(':');
          int totalSeconds = 0;

          if (timeParts.length == 4) {
            int days = int.tryParse(timeParts[0]) ?? 0;
            int hours = int.tryParse(timeParts[1]) ?? 0;
            int minutes = int.tryParse(timeParts[2]) ?? 0;
            int seconds = int.tryParse(timeParts[3]) ?? 0;
            totalSeconds = days * 86400 + hours * 3600 + minutes * 60 + seconds;
          } else if (timeParts.length == 3) {
            int hours = int.tryParse(timeParts[0]) ?? 0;
            int minutes = int.tryParse(timeParts[1]) ?? 0;
            int seconds = int.tryParse(timeParts[2]) ?? 0;
            totalSeconds = hours * 3600 + minutes * 60 + seconds;
          }

          row[0] = totalSeconds.toString();
          print('TIME TXT chuyển sang giây: $timeStr -> $totalSeconds');

          // Xử lý giá trị DEPTH
          if (row.length > 1) {
            double? depthVal = double.tryParse(row[1]);
            if (depthVal != null) {
              double depthFloor = (depthVal * 10).floor() / 10.0;
              row[1] = depthFloor.toStringAsFixed(3);
            }
          }
        }
      }

      // Debug logging
      print('=== READ TXT RESULTS ===');
      print('Found header: $foundHeader, Header: $headerList');
      print('Found unit: $foundUnit, Unit: $unitList');
      print('Data rows: ${dataRows.length}');

      return {
        'headerList': headerList,
        'unitList': unitList,
        'dataRows': dataRows,
        'success': true,
        'message': 'Đọc file TXT thành công',
      };
    } catch (e) {
      return {
        'headerList': [],
        'unitList': [],
        'dataRows': [],
        'success': false,
        'message': 'Lỗi khi đọc file TXT: $e',
      };
    }
  }

  // Parse file LAS và merge với dữ liệu TXT
  static Future<Map<String, dynamic>> mergeTxtLas(
    String lasPath,
    List<List<String>> dataRows,
  ) async {
    List<CurveInfo> curveInfoList = [];
    List<CurveInfo> wellInfoList = [];
    List<BlockData> blockList = [];

    try {
      File lasFile = File(lasPath);
      if (!await lasFile.exists()) {
        throw Exception('Không mở được file LAS!');
      }

      // Xử lý dataRow để tìm min max depth
      Set<int> txtTimeSet = {};
      Map<int, double> timeToDepthMap = {};
      int minTime = double.maxFinite.toInt(); // Max safe int
      int maxTime = -double.maxFinite.toInt(); // Min safe int

      for (List<String> row in dataRows) {
        if (row.isEmpty || row.length < 2) continue;

        int? t = int.tryParse(row[0]);
        double? depthVal = double.tryParse(row[1]);

        if (t != null && depthVal != null) {
          txtTimeSet.add(t);
          double depthValFloor = (depthVal * 10).floor() / 10.0;
          String depthStr = '${depthValFloor.toStringAsFixed(1)}00';
          timeToDepthMap[t] = double.tryParse(depthStr) ?? 0.0;
          if (t < minTime) minTime = t;
          if (t > maxTime) maxTime = t;
        }
      }

      if (minTime == double.maxFinite.toInt() ||
          maxTime == -double.maxFinite.toInt()) {
        throw Exception('Không tìm thấy TIME hợp lệ trong TXT!');
      }

      List<String> lines = await lasFile.readAsLines(encoding: utf8);
      String section = '';

      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        String trimmed = line.trim();

        if (trimmed.startsWith('~')) {
          section = trimmed.toUpperCase();
          continue;
        }

        if (section == '~CURVE INFORMATION' || section == '~CURVE') {
          if (trimmed.startsWith('#') || trimmed.isEmpty) continue;

          // Regex nhận mọi trường hợp: MNEM . UNIT VALUE : DESCRIPTION
          RegExp re = RegExp(
            r'^([A-Za-z0-9_]+)\s*\.\s*([A-Za-z0-9_]*)\s*([^:]*)?:?\s*(.*)$',
          );
          RegExpMatch? match = re.firstMatch(trimmed);

          if (match != null) {
            CurveInfo info = CurveInfo(
              mnemonic: match.group(1)?.trim() ?? '',
              unit: match.group(2)?.trim() ?? '',
              value: match.group(3)?.trim() ?? '',
              description: match.group(4)?.trim() ?? '',
            );
            curveInfoList.add(info);
          }
        } else if (section == '~WELL INFORMATION' || section == '~WELL') {
          if (trimmed.startsWith('#') || trimmed.isEmpty) continue;

          RegExp re = RegExp(
            r'^([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)\s+([^:]*):\s*(.*)$',
          );
          RegExpMatch? match = re.firstMatch(trimmed);

          if (match != null) {
            CurveInfo info = CurveInfo(
              mnemonic: match.group(1)?.trim() ?? '',
              unit: match.group(2)?.trim() ?? '',
              value: match.group(3)?.trim() ?? '',
              description: match.group(4)?.trim() ?? '',
            );
            wellInfoList.add(info);
          }
        } else if (section == '~ASCII' || section == '~ASCII DATA') {
          blockList.clear();
          print('=== PARSING ASCII SECTION ===');
          print('Number of curves: ${curveInfoList.length}');

          // numCurves = curveInfoList.size() - 1 (trừ DEPT/TIME curve đầu tiên)
          int numCurves = curveInfoList.length - 1;
          print('numCurves (data values per block): $numCurves');

          while (i < lines.length) {
            String line = lines[i];
            String trimmed = line.trim();

            // Bỏ qua dòng trống và comments
            if (trimmed.isEmpty || trimmed.startsWith('#')) {
              i++;
              continue;
            }

            // Kiểm tra nếu gặp section mới thì dừng
            if (trimmed.startsWith('~')) {
              break;
            }

            // Xử lý depth header (TIME)
            double? depthVal = double.tryParse(trimmed);
            if (depthVal != null) {
              print('Found TIME block: $depthVal');
              BlockData block = BlockData(depth: depthVal);

              // Đọc các dòng dữ liệu tiếp theo cho block này
              i++; // Move to next line for data
              List<List<double>> values = [];
              int num = 0; // Đếm tổng số values đã đọc

              while (i < lines.length) {
                if (i >= lines.length) break;

                line = lines[i];
                String dataLineTrimmed = line.trim();

                // Dừng nếu gặp dòng trống (kết thúc block)
                if (dataLineTrimmed.isEmpty) {
                  break;
                }

                // Parse dòng data
                List<String> valueParts = dataLineTrimmed.split(RegExp(r'\s+'));
                List<double> row = [];

                for (String val in valueParts) {
                  double? d = double.tryParse(val);
                  if (d != null) {
                    row.add(d);
                    num++; // Đếm số values
                  }
                }

                if (row.isNotEmpty) {
                  values.add(row);
                }

                // Dừng khi đã đọc đủ numCurves values (như code C++)
                if (num >= numCurves) {
                  break;
                }

                i++;
              }

              block.data = values;
              blockList.add(block);
              print(
                'Added block with TIME=$depthVal, total values=$num/$numCurves, rows=${values.length}',
              );

              // Tiến tới dòng tiếp theo
              i++;
            } else {
              i++;
            }
          }
          print('Total blocks parsed: ${blockList.length}');
          break;
        }
      }

      // Lọc block theo TIME có trong TXT
      List<BlockData> filteredBlocks = [];

      // Tạo mapping từ TIME (giây) sang index trong dataRows để tra cứu depth
      Map<int, double> timeToDepthFromTxt = {};
      print('=== PARSING TXT DATA ===');
      print('Total dataRows: ${dataRows.length}');

      for (int i = 0; i < dataRows.length; i++) {
        List<String> row = dataRows[i];
        if (row.length >= 2) {
          int? timeSeconds = int.tryParse(row[0]);
          double? depthVal = double.tryParse(row[1]);

          if (i < 5) {
            // Debug first 5 rows
            print(
              '  Row $i: TIME="${row[0]}" -> ${timeSeconds}s, DEPTH="${row[1]}" -> ${depthVal}m',
            );
          }

          if (timeSeconds != null && depthVal != null) {
            double depthFloor = (depthVal * 10).floor() / 10.0;
            timeToDepthFromTxt[timeSeconds] = depthFloor;
          }
        }
      }
      print(
        'Successfully mapped TIME values: ${timeToDepthFromTxt.keys.toList().take(10)}',
      );

      // Logic sửa đổi: block.depth trong LAS là TIME (milliseconds), chia 1000 thành seconds
      print('=== PROCESSING LAS BLOCKS ===');
      print('Total LAS blocks: ${blockList.length}');

      for (int i = 0; i < blockList.length; i++) {
        BlockData block = blockList[i];
        // TIME trong LAS là milliseconds, chia 1000 thành seconds
        int timeInSeconds = (block.depth / 1000.0).round();

        if (i < 5) {
          // Debug first 5 blocks
          print('  Block $i: LAS_TIME=${block.depth}ms -> ${timeInSeconds}s');
        }

        // Tìm kiếm chính xác trước
        if (timeToDepthFromTxt.containsKey(timeInSeconds)) {
          double newDepth = timeToDepthFromTxt[timeInSeconds]!;
          if (i < 5) {
            print('    -> MATCH! New depth: ${newDepth}m');
          }
          block.depth = newDepth;
          filteredBlocks.add(block);
        } else {
          // Nếu không tìm thấy chính xác, thử tìm trong khoảng ±2 giây
          bool found = false;
          for (int offset = -2; offset <= 2 && !found; offset++) {
            int searchTime = timeInSeconds + offset;
            if (timeToDepthFromTxt.containsKey(searchTime)) {
              double newDepth = timeToDepthFromTxt[searchTime]!;
              if (i < 5) {
                print(
                  '    -> APPROXIMATE MATCH! offset=${offset}, time=${searchTime}s, depth=${newDepth}m',
                );
              }
              block.depth = newDepth;
              filteredBlocks.add(block);
              found = true;
            }
          }
          if (!found && i < 5) {
            print('    -> NO MATCH for ${timeInSeconds}s');
          }
        }
      }

      // Debug logging
      print('=== MERGE RESULTS ===');
      print('Original blocks: ${blockList.length}');
      print('Filtered blocks: ${filteredBlocks.length}');
      print('Time to depth mapping entries: ${timeToDepthFromTxt.length}');

      // Show detailed TIME comparison
      if (blockList.isNotEmpty) {
        print('LAS TIME samples (milliseconds):');
        for (
          int i = 0;
          i < (blockList.length < 5 ? blockList.length : 5);
          i++
        ) {
          double timeMs = blockList[i].depth;
          int timeSeconds = (timeMs / 1000.0).round();
          print('  Block $i: ${timeMs}ms -> ${timeSeconds}s');
        }
      }

      if (timeToDepthFromTxt.isNotEmpty) {
        print('TXT TIME samples (seconds):');
        int count = 0;
        for (var entry in timeToDepthFromTxt.entries) {
          if (count >= 5) break;
          print('  ${entry.key}s -> depth ${entry.value}m');
          count++;
        }
      }

      // Show matching results
      print('Matching TIME values:');
      int matchCount = 0;
      for (BlockData block in blockList) {
        int timeInSeconds = (block.depth / 1000.0).round();
        if (timeToDepthFromTxt.containsKey(timeInSeconds)) {
          if (matchCount < 5) {
            print(
              '  Match: LAS ${block.depth}ms (${timeInSeconds}s) -> TXT depth ${timeToDepthFromTxt[timeInSeconds]}m',
            );
          }
          matchCount++;
        }
      }
      print('Total matches: $matchCount/${blockList.length}');
      print('Total matches: $matchCount/${blockList.length}');

      if (filteredBlocks.isNotEmpty) {
        print(
          'First filtered block depth (converted from TXT): ${filteredBlocks.first.depth}',
        );
      }

      return {
        'curveInfoList': curveInfoList,
        'wellInfoList': wellInfoList,
        'blockList': filteredBlocks,
        'success': true,
        'message': 'Merge TXT và LAS thành công',
      };
    } catch (e) {
      return {
        'curveInfoList': [],
        'wellInfoList': [],
        'blockList': [],
        'success': false,
        'message': 'Lỗi khi merge TXT và LAS: $e',
      };
    }
  }

  // Ghi blockList ra file LAS mới
  static Future<bool> writeBlockListToLas(
    String outputPath,
    List<BlockData> blocks,
    List<CurveInfo> wellInfoList,
    List<CurveInfo> curveInfoList,
    bool isDepthIncreasing,
  ) async {
    print('=== WRITING LAS FILE ===');
    print('Output path: $outputPath');
    print('Blocks to write: ${blocks.length}');
    print('Well info entries: ${wellInfoList.length}');
    print('Curve info entries: ${curveInfoList.length}');
    print('Depth increasing: $isDepthIncreasing');

    try {
      File outFile = File(outputPath);
      StringBuffer content = StringBuffer();

      // Sửa thông tin Step
      for (CurveInfo info in wellInfoList) {
        if (info.mnemonic.toUpperCase() == 'STEP') {
          if (isDepthIncreasing) {
            info.value = '0.100'; // Cố định step 0.1
          } else {
            info.value = '-0.100'; // Cố định step -0.1
          }
          info.unit = 'M'; // Đơn vị mét
          break;
        }
      }

      // Sửa thông tin curve TIME thành DEPTH
      if (curveInfoList.isNotEmpty) {
        curveInfoList[0].mnemonic = 'DEPT';
        curveInfoList[0].unit = 'M';
        curveInfoList[0].description = 'M';
      }

      // Ghi section ~Version information
      content.writeln('~Version information');
      content.writeln(
        '  VERS.                         2.00 : CWLS LOG ASCII STANDARD - VERSION 2.00              ',
      );
      content.writeln(
        '  WRAP.                          YES : MULTIPLE LINES PER DEPTH STEP             ',
      );

      // Ghi Well information
      _writeCurveInfo(content, wellInfoList, '~Well information');

      // Ghi Curve information
      _writeCurveInfo(content, curveInfoList, '~Curve information');

      content.writeln('~ASCII');

      // Debug: Kiểm tra trước khi ghi blocks
      print('About to write ${blocks.length} blocks to ASCII section');

      // Ghi từng block
      for (BlockData block in blocks) {
        // Ghi depth với 3 số thập phân (vd: 12.300)
        content.writeln(block.depth.toStringAsFixed(3));

        for (List<double> row in block.data) {
          List<String> rowStrs = [];
          for (double v in row) {
            rowStrs.add(v.toStringAsFixed(3));
          }
          content.writeln(rowStrs.join('    '));
        }
      }

      await outFile.writeAsString(content.toString(), encoding: utf8);

      // Debug: Kiểm tra file đã được ghi
      print('File written successfully. Content length: ${content.length}');
      print(
        'ASCII section sample: ${content.toString().split('~ASCII').length > 1 ? content.toString().split('~ASCII')[1].substring(0, min(200, content.toString().split('~ASCII')[1].length)) : 'No ASCII section'}',
      );

      return true;
    } catch (e) {
      print('Lỗi khi ghi file LAS: $e');
      return false;
    }
  }

  static void _writeCurveInfo(
    StringBuffer content,
    List<CurveInfo> curveList,
    String sectionName,
  ) {
    content.writeln(sectionName);
    // Dòng tiêu đề mẫu
    content.writeln(
      '# ====.==============================:=====================================================',
    );

    for (CurveInfo info in curveList) {
      // Format: mnemonic.unit (left, 15), value (right, 15, 3 decimals), colon, description (left, 40)
      String mnemonicUnit = '${info.mnemonic}.${info.unit}';
      mnemonicUnit = mnemonicUnit.padRight(15);

      String value = '';
      if (info.value.isNotEmpty) {
        double? val = double.tryParse(info.value);
        if (val != null) {
          value = val.toStringAsFixed(3);
        } else {
          value = info.value;
        }
      }
      value = value.padLeft(15);

      String desc = info.description.padRight(40);
      String line = '$mnemonicUnit$value : $desc';
      content.writeln(line);
    }
  }
}
