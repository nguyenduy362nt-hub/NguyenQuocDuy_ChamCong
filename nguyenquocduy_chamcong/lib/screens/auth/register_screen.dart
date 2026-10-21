import 'package:flutter/material.dart';

import '../../api.dart';
import '../../widgets.dart';
import 'auth_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _full = TextEditingController();
  final _user = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  String _role = 'NhanVien';
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_full, _user, _email, _phone, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.register({
        'fullName': _full.text.trim(),
        'username': _user.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'password': _pass.text,
        'role': _role,
      });
      if (!mounted) return;
      showSnack(context, 'Đăng ký thành công! Hãy đăng nhập.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Tạo tài khoản',
      subtitle: 'Đăng ký bằng email của bạn',
      icon: Icons.mark_email_read_outlined,
      showBack: true,
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_error != null) ErrorBox(_error!),
          const Text('Bạn là', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'NhanVien', label: Text('Nhân viên'), icon: Icon(Icons.badge_outlined)),
              ButtonSegment(value: 'KhachHang', label: Text('Khách hàng'), icon: Icon(Icons.people_outline)),
            ],
            selected: {_role},
            onSelectionChanged: (s) => setState(() => _role = s.first),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _full,
            decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Icons.badge_outlined)),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _user,
            decoration: const InputDecoration(labelText: 'Tên đăng nhập', prefixIcon: Icon(Icons.person_outline)),
            validator: (v) => (v ?? '').trim().length < 3 ? 'Tối thiểu 3 ký tự' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email (nhận mã OTP)', prefixIcon: Icon(Icons.email_outlined)),
            validator: (v) {
              final s = (v ?? '').trim();
              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s) ? null : 'Email không hợp lệ';
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Số điện thoại (tuỳ chọn)', prefixIcon: Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pass,
            obscureText: _hide,
            decoration: InputDecoration(
              labelText: 'Mật khẩu (≥ 6 ký tự, có số)',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
            validator: (v) {
              final s = v ?? '';
              if (s.length < 6) return 'Tối thiểu 6 ký tự';
              if (!RegExp(r'\d').hasMatch(s)) return 'Cần có ít nhất 1 chữ số';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pass2,
            obscureText: _hide,
            decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu', prefixIcon: Icon(Icons.lock_reset)),
            validator: (v) => v != _pass.text ? 'Mật khẩu nhập lại không khớp' : null,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Đăng ký'),
          ),
        ]),
      ),
    );
  }
}
