import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../api.dart';
import '../../widgets.dart';

/// Admin hiển thị mã QR ĐỘNG: tự đổi mỗi 30 giây, chống chụp ảnh gửi cho người khác chấm công hộ.
class QrDisplayPage extends StatefulWidget {
  const QrDisplayPage({super.key});
  @override
  State<QrDisplayPage> createState() => _QrDisplayPageState();
}

class _QrDisplayPageState extends State<QrDisplayPage> {
  String? _token;
  String _site = '';
  int _remain = 0;
  int _window = 30;
  String? _error;
  Timer? _timer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remain > 0) {
        setState(() => _remain--);
      } else {
        _fetch();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_loading) return;
    _loading = true;
    try {
      final r = await Api.get('qr/current');
      if (!mounted) return;
      setState(() {
        _token = r['token'] as String;
        _site = '${r['siteName']}';
        _remain = (r['expiresIn'] as num).toInt();
        _window = (r['windowSeconds'] as num).toInt();
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _remain = 3;
      });
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('QR chấm công động')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text(_site.isEmpty ? '...' : _site, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Nhân viên mở app → Chấm công → "Quét QR" để chấm công', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 18),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: kDanger))
            else if (_token == null)
              const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kPrimary, width: 3)),
                child: QrImageView(data: _token!, version: QrVersions.auto, size: 250, backgroundColor: Colors.white),
              ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _window == 0 ? 0 : (_remain / _window).clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: _remain <= 8 ? kDanger : kPrimary,
              backgroundColor: Colors.black12,
            ),
            const SizedBox(height: 8),
            Text('Tự đổi mã sau $_remain giây', style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Mã dạng chữ (dùng khi máy ảo không quét được camera)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SelectableText(_token ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _token == null
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: _token!));
                      showSnack(context, 'Đã sao chép mã');
                    },
              icon: const Icon(Icons.copy),
              label: const Text('Sao chép'),
            ),
          ]),
        ),
      ]),
    );
  }
}
