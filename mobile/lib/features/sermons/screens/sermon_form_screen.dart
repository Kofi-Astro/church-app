import 'package:flutter/material.dart';

import '../sermon_service.dart';

/// Admin-only form to create a new sermon entry (title, speaker, series,
/// date, video URL, description). Pops back with `true` on success so the
/// caller (SermonListScreen) knows to refresh its list.
class SermonFormScreen extends StatefulWidget {
  final SermonService sermonService;

  const SermonFormScreen({super.key, required this.sermonService});

  @override
  State<SermonFormScreen> createState() => _SermonFormScreenState();
}

/// Manages the new-sermon form's field controllers, selected date, and
/// save/loading state.
class _SermonFormScreenState extends State<SermonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _speakerController = TextEditingController();
  final _seriesController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  // Defaults to today; updated via the date picker below.
  DateTime _sermonDate = DateTime.now();
  bool _saving = false;

  /// Opens the date picker and updates [_sermonDate] with the selection.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sermonDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _sermonDate = picked);
  }

  /// Validates the form, then creates the sermon via the API and pops
  /// back to the caller (passing `true` to signal success).
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.sermonService.createSermon(
        title: _titleController.text.trim(),
        speaker: _speakerController.text.trim(),
        series: _seriesController.text.trim(),
        sermonDate: _sermonDate,
        videoUrl: _videoUrlController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save sermon: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New sermon')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _speakerController,
              decoration: const InputDecoration(labelText: 'Speaker (optional)'),
            ),
            TextFormField(
              controller: _seriesController,
              decoration: const InputDecoration(labelText: 'Series (optional)'),
            ),
            TextFormField(
              controller: _videoUrlController,
              decoration: const InputDecoration(labelText: 'Video URL (optional)'),
              keyboardType: TextInputType.url,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 3,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date: ${_sermonDate.toLocal().toString().split(' ').first}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
