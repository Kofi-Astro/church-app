import 'package:flutter/material.dart';

import '../event_service.dart';

class EventFormScreen extends StatefulWidget {
  final EventService eventService;

  const EventFormScreen({super.key, required this.eventService});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _saving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final eventDate = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    try {
      await widget.eventService.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDate: eventDate,
        location: _locationController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save event: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New event')),
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
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location (optional)'),
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 3,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date: ${_date.toLocal().toString().split(' ').first}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Time: ${_time.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
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
