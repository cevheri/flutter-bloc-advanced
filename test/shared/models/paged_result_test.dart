import 'package:flutter_bloc_advance/shared/models/paged_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PagedResult', () {
    test('hasMore is true when more pages exist', () {
      const result = PagedResult(items: [1, 2, 3], totalCount: 10, page: 0, pageSize: 3);
      expect(result.hasMore, true);
    });

    test('hasMore is false on last page', () {
      const result = PagedResult(items: [1], totalCount: 3, page: 2, pageSize: 1);
      expect(result.hasMore, false);
    });

    test('hasMore is false when items fit in one page', () {
      const result = PagedResult(items: [1, 2], totalCount: 2, page: 0, pageSize: 10);
      expect(result.hasMore, false);
    });

    test('totalPages calculates correctly', () {
      const result = PagedResult(items: [1], totalCount: 25, page: 0, pageSize: 10);
      expect(result.totalPages, 3);
    });

    test('totalPages is 1 for exact fit', () {
      const result = PagedResult(items: [1], totalCount: 10, page: 0, pageSize: 10);
      expect(result.totalPages, 1);
    });

    test('isEmpty and isNotEmpty', () {
      const empty = PagedResult<int>(items: [], totalCount: 0, page: 0, pageSize: 10);
      expect(empty.isEmpty, true);
      expect(empty.isNotEmpty, false);

      const notEmpty = PagedResult(items: [1], totalCount: 1, page: 0, pageSize: 10);
      expect(notEmpty.isEmpty, false);
      expect(notEmpty.isNotEmpty, true);
    });

    test('copyWith preserves unchanged fields', () {
      const original = PagedResult(items: [1, 2], totalCount: 10, page: 0, pageSize: 5);
      final copied = original.copyWith(page: 1);
      expect(copied.items, [1, 2]);
      expect(copied.totalCount, 10);
      expect(copied.page, 1);
      expect(copied.pageSize, 5);
    });

    test('supports value equality', () {
      const a = PagedResult(items: [1, 2], totalCount: 10, page: 0, pageSize: 5);
      const b = PagedResult(items: [1, 2], totalCount: 10, page: 0, pageSize: 5);
      expect(a, b);
    });

    test('toString includes key info', () {
      const result = PagedResult(items: [1, 2], totalCount: 10, page: 0, pageSize: 5);
      expect(result.toString(), contains('page: 0'));
      expect(result.toString(), contains('totalCount: 10'));
    });
  });
}
