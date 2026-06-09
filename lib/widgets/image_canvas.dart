import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ImageCanvas extends StatefulWidget {
  final File image;
  final List<CanvasAnnotation> annotations;
  final ValueChanged<List<CanvasAnnotation>>? onAnnotationsChanged;
  final bool editable;
  final double scale;

  const ImageCanvas({
    super.key,
    required this.image,
    this.annotations = const [],
    this.onAnnotationsChanged,
    this.editable = true,
    this.scale = 1.0,
  });

  @override
  State<ImageCanvas> createState() => _ImageCanvasState();
}

class _ImageCanvasState extends State<ImageCanvas> {
  final GlobalKey _repaintKey = GlobalKey();
  List<Offset> _currentPoints = [];
  Color _currentColor = AppColors.primary;
  double _strokeWidth = 3.0;
  CanvasTool _currentTool = CanvasTool.pen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.editable)
          _buildToolBar(),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: RepaintBoundary(
              key: _repaintKey,
              child: CustomPaint(
                painter: _CanvasPainter(
                  image: widget.image,
                  annotations: widget.annotations,
                  currentPoints: _currentPoints,
                  currentColor: _currentColor,
                  strokeWidth: _strokeWidth,
                  currentTool: _currentTool,
                  scale: widget.scale,
                ),
                child: GestureDetector(
                  onPanStart: widget.editable ? _onPanStart : null,
                  onPanUpdate: widget.editable ? _onPanUpdate : null,
                  onPanEnd: widget.editable ? _onPanEnd : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          _ToolButton(
            icon: Icons.edit,
            selected: _currentTool == CanvasTool.pen,
            onTap: () => setState(() => _currentTool = CanvasTool.pen),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.text_fields,
            selected: _currentTool == CanvasTool.text,
            onTap: () => setState(() => _currentTool = CanvasTool.text),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.arrow_back,
            selected: false,
            onTap: _undo,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showColorPicker(),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Slider(
              value: _strokeWidth,
              min: 1,
              max: 10,
              onChanged: (v) => setState(() => _strokeWidth = v),
            ),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.delete,
            selected: false,
            onTap: () => setState(() {
              widget.onAnnotationsChanged?.call([]);
            }),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentPoints = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPoints.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPoints.length > 1) {
      final annotation = CanvasAnnotation(
        points: List.from(_currentPoints),
        color: _currentColor,
        strokeWidth: _strokeWidth,
        tool: _currentTool,
      );
      final updated = [...widget.annotations, annotation];
      widget.onAnnotationsChanged?.call(updated);
    }
    setState(() => _currentPoints = []);
  }

  void _undo() {
    if (widget.annotations.isNotEmpty) {
      final updated = List<CanvasAnnotation>.from(widget.annotations)
        ..removeLast();
      widget.onAnnotationsChanged?.call(updated);
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Choose Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppColors.filterColors.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() => _currentColor = color);
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _currentColor == color ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<File?> exportCanvas() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = await Helpers.getTempDirectory();
      final file = File('${tempDir.path}/canvas_export_${Helpers.generateId()}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (e) {
      debugPrint('Canvas export error: $e');
      return null;
    }
  }
}

enum CanvasTool { pen, text, eraser }

class CanvasAnnotation {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final CanvasTool tool;

  const CanvasAnnotation({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.tool = CanvasTool.pen,
  });
}

class _CanvasPainter extends CustomPainter {
  final File image;
  final List<CanvasAnnotation> annotations;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double strokeWidth;
  final CanvasTool currentTool;
  final double scale;

  _CanvasPainter({
    required this.image,
    required this.annotations,
    required this.currentPoints,
    required this.currentColor,
    required this.strokeWidth,
    required this.currentTool,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintImage = Painting(
      image: null, // Would load decodeImageFromList
      rect: Offset.zero & size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    // Draw image
    final rawImage = decodeImageFromList(image.readAsBytesSync());
    // Actually, we'd draw the image differently in production
    // This is a simplified version

    // Draw annotations
    for (final annotation in annotations) {
      _drawAnnotation(canvas, annotation);
    }

    // Draw current stroke
    if (currentPoints.length > 1) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(currentPoints[0].dx, currentPoints[0].dy);
      for (int i = 1; i < currentPoints.length; i++) {
        path.lineTo(currentPoints[i].dx, currentPoints[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawAnnotation(Canvas canvas, CanvasAnnotation annotation) {
    final paint = Paint()
      ..color = annotation.color
      ..strokeWidth = annotation.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (annotation.points.length > 1) {
      final path = Path();
      path.moveTo(annotation.points[0].dx, annotation.points[0].dy);
      for (int i = 1; i < annotation.points.length; i++) {
        path.lineTo(annotation.points[i].dx, annotation.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CanvasPainter oldDelegate) =>
      oldDelegate.annotations != annotations ||
      oldDelegate.currentPoints != currentPoints;
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? AppColors.primary : Colors.grey,
        ),
      ),
    );
  }
}
