import 'package:equatable/equatable.dart';

/// Generic pagination wrapper for list results.
///
/// Usage:
/// ```dart
/// final paged = PagedResult<UserEntity>(
///   items: users,
///   totalCount: 100,
///   page: 0,
///   pageSize: 10,
/// );
/// if (paged.hasMore) loadNextPage();
/// ```
class PagedResult<T> extends Equatable {
  const PagedResult({required this.items, required this.totalCount, required this.page, required this.pageSize});

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  bool get hasMore => (page + 1) * pageSize < totalCount;
  int get totalPages => (totalCount / pageSize).ceil();
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  PagedResult<T> copyWith({List<T>? items, int? totalCount, int? page, int? pageSize}) {
    return PagedResult(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [items, totalCount, page, pageSize];

  @override
  String toString() => 'PagedResult(page: $page, pageSize: $pageSize, totalCount: $totalCount, items: ${items.length})';
}
