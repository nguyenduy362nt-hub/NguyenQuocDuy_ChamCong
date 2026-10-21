import 'package:flutter/material.dart';

import '../../api.dart';
import '../../widgets.dart';
import 'auth_shell.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final u = _user.text.trim();
    final p = _pass.text;
    if (u.isEmpty || p.isEmpty) {
      setState(() => _error = 'Vui lòng nhập tên đăng nhập và mật khẩu');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await Api.login(u, p);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            username: u,
            password: p,
            maskedEmail: (r['email'] ?? '').toString(),
            devOtp: r['devOtp']?.toString(),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Chấm Công',
      subtitle: 'Nguyễn Quốc Duy • 23DTHC4',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Đăng nhập', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Bước 1/2: tên đăng nhập và mật khẩu, sau đó nhập mã OTP gửi qua email.',
            style: TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 18),
        if (_error != null) ErrorBox(_error!),
        TextField(
          controller: _user,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Tên đăng nhập', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _pass,
          obscureText: _hide,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _hide = !_hide),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Text('Tiếp tục'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
          child: const Text('Chưa có tài khoản? Đăng ký bằng email'),
        ),
      ]),
    );
  }
}
