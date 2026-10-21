import 'package:flutter/material.dart';

import '../../api.dart';
import '../../widgets.dart';

class ProfilePage extends StatelessWidget {
  final List<Widget> extra;
  const ProfilePage({super.key, this.extra = const []});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: ListView(padding: const EdgeInsets.all(16), children: [
        GradientHeader(
          title: Session.fullName,
          subtitle: roleLabel(Session.role),
          trailing: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Text(
              Session.fullName.isEmpty ? '?' : Session.fullName.characters.first.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline, color: kPrimary),
              title: const Text('Tên đăng nhập'),
              subtitle: Text(Session.username),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_user_outlined, color: kPrimary),
              title: const Text('Quyền'),
              subtitle: Text(roleLabel(Session.role)),
            ),
          ]),
        ),
        ...extra,
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: kDanger,
            side: const BorderSide(color: kDanger),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => logout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Đăng xuất'),
        ),
        const SizedBox(height: 16),
        const Center(child: Text('Chấm Công • Nguyễn Quốc Duy • 23DTHC4', style: TextStyle(color: Colors.black38, fontSize: 12))),
      ]),
    );
  }
}
