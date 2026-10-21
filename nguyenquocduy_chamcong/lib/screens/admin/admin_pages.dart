import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api.dart';
import '../../widgets.dart';

// ---------- helpers ----------
Future<List<MapEntry<dynamic, String>>> _departmentOptions() async {
  final list = await Api.get('departments') as List;
  return [
    const MapEntry<dynamic, String>(null, '— Không phòng ban —'),
    for (final d in list) MapEntry<dynamic, String>(d['id'], d['name'].toString()),
  ];
}

Future<List<MapEntry<dynamic, String>>> _employeeOptions() async {
  final list = await Api.get('employees') as List;
  return [for (final e in list) MapEntry<dynamic, String>(e['id'], '${e['code']} - ${e['fullName']}')];
}

// ======================= NHÂN VIÊN =======================
class AdminEmployeesPage extends StatelessWidget {
  final bool showAppBar;
  const AdminEmployeesPage({super.key, this.showAppBar = false});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Nhân viên',
      showAppBar: showAppBar,
      emptyText: 'Chưa có nhân viên nào',
      load: () async => await Api.get('employees') as List,
      titleOf: (e) => '${e['fullName']}',
      subtitleOf: (e) =>
          '${e['code']} • ${e['position'] ?? ''}\n${e['departmentName'] ?? 'Chưa có phòng ban'} • ${e['phone'] ?? ''}',
      badgeOf: (e) => Wrap(spacing: 6, children: [
        StatusChip(e['isActive'] == true ? 'Đang làm việc' : 'Ngưng', e['isActive'] == true ? kOk : Colors.grey),
        if (e['hasAccount'] == true) const StatusChip('Có tài khoản', kPrimary),
      ]),
      createDefaults: const {'isActive': true},
      loadFields: (isCreate) async {
        final deps = await _departmentOptions();
        return [
          const FieldSpec('fullName', 'Họ và tên', required: true, icon: Icons.badge_outlined),
          const FieldSpec('code', 'Mã nhân viên (để trống = tự sinh)', icon: Icons.numbers),
          const FieldSpec('position', 'Chức vụ', icon: Icons.work_outline),
          const FieldSpec('phone', 'Số điện thoại', icon: Icons.phone_outlined),
          FieldSpec('departmentId', 'Phòng ban', type: FieldType.dropdown, options: deps, icon: Icons.apartment),
          const FieldSpec('isActive', 'Đang làm việc', type: FieldType.boolean),
          if (isCreate) ...const [
            FieldSpec('username', 'Tên đăng nhập (tạo tài khoản, tuỳ chọn)', icon: Icons.person_outline),
            FieldSpec('email', 'Email tài khoản', type: FieldType.email, icon: Icons.email_outlined),
            FieldSpec('password', 'Mật khẩu tài khoản', type: FieldType.password, icon: Icons.lock_outline),
          ],
        ];
      },
      initialOf: (e) => {
        'fullName': e['fullName'],
        'code': e['code'],
        'position': e['position'],
        'phone': e['phone'],
        'departmentId': e['departmentId'],
        'isActive': e['isActive'] == true,
      },
      onCreate: (d) async => await Api.post('employees', d),
      onUpdate: (e, d) async => await Api.put('employees/${e['id']}', d),
      onDelete: (e) async => await Api.delete('employees/${e['id']}'),
    );
  }
}

// ======================= PHÒNG BAN =======================
class AdminDepartmentsPage extends StatelessWidget {
  const AdminDepartmentsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Phòng ban',
      load: () async => await Api.get('departments') as List,
      titleOf: (d) => '${d['name']}',
      subtitleOf: (d) => '${d['description'] ?? ''}\n${d['employeeCount']} nhân viên',
      leadingOf: (d) => const CircleAvatar(backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.apartment, color: kPrimary)),
      loadFields: (_) async => const [
        FieldSpec('name', 'Tên phòng ban', required: true, icon: Icons.apartment),
        FieldSpec('description', 'Mô tả', type: FieldType.multiline),
      ],
      initialOf: (d) => {'name': d['name'], 'description': d['description']},
      onCreate: (d) async => await Api.post('departments', d),
      onUpdate: (d, v) async => await Api.put('departments/${d['id']}', v),
      onDelete: (d) async => await Api.delete('departments/${d['id']}'),
    );
  }
}

