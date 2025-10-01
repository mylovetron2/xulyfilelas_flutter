import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../services/services.dart';
import '../models/models.dart';
import 'las_chart_screen.dart';
import 'las_data_table_screen.dart';

class LasReaderScreen extends StatefulWidget {
  const LasReaderScreen({super.key});

  @override
  State<LasReaderScreen> createState() => _LasReaderScreenState();
}

class _LasReaderScreenState extends State<LasReaderScreen> {
  String? selectedLasFile;
  Uint8List? selectedLasFileBytes;
  String? selectedLasFileName;
  bool isProcessing = false;
  bool hasData = false;

  // LAS file data
  List<String> parameterNames = [];
  List<String> parameterUnits = [];
  List<String> parameterDescriptions = [];
  List<BlockData> blockList = [];
  List<CurveInfo> curveInfoList = [];
  List<CurveInfo> wellInfoList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đọc File LAS'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File selection card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn file LAS:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedLasFile != null
                                ? 'File: ${selectedLasFile!.split('/').last}'
                                : 'Chưa chọn file LAS',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _pickLasFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Chọn File'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Process button
            if (selectedLasFile != null)
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: !isProcessing ? _processLasFile : null,
                  icon: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.analytics),
                  label: Text(
                    isProcessing ? 'Đang xử lý...' : 'Đọc và Phân Tích File',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Data display
            if (hasData) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Parameters info card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin Parameters:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Số lượng parameters: ${parameterNames.length}',
                              ),
                              if (parameterNames.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 150,
                                  child: ListView.builder(
                                    itemCount: parameterNames.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          parameterNames[index],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        subtitle: Text(
                                          '${parameterUnits.length > index ? parameterUnits[index] : ''} - ${parameterDescriptions.length > index ? parameterDescriptions[index] : ''}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Block data info card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin Dữ liệu:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Số lượng blocks: ${blockList.length}'),
                              if (blockList.isNotEmpty) ...[
                                Text(
                                  '${_getIndexTypeLabel()}: ${blockList.first.index} - ${blockList.last.index}',
                                ),
                                Text(
                                  'Số cột dữ liệu: ${blockList.first.data.isNotEmpty ? blockList.first.data.length : 0}',
                                ),
                                const SizedBox(height: 8),
                                // Debug info cho 3 blocks đầu tiên
                                Text(
                                  'Debug - 3 blocks đầu:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                ...blockList
                                    .take(3)
                                    .map(
                                      (block) => Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8.0,
                                        ),
                                        child: Text(
                                          '${block.indexType}: ${block.index} (${block.data.length} curves)',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Chart button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _openChartScreen(),
                          icon: const Icon(Icons.show_chart),
                          label: const Text('Vẽ Đồ Thị'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Data table button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _openDataTableScreen(),
                          icon: const Icon(Icons.table_view),
                          label: const Text('Xem Bảng Dữ Liệu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Debug button
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () => _showDebugDialog(),
                          icon: const Icon(Icons.bug_report, size: 16),
                          label: const Text('Debug Info'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Help text
            if (!hasData && !isProcessing)
              Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hướng dẫn:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Chọn file LAS từ máy tính',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '2. Nhấn "Đọc và Phân Tích File"',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '3. Xem thông tin parameters và dữ liệu',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '4. Nhấn "Vẽ Đồ Thị" để xem visualization',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

            // Processing indicator
            if (isProcessing)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Đang đọc và phân tích file LAS...\nQuá trình này có thể mất vài giây.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLasFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['las'],
    );

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          selectedLasFileBytes = result.files.single.bytes;
          selectedLasFileName = result.files.single.name;
          selectedLasFile = result.files.single.name;
        } else {
          selectedLasFile = result.files.single.path!;
        }
        hasData = false; // Reset data when new file is selected
      });
    }
  }

  Future<void> _processLasFile() async {
    if (selectedLasFile == null) return;

    setState(() {
      isProcessing = true;
    });

    try {
      Map<String, dynamic> result;

      if (kIsWeb) {
        result = await LasService.readLasFromBytes(
          selectedLasFileBytes!,
          selectedLasFileName!,
        );
      } else {
        result = await LasService.readLasFile(selectedLasFile!);
      }

      if (!result['success']) {
        _showErrorDialog(result['message']);
        return;
      }

      setState(() {
        parameterNames = List<String>.from(result['parameterNames'] ?? []);
        parameterUnits = List<String>.from(result['parameterUnits'] ?? []);
        parameterDescriptions = List<String>.from(
          result['parameterDescriptions'] ?? [],
        );
        blockList = List<BlockData>.from(result['blockList'] ?? []);
        curveInfoList = List<CurveInfo>.from(result['curveInfoList'] ?? []);
        wellInfoList = List<CurveInfo>.from(result['wellInfoList'] ?? []);
        hasData = true;
      });

      _showSuccessDialog('Đã đọc file LAS thành công!');
    } catch (e) {
      _showErrorDialog('Lỗi khi đọc file LAS: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _openChartScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LasChartScreen(
          blockList: blockList,
          parameterNames: parameterNames,
          parameterUnits: parameterUnits,
          parameterDescriptions: parameterDescriptions,
          curveInfoList: curveInfoList,
        ),
      ),
    );
  }

  void _openDataTableScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LasDataTableScreen(
          blockList: blockList,
          curveInfoList: curveInfoList,
          fileName:
              selectedLasFileName ??
              selectedLasFile?.split('/').last ??
              'Unknown File',
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getIndexTypeLabel() {
    if (blockList.isEmpty) return 'Index';
    return blockList.first.indexType == 'TIME' ? 'Time' : 'Depth';
  }

  void _showDebugDialog() {
    if (blockList.isEmpty) {
      _showErrorDialog('Không có dữ liệu để debug');
      return;
    }

    String debugInfo = _generateDebugInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              debugInfo,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _generateDebugInfo() {
    StringBuffer buffer = StringBuffer();

    buffer.writeln('🔍 DEBUG INFORMATION');
    buffer.writeln('===================');
    buffer.writeln('📊 Total blocks: ${blockList.length}');
    buffer.writeln('📋 Index Type: ${blockList.first.indexType}');
    buffer.writeln(
      '🎯 Index Range: ${blockList.first.index} → ${blockList.last.index}',
    );
    buffer.writeln('📈 Curves count: ${curveInfoList.length}');
    buffer.writeln('');

    // Curve info
    buffer.writeln('📝 CURVE INFORMATION:');
    for (int i = 0; i < curveInfoList.length; i++) {
      var curve = curveInfoList[i];
      String indexIndicator = i == 0 ? ' (INDEX)' : '';
      buffer.writeln(
        '  [$i] ${curve.mnemonic}.${curve.unit} - ${curve.description}$indexIndicator',
      );
    }
    buffer.writeln('');

    // First 10 blocks
    int maxBlocks = blockList.length < 10 ? blockList.length : 10;
    buffer.writeln('📋 FIRST $maxBlocks BLOCKS:');

    for (int i = 0; i < maxBlocks; i++) {
      var block = blockList[i];
      buffer.writeln('  Block $i:');
      buffer.writeln('    ${block.indexType}: ${block.index}');
      buffer.writeln('    Data curves: ${block.data.length}');

      for (int j = 0; j < block.data.length; j++) {
        // j trong block.data tương ứng với curve thứ (j+1) trong curveInfoList
        int curveIndex = j + 1; // Skip curve đầu tiên (index curve)
        String curveName = curveIndex < curveInfoList.length
            ? curveInfoList[curveIndex].mnemonic
            : 'Unknown';
        String value = block.data[j].isNotEmpty
            ? block.data[j][0].toStringAsFixed(3)
            : 'No data';
        buffer.writeln('      [$j] $curveName: $value');
      }
      buffer.writeln('');
    }

    // Statistics
    if (blockList.length > 1) {
      double indexStep = blockList[1].index - blockList[0].index;
      buffer.writeln('📏 Index step: $indexStep');
    }

    return buffer.toString();
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thành công'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
