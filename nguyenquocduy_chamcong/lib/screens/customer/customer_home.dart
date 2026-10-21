import 'package:flutter/material.dart';

import '../../api.dart';
import '../../widgets.dart';
import '../common/leaderboard_page.dart';
import '../common/profile_page.dart';

/// Trang dành cho Khách hàng: xem nhân viên, đánh giá (CRUD), xem bảng xếp hạng.
class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _tab = 0;
  int _ver = 0; // tăng mỗi lần đổi tab để tab tự tải lại dữ liệu

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _StaffTab(),
      _MyFeedbackTab(key: ValueKey('fb$_ver')),
      LeaderboardPage(key: ValueKey('lb$_ver')),
      const ProfilePage(),
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
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Nhân viên'),
          NavigationDestination(icon: Icon(Icons.rate_review_outlined), selectedIcon: Icon(Icons.rate_review), label: 'Đánh giá'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Xếp hạng'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Tôi'),
        ],
      ),
    );
  }
}

class _StaffTab extends StatelessWidget {
  const _StaffTab();
  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Đội ngũ nhân viên',
      showAppBar: false,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: GradientHeader(subtitle: 'Xin chào khách hàng', title: Session.fullName, bottom: const Text('Đội ngũ phục vụ bạn hôm nay', style: TextStyle(color: Colors.white))),
      ),
      load: () async => (await Api.get('employees') as List).where((e) => e['isActive'] == true).toList(),
      titleOf: (e) => '${e['fullName']}',
      subtitleOf: (e) => '${e['position'] ?? ''} • ${e['departmentName'] ?? 'Công ty'}',
      extraActions: (c, e, reload) => TextButton.icon(
        onPressed: () async {
          final r = await showFormDialog(c, title: 'Đánh giá ${e['fullName']}', fields: _feedbackFields(null), initial: {'employeeId': e['id'], 'rating': 5});
          if (r == null) return;
          r['employeeId'] = e['id'];
          try {
            await Api.post('feedbacks', r);
            if (c.mounted) showSnack(c, 'Cảm ơn bạn đã đánh giá!');
          } on ApiException catch (ex) {
            if (c.mounted) showSnack(c, ex.message, error: true);
          }
        },
        icon: const Icon(Icons.star_outline, color: kAccent),
        label: const Text('Đánh giá'),
      ),
    );
  }
}

List<FieldSpec> _feedbackFields(List<MapEntry<dynamic, String>>? staff) => [
  if (staff != null) FieldSpec('employeeId', 'Nhân viên được đánh giá', type: FieldType.dropdown, options: staff),
  const FieldSpec('rating', 'Số sao', type: FieldType.dropdown, required: true, options: [
    MapEntry<dynamic, String>(5, '★★★★★  Tuyệt vời'),
    MapEntry<dynamic, String>(4, '★★★★  Tốt'),
    MapEntry<dynamic, String>(3, '★★★  Bình thường'),
    MapEntry<dynamic, String>(2, '★★  Chưa tốt'),
    MapEntry<dynamic, String>(1, '★  Tệ'),
  ]),
  const FieldSpec('content', 'Nội dung đánh giá', type: FieldType.multiline, required: true),
];

class _MyFeedbackTab extends StatelessWidget {
  const _MyFeedbackTab({super.key});
  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Đánh giá của tôi',
      showAppBar: false,
      emptyText: 'Bạn chưa gửi đánh giá nào.\nNhấn "Thêm" để viết đánh giá.',
      header: const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: GradientHeader(title: 'Đánh giá của tôi', subtitle: 'Thêm • sửa • xóa phản hồi'),
      ),
      load: () async => await Api.get('feedbacks') as List,
      titleOf: (f) => '${'★' * (f['rating'] as int)}${'☆' * (5 - (f['rating'] as int))}',
      subtitleOf: (f) => 'Về: ${f['employeeName'] ?? 'Công ty'}\n${f['content']}',
      leadingOf: (f) => const CircleAvatar(backgroundColor: Color(0xFFFEF3C7), child: Icon(Icons.star, color: kAccent)),
      loadFields: (_) async {
        final list = await Api.get('employees') as List;
        return _feedbackFields([
          const MapEntry<dynamic, String>(null, '— Công ty nói chung —'),
          for (final e in list) MapEntry<dynamic, String>(e['id'], '${e['fullName']}'),
        ]);
      },
      createDefaults: const {'rating': 5},
      initialOf: (f) => {'employeeId': f['employeeId'], 'rating': f['rating'], 'content': f['content']},
      onCreate: (d) async => await Api.post('feedbacks', d),
      onUpdate: (f, d) async => await Api.put('feedbacks/${f['id']}', d),
      onDelete: (f) async => await Api.delete('feedbacks/${f['id']}'),
    );
  }
}
