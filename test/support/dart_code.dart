/// Helpers for the guards in `test/architecture/` that read Dart source.
library;

final _interpolatedName = RegExp('[A-Za-z_][A-Za-z0-9_]*');

/// [source] with every comment and the text of every string literal replaced by spaces, and its line breaks kept, so
/// a pattern matched against it never matches inside a comment or a string. The code of an interpolation stays, so
/// `'$password'` and `'${dto.password}'` still read as code.
String codeOnly(String source) {
  final code = StringBuffer();
  var i = 0;
  while (i < source.length) {
    if (source.startsWith('//', i)) {
      final end = source.indexOf('\n', i);
      final next = end == -1 ? source.length : end;
      code.write(' ' * (next - i));
      i = next;
    } else if (source.startsWith('/*', i)) {
      final end = source.indexOf('*/', i + 2);
      final next = end == -1 ? source.length : end + 2;
      code.write(source.substring(i, next).replaceAll(RegExp('[^\n]'), ' '));
      i = next;
    } else if (source[i] == "'" || source[i] == '"') {
      i = _writeString(source, i, code);
    } else {
      code.write(source[i]);
      i++;
    }
  }
  return code.toString();
}

/// The index of the bracket in [code], an output of [codeOnly], that closes the one before [start].
int closingBracket(String code, int start) => _closing(code, start, strings: false);

/// [code], an output of [codeOnly], without its calls to the function [name], arguments included.
String withoutCalls(String code, String name) {
  final call = RegExp('\\b$name\\s*\\(').firstMatch(code);
  if (call == null) return code;
  final end = closingBracket(code, call.end);
  return code.substring(0, call.start) + withoutCalls(end < code.length ? code.substring(end + 1) : '', name);
}

/// Writes into [code] what [codeOnly] keeps of the string literal that starts at [start], and returns the index after
/// the literal.
int _writeString(String source, int start, StringBuffer code) {
  final raw = start > 0 && source[start - 1] == 'r';
  final quote = source.startsWith(source[start] * 3, start) ? source[start] * 3 : source[start];
  code.write(' ' * quote.length);
  var i = start + quote.length;
  while (i < source.length && !source.startsWith(quote, i)) {
    if (!raw && source[i] == r'\') {
      code.write(' ' * (i + 2 > source.length ? 1 : 2));
      i += 2;
    } else if (!raw && source.startsWith(r'${', i)) {
      final end = _closing(source, i + 2, strings: true);
      code.write('  ${codeOnly(source.substring(i + 2, end))} ');
      i = end + 1;
    } else if (!raw && source[i] == r'$') {
      final name = _interpolatedName.matchAsPrefix(source, i + 1);
      code.write(' ${name?[0] ?? ''}');
      i = name?.end ?? i + 1;
    } else {
      code.write(source[i] == '\n' ? '\n' : ' ');
      i++;
    }
  }
  final end = i + quote.length > source.length ? source.length : i + quote.length;
  code.write(' ' * (end - i));
  return end;
}

/// The index of the bracket that closes the one before [start]. With [strings], [text] is source whose string
/// literals are skipped; otherwise it is an output of [codeOnly], which has none.
int _closing(String text, int start, {required bool strings}) {
  var depth = 0;
  var i = start;
  while (i < text.length) {
    if (strings && (text[i] == "'" || text[i] == '"')) {
      i = _writeString(text, i, StringBuffer());
      continue;
    }
    if ('([{'.contains(text[i])) depth++;
    if (')]}'.contains(text[i]) && depth-- == 0) return i;
    i++;
  }
  return text.length;
}
