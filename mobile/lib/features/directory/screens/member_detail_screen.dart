import 'package:flutter/material.dart';

import '../models.dart';

class MemberDetailScreen extends StatelessWidget {
  final Member member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(member.fullName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (member.email != null) ListTile(leading: const Icon(Icons.email), title: Text(member.email!)),
          if (member.phone != null) ListTile(leading: const Icon(Icons.phone), title: Text(member.phone!)),
          if (member.email == null && member.phone == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No contact details on file.'),
            ),
        ],
      ),
    );
  }
}