// ======================= CA LÀM VIỆC =======================
class AdminShiftsPage extends StatelessWidget {
  const AdminShiftsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Ca làm việc',
      load: () async => await Api.get('shifts') as List,
      titleOf: (s) => '${s['name']}',
      subtitleOf: (s) => '${s['startTime']} → ${s['endTime']} • trễ sau ${s['lateGraceMinutes']} phút',
      leadingOf: (s) => const CircleAvatar(backgroundColor: Color(0xFFFEF3C7), child: Icon(Icons.schedule, color: Color(0xFFB45309))),
      loadFields: (_) async => const [
        FieldSpec('name', 'Tên ca', required: true, icon: Icons.label_outline),
        FieldSpec('startTime', 'Giờ bắt đầu', type: FieldType.time, required: true),
        FieldSpec('endTime', 'Giờ kết thúc', type: FieldType.time, required: true),
        FieldSpec('lateGraceMinutes', 'Cho phép trễ (phút)', type: FieldType.number, required: true),
      ],
      createDefaults: const {'startTime': '08:00', 'endTime': '17:00', 'lateGraceMinutes': 10},
      initialOf: (s) => {
        'name': s['name'],
        'startTime': s['startTime'],
        'endTime': s['endTime'],
        'lateGraceMinutes': s['lateGraceMinutes'],
      },
      onCreate: (d) async => await Api.post('shifts', d),
      onUpdate: (s, d) async => await Api.put('shifts/${s['id']}', d),
      onDelete: (s) async => await Api.delete('shifts/${s['id']}'),
    );
  }
}

// ======================= ĐIỂM LÀM VIỆC =======================
class AdminSitesPage extends StatelessWidget {
  const AdminSitesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Điểm làm việc (geofence)',
      load: () async => await Api.get('worksites') as List,
      titleOf: (s) => '${s['name']}',
      subtitleOf: (s) => 'Vĩ độ ${s['latitude']} • Kinh độ ${s['longitude']}\nBán kính cho phép ${s['radiusMeters']} m',
      leadingOf: (s) => const CircleAvatar(backgroundColor: Color(0xFFDBEAFE), child: Icon(Icons.location_city, color: Color(0xFF1D4ED8))),
      loadFields: (_) async => const [
        FieldSpec('name', 'Tên địa điểm', required: true),
        FieldSpec('latitude', 'Vĩ độ (latitude)', type: FieldType.number, required: true),
        FieldSpec('longitude', 'Kinh độ (longitude)', type: FieldType.number, required: true),
        FieldSpec('radiusMeters', 'Bán kính (mét)', type: FieldType.number, required: true),
      ],
      initialOf: (s) => {
        'name': s['name'],
        'latitude': s['latitude'],
        'longitude': s['longitude'],
        'radiusMeters': s['radiusMeters'],
      },
      onCreate: (d) async => await Api.post('worksites', d),
      onUpdate: (s, d) async => await Api.put('worksites/${s['id']}', d),
      onDelete: (s) async => await Api.delete('worksites/${s['id']}'),
    );
  }
}

// ======================= CHẤM CÔNG =======================
class AdminAttendancePage extends StatefulWidget {
  final bool showAppBar;
  const AdminAttendancePage({super.key, this.showAppBar = false});
  @override
  State<AdminAttendancePage> createState() => _AdminAttendancePageState();
}

class _AdminAttendancePageState extends State<AdminAttendancePage> {
  String? _date; // yyyy-MM-dd

