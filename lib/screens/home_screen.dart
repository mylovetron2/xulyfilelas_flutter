import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/services.dart';
import 'txt_analysis_screen.dart';
import 'merge_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isProcessing = false;

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

            // Action buttons
            Expanded(
              child: Column(
                children: [
                  // Merge LAS & TXT button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MergeScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.merge_type, size: 28),
                      label: const Text(
                        'Merge LAS & TXT',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Phân tích TXT chuyên dụng button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TxtAnalysisScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.analytics, size: 28),
                      label: const Text(
                        'Phân Tích TXT Chuyên Dụng',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Export LIS to LAS button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _exportLisToLas,
                      icon: const Icon(Icons.transform, size: 28),
                      label: const Text(
                        'Chuyển LIS thành LAS',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

    // Chọn nơi lưu file LAS
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
