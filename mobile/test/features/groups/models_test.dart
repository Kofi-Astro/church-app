import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/groups/models.dart';

void main() {
  test('SmallGroup.fromJson parses a nullable leader_id and defaults category', () {
    final group = SmallGroup.fromJson({
      'id': 'g1',
      'name': 'Young Adults',
      'description': null,
      'leader_id': null,
      'created_at': '2026-01-01T00:00:00Z',
    });

    expect(group.name, 'Young Adults');
    expect(group.leaderId, isNull);
    expect(group.category, GroupCategory.smallGroup);
  });

  test('SmallGroup.fromJson parses an auxiliary category', () {
    final group = SmallGroup.fromJson({
      'id': 'g2',
      'name': 'Royal Ambassadors',
      'description': null,
      'leader_id': null,
      'category': 'auxiliary',
      'created_at': '2026-01-01T00:00:00Z',
    });

    expect(group.category, GroupCategory.auxiliary);
  });

  test('GroupMaterial.fromJson parses an optional url', () {
    final material = GroupMaterial.fromJson({
      'id': 'm1',
      'group_id': 'g1',
      'title': 'Week 1 guide',
      'url': 'https://example.com/guide.pdf',
      'description': null,
      'created_at': '2026-01-01T00:00:00Z',
    });

    expect(material.title, 'Week 1 guide');
    expect(material.url, 'https://example.com/guide.pdf');
  });
}
