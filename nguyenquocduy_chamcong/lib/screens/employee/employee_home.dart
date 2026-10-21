import 'package:flutter/material.dart';

import '../../api.dart';
import '../../widgets.dart';
import '../common/leaderboard_page.dart';
import '../common/profile_page.dart';
import 'checkin_tab.dart';

/// Dashboard của nhân viên.
class EmployeeHome extends StatefulWidget {
  const EmployeeHome({super.key});
  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome> {
  int _tab = 0;
  int _ver = 0; // tăng mỗi lần đổi tab để các tab tự tải lại dữ liệu

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const CheckInTab(),
      _HistoryTab(key: ValueKey('h$_ver')),
      _LeaveTab(key: ValueKey('l$_ver')),
      LeaderboardPage(key: ValueKey('lb$_ver')),
      ProfilePage(key: ValueKey('p$_ver'), extra: const [_MyStatsCard()]),
    ];
    return Scaffold(
      body: SafeArea(bottom: false, child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() {
          _tab = i;
          _ver++;
        }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.fingerprint), label: 'Chấm công'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Lịch sử'),
          NavigationDestination(icon: Icon(Icons.beach_access_outlined), selectedIcon: Icon(Icons.beach_access), label: 'Nghỉ phép'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Xếp hạng'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Tôi'),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({super.key});
  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Lịch sử chấm công',
      showAppBar: false,
      emptyText: 'Chưa có lịch sử chấm công',
      header: const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: GradientHeader(title: 'Lịch sử chấm công', subtitle: '60 ngày gần nhất'),
      ),
      load: () async => await Api.get('attendance/mine') as List,
      titleOf: (a) => fmtDate(a['workDate']),
      subtitleOf: (a) =>
      'Vào ${fmtTime(a['checkInTime'])} • Ra ${a['checkOutTime'] == null ? '--:--' : fmtTime(a['checkOutTime'])} • ${fmtMinutes(a['workedMinutes'])}\n${a['method']}',
      badgeOf: (a) => StatusChip(statusLabel('${a['status']}'), statusColor('${a['status']}')),
      leadingOf: (a) => CircleAvatar(
        backgroundColor: statusColor('${a['status']}').withOpacity(0.12),
        child: Icon(a['status'] == 'DungGio' ? Icons.check : Icons.alarm, color: statusColor('${a['status']}')),
      ),
    );
  }
}

class _LeaveTab extends StatelessWidget {
  const _LeaveTab({super.key});
  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Nghỉ phép',
      showAppBar: false,
      emptyText: 'Bạn chưa có đơn nghỉ phép nào.\nNhấn "Thêm" để xin nghỉ.',
      header: const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: GradientHeader(title: 'Đơn nghỉ phép của tôi', subtitle: 'Gửi đơn & theo dõi duyệt'),
      ),
      load: () async => await Api.get('leaves/mine') as List,
      titleOf: (l) => '${fmtDate(l['fromDate'])} → ${fmtDate(l['toDate'])}',
      subtitleOf: (l) => '${l['reason']}${(l['adminNote'] ?? '').toString().isEmpty ? '' : '\nQuản lý: ${l['adminNote']}'}',
      leadingOf: (l) => CircleAvatar(
        backgroundColor: statusColor('${l['status']}').withOpacity(0.12),
        child: Icon(Icons.event_note, color: statusColor('${l['status']}')),
      ),
      badgeOf: (l) => StatusChip(statusLabel('${l['status']}'), statusColor('${l['status']}')),
      canEdit: (l) => l['status'] == 'ChoDuyet',
      canDelete: (l) => l['status'] == 'ChoDuyet',
      loadFields: (_) async => const [
        FieldSpec('fromDate', 'Từ ngày', type: FieldType.date, required: true),
        FieldSpec('toDate', 'Đến ngày', type: FieldType.date, required: true),
        FieldSpec('reason', 'Lý do', type: FieldType.multiline, required: true),
      ],
      initialOf: (l) => {'fromDate': l['fromDate'], 'toDate': l['toDate'], 'reason': l['reason']},
      onCreate: (d) async => await Api.post('leaves', d),
      onUpdate: (l, d) async => await Api.put('leaves/${l['id']}', d),
      onDelete: (l) async => await Api.delete('leaves/${l['id']}'),
    );
  }
}

class _MyStatsCard extends StatelessWidget {
  const _MyStatsCard();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: Api.get('stats/me'),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final row = (snap.data as Map)['row'];
        final total = (snap.data as Map)['totalPeople'];
        if (row == null) return const SizedBox.shrink();
        return AppCard(
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _Num('${row['points']}', 'Điểm 30 ngày'),
            _Num('#${row['rank']}/$total', 'Xếp hạng'),
            _Num('${row['onTime']}', 'Đúng giờ'),
            _Num('${row['late']}', 'Đi trễ'),
          ]),
        );
      },
    );
  }
}

class _Num extends StatelessWidget {
  final String v;
  final String l;
  const _Num(this.v, this.l);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimary)),
    Text(l, style: const TextStyle(fontSize: 11, color: Colors.black54)),
  ]);
}