  Future<void> _pick() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date ?? '') ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = DateFormat('yyyy-MM-dd').format(d));
  }

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      key: ValueKey(_date),
      title: 'Chấm công',
      showAppBar: widget.showAppBar,
      emptyText: 'Không có bản ghi chấm công',
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(children: [
          ActionChip(
            avatar: const Icon(Icons.calendar_month, size: 18),
            label: Text(_date == null ? 'Tất cả các ngày' : fmtDate(_date)),
            onPressed: _pick,
          ),
          const SizedBox(width: 8),
          if (_date != null)
            ActionChip(avatar: const Icon(Icons.close, size: 18), label: const Text('Bỏ lọc'), onPressed: () => setState(() => _date = null)),
        ]),
      ),
      load: () async => await Api.get('attendance', query: _date == null ? null : {'date': _date!}) as List,
      titleOf: (a) => '${a['employeeName']}',
      subtitleOf: (a) =>
          '${fmtDate(a['workDate'])} • Vào ${fmtTime(a['checkInTime'])} • Ra ${a['checkOutTime'] == null ? '--:--' : fmtTime(a['checkOutTime'])}\n'
          '${fmtMinutes(a['workedMinutes'])} • ${a['method']}${a['motionVerified'] == true ? ' • đã xác thực chuyển động' : ''}',
      badgeOf: (a) => StatusChip(statusLabel('${a['status']}'), statusColor('${a['status']}')),
      createDefaults: {'workDate': DateFormat('yyyy-MM-dd').format(DateTime.now()), 'checkIn': '08:00', 'status': 'DungGio'},
      loadFields: (_) async {
        final emps = await _employeeOptions();
        return [
          FieldSpec('employeeId', 'Nhân viên', type: FieldType.dropdown, options: emps, required: true),
          const FieldSpec('workDate', 'Ngày làm việc', type: FieldType.date, required: true),
          const FieldSpec('checkIn', 'Giờ vào', type: FieldType.time, required: true),
          const FieldSpec('checkOut', 'Giờ ra (tuỳ chọn)', type: FieldType.time),
          const FieldSpec('status', 'Trạng thái', type: FieldType.dropdown, required: true, options: [
            MapEntry<dynamic, String>('DungGio', 'Đúng giờ'),
            MapEntry<dynamic, String>('DiTre', 'Đi trễ'),
            MapEntry<dynamic, String>('NghiPhep', 'Nghỉ phép'),
          ]),
          const FieldSpec('note', 'Ghi chú', type: FieldType.multiline),
        ];
      },
      initialOf: (a) => {
        'employeeId': a['employeeId'],
        'workDate': a['workDate'],
        'checkIn': fmtTime(a['checkInTime']),
        'checkOut': a['checkOutTime'] == null ? '' : fmtTime(a['checkOutTime']),
        'status': a['status'],
        'note': a['note'],
      },
      onCreate: (d) async => await Api.post('attendance/manual', d),
      onUpdate: (a, d) async => await Api.put('attendance/${a['id']}', d),
      onDelete: (a) async => await Api.delete('attendance/${a['id']}'),
    );
  }
}

// ======================= NGHỈ PHÉP (DUYỆT ĐƠN) =======================
class AdminLeavesPage extends StatelessWidget {
  const AdminLeavesPage({super.key});

  Future<void> _set(BuildContext c, dynamic l, String status, VoidCallback reload) async {
    try {
      await Api.put('leaves/${l['id']}/status', {'status': status, 'adminNote': ''});
      if (c.mounted) showSnack(c, status == 'DaDuyet' ? 'Đã duyệt đơn' : 'Đã từ chối đơn');
      reload();
    } on ApiException catch (e) {
      if (c.mounted) showSnack(c, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Đơn nghỉ phép',
      emptyText: 'Chưa có đơn nghỉ phép',
      load: () async => await Api.get('leaves') as List,
      titleOf: (l) => '${l['employeeName']}',
      subtitleOf: (l) => '${fmtDate(l['fromDate'])} → ${fmtDate(l['toDate'])}\n${l['reason']}',
      badgeOf: (l) => StatusChip(statusLabel('${l['status']}'), statusColor('${l['status']}')),
      extraActions: (c, l, reload) => l['status'] == 'ChoDuyet'
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Duyệt',
                icon: const Icon(Icons.check_circle, color: kOk),
                onPressed: () => _set(c, l, 'DaDuyet', reload),
              ),
              IconButton(
                tooltip: 'Từ chối',
                icon: const Icon(Icons.cancel, color: kDanger),
                onPressed: () => _set(c, l, 'TuChoi', reload),
              ),
            ])
          : const SizedBox.shrink(),
      onDelete: (l) async => await Api.delete('leaves/${l['id']}'),
    );
  }
}

// ======================= ĐÁNH GIÁ CỦA KHÁCH HÀNG =======================
class AdminFeedbacksPage extends StatelessWidget {
  const AdminFeedbacksPage({super.key});
  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Đánh giá của khách hàng',
      emptyText: 'Chưa có đánh giá nào',
      load: () async => await Api.get('feedbacks') as List,
      titleOf: (f) => '${f['customerName']}  ${'★' * (f['rating'] as int)}',
      subtitleOf: (f) => 'Về: ${f['employeeName'] ?? 'Công ty'}\n${f['content']}',
      leadingOf: (f) => const CircleAvatar(backgroundColor: Color(0xFFFEF3C7), child: Icon(Icons.star, color: kAccent)),
      onDelete: (f) async => await Api.delete('feedbacks/${f['id']}'),
    );
  }
}
