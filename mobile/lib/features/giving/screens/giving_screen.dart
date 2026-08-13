import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../giving_service.dart';
import '../models.dart';

/// The real Give screen — form, submit flow, and history all wired to
/// the real backend (see backend/app/api/v1/giving.py). The one thing
/// that isn't real yet is Paystack itself: PAYSTACK_SECRET_KEY isn't set,
/// so the backend returns a clean 503 on submit, which this screen shows
/// as an explanatory dialog rather than a raw error. Everything else —
/// layout, validation, the giving-type picker, the history list — is
/// exactly what a member will see once that key is added.
class GivingScreen extends StatefulWidget {
  final GivingService givingService;

  const GivingScreen({super.key, required this.givingService});

  @override
  State<GivingScreen> createState() => _GivingScreenState();
}

class _GivingScreenState extends State<GivingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  GivingType _givingType = GivingType.tithe;
  bool _submitting = false;

  List<GivingTransaction> _history = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final page = await widget.givingService.myHistory();
      if (!mounted) return;
      setState(() => _history = page.items);
    } catch (_) {
      // Giving history is secondary to the form itself on this screen —
      // fail quietly and leave the list empty rather than blocking the
      // form behind an error.
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final result = await widget.givingService.initialize(
        amount: _amountController.text.trim(),
        givingType: _givingType,
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      await launchUrl(Uri.parse(result.authorizationUrl), mode: LaunchMode.externalApplication);
      _amountController.clear();
      _noteController.clear();
      await _loadHistory();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 503) {
        await _showNotConfiguredDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start giving: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showNotConfiguredDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_clock_outlined),
        title: const Text('Online giving isn\'t connected yet'),
        content: const Text(
          'This is exactly what giving will look like — the form, the '
          'amount, the giving type. The only missing piece is the '
          'church\'s Paystack account; once that\'s added, "Give now" '
          'will take you to Paystack to complete your gift.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Give')),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<GivingType>(
                initialValue: _givingType,
                decoration: const InputDecoration(labelText: 'Giving type'),
                items: [
                  for (final type in GivingType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _givingType = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (GHS)', prefixText: 'GHS '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Give now'),
              ),
              const SizedBox(height: 32),
              Text('Recent giving', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_loadingHistory)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else if (_history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No giving history yet.'),
                )
              else
                for (final transaction in _history)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${transaction.currency} ${transaction.amount} — ${transaction.givingType.label}'),
                    subtitle: Text(_statusLabel(transaction.status)),
                    trailing: Text(transaction.createdAt.toLocal().toString().split(' ').first),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(GivingStatus status) => switch (status) {
        GivingStatus.pending => 'Pending',
        GivingStatus.success => 'Completed',
        GivingStatus.failed => 'Failed',
      };
}
