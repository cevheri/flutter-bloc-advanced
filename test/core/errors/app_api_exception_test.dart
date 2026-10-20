import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/printed_lines.dart';

// Regression: every AppException logged itself at error level when it was built, so a 401 before a token refresh, a
// validation error shown to the user or a 404 printed an error line, and the catch site that handled it printed the
// same failure again.
void main() {
  group('AppException', () {
    final exceptions = <String, AppException Function()>{
      'FetchDataException': () => FetchDataException('Not found: {"title":"missing"}'),
      'UntrustedCertificateException': () => UntrustedCertificateException('Untrusted connection to api:443'),
      'BadRequestException': () => BadRequestException('{"title":"invalid"}'),
      'UnauthorizedException': () => UnauthorizedException('{"title":"expired"}'),
      'CircuitBreakerOpenException': () => CircuitBreakerOpenException('GET /api/users'),
    };

    for (final MapEntry(key: name, value: build) in exceptions.entries) {
      test('$name prints nothing when it is built', () async {
        final lines = await printedLines(build);

        expect(lines, isEmpty);
      });
    }

    test('keeps its prefix and message in its text', () {
      expect(UnauthorizedException('{"title":"expired"}').toString(), 'Unauthorized: {"title":"expired"}');
    });
  });
}
