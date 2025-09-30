import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import '../models/models.dart';

class LasService {
  // Đọc file LAS từ path (desktop)
  static Future<Map<String, dynamic>> readLasFile(String filePath) async {
    try {
      File file = File(filePath);
      if (!await file.exists()) {
        return {'success': false, 'message': 'File không tồn tại'};
      }

      String content = await file.readAsString(encoding: utf8);
      return _parseLasContent(content);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi đọc file: $e'};
    }
  }

  // Đọc file LAS từ bytes (web)
  static Future<Map<String, dynamic>> readLasFromBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      String content = utf8.decode(bytes);
      return _parseLasContent(content);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi đọc file: $e'};
    }
  }

  // Parse nội dung file LAS
  static Map<String, dynamic> _parseLasContent(String content) {
    try {
      List<String> lines = content.split('\n');

      // Khởi tạo các biến
      List<String> parameterNames = [];
      List<String> parameterUnits = [];
      List<String> parameterDescriptions = [];
      List<CurveInfo> curveInfoList = [];
      List<CurveInfo> wellInfoList = [];
      List<BlockData> blockList = [];

      String currentSection = '';
      bool inDataSection = false;
      List<String> dataLines = [];

      for (String line in lines) {
        line = line.trim();

        // Bỏ qua dòng trống
        if (line.isEmpty) continue;

        // Kiểm tra section headers
        if (line.startsWith('~')) {
          currentSection = line.toLowerCase();
          inDataSection =
              currentSection.contains('~a') ||
              currentSection.contains('~ascii');
          continue;
        }

        // Bỏ qua comments
        if (line.startsWith('#')) continue;

        if (inDataSection) {
          // Thu thập dữ liệu
          dataLines.add(line);
        } else if (currentSection.contains('~p') ||
            currentSection.contains('~parameter')) {
          // Parse parameter section
          _parseParameterLine(
            line,
            parameterNames,
            parameterUnits,
            parameterDescriptions,
          );
        } else if (currentSection.contains('~c') ||
            currentSection.contains('~curve')) {
          // Parse curve section
          _parseCurveLine(line, curveInfoList);
        } else if (currentSection.contains('~w') ||
            currentSection.contains('~well')) {
          // Parse well information section
          _parseWellLine(line, wellInfoList);
        }
      }

      // Xử lý dữ liệu ASCII
      if (dataLines.isNotEmpty && curveInfoList.isNotEmpty) {
        blockList = _parseDataLines(dataLines, curveInfoList);
      }

      return {
        'success': true,
        'parameterNames': parameterNames,
        'parameterUnits': parameterUnits,
        'parameterDescriptions': parameterDescriptions,
        'curveInfoList': curveInfoList,
        'wellInfoList': wellInfoList,
        'blockList': blockList,
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi parse file LAS: $e'};
    }
  }

  // Parse dòng parameter
  static void _parseParameterLine(
    String line,
    List<String> parameterNames,
    List<String> parameterUnits,
    List<String> parameterDescriptions,
  ) {
    try {
      // Format: MNEM.UNIT VALUE : DESCRIPTION
      if (!line.contains('.') || !line.contains(':')) return;

      List<String> parts = line.split(':');
      if (parts.length < 2) return;

      String leftPart = parts[0].trim();
      String description = parts[1].trim();

      // Tách mnem và unit
      List<String> mnemParts = leftPart.split('.');
      if (mnemParts.length < 2) return;

      String mnem = mnemParts[0].trim();
      String unit = mnemParts[1].split(' ')[0].trim(); // Lấy unit trước space

      parameterNames.add(mnem);
      parameterUnits.add(unit);
      parameterDescriptions.add(description);
    } catch (e) {
      // Bỏ qua dòng không parse được
    }
  }

  // Parse dòng curve
  static void _parseCurveLine(String line, List<CurveInfo> curveInfoList) {
    try {
      // Format: MNEM.UNIT VALUE : DESCRIPTION
      if (!line.contains('.') || !line.contains(':')) return;

      List<String> parts = line.split(':');
      if (parts.length < 2) return;

      String leftPart = parts[0].trim();
      String description = parts[1].trim();

      // Tách mnem và unit
      List<String> mnemParts = leftPart.split('.');
      if (mnemParts.length < 2) return;

      String mnem = mnemParts[0].trim();
      String unit = mnemParts[1].split(' ')[0].trim();

      curveInfoList.add(
        CurveInfo(
          mnemonic: mnem,
          unit: unit,
          description: description,
          value: '', // Không có value cho curve
        ),
      );
    } catch (e) {
      // Bỏ qua dòng không parse được
    }
  }

  // Parse dòng well information
  static void _parseWellLine(String line, List<CurveInfo> wellInfoList) {
    try {
      // Format: MNEM.UNIT VALUE : DESCRIPTION
      if (!line.contains('.') || !line.contains(':')) return;

      List<String> parts = line.split(':');
      if (parts.length < 2) return;

      String leftPart = parts[0].trim();
      String description = parts[1].trim();

      // Tách mnem, unit và value
      List<String> mnemParts = leftPart.split('.');
      if (mnemParts.length < 2) return;

      String mnem = mnemParts[0].trim();
      List<String> unitValueParts = mnemParts[1].split(' ');
      String unit = unitValueParts[0].trim();
      String value = unitValueParts.length > 1
          ? unitValueParts.sublist(1).join(' ').trim()
          : '';

      wellInfoList.add(
        CurveInfo(
          mnemonic: mnem,
          unit: unit,
          description: description,
          value: value,
        ),
      );
    } catch (e) {
      // Bỏ qua dòng không parse được
    }
  }

  // Parse data lines thành BlockData
  static List<BlockData> _parseDataLines(
    List<String> dataLines,
    List<CurveInfo> curveInfoList,
  ) {
    List<BlockData> blockList = [];

    try {
      for (String line in dataLines) {
        line = line.trim();
        if (line.isEmpty) continue;

        // Tách các giá trị bằng space hoặc tab
        List<String> values = line.split(RegExp(r'\s+'));

        if (values.length < 2) continue; // Cần ít nhất depth và 1 giá trị

        // Giá trị đầu tiên thường là depth
        double depth = double.tryParse(values[0]) ?? 0.0;

        // Các giá trị còn lại là data
        List<List<double>> data = [];
        for (int i = 1; i < values.length && i <= curveInfoList.length; i++) {
          double value = double.tryParse(values[i]) ?? 0.0;
          data.add([value]); // Mỗi curve là một list
        }

        blockList.add(BlockData(depth: depth, data: data));
      }
    } catch (e) {
      print('Lỗi parse data lines: $e');
    }

    return blockList;
  }

  // Validate file LAS
  static Future<bool> isValidLasFile(String filePath) async {
    try {
      File file = File(filePath);
      if (!await file.exists()) return false;

      String content = await file.readAsString(encoding: utf8);
      List<String> lines = content.split('\n');

      // Kiểm tra có section headers LAS không
      bool hasVersionSection = false;
      bool hasWellSection = false;
      bool hasCurveSection = false;

      for (String line in lines.take(100)) {
        // Chỉ kiểm tra 100 dòng đầu
        line = line.trim().toLowerCase();
        if (line.startsWith('~v') || line.startsWith('~version')) {
          hasVersionSection = true;
        } else if (line.startsWith('~w') || line.startsWith('~well')) {
          hasWellSection = true;
        } else if (line.startsWith('~c') || line.startsWith('~curve')) {
          hasCurveSection = true;
        }
      }

      return hasVersionSection || hasWellSection || hasCurveSection;
    } catch (e) {
      return false;
    }
  }
}
