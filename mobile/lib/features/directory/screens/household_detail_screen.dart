import 'package:flutter/material.dart';

import '../directory_service.dart';
import '../models.dart';

/// Shows a household's members — the "household grouping UI" from the
/// Phase 1 roadmap: rather than a flat member list, members are reachable
/// grouped by the household they belong to.
class HouseholdDetailScreen extends StatefulWidget {
  final Household household;
  final DirectoryService directoryService;

  const HouseholdDetailScreen({
    super.key,
    required this.household,
    required this.directoryService,
  });

  @override
  State<HouseholdDetailScreen> createState() => _HouseholdDetailScreenState();
}

class _HouseholdDetailScreenState extends State<HouseholdDetailScreen> {
  late Future<PagedResultOrError> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _loadMembers();
  }

  Future<PagedResultOrError> _loadMembers() async {
    try {
      final page = await widget.directoryService.listMembers(
        householdId: widget.household.id,
        limit: 100,
      );
      return PagedResultOrError.ok(page.items);
    } catch (e) {
      return PagedResultOrError.error(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.household.name)),
      body: FutureBuilder<PagedResultOrError>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data!;
          if (result.error != null) {
            return Center(child: Text(result.error!));
          }
          final members = result.members!;
          if (members.isEmpty) {
            return const Center(child: Text('No members in this household yet.'));
          }
          return ListView(
            children: [
              if (widget.household.address != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.household.address!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              const Divider(height: 1),
              for (final member in members)
                ListTile(
                  title: Text(member.fullName),
                  subtitle: Text([member.email, member.phone].whereType<String>().join(' · ')),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Small result wrapper so the FutureBuilder above can distinguish "loaded
/// with an error" from "still loading" without throwing inside build().
class PagedResultOrError {
  final List<Member>? members;
  final String? error;

  const PagedResultOrError._(this.members, this.error);

  factory PagedResultOrError.ok(List<Member> members) => PagedResultOrError._(members, null);
  factory PagedResultOrError.error(String error) => PagedResultOrError._(null, error);
}
