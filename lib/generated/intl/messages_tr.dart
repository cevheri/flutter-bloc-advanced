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
            'new_user': 'Yeni Kullanıcı Ekle',
            'list_user': 'Kullanıcılar',
            'other': 'Diğer',
          })}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "account": MessageLookupByLibrary.simpleMessage("Hesabım"),
        "active": MessageLookupByLibrary.simpleMessage("Aktif"),
        "admin": MessageLookupByLibrary.simpleMessage("Admin"),
        "authorities": MessageLookupByLibrary.simpleMessage("Roller"),
        "back": MessageLookupByLibrary.simpleMessage("Geri"),
        "change_password":
            MessageLookupByLibrary.simpleMessage("Şifre Değiştir"),
        "create_user":
            MessageLookupByLibrary.simpleMessage("Kullanıcı Oluştur"),
        "current_password":
            MessageLookupByLibrary.simpleMessage("Mevcut Şifre"),
        "delete_confirmation": MessageLookupByLibrary.simpleMessage(
            "Silmek istediğinize emin misiniz?"),
        "delete_user": MessageLookupByLibrary.simpleMessage("Kullanıcı Sil"),
        "edit_user": MessageLookupByLibrary.simpleMessage("Kullanıcı Düzenle"),
        "email": MessageLookupByLibrary.simpleMessage("E-posta"),
        "email_pattern": MessageLookupByLibrary.simpleMessage(
            "E-posta adresi geçerli değil"),
        "email_send": MessageLookupByLibrary.simpleMessage("E-posta Gönder"),
        "english": MessageLookupByLibrary.simpleMessage("İngilizce"),
        "failed": MessageLookupByLibrary.simpleMessage("Başarısız"),
        "filter": MessageLookupByLibrary.simpleMessage("Filtrele"),
        "first_name": MessageLookupByLibrary.simpleMessage("İsim"),
        "guest": MessageLookupByLibrary.simpleMessage("Kullanıcı"),
        "language_select": MessageLookupByLibrary.simpleMessage("Dil Seçimi"),
        "last_name": MessageLookupByLibrary.simpleMessage("Soyisim"),
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
        "max_length_10": MessageLookupByLibrary.simpleMessage(
            "Maksimum 10 karakter uzunluğunda olmalıdır"),
        "max_length_100": MessageLookupByLibrary.simpleMessage(
            "Maksimum 100 karakter uzunluğunda olmalıdır"),
        "max_length_1000": MessageLookupByLibrary.simpleMessage(
            "Maksimum 1000 karakter uzunluğunda olmalıdır"),
        "max_length_20": MessageLookupByLibrary.simpleMessage(
            "Maksimum 20 karakter uzunluğunda olmalıdır"),
        "max_length_250": MessageLookupByLibrary.simpleMessage(
            "Maksimum 250 karakter uzunluğunda olmalıdır"),
        "max_length_4000": MessageLookupByLibrary.simpleMessage(
            "Maksimum 4000 karakter uzunluğunda olmalıdır"),
        "max_length_50": MessageLookupByLibrary.simpleMessage(
            "Maksimum 50 karakter uzunluğunda olmalıdır"),
        "max_length_500": MessageLookupByLibrary.simpleMessage(
            "Maksimum 500 karakter uzunluğunda olmalıdır"),
        "min_length_2": MessageLookupByLibrary.simpleMessage(
            "Minimum 2 karakter uzunluğunda olmalıdır"),
        "min_length_3": MessageLookupByLibrary.simpleMessage(
            "Minimum 3 karakter uzunluğunda olmalıdır"),
        "min_length_4": MessageLookupByLibrary.simpleMessage(
            "Minimum 4 karakter uzunluğunda olmalıdır"),
        "min_length_5": MessageLookupByLibrary.simpleMessage(
            "Minimum 5 karakter uzunluğunda olmalıdır"),
        "name": MessageLookupByLibrary.simpleMessage("İsim"),
        "new_password": MessageLookupByLibrary.simpleMessage("Yeni Şifre"),
        "new_user": MessageLookupByLibrary.simpleMessage("Yeni Kullanıcı Ekle"),
        "no": MessageLookupByLibrary.simpleMessage("Hayır"),
        "no_changes_made":
            MessageLookupByLibrary.simpleMessage("Değişiklik yapılmadı"),
        "no_data": MessageLookupByLibrary.simpleMessage("Veri Yok"),
        "password_forgot":
            MessageLookupByLibrary.simpleMessage("Şifremi unuttum"),
        "password_max_length": MessageLookupByLibrary.simpleMessage(
            "Şifre en fazla 20 karakter uzunluğunda olmalıdır"),
        "password_min_length": MessageLookupByLibrary.simpleMessage(
            "Şifre en az 6 karakter uzunluğunda olmalıdır"),
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
        "unsaved_changes": MessageLookupByLibrary.simpleMessage(
            "Kaydedilmemiş değişiklikleriniz var. Çıkmak istediğinize emin misiniz?"),
        "view_user":
            MessageLookupByLibrary.simpleMessage("Kullanıcı Görüntüle"),
        "warning": MessageLookupByLibrary.simpleMessage("Uyarı"),
        "yes": MessageLookupByLibrary.simpleMessage("Evet")
      };
}
