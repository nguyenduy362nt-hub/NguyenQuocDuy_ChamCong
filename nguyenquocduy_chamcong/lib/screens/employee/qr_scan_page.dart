import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../widgets.dart';

/// TÍNH NĂNG: QUÉT QR chấm công. Trả về chuỗi token (bắt đầu bằng "CC1.") cho màn hình gọi.
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});
  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  final _manual = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _manual.dispose();
    super.dispose();
  }

  void _finish(String raw) {
    if (_done) return;
    final t = raw.trim();
    if (!t.startsWith('CC1.')) {
      showSnack(context, 'Đây không phải mã QR chấm công của công ty', error: true);
      return;
    }
    _done = true;
    Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét QR chấm công')),
      body: Column(children: [
        Expanded(
          child: Stack(children: [
            MobileScanner(
              controller: _ctrl,
              onDetect: (capture) {
                for (final b in capture.barcodes) {
                  final v = b.rawValue;
                  if (v != null) {
                    _finish(v);
                    break;
                  }
                }
              },
            ),
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Text('Hướng camera vào mã QR trên màn hình Admin', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Máy ảo không quét được? Dán mã dạng chữ từ màn hình QR của Admin:', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _manual, decoration: const InputDecoration(hintText: 'CC1.1|...'))),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(90, 50)),
                  onPressed: () => _finish(_manual.text),
                  child: const Text('Dùng'),
                ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}
