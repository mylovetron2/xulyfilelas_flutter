import 'package:flutter/material.dart';
import '../models/models.dart';

class CurveSettingsScreen extends StatefulWidget {
  final List<CurveInfo> curveInfoList;
  final Map<int, bool> curveVisibility;
  final Map<int, Color> curveColors;
  final Map<int, double> curveWidths;
  final Map<int, double> curveMinValues;
  final Map<int, double> curveMaxValues;
  final Function(
    Map<int, bool> visibility,
    Map<int, Color> colors,
    Map<int, double> widths,
    Map<int, double> minValues,
    Map<int, double> maxValues,
  )
  onSettingsChanged;

  const CurveSettingsScreen({
    super.key,
    required this.curveInfoList,
    required this.curveVisibility,
    required this.curveColors,
    required this.curveWidths,
    required this.curveMinValues,
    required this.curveMaxValues,
    required this.onSettingsChanged,
  });

  @override
  State<CurveSettingsScreen> createState() => _CurveSettingsScreenState();
}

class _CurveSettingsScreenState extends State<CurveSettingsScreen> {
  late Map<int, bool> visibility;
  late Map<int, Color> colors;
  late Map<int, double> widths;
  late Map<int, double> minValues;
  late Map<int, double> maxValues;
  late Map<int, TextEditingController> minControllers;
  late Map<int, TextEditingController> maxControllers;

  @override
  void initState() {
    super.initState();

    // Copy settings để có thể modify
    visibility = Map.from(widget.curveVisibility);
    colors = Map.from(widget.curveColors);
    widths = Map.from(widget.curveWidths);
    minValues = Map.from(widget.curveMinValues);
    maxValues = Map.from(widget.curveMaxValues);

    // Khởi tạo controllers cho min/max inputs
    minControllers = {};
    maxControllers = {};
    for (int i = 0; i < widget.curveInfoList.length; i++) {
      minControllers[i] = TextEditingController(
        text: minValues[i]?.toStringAsFixed(2),
      );
      maxControllers[i] = TextEditingController(
        text: maxValues[i]?.toStringAsFixed(2),
      );
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    for (var controller in minControllers.values) {
      controller.dispose();
    }
    for (var controller in maxControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt Curves'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Lưu',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header với action buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _selectAllCurves,
                  icon: const Icon(Icons.select_all),
                  label: const Text('Chọn Tất Cả'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _deselectAllCurves,
                  icon: const Icon(Icons.deselect),
                  label: const Text('Bỏ Chọn Tất Cả'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ),

          // Curve list
          Expanded(
            child: ListView.builder(
              itemCount: widget.curveInfoList.length,
              itemBuilder: (context, index) {
                var curve = widget.curveInfoList[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ExpansionTile(
                    leading: Checkbox(
                      value: visibility[index] ?? false,
                      onChanged: (value) {
                        setState(() {
                          visibility[index] = value ?? false;
                        });
                      },
                    ),
                    title: Text(
                      curve.mnemonic,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${curve.unit} - ${curve.description}'),
                    trailing: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colors[index] ?? Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Color picker
                            const Text(
                              'Màu sắc:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children:
                                  [
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
                                  ].map((color) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          colors[index] = color;
                                        });
                                      },
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: colors[index] == color
                                                ? Colors.black
                                                : Colors.grey,
                                            width: colors[index] == color
                                                ? 2
                                                : 1,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),

                            const SizedBox(height: 16),

                            // Line width
                            Text(
                              'Độ rộng đường: ${widths[index]?.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: widths[index] ?? 2.0,
                              min: 0.5,
                              max: 5.0,
                              divisions: 9,
                              onChanged: (value) {
                                setState(() {
                                  widths[index] = value;
                                });
                              },
                            ),

                            const SizedBox(height: 16),

                            // Min/Max values
                            const Text(
                              'Thang đo:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: minControllers[index],
                                    decoration: const InputDecoration(
                                      labelText: 'Min',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      double? parsedValue = double.tryParse(
                                        value,
                                      );
                                      if (parsedValue != null) {
                                        minValues[index] = parsedValue;
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: maxControllers[index],
                                    decoration: const InputDecoration(
                                      labelText: 'Max',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      double? parsedValue = double.tryParse(
                                        value,
                                      );
                                      if (parsedValue != null) {
                                        maxValues[index] = parsedValue;
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

  void _selectAllCurves() {
    setState(() {
      for (int i = 0; i < widget.curveInfoList.length; i++) {
        visibility[i] = true;
      }
    });
  }

  void _deselectAllCurves() {
    setState(() {
      for (int i = 0; i < widget.curveInfoList.length; i++) {
        visibility[i] = false;
      }
    });
  }

  void _resetToDefaults() {
    setState(() {
      for (int i = 0; i < widget.curveInfoList.length; i++) {
        visibility[i] = i < 5;
        colors[i] = _getDefaultColor(i);
        widths[i] = 2.0;

        // Reset controllers
        minControllers[i]?.text =
            widget.curveMinValues[i]?.toStringAsFixed(2) ?? '0.00';
        maxControllers[i]?.text =
            widget.curveMaxValues[i]?.toStringAsFixed(2) ?? '100.00';
        minValues[i] = widget.curveMinValues[i] ?? 0.0;
        maxValues[i] = widget.curveMaxValues[i] ?? 100.0;
      }
    });
  }

  Color _getDefaultColor(int index) {
    List<Color> defaultColors = [
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
    return defaultColors[index % defaultColors.length];
  }

  void _saveSettings() {
    // Update min/max values from controllers
    for (int i = 0; i < widget.curveInfoList.length; i++) {
      double? minValue = double.tryParse(minControllers[i]?.text ?? '');
      double? maxValue = double.tryParse(maxControllers[i]?.text ?? '');

      if (minValue != null) minValues[i] = minValue;
      if (maxValue != null) maxValues[i] = maxValue;
    }

    // Call callback với settings mới
    widget.onSettingsChanged(visibility, colors, widths, minValues, maxValues);

    Navigator.pop(context);
  }
}
