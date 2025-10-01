import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../models/models.dart';

class LasDataTableScreen extends StatefulWidget {
  final List<BlockData> blockList;
  final List<CurveInfo> curveInfoList;
  final String fileName;

  const LasDataTableScreen({
    super.key,
    required this.blockList,
    required this.curveInfoList,
    required this.fileName,
  });

  @override
  State<LasDataTableScreen> createState() => _LasDataTableScreenState();
}

class _LasDataTableScreenState extends State<LasDataTableScreen> {
  int _currentPage = 0;
  int _rowsPerPage = 20;
  List<int> _selectedCurves = [];
  String _searchText = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mặc định hiển thị 5 curve đầu tiên (bỏ qua curve đầu tiên vì đó là index)
    List<int> availableCurves = [];
    for (int i = 1; i < widget.curveInfoList.length; i++) {
      // Start from 1 to skip index
      availableCurves.add(i);
    }

    _selectedCurves = availableCurves.take(5).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<BlockData> filteredData = _getFilteredData();
    int totalPages = (filteredData.length / _rowsPerPage).ceil();

    return Scaffold(
      appBar: AppBar(
        title: Text('Dữ Liệu LAS - ${widget.fileName}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _exportToCSV,
            icon: const Icon(Icons.download),
            tooltip: 'Xuất CSV',
          ),
          IconButton(
            onPressed: _showCurveSelectionDialog,
            icon: const Icon(Icons.view_column),
            tooltip: 'Chọn Curves',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Tìm kiếm theo ${_getIndexTypeLabel().toLowerCase()}...',
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchText = value;
                            _currentPage = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<int>(
                      value: _rowsPerPage,
                      items: [10, 20, 50, 100].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text('$value dòng'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _rowsPerPage = value!;
                          _currentPage = 0;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Hiển thị: ${_selectedCurves.length}/${widget.curveInfoList.length - 1} curves',
                    ),
                    const Spacer(),
                    Text('Tổng: ${filteredData.length} điểm dữ liệu'),
                  ],
                ),
              ],
            ),
          ),

          // Data table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: _buildDataColumns(),
                  rows: _buildDataRows(filteredData),
                  columnSpacing: 20,
                  dataRowHeight: 40,
                  headingRowHeight: 50,
                  border: TableBorder.all(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),

          // Pagination
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trang ${_currentPage + 1} / $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0 ? _previousPage : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    ...List.generate(totalPages > 5 ? 5 : totalPages, (index) {
                      int pageNum = _currentPage < 3
                          ? index
                          : _currentPage - 2 + index;
                      if (pageNum >= totalPages) return const SizedBox.shrink();

                      return TextButton(
                        onPressed: () => _goToPage(pageNum),
                        style: TextButton.styleFrom(
                          backgroundColor: pageNum == _currentPage
                              ? Theme.of(context).primaryColor
                              : null,
                          foregroundColor: pageNum == _currentPage
                              ? Colors.white
                              : null,
                        ),
                        child: Text('${pageNum + 1}'),
                      );
                    }),
                    IconButton(
                      onPressed: _currentPage < totalPages - 1
                          ? _nextPage
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _buildDataColumns() {
    List<DataColumn> columns = [
      DataColumn(
        label: Text(
          _getIndexTypeLabel(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ];

    for (int i in _selectedCurves) {
      if (i < widget.curveInfoList.length) {
        var curve = widget.curveInfoList[i];
        columns.add(
          DataColumn(
            label: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  curve.mnemonic,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  curve.unit,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }
    }

    return columns;
  }

  List<DataRow> _buildDataRows(List<BlockData> data) {
    int startIndex = _currentPage * _rowsPerPage;
    int endIndex = (startIndex + _rowsPerPage).clamp(0, data.length);

    return data.sublist(startIndex, endIndex).map((block) {
      List<DataCell> cells = [
        DataCell(
          Text(
            block.index.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ];

      for (int i in _selectedCurves) {
        String value = '-';
        // i là index trong curveInfoList, cần chuyển thành index trong block.data
        int dataIndex = i - 1; // Skip curve đầu tiên (index curve)
        if (dataIndex >= 0 &&
            dataIndex < block.data.length &&
            block.data[dataIndex].isNotEmpty) {
          value = block.data[dataIndex][0].toStringAsFixed(3);
        }
        cells.add(DataCell(Text(value)));
      }

      return DataRow(cells: cells);
    }).toList();
  }

  List<BlockData> _getFilteredData() {
    if (_searchText.isEmpty) {
      return widget.blockList;
    }

    double? searchIndex = double.tryParse(_searchText);
    if (searchIndex != null) {
      return widget.blockList.where((block) {
        return block.index.toString().contains(_searchText) ||
            (block.index - searchIndex).abs() < 0.1;
      }).toList();
    }

    return widget.blockList;
  }

  void _previousPage() {
    setState(() {
      _currentPage = (_currentPage - 1).clamp(0, double.infinity).toInt();
    });
  }

  void _nextPage() {
    List<BlockData> filteredData = _getFilteredData();
    int totalPages = (filteredData.length / _rowsPerPage).ceil();

    setState(() {
      _currentPage = (_currentPage + 1).clamp(0, totalPages - 1);
    });
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _showCurveSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Chọn Curves Hiển Thị'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            // Chọn tất cả curves trừ curve đầu tiên (index)
                            _selectedCurves = List.generate(
                              widget.curveInfoList.length - 1,
                              (index) =>
                                  index + 1, // Start from 1 to skip index
                            );
                          });
                        },
                        child: const Text('Chọn Tất Cả'),
                      ),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            _selectedCurves.clear();
                          });
                        },
                        child: const Text('Bỏ Chọn Tất Cả'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount:
                          widget.curveInfoList.length - 1, // Skip index curve
                      itemBuilder: (context, index) {
                        int curveIndex =
                            index + 1; // Skip index curve (start from 1)
                        var curve = widget.curveInfoList[curveIndex];
                        bool isSelected = _selectedCurves.contains(curveIndex);

                        return CheckboxListTile(
                          title: Text(curve.mnemonic),
                          subtitle: Text(
                            '${curve.unit} - ${curve.description}',
                          ),
                          value: isSelected,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                _selectedCurves.add(curveIndex);
                              } else {
                                _selectedCurves.remove(curveIndex);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentPage = 0;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Áp Dụng'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _exportToCSV() {
    // Tạo CSV content
    List<String> csvLines = [];

    // Header
    List<String> headers = [_getIndexTypeLabel()];
    for (int i in _selectedCurves) {
      if (i < widget.curveInfoList.length) {
        headers.add(
          '${widget.curveInfoList[i].mnemonic} (${widget.curveInfoList[i].unit})',
        );
      }
    }
    csvLines.add(headers.join(','));

    // Data rows
    List<BlockData> filteredData = _getFilteredData();
    for (var block in filteredData) {
      List<String> row = [block.index.toString()];
      for (int i in _selectedCurves) {
        // i là index trong curveInfoList, cần chuyển thành index trong block.data
        int dataIndex = i - 1; // Skip curve đầu tiên (index curve)
        if (dataIndex >= 0 &&
            dataIndex < block.data.length &&
            block.data[dataIndex].isNotEmpty) {
          row.add(block.data[dataIndex][0].toString());
        } else {
          row.add('');
        }
      }
      csvLines.add(row.join(','));
    }

    String csvContent = csvLines.join('\n');

    // Show export dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xuất CSV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sẵn sàng xuất ${filteredData.length} dòng dữ liệu'),
            Text('Với ${_selectedCurves.length} curves'),
            const SizedBox(height: 16),
            const Text(
              'Trên web, file sẽ được tự động tải xuống.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              _downloadCSV(csvContent);
              Navigator.pop(context);
            },
            child: const Text('Xuất'),
          ),
        ],
      ),
    );
  }

  void _downloadCSV(String csvContent) {
    // Tạo filename với timestamp
    String fileName = 'las_data_${DateTime.now().millisecondsSinceEpoch}.csv';

    // Tương tự như trong merge_screen.dart
    final bytes = csvContent.codeUnits;
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã xuất file $fileName')));
  }

  String _getIndexTypeLabel() {
    if (widget.blockList.isEmpty) return 'Index';
    return widget.blockList.first.indexType == 'TIME' ? 'Time' : 'Depth';
  }
}
