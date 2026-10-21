import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_page_restore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a page restored from the back-forward cache is reloaded', () {
    var reloads = 0;

    onPageShow(persisted: true, reload: () => reloads++);

    expect(reloads, 1);
  });

  test('a page the browser loaded afresh is not reloaded', () {
    onPageShow(persisted: false, reload: () => fail('a fresh page load was reloaded'));
  });
}
