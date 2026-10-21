import 'package:flutter/material.dart';

import '../../api.dart';
import '../../widgets.dart';

/// TÍNH NĂNG MỚI: Điểm chuyên cần & bảng xếp hạng 30 ngày.
/// Đúng giờ +10, đi trễ +6, mỗi giờ làm đủ +1 (tối đa +9/ngày).
class LeaderboardPage extends StatefulWidget {
  final bool showAppBar;
  const LeaderboardPage({super.key, this.showAppBar = false});
  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<dynamic> _f;

  @override
  void initState() {
    super.initState();
    _f = Api.get('stats/leaderboard');
  }

  void _reload() {
    setState(() {
      _f = Api.get('stats/leaderboard');
    });
  }

  Color _medal(int rank) {
    if (rank == 1) return const Color(0xFFF59E0B);
    if (rank == 2) return const Color(0xFF94A3B8);
    if (rank == 3) return const Color(0xFFB45309);
    return Colors.black26;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: widget.showAppBar ? AppBar(title: const Text('Xếp hạng chuyên cần')) : null,
      body: FutureBuilder<dynamic>(
        future: _f,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return ErrorView(error: snap.error!, onRetry: _reload);
          final rows = (snap.data as List).cast<dynamic>();
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _f;
            },
            child: ListView(padding: const EdgeInsets.all(16), children: [
              const GradientHeader(
                title: 'Bảng vàng chuyên cần',
                subtitle: '30 ngày gần nhất • đúng giờ +10đ • đi trễ +6đ • +1đ/giờ làm',
              ),
              const SizedBox(height: 14),
              if (rows.isEmpty) const EmptyState(text: 'Chưa có dữ liệu chấm công'),
              for (final r in rows)
                AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: _medal(r['rank'] as int).withOpacity(0.15),
                      child: (r['rank'] as int) <= 3
                          ? Icon(Icons.emoji_events, color: _medal(r['rank'] as int))
                          : Text('${r['rank']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${r['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          '${r['department']}'.isEmpty ? 'Chưa phân phòng' : '${r['department']}',
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Wrap(spacing: 6, children: [
                          StatusChip('${r['onTime']} đúng giờ', kOk),
                          StatusChip('${r['late']} trễ', const Color(0xFFD97706)),
                          StatusChip('${r['workedHours']}h', Colors.blueGrey),
                        ]),
                      ]),
                    ),
                    Column(children: [
                      Text('${r['points']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimary)),
                      const Text('điểm', style: TextStyle(fontSize: 11, color: Colors.black45)),
                    ]),
                  ]),
                ),
            ]),
          );
        },
      ),
    );
  }
}
