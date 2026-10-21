import 'dart:async';

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api.dart';
import '../../location_helper.dart';
import '../../widgets.dart';
import 'motion_challenge_page.dart';
import 'qr_scan_page.dart';

/// Tab chấm công của nhân viên: GPS + xác thực chuyển động, QR động, chia sẻ vị trí.
class CheckInTab extends StatefulWidget {
  const CheckInTab({super.key});
  @override
  State<CheckInTab> createState() => _CheckInTabState();
}

class _CheckInTabState extends State<CheckInTab> {
  Map<String, dynamic>? _record;
  Map<String, dynamic>? _shift;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  bool _sharing = false;
  DateTime? _lastShared;
  Timer? _shareTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _shareTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Api.get('attendance/today') as Map;
      if (!mounted) return;
      setState(() {
        _record = r['record'] == null ? null : Map<String, dynamic>.from(r['record'] as Map);
        _shift = r['shift'] == null ? null : Map<String, dynamic>.from(r['shift'] as Map);
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  // ---------- chấm công ----------
  Future<void> _checkInGps() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const MotionChallengePage()));
    if (ok != true) return;
    await _doCheckIn(method: 'GPS', motion: true);
  }

  Future<void> _checkInQr() async {
    final token = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const QrScanPage()));
    if (token == null) return;
    await _doCheckIn(method: 'QR', qr: token);
  }

  Future<void> _doCheckIn({required String method, String? qr, bool motion = false}) async {
    setState(() => _busy = true);
    try {
      final pos = await LocationHelper.current();
      await Api.post('attendance/check-in', {
        'method': method,
        'qrToken': qr,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'motionVerified': motion,
      });
      if (mounted) showSnack(context, 'Chấm công vào thành công!');
      await _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkOut() async {
    if (!await confirmDialog(context, 'Xác nhận chấm công RA?', okText: 'Chấm công ra')) return;
    setState(() => _busy = true);
    try {
      final pos = await LocationHelper.current();
      await Api.post('attendance/check-out', {'latitude': pos.latitude, 'longitude': pos.longitude});
      if (mounted) showSnack(context, 'Đã chấm công ra. Hẹn gặp lại!');
      await _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- chia sẻ vị trí ----------
  Future<void> _sendLocation() async {
    final pos = await LocationHelper.current();
    await Api.post('locations', {'latitude': pos.latitude, 'longitude': pos.longitude});
    if (mounted) setState(() => _lastShared = DateTime.now());
  }

  Future<void> _toggleShare(bool on) async {
    if (on) {
      try {
        await _sendLocation();
      } on ApiException catch (e) {
        if (mounted) showSnack(context, e.message, error: true);
        return;
      }
      _shareTimer?.cancel();
      _shareTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        try {
          await _sendLocation();
        } catch (_) {}
      });
      if (mounted) setState(() => _sharing = true);
    } else {
      _shareTimer?.cancel();
      try {
        await Api.delete('locations/mine');
      } on ApiException catch (_) {}
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(error: _error!, onRetry: () {
      setState(() => _loading = true);
      _load();
    });

    final checkedIn = _record != null;
    final checkedOut = checkedIn && _record!['checkOutTime'] != null;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        GradientHeader(
          subtitle: _dateText(),
          title: 'Xin chào, ${Session.fullName}',
          trailing: const _Clock(),
          bottom: _shift == null
              ? null
              : Text('Ca hôm nay: ${_shift!['name']} (${_shift!['startTime']} - ${_shift!['endTime']})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Row(children: [
              const Text('Hôm nay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (checkedIn) StatusChip(statusLabel('${_record!['status']}'), statusColor('${_record!['status']}')),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _TimeBox(label: 'Giờ vào', value: checkedIn ? fmtTime(_record!['checkInTime']) : '--:--', icon: Icons.login, color: kOk)),
              const SizedBox(width: 12),
              Expanded(child: _TimeBox(label: 'Giờ ra', value: checkedOut ? fmtTime(_record!['checkOutTime']) : '--:--', icon: Icons.logout, color: kDanger)),
            ]),
            if (checkedIn) ...[
              const SizedBox(height: 10),
              Text('Hình thức: ${_record!['method']}${_record!['motionVerified'] == true ? ' • đã xác thực chuyển động' : ''}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ]),
        ),
        if (!checkedIn) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text('Chọn cách chấm công vào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          _BigAction(
            icon: Icons.my_location,
            color: kPrimary,
            title: 'Chấm công bằng GPS',
            sub: 'Lắc điện thoại 4 lần để xác thực → kiểm tra vị trí trong vùng làm việc',
            busy: _busy,
            onTap: _checkInGps,
          ),
          _BigAction(
            icon: Icons.qr_code_scanner,
            color: const Color(0xFF7C3AED),
            title: 'Quét QR động',
            sub: 'Quét mã QR (đổi mỗi 30 giây) tại văn phòng',
            busy: _busy,
            onTap: _checkInQr,
          ),
        ] else if (!checkedOut)
          _BigAction(
            icon: Icons.logout,
            color: kDanger,
            title: 'Chấm công RA',
            sub: 'Kết thúc ca làm việc hôm nay',
            busy: _busy,
            onTap: _checkOut,
          )
        else
          AppCard(
            child: Row(children: [
              const Icon(Icons.check_circle, color: kOk, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Bạn đã hoàn thành ngày làm việc • ${fmtMinutes(_record!['workedMinutes'])}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        const SizedBox(height: 4),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: CircleAvatar(
                backgroundColor: (_sharing ? kOk : Colors.grey).withOpacity(0.15),
                child: Icon(Icons.share_location, color: _sharing ? kOk : Colors.grey),
              ),
              title: const Text('Chia sẻ vị trí với quản lý', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(_sharing
                  ? 'Đang chia sẻ • cập nhật lúc ${_lastShared == null ? '...' : DateFormat('HH:mm:ss').format(_lastShared!)}'
                  : 'Tắt • bật để quản lý thấy bạn trên bản đồ'),
              value: _sharing,
              onChanged: _toggleShare,
            ),
          ]),
        ),
      ]),
    );
  }

  String _dateText() {
    const days = ['Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy', 'Chủ nhật'];
    final n = DateTime.now();
    return '${days[n.weekday - 1]}, ${DateFormat('dd/MM/yyyy').format(n)}';
  }
}

class _Clock extends StatefulWidget {
  const _Clock();
  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  late Timer _t;
  DateTime _now = DateTime.now();
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        DateFormat('HH:mm:ss').format(_now),
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()]),
      );
}

class _TimeBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _TimeBox({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ]),
      );
}

class _BigAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  final bool busy;
  final VoidCallback onTap;
  const _BigAction({required this.icon, required this.color, required this.title, required this.sub, required this.busy, required this.onTap});
  @override
  Widget build(BuildContext context) => AppCard(
        onTap: busy ? null : onTap,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: busy ? SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 3, color: color)) : Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: Colors.black38),
        ]),
      );
}
