// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a tr locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'tr';

  static String m0(translate) => "${Intl.select(translate, {
            'account': 'Hesabım',
            'userManagement': 'Kullanıcı Yönetimi',
            'settings': 'Ayarlar',
            'logout': 'Çıkış',
            'info': 'Bilgiler',
            'language': 'Diller',
            'theme': 'Tema',
            'create': 'Oluştur',
            'list': 'Listele/Düzenle ',
            'other': 'Diğer',
          })}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "account": MessageLookupByLibrary.simpleMessage("Hesabım"),
        "active": MessageLookupByLibrary.simpleMessage("Aktif"),
        "admin": MessageLookupByLibrary.simpleMessage("Admin"),
        "authorities": MessageLookupByLibrary.simpleMessage("Roller"),
        "change_password":
            MessageLookupByLibrary.simpleMessage("Şifre Değiştir"),
        "create_user":
            MessageLookupByLibrary.simpleMessage("Kullanıcı Oluştur"),
        "current_password":
            MessageLookupByLibrary.simpleMessage("Mevcut Şifre"),
        "edit_user": MessageLookupByLibrary.simpleMessage("Kullanıcı Düzenle"),
        "email": MessageLookupByLibrary.simpleMessage("E-posta"),
        "email_pattern": MessageLookupByLibrary.simpleMessage(
            "E-posta adresi geçerli değil"),
        "email_required":
            MessageLookupByLibrary.simpleMessage("E-posta gereklidir"),
        "email_send": MessageLookupByLibrary.simpleMessage("E-posta Gönder"),
        "english": MessageLookupByLibrary.simpleMessage("İngilizce"),
        "failed": MessageLookupByLibrary.simpleMessage("Başarısız"),
        "first_name": MessageLookupByLibrary.simpleMessage("İsim"),
        "firstname_max_length": MessageLookupByLibrary.simpleMessage(
            "İsim en fazla 20 karakter uzunluğunda olmalıdır"),
        "firstname_min_length": MessageLookupByLibrary.simpleMessage(
            "İsim en az 5 karakter uzunluğunda olmalıdır"),
        "firstname_required":
            MessageLookupByLibrary.simpleMessage("İsim gereklidir"),
        "guest": MessageLookupByLibrary.simpleMessage("Kullanıcı"),
        "language_select": MessageLookupByLibrary.simpleMessage("Dil Seçimi"),
        "last_name": MessageLookupByLibrary.simpleMessage("Soyisim"),
        "lastname_max_length": MessageLookupByLibrary.simpleMessage(
            "Soyisim en fazla 20 karakter uzunluğunda olmalıdır"),
        "lastname_min_length": MessageLookupByLibrary.simpleMessage(
            "Soyisim en az 5 karakter uzunluğunda olmalıdır"),
        "lastname_required":
            MessageLookupByLibrary.simpleMessage("Soyisim gereklidir"),
        "list": MessageLookupByLibrary.simpleMessage("Listele"),
        "list_user": MessageLookupByLibrary.simpleMessage("Kullanıcılar"),
        "loading": MessageLookupByLibrary.simpleMessage("Loading..."),
        "login": MessageLookupByLibrary.simpleMessage("Kullanıcı Adı"),
        "login_button": MessageLookupByLibrary.simpleMessage("Giriş Yap"),
        "login_password": MessageLookupByLibrary.simpleMessage("Şifre"),
        "login_user_name":
            MessageLookupByLibrary.simpleMessage("Kullanıcı adı"),
        "logout": MessageLookupByLibrary.simpleMessage("Çıkış Yap"),
        "logout_sure": MessageLookupByLibrary.simpleMessage(
            "Çıkış yapmak istediğinize emin misiniz?"),
        "name": MessageLookupByLibrary.simpleMessage("İsim"),
        "new_password": MessageLookupByLibrary.simpleMessage("Yeni Şifre"),
        "no": MessageLookupByLibrary.simpleMessage("Hayır"),
        "password_forgot":
            MessageLookupByLibrary.simpleMessage("Şifremi unuttum"),
        "password_max_length": MessageLookupByLibrary.simpleMessage(
            "Şifre en fazla 20 karakter uzunluğunda olmalıdır"),
        "password_min_length": MessageLookupByLibrary.simpleMessage(
            "Şifre en az 6 karakter uzunluğunda olmalıdır"),
        "password_required":
            MessageLookupByLibrary.simpleMessage("Şifre gereklidir"),
        "phone_number": MessageLookupByLibrary.simpleMessage("Tel No"),
        "register": MessageLookupByLibrary.simpleMessage("Kayıt Ol"),
        "required_field": MessageLookupByLibrary.simpleMessage("Zorunlu Alan"),
        "required_range":
            MessageLookupByLibrary.simpleMessage("Aralık gereklidir"),
        "role": MessageLookupByLibrary.simpleMessage("Rol"),
        "save": MessageLookupByLibrary.simpleMessage("Kaydet"),
        "screen_size_error":
            MessageLookupByLibrary.simpleMessage("Ekran boyutu çok küçük."),
        "settings": MessageLookupByLibrary.simpleMessage("Ayarlar"),
        "success": MessageLookupByLibrary.simpleMessage("Başarılı"),
        "translate_menu_title": m0,
        "turkish": MessageLookupByLibrary.simpleMessage("Türkçe"),
        "username_max_length": MessageLookupByLibrary.simpleMessage(
            "Kullanıcı adı en fazla 20 karakter uzunluğunda olmalıdır"),
        "username_min_length": MessageLookupByLibrary.simpleMessage(
            "Kullanıcı adı en az 5 karakter uzunluğunda olmalıdır"),
        "username_regex_pattern":
            MessageLookupByLibrary.simpleMessage("Kullanıcı adı geçerli değil"),
        "username_required":
            MessageLookupByLibrary.simpleMessage("Kullanıcı adı gereklidir"),
        "yes": MessageLookupByLibrary.simpleMessage("Evet")
      };
}
