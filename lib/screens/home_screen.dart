import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/services.dart';
import '../models/models.dart';
import 'txt_analysis_screen.dart';

// Conditional imports for web support
import 'dart:html' as html;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedLasFile;
  String? selectedTxtFile;
  Uint8List? selectedLasFileBytes;
  Uint8List? selectedTxtFileBytes;
  String? selectedLasFileName;
  String? selectedTxtFileName;
  bool isProcessing = false;

  // Data cho xử lý file
  List<String> headerList = [];
  List<String> unitList = [];
  List<List<String>> dataRows = [];
  List<CurveInfo> curveInfoList = [];
  List<CurveInfo> wellInfoList = [];
  List<BlockData> blockList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xử Lý File LAS'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chức năng xử lý file LAS và TXT',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // File selection section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn file:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // LAS file selection
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedLasFile != null
                                ? 'LAS: ${selectedLasFile!.split('/').last}'
                                : 'Chưa chọn file LAS',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _pickLasFile,
                          child: const Text('Chọn LAS'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // TXT file selection
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedTxtFile != null
                                ? 'TXT: ${selectedTxtFile!.split('/').last}'
                                : 'Chưa chọn file TXT',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _pickTxtFile,
                          child: const Text('Chọn TXT'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Expanded(
              child: Column(
                children: [
                  // Merge LAS & TXT button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed:
                          (selectedLasFile != null &&
                              selectedTxtFile != null &&
                              !isProcessing)
                          ? _processFiles
                          : null,
                      icon: isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.merge_type),
                      label: Text(
                        isProcessing ? 'Đang xử lý...' : 'Merge LAS & TXT',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Phân tích TXT chuyên dụng button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TxtAnalysisScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.analytics),
                      label: const Text('Phân Tích TXT Chuyên Dụng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Export LIS to LAS button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _exportLisToLas,
                      icon: const Icon(Icons.transform),
                      label: const Text('Chuyển LIS thành LAS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Status text
            if (isProcessing)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Đang xử lý file, vui lòng chờ...'),
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
      });
    }
  }

  Future<void> _pickTxtFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          selectedTxtFileBytes = result.files.single.bytes;
          selectedTxtFileName = result.files.single.name;
          selectedTxtFile = result.files.single.name;
        } else {
          selectedTxtFile = result.files.single.path!;
        }
      });
    }
  }

  // Helper method để download file trên web platform
  void _downloadFileOnWeb(String content, String fileName) {
    if (kIsWeb) {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> _processFiles() async {
    if (selectedLasFile == null || selectedTxtFile == null) return;

    setState(() {
      isProcessing = true;
    });

    try {
      // Đọc file TXT
      Map<String, dynamic> txtResult;

      if (kIsWeb) {
        txtResult = await FileService.readTXTFromBytes(
          selectedTxtFileBytes!,
          selectedTxtFileName!,
        );
      } else {
        txtResult = await FileService.readTXT(selectedTxtFile!);
      }

      if (!txtResult['success']) {
        _showErrorDialog(txtResult['message']);
        return;
      }

      headerList = List<String>.from(txtResult['headerList']);
      unitList = List<String>.from(txtResult['unitList']);
      dataRows = (txtResult['dataRows'] as List)
          .map((e) => List<String>.from(e))
          .toList();

      // Debug: Kiểm tra dữ liệu TXT
      print('=== DEBUG TXT ===');
      print('Header: $headerList');
      print('Units: $unitList');
      print('Data rows count: ${dataRows.length}');
      if (dataRows.isNotEmpty) {
        print('First row: ${dataRows.first}');
        print('Last row: ${dataRows.last}');
      }

      // Merge TXT với LAS
      Map<String, dynamic> mergeResult;

      if (kIsWeb) {
        mergeResult = await FileService.mergeTxtLasFromBytes(
          selectedLasFileBytes!,
          selectedLasFileName!,
          dataRows,
        );
      } else {
        mergeResult = await FileService.mergeTxtLas(selectedLasFile!, dataRows);
      }

      if (!mergeResult['success']) {
        _showErrorDialog(mergeResult['message']);
        return;
      }

      curveInfoList = List<CurveInfo>.from(mergeResult['curveInfoList']);
      wellInfoList = List<CurveInfo>.from(mergeResult['wellInfoList']);
      blockList = List<BlockData>.from(mergeResult['blockList']);

      // Debug: Kiểm tra kết quả merge
      print('=== DEBUG MERGE ===');
      print('Curve info count: ${curveInfoList.length}');
      print('Well info count: ${wellInfoList.length}');
      print('Block list count: ${blockList.length}');
      if (blockList.isNotEmpty) {
        print('First block depth: ${blockList.first.depth}');
        print('First block data rows: ${blockList.first.data.length}');
        if (blockList.first.data.isNotEmpty) {
          print('First block first row: ${blockList.first.data.first}');
        }
      }

      // Xử lý blockList
      blockList = DataProcessingService.processBlockList(blockList);

      // Debug: Kiểm tra sau xử lý
      print('=== DEBUG PROCESSED ===');
      print('Processed block count: ${blockList.length}');
      if (blockList.isNotEmpty) {
        print('First processed block depth: ${blockList.first.depth}');
        print(
          'First processed block data rows: ${blockList.first.data.length}',
        );
        print('Last processed block depth: ${blockList.last.depth}');
      }

      // Lưu file (khác nhau giữa web và desktop)
      if (kIsWeb) {
        // Phân tích xu hướng để xác định isDepthIncreasing
        List<double> depthList = blockList.map((b) => b.depth).toList();
        Map<String, dynamic> trendAnalysis =
            DataProcessingService.analyzeDepthTrend(depthList);
        bool isDepthIncreasing = trendAnalysis['isIncreasing'];

        // Tạo nội dung LAS file
        String lasContent = await FileService.generateLasContent(
          blockList,
          wellInfoList,
          curveInfoList,
          isDepthIncreasing,
        );

        // Download file trên web
        _downloadFileOnWeb(lasContent, 'processed.las');
        _showSuccessDialog('Đã lưu file LAS mới thành công!', 'processed.las');
      } else {
        // Chọn nơi lưu file cho desktop
        String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Lưu file LAS mới',
          fileName: 'processed.las',
          type: FileType.custom,
          allowedExtensions: ['las'],
        );

        if (outputPath != null) {
          // Phân tích xu hướng để xác định isDepthIncreasing
          List<double> depthList = blockList.map((b) => b.depth).toList();
          Map<String, dynamic> trendAnalysis =
              DataProcessingService.analyzeDepthTrend(depthList);
          bool isDepthIncreasing = trendAnalysis['isIncreasing'];

          bool success = await FileService.writeBlockListToLas(
            outputPath,
            blockList,
            wellInfoList,
            curveInfoList,
            isDepthIncreasing,
          );

          if (success) {
            _showSuccessDialog('Đã lưu file LAS mới thành công!', outputPath);
          } else {
            _showErrorDialog('Không ghi được file LAS mới!');
          }
        }
      }
    } catch (e) {
      _showErrorDialog('Lỗi khi xử lý file: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _exportLisToLas() async {
    // Chọn file LIS
    FilePickerResult? lisResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['lis'],
    );

    if (lisResult == null || lisResult.files.single.path == null) return;
    String lisPath = lisResult.files.single.path!;

    // Validate LIS file
    bool isValid = await LisService.isValidLisFile(lisPath);
    if (!isValid) {
      _showErrorDialog('File LIS không hợp lệ!');
      return;
    }

    // Lưu file (khác nhau giữa web và desktop)
    if (kIsWeb) {
      setState(() {
        isProcessing = true;
      });

      try {
        String lasContent = await LisService.convertLisToLasContent(lisPath);
        if (lasContent.isNotEmpty) {
          _downloadFileOnWeb(lasContent, 'converted.las');
          _showSuccessDialog(
            'Đã chuyển file LIS thành LAS thành công!',
            'converted.las',
          );
        } else {
          _showErrorDialog('Không thể chuyển đổi file LIS!');
        }
      } catch (e) {
        _showErrorDialog('Lỗi khi chuyển đổi: $e');
      } finally {
        setState(() {
          isProcessing = false;
        });
      }
    } else {
      // Chọn nơi lưu file LAS cho desktop
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Lưu file LAS',
        fileName: 'converted.las',
        type: FileType.custom,
        allowedExtensions: ['las'],
      );

      if (outputPath != null) {
        setState(() {
          isProcessing = true;
        });

        try {
          bool success = await LisService.convertLisToLas(lisPath, outputPath);
          if (success) {
            _showSuccessDialog(
              'Đã chuyển file LIS thành LAS thành công!',
              outputPath,
            );
          } else {
            _showErrorDialog('Không thể chuyển đổi file LIS!');
          }
        } catch (e) {
          _showErrorDialog('Lỗi khi chuyển đổi: $e');
        } finally {
          setState(() {
            isProcessing = false;
          });
        }
      }
    }
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

  void _showSuccessDialog(String message, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thành công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Text(
              'File: ${filePath.split('/').last}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openFile(filePath);
            },
            child: const Text('Mở File'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(String filePath) async {
    final uri = Uri.file(filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
