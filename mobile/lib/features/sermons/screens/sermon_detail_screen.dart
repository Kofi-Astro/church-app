import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';

class SermonDetailScreen extends StatelessWidget {
  final Sermon sermon;

  const SermonDetailScreen({super.key, required this.sermon});

  Future<void> _watch() async {
    final url = sermon.videoUrl;
    if (url == null || url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(sermon.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(sermon.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            [
              if (sermon.speaker != null) sermon.speaker,
              if (sermon.series != null) sermon.series,
              DateFormat.yMMMd().format(sermon.sermonDate),
            ].join(' · '),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (sermon.videoUrl != null && sermon.videoUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _watch,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Watch'),
            ),
          ],
          if (sermon.description != null && sermon.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(sermon.description!),
          ],
        ],
      ),
    );
  }
}
