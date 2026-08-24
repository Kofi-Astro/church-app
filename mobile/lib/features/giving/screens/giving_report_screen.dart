import 'package:flutter/material.dart';

import '../giving_service.dart';
import '../models.dart';

/// Admin/finance_admin view of *every* member's giving transactions (as
/// opposed to [GivingScreen], which is a member's own give-and-history
/// view). The backend enforces the role check independently — this
/// screen is only ever linked to from admin-gated menus, but would 403
/// gracefully even if reached directly.
class GivingReportScreen extends StatefulWidget {
  final GivingService givingService;

  const GivingReportScreen({super.key, required this.givingService});

  @override
  State<GivingReportScreen> createState() => _GivingReportScreenState();
}

// Loads and paginates the full cross-member transaction list.
class _GivingReportScreenState extends State<GivingReportScreen> {
  final List<GivingTransaction> _transactions = [];
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.givingService.allTransactions(offset: _transactions.length);
      setState(() {
        _transactions.addAll(page.items);
        _hasMore = page.hasMore;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _transactions.clear();
      _hasMore = true;
    });
    await _loadMore();
  }

  String _statusLabel(GivingStatus status) => switch (status) {
        GivingStatus.pending => 'Pending',
        GivingStatus.success => 'Completed',
        GivingStatus.failed => 'Failed',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giving report')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _transactions.isEmpty && !_loading
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _error ?? 'No giving transactions yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : ListView.builder(
                // +1 slot at the end for the "load more" spinner/sentinel.
                itemCount: _transactions.length + 1,
                itemBuilder: (context, index) {
                  if (index == _transactions.length) {
                    if (_hasMore) {
                      _loadMore();
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                  final transaction = _transactions[index];
                  return ListTile(
                    title: Text(
                      '${transaction.currency} ${transaction.amount} — ${transaction.givingType.label}',
                    ),
                    subtitle: Text(
                      '${_statusLabel(transaction.status)} · ${transaction.createdAt.toLocal().toString().split(' ').first}',
                    ),
                  );
                },
              ),
      ),
    );
  }
}
