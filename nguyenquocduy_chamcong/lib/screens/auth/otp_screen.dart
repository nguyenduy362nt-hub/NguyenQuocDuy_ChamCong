import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_auth/smart_auth.dart';

import '../../api.dart';
import '../../widgets.dart';
import 'auth_shell.dart';

class OtpScreen extends StatefulWidget {
  final String username;
  final String password;
  final String maskedEmail;
  final String? devOtp;
  const OtpScreen({
    super.key,
    required this.username,
    required this.password,
    required this.maskedEmail,
    this.devOtp,
  });
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  bool _listening = false;
  String? _error;
  String? _devOtp;
  int _cooldown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _devOtp = widget.devOtp;
    _startTimer();
    _listenSms();
  }

  // Tự đọc SMS (SMS User Consent API) rồi điền mã OTP 6 số
  Future<void> _listenSms() async {
    if (mounted) setState(() => _listening = true);
    try {
      final res = await SmartAuth.instance.getSmsWithUserConsentApi();
      if (!mounted) return;
      final sms = res.data?.sms ?? '';
      final m = RegExp(r'(\d{6})').firstMatch(sms);
      if (m != null) {
        setState(() {
          _code.text = m.group(1)!;
          _listening = false;
        });
        _verify();
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _listening = false);
  }

  void _startTimer() {
    _cooldown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown = _cooldown > 0 ? _cooldown - 1 : 0);
      if (_cooldown == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      SmartAuth.instance.removeUserConsentApiListener();
    } catch (_) {}
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final c = _code.text.trim();
    if (c.length != 6) {
      setState(() => _error = 'Vui lòng nhập đủ 6 chữ số');
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.verifyOtp(widget.username, c);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      final r = await Api.login(widget.username, widget.password);
      if (!mounted) return;
      setState(() {
        _devOtp = r['devOtp']?.toString();
        _error = null;
      });
      _startTimer();
      showSnack(context, 'Đã gửi lại mã OTP');
      _listenSms();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Xác thực OTP',
      subtitle: 'Mã 6 số đã gửi qua SMS và email ${widget.maskedEmail}',
      icon: Icons.sms_outlined,
      showBack: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_error != null) ErrorBox(_error!),
        if (_listening)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Expanded(child: Text('Đang chờ tin nhắn SMS chứa mã OTP...')),
            ]),
          ),
        if (_devOtp != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: kAccent)),
            child: Row(children: [
              const Icon(Icons.developer_mode, color: Color(0xFFB45309)),
              const SizedBox(width: 10),
              Expanded(child: Text('Chế độ demo: mã của bạn là $_devOtp', style: const TextStyle(color: Color(0xFF92400E)))),
              TextButton(onPressed: () => setState(() => _code.text = _devOtp!), child: const Text('Điền')),
            ]),
          ),
        TextField(
          controller: _code,
          maxLength: 6,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 30, letterSpacing: 12, fontWeight: FontWeight.bold),
          onSubmitted: (_) => _verify(),
          decoration: const InputDecoration(counterText: '', hintText: '------'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _verify,
          child: _busy
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Text('Xác nhận & đăng nhập'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _cooldown == 0 ? _resend : null,
          child: Text(_cooldown == 0 ? 'Gửi lại mã' : 'Gửi lại mã sau ${_cooldown}s'),
        ),
      ]),
    );
  }
}
