/// Generic wrapper for a "page" of results returned by paginated backend
/// endpoints (e.g. member lists, attendance records). [T] is the type of
/// item in the page — use [fromJson] to parse a raw API response into a
/// typed PagedResult.
class PagedResult<T> {
  /// The items in this page.
  final List<T> items;
  /// Total number of items across all pages (not just this one).
  final int total;
  /// Page size that was requested.
  final int limit;
  /// How many items were skipped before this page (0-based).
  final int offset;

  const PagedResult({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  /// True if there are more items beyond this page — i.e. the caller
  /// should fetch another page (offset + limit) to see the rest.
  bool get hasMore => offset + items.length < total;

  /// Parses a paginated API response shaped like
  /// `{ "items": [...], "total": n, "limit": n, "offset": n }`, using
  /// [fromJson] to convert each raw item map into a [T].
  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PagedResult(
      items: (json['items'] as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      limit: json['limit'] as int,
      offset: json['offset'] as int,
    );
  }
}
