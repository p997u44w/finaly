import 'package:flutter/material.dart';
import '../services/online_class_service.dart';

class _Stroke {
  Color color;
  double width;
  final List<Offset> points = [];
  _Stroke(this.color, this.width);
}

/// تخته‌ی مشترک زنده. فقط معلم/میزبان‌های کلاس (isModerator) می‌تونن بکشن و
/// رنگ رو عوض کنن؛ بقیه (دانش‌آموزها) فقط زنده می‌بینن چی کشیده می‌شه.
class WhiteboardCanvas extends StatefulWidget {
  final OnlineClassService service;
  const WhiteboardCanvas({super.key, required this.service});

  @override
  State<WhiteboardCanvas> createState() => _WhiteboardCanvasState();
}

class _WhiteboardCanvasState extends State<WhiteboardCanvas> {
  final Map<String, _Stroke> _strokes = {};
  int _processedCount = 0;
  String? _activeStrokeId;

  static const _palette = [
    Color(0xFF1B3358), // سرمه‌ای (پیش‌فرض)
    Color(0xFFE53935), // قرمز
    Color(0xFF2E7D32), // سبز
    Color(0xFF1976D2), // آبی
    Color(0xFFF9A825), // زرد
  ];

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onServiceChange);
    widget.service.whiteboardClearedController.stream.listen((_) {
      setState(_strokes.clear);
    });
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChange);
    super.dispose();
  }

  void _onServiceChange() {
    final list = widget.service.whiteboardStrokes;
    if (list.length == _processedCount) return;
    for (var i = _processedCount; i < list.length; i++) {
      _applyIncoming(list[i]);
    }
    _processedCount = list.length;
    if (mounted) setState(() {});
  }

  void _applyIncoming(Map<String, dynamic> stroke) {
    final id = stroke['strokeId'] as String?;
    if (id == null) return;
    switch (stroke['type']) {
      case 'start':
        final color = Color(int.parse((stroke['color'] as String).replaceFirst('#', '0xff')));
        final s = _Stroke(color, (stroke['width'] as num?)?.toDouble() ?? 4);
        s.points.add(Offset((stroke['x'] as num).toDouble(), (stroke['y'] as num).toDouble()));
        _strokes[id] = s;
        break;
      case 'point':
        _strokes[id]?.points.add(Offset((stroke['x'] as num).toDouble(), (stroke['y'] as num).toDouble()));
        break;
    }
  }

  bool get _canDraw => widget.service.isModerator;

  void _onPanStart(DragStartDetails details, Size size) {
    if (!_canDraw) return;
    final id = '${widget.service.mySocketId}_${DateTime.now().microsecondsSinceEpoch}';
    _activeStrokeId = id;
    final color = widget.service.whiteboardColor;
    final s = _Stroke(Color(int.parse(color.replaceFirst('#', '0xff'))), 4);
    s.points.add(details.localPosition);
    setState(() => _strokes[id] = s);
    widget.service.drawStroke({
      'type': 'start',
      'strokeId': id,
      'x': details.localPosition.dx,
      'y': details.localPosition.dy,
      'color': color,
      'width': 4,
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_canDraw || _activeStrokeId == null) return;
    setState(() => _strokes[_activeStrokeId]!.points.add(details.localPosition));
    widget.service.drawStroke({
      'type': 'point',
      'strokeId': _activeStrokeId,
      'x': details.localPosition.dx,
      'y': details.localPosition.dy,
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _activeStrokeId = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_canDraw)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                ..._palette.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        onTap: () => widget.service
                            .changeWhiteboardColor('#${c.value.toRadixString(16).substring(2)}'),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: widget.service.whiteboardColor.toLowerCase() ==
                                      '#${c.value.toRadixString(16).substring(2)}'
                                  ? 3
                                  : 1,
                            ),
                          ),
                        ),
                      ),
                    )),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
                  tooltip: 'پاک کردن تخته',
                  onPressed: () {
                    setState(_strokes.clear);
                    widget.service.clearWhiteboard();
                  },
                ),
              ],
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanStart: (d) => _onPanStart(d, size),
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: double.infinity,
                  child: CustomPaint(painter: _BoardPainter(_strokes)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BoardPainter extends CustomPainter {
  final Map<String, _Stroke> strokes;
  _BoardPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes.values) {
      if (s.points.length < 2) continue;
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < s.points.length - 1; i++) {
        canvas.drawLine(s.points[i], s.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
