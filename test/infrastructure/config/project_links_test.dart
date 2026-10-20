import 'package:flutter_bloc_advance/infrastructure/config/project_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectLinks', () {
    test('gives each link that is filled in', () {
      const links = ProjectLinks(
        repository: 'https://github.com/acme/dashboard',
        docs: 'https://docs.acme.example',
        sponsor: 'https://github.com/sponsors/acme',
      );

      expect(links.repositoryUrl, 'https://github.com/acme/dashboard');
      expect(links.docsUrl, 'https://docs.acme.example');
      expect(links.sponsorUrl, 'https://github.com/sponsors/acme');
    });

    // Made-up keys: replacing the template's real placeholders across a project leaves this test as it is.
    test('leaves out each link that is still a placeholder', () {
      const links = ProjectLinks(repository: '__REPOSITORY__', docs: '__DOCS__', sponsor: '__SPONSOR__');

      expect(links.repositoryUrl, isNull);
      expect(links.docsUrl, isNull);
      expect(links.sponsorUrl, isNull);
    });

    test('leaves out each link given as an empty value', () {
      const links = ProjectLinks(repository: '', docs: '', sponsor: '');

      expect(links.repositoryUrl, isNull);
      expect(links.docsUrl, isNull);
      expect(links.sponsorUrl, isNull);
    });
  });
}
