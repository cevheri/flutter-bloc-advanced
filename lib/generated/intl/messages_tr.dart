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
            'customer': 'Müşteriler',
            'tasks': 'Tasklar',
            'account': 'Hesabım',
            'settings': 'Ayarlar',
            'dashboard': 'Grafikler',
            'reports': 'Raporlar',
            'logout': 'Çıkış',
            'info': 'Bilgiler',
            'language': 'Diller',
            'theme': 'Tema',
            'createOffer': 'Temsilci Oluştur',
            'editOffer': 'Listele/Düzenle ',
            'other': 'Diğer',
          })}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountScreenTitle": MessageLookupByLibrary.simpleMessage("Hesapım"),
        "drawerLogoutTitle": MessageLookupByLibrary.simpleMessage("Çıkış Yap"),
        "drawerMenuHome": MessageLookupByLibrary.simpleMessage("Ana Sayfa"),
        "drawerSettingsTitle": MessageLookupByLibrary.simpleMessage("Ayarlar"),
        "drawerTasks": MessageLookupByLibrary.simpleMessage("Görevler"),
        "english": MessageLookupByLibrary.simpleMessage("İngilizce"),
        "firstName": MessageLookupByLibrary.simpleMessage("Adı"),
        "homeScreenTitle": MessageLookupByLibrary.simpleMessage("Ana Sayfa"),
        "language_select": MessageLookupByLibrary.simpleMessage("Dil Seçimi"),
        "locale": MessageLookupByLibrary.simpleMessage("tr"),
        "loginScreenTitle":
            MessageLookupByLibrary.simpleMessage("Giriş Sayfası"),
        "pageSettingsTitle": MessageLookupByLibrary.simpleMessage("Settings"),
        "save": MessageLookupByLibrary.simpleMessage("Kaydet"),
        "settingsScreenTitle": MessageLookupByLibrary.simpleMessage("Ayarlar"),
        "taskName": MessageLookupByLibrary.simpleMessage("Adı"),
        "taskPrice": MessageLookupByLibrary.simpleMessage("Fiyat"),
        "taskSaveScreenTitle":
            MessageLookupByLibrary.simpleMessage("Görev Kaydet/Güncelle"),
        "tasksScreenTitle": MessageLookupByLibrary.simpleMessage("Görevler"),
        "title": MessageLookupByLibrary.simpleMessage("Görev Yönetim Sistemi"),
        "translate_menu_title": m0,
        "turkish": MessageLookupByLibrary.simpleMessage("Türkçe")
      };
}
