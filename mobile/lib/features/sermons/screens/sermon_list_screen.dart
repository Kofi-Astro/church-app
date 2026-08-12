import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_service.dart';
import '../models.dart';
import '../sermon_service.dart';
import 'sermon_detail_screen.dart';
import 'sermon_form_screen.dart';

class SermonListScreen extends StatefulWidget {
  final SermonService sermonService;
  final AppProfile? profile;

  const SermonListScreen({super.key, required this.sermonService, required this.profile});

  @override
  State<SermonListScreen> createState() => _SermonListScreenState();
}

class _SermonListScreenState extends State<SermonListScreen> {
  List<Sermon> _sermons = [];
  ChurchSettings? _settings;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sermons = await widget.sermonService.listSermons(limit: 50);
      final settings = await widget.sermonService.getChurchSettings();
      setState(() {
        _sermons = sermons.items;
        _settings = settings;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _watchLive() async {
    final url = _settings?.livestreamUrl;
    if (url == null || url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final canManage = widget.profile?.role == AppRole.admin;
    final liveUrl = _settings?.livestreamUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Sermons')),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SermonFormScreen(sermonService: widget.sermonService),
                  ),
                );
                if (created == true) _load();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView(
                    children: [
                      if (liveUrl != null && liveUrl.isNotEmpty)
                        Card(
                          margin: const EdgeInsets.all(12),
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: ListTile(
                            leading: const Icon(Icons.live_tv),
                            title: const Text('Watch live'),
                            trailing: FilledButton(onPressed: _watchLive, child: const Text('Watch')),
                          ),
                        ),
                      if (_sermons.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No sermons yet.', textAlign: TextAlign.center),
                        ),
                      for (final sermon in _sermons)
                        ListTile(
                          title: Text(sermon.title),
                          subtitle: Text(
                            [
                              if (sermon.speaker != null) sermon.speaker,
                              if (sermon.series != null) sermon.series,
                              DateFormat.yMMMd().format(sermon.sermonDate),
                            ].join(' · '),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SermonDetailScreen(sermon: sermon)),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
