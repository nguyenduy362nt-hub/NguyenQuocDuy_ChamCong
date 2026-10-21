import 'package:flutter/material.dart';

import '../../api.dart';
import '../../widgets.dart';
import '../common/leaderboard_page.dart';
import '../common/profile_page.dart';
import 'admin_pages.dart';
import 'live_map_page.dart';
import 'qr_display_page.dart';

/// Trang quản trị (Admin).
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _AdminDashboard(),
      const AdminEmployeesPage(),
      const AdminAttendancePage(),
      const _AdminMenu(),
      const ProfilePage(),
    ];
    return Scaffold(
      body: SafeArea(bottom: false, child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Tổng quan'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Nhân viên'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: 'Chấm công'),
          NavigationDestination(icon: Icon(Icons.apps_outlined), selectedIcon: Icon(Icons.apps), label: 'Quản lý'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Tôi'),
        ],
      ),
    );
  }
}

class _AdminDashboard extends StatefulWidget {
  const _AdminDashboard();
  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  late Future<dynamic> _f;

  @override
  void initState() {
    super.initState();
    _f = Api.get('stats/summary');
  }

  void _reload() {
    setState(() {
      _f = Api.get('stats/summary');
    });
  }

  void _open(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _f,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return ErrorView(error: snap.error!, onRetry: _reload);
        final s = snap.data as Map;
        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _f;
          },
          child: ListView(padding: const EdgeInsets.all(16), children: [
            GradientHeader(
              subtitle: 'Trang quản trị',
              title: 'Xin chào, ${Session.fullName}',
              bottom: Text(
                'Hôm nay có ${s['present']}/${s['totalEmployees']} nhân viên đã chấm công',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                StatTile(icon: Icons.groups, label: 'Tổng nhân viên', value: '${s['totalEmployees']}', color: kPrimary),
                StatTile(icon: Icons.how_to_reg, label: 'Đã chấm công', value: '${s['present']}', color: kOk),
                StatTile(icon: Icons.alarm, label: 'Đi trễ', value: '${s['late']}', color: const Color(0xFFD97706)),
                StatTile(icon: Icons.person_off, label: 'Vắng mặt', value: '${s['absent']}', color: kDanger),
                StatTile(icon: Icons.beach_access, label: 'Nghỉ phép', value: '${s['onLeave']}', color: const Color(0xFF2563EB)),
                StatTile(icon: Icons.location_on, label: 'Đang chia sẻ vị trí', value: '${s['sharing']}', color: const Color(0xFF7C3AED)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Thao tác nhanh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _Quick(icon: Icons.qr_code_2, title: 'Hiển thị QR chấm công', sub: 'Mã tự đổi mỗi 30 giây', onTap: () => _open(const QrDisplayPage())),
            _Quick(icon: Icons.map, title: 'Bản đồ nhân viên', sub: 'Xem ai đang ở đâu theo thời gian thực', onTap: () => _open(const LiveMapPage())),
            _Quick(
              icon: Icons.event_note,
              title: 'Duyệt đơn nghỉ phép',
              sub: '${s['pendingLeaves']} đơn đang chờ duyệt',
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLeavesPage()));
                _reload();
              },
            ),
          ]),
        );
      },
    );
  }
}

class _Quick extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _Quick({required this.icon, required this.title, required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(children: [
      CircleAvatar(backgroundColor: kPrimary.withOpacity(0.12), foregroundColor: kPrimary, child: Icon(icon)),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ]),
      ),
      const Icon(Icons.chevron_right, color: Colors.black38),
    ]),
  );
}

class _AdminMenu extends StatelessWidget {
  const _AdminMenu();

  @override
  Widget build(BuildContext context) {
    void open(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const GradientHeader(title: 'Quản lý hệ thống', subtitle: 'Danh mục & chức năng'),
      const SizedBox(height: 16),
      _Quick(icon: Icons.apartment, title: 'Phòng ban', sub: 'Thêm / sửa / xóa phòng ban', onTap: () => open(const AdminDepartmentsPage())),
      _Quick(icon: Icons.schedule, title: 'Ca làm việc', sub: 'Giờ vào, giờ ra, thời gian cho phép trễ', onTap: () => open(const AdminShiftsPage())),
      _Quick(icon: Icons.location_city, title: 'Điểm làm việc', sub: 'Tọa độ & bán kính geofence', onTap: () => open(const AdminSitesPage())),
      _Quick(icon: Icons.event_note, title: 'Đơn nghỉ phép', sub: 'Duyệt hoặc từ chối', onTap: () => open(const AdminLeavesPage())),
      _Quick(icon: Icons.star_rate, title: 'Đánh giá của khách hàng', sub: 'Phản hồi về nhân viên', onTap: () => open(const AdminFeedbacksPage())),
      _Quick(icon: Icons.emoji_events, title: 'Xếp hạng chuyên cần', sub: 'Điểm 30 ngày gần nhất', onTap: () => open(const LeaderboardPage(showAppBar: true))),
      _Quick(icon: Icons.qr_code_2, title: 'QR chấm công động', sub: 'Hiển thị tại cửa văn phòng', onTap: () => open(const QrDisplayPage())),
      _Quick(icon: Icons.map, title: 'Bản đồ nhân viên', sub: 'Vị trí đang chia sẻ', onTap: () => open(const LiveMapPage())),
    ]);
  }
}
