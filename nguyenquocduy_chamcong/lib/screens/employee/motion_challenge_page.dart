import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../widgets.dart';

/// TÍNH NĂNG: ĐO CHUYỂN ĐỘNG (gia tốc kế).
/// Thử thách "lắc điện thoại 4 lần" để chứng minh người thật đang cầm máy trước khi chấm công GPS
/// (chống dùng app giả lập vị trí chấm công hộ). Trên máy ảo: Extended controls → Virtual sensors → Device pose / Accelerometer.
class MotionChallengePage extends StatefulWidget {
  const MotionChallengePage({super.key});
  @override
  State<MotionChallengePage> createState() => _MotionChallengePageState();
}

class _MotionChallengePageState extends State<MotionChallengePage> {
  static const int _need = 4;
  static const double _threshold = 5.0; // m/s² lệch khỏi trọng lực
  StreamSubscription<AccelerometerEvent>? _sub;
  final List<double> _history = [];
  double _delta = 0;
  double _max = 0;
  int _shakes = 0;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  bool _done = false;
  bool _noSensor = true;
  Timer? _noSensorTimer;

  @override
  void initState() {
    super.initState();
    try {
      _sub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(_onEvent, onError: (_) {});
    } catch (_) {}
    _noSensorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _history.isEmpty) setState(() => _noSensor = true);
    });
  }

  void _onEvent(AccelerometerEvent e) {
    if (!mounted || _done) return;
    final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    final d = (mag - 9.81).abs();
    setState(() {
      _noSensor = false;
      _delta = d;
      if (d > _max) _max = d;
      _history.add(d);
      if (_history.length > 60) _history.removeAt(0);
    });
    final now = DateTime.now();
    if (d > _threshold && now.difference(_last).inMilliseconds > 300) {
      _last = now;
      _addShake();
    }
  }

  void _addShake() {
    if (_done) return;
    setState(() => _shakes++);
    if (_shakes >= _need) {
      _done = true;
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) Navigator.pop(context, true);
      });
    }
  }

  @override
  void dispose() {
    _noSensorTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_shakes / _need).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực chuyển động')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Icon(_done ? Icons.verified : Icons.vibration, size: 72, color: _done ? kOk : kPrimary),
            const SizedBox(height: 10),
            Text(_done ? 'Đã xác thực chuyển động!' : 'Hãy lắc điện thoại $_need lần',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('$_shakes / $_need lần', style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 14),
            LinearProgressIndicator(value: pct, minHeight: 10, borderRadius: BorderRadius.circular(8), color: _done ? kOk : kPrimary, backgroundColor: Colors.black12),
          ]),
        ),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Cảm biến gia tốc', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              StatusChip('Δ ${_delta.toStringAsFixed(1)} m/s²', _delta > _threshold ? kDanger : kPrimary),
            ]),
            const SizedBox(height: 10),
            SizedBox(height: 90, width: double.infinity, child: CustomPaint(painter: _WavePainter(List.of(_history), _threshold))),
            const SizedBox(height: 6),
            Text('Cực đại: ${_max.toStringAsFixed(1)} m/s²  •  ngưỡng lắc: $_threshold m/s²', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
        if (_noSensor)
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Chưa nhận được dữ liệu cảm biến', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                'Máy ảo: bấm "..." (Extended controls) → Virtual sensors → Device pose, kéo các thanh Move/Rotate liên tục để tạo chuyển động. '
                'Hoặc dùng nút giả lập bên dưới khi demo.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ]),
          ),
        OutlinedButton.icon(
          onPressed: _done ? null : _addShake,
          icon: const Icon(Icons.science_outlined),
          label: const Text('Giả lập một cú lắc (chỉ để thử trên máy ảo)'),
        ),
      ]),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<double> data;
  final double threshold;
  _WavePainter(this.data, this.threshold);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)), bg);
    const maxV = 20.0;
    final ty = size.height - (threshold / maxV).clamp(0.0, 1.0) * size.height;
    canvas.drawLine(Offset(0, ty), Offset(size.width, ty), Paint()..color = kDanger.withOpacity(0.5)..strokeWidth = 1);
    if (data.length < 2) return;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / 59 * size.width;
      final y = size.height - (data[i] / maxV).clamp(0.0, 1.0) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = kPrimary..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => true;
}
