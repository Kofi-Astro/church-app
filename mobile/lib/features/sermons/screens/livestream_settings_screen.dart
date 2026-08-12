import 'package:flutter/material.dart';

import '../sermon_service.dart';

class LivestreamSettingsScreen extends StatefulWidget {
  final SermonService sermonService;

  const LivestreamSettingsScreen({super.key, required this.sermonService});

  @override
  State<LivestreamSettingsScreen> createState() => _LivestreamSettingsScreenState();
}

class _LivestreamSettingsScreenState extends State<LivestreamSettingsScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await widget.sermonService.getChurchSettings();
      _controller.text = settings.livestreamUrl ?? '';
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.sermonService.updateLivestreamUrl(
        _controller.text.trim().isEmpty ? null : _controller.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Livestream URL')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) Text(_error!),
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'YouTube/Vimeo live URL',
                      hintText: 'https://youtube.com/live/...',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Shown as a "Watch live" banner at the top of the Sermons tab '
                    'for everyone when set. Leave blank to hide it.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }
}
