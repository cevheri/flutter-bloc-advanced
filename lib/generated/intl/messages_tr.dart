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

  static String m0(count) => "${Intl.plural(count, other: 'Önbellekte ${count} öğe')}";

  static String m1(count) => "${Intl.plural(count, other: '${count} uç nokta')}";

  static String m2(count) => "Hata: ${count}";

  static String m3(enabled, total) => "${enabled}/${total} etkin";

  static String m4(count) => "${count} açık";

  static String m5(url) => "${url} açılamadı";

  static String m6(currentVersion, minimumVersion) => "Mevcut: ${currentVersion}  •  Gerekli: ${minimumVersion}";

  static String m7(email) => "OTP kodu ${email} adresine gönderildi";

  static String m8(max) => "Şifre en fazla ${max} karakter uzunluğunda olmalıdır";

  static String m9(min) => "Şifre en az ${min} karakter uzunluğunda olmalıdır";

  static String m10(translate) =>
      "${Intl.select(translate, {'account': 'Hesabım', 'userManagement': 'Kullanıcı Yönetimi', 'settings': 'Ayarlar', 'logout': 'Çıkış', 'info': 'Bilgiler', 'language': 'Diller', 'theme': 'Tema', 'new_user': 'Yeni Kullanıcı Ekle', 'list_user': 'Kullanıcılar', 'other': 'Diğer'})}";

  static String m11(error) => "Kaydedilemedi: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "account": MessageLookupByLibrary.simpleMessage("Hesabım"),
    "active": MessageLookupByLibrary.simpleMessage("Aktif"),
    "admin": MessageLookupByLibrary.simpleMessage("Admin"),
    "authorities": MessageLookupByLibrary.simpleMessage("Roller"),
    "authorities_load_failed": MessageLookupByLibrary.simpleMessage("Roller alınamadı"),
    "back": MessageLookupByLibrary.simpleMessage("Geri"),
    "cancel": MessageLookupByLibrary.simpleMessage("İptal"),
    "change_password": MessageLookupByLibrary.simpleMessage("Şifre Değiştir"),
    "change_password_description": MessageLookupByLibrary.simpleMessage(
      "Hesabınızın güvende kalması için uzun ve rastgele bir şifre kullandığınızdan emin olun.",
    ),
    "command_palette_account_description": MessageLookupByLibrary.simpleMessage("Profiliniz"),
    "command_palette_change_password_description": MessageLookupByLibrary.simpleMessage("Şifrenizi güncelleyin"),
    "command_palette_hint": MessageLookupByLibrary.simpleMessage("Bir komut yazın veya arayın..."),
    "command_palette_home_description": MessageLookupByLibrary.simpleMessage("Ana sayfaya git"),
    "command_palette_new_user_description": MessageLookupByLibrary.simpleMessage("Yeni bir kullanıcı oluşturun"),
    "command_palette_no_results": MessageLookupByLibrary.simpleMessage("Sonuç bulunamadı"),
    "command_palette_settings_description": MessageLookupByLibrary.simpleMessage("Uygulama tercihleri"),
    "command_palette_users_description": MessageLookupByLibrary.simpleMessage("Kullanıcıları yönetin"),
    "community_contribute": MessageLookupByLibrary.simpleMessage("Katkıda Bulun"),
    "community_discussions": MessageLookupByLibrary.simpleMessage("Tartışmalar"),
    "community_docs": MessageLookupByLibrary.simpleMessage("Dokümantasyon"),
    "community_issue": MessageLookupByLibrary.simpleMessage("Sorun Bildir"),
    "community_open_source": MessageLookupByLibrary.simpleMessage("Açık Kaynak"),
    "community_sponsor": MessageLookupByLibrary.simpleMessage("Sponsor Ol"),
    "community_star": MessageLookupByLibrary.simpleMessage("Yıldız & Fork"),
    "community_subtitle": MessageLookupByLibrary.simpleMessage(
      "Bu proje açık kaynaktır. Katkılarınız onu daha iyi yapar!",
    ),
    "community_title": MessageLookupByLibrary.simpleMessage("Topluluğa Katılın"),
    "community_translate": MessageLookupByLibrary.simpleMessage("Çeviriye Yardım Et"),
    "connectivity_offline": MessageLookupByLibrary.simpleMessage("İnternet bağlantısı yok"),
    "create_user": MessageLookupByLibrary.simpleMessage("Kullanıcı Oluştur"),
    "current_password": MessageLookupByLibrary.simpleMessage("Mevcut Şifre"),
    "dashboard": MessageLookupByLibrary.simpleMessage("Panel"),
    "dashboard_app_configuration": MessageLookupByLibrary.simpleMessage("Uygulama Yapılandırması"),
    "dashboard_cache": MessageLookupByLibrary.simpleMessage("Önbellek"),
    "dashboard_cached_item_count": m0,
    "dashboard_circuit_breaker": MessageLookupByLibrary.simpleMessage("Devre Kesici"),
    "dashboard_circuit_breaker_health": MessageLookupByLibrary.simpleMessage("Devre Kesici Durumu"),
    "dashboard_clear_cache": MessageLookupByLibrary.simpleMessage("Önbelleği Temizle"),
    "dashboard_connectivity": MessageLookupByLibrary.simpleMessage("Bağlantı"),
    "dashboard_current_version": MessageLookupByLibrary.simpleMessage("Mevcut Sürüm"),
    "dashboard_endpoint_count": m1,
    "dashboard_environment": MessageLookupByLibrary.simpleMessage("Ortam"),
    "dashboard_error_title": MessageLookupByLibrary.simpleMessage("Panel Hatası"),
    "dashboard_failure_count": m2,
    "dashboard_feature_flags": MessageLookupByLibrary.simpleMessage("Özellik Bayrakları"),
    "dashboard_feature_flags_enabled": m3,
    "dashboard_interceptor_chain": MessageLookupByLibrary.simpleMessage("Interceptor Zinciri"),
    "dashboard_maintenance_mode": MessageLookupByLibrary.simpleMessage("Bakım Modu"),
    "dashboard_minimum_version": MessageLookupByLibrary.simpleMessage("En Düşük Sürüm"),
    "dashboard_no_endpoints": MessageLookupByLibrary.simpleMessage("Henüz izlenen uç nokta yok"),
    "dashboard_no_feature_flags": MessageLookupByLibrary.simpleMessage("Yapılandırılmış özellik bayrağı yok"),
    "dashboard_off": MessageLookupByLibrary.simpleMessage("KAPALI"),
    "dashboard_offline": MessageLookupByLibrary.simpleMessage("Çevrimdışı"),
    "dashboard_on": MessageLookupByLibrary.simpleMessage("AÇIK"),
    "dashboard_online": MessageLookupByLibrary.simpleMessage("Çevrimiçi"),
    "dashboard_open_count": m4,
    "dashboard_open_dynamic_forms": MessageLookupByLibrary.simpleMessage("Dinamik Formları Aç"),
    "dashboard_reset_circuit_breakers": MessageLookupByLibrary.simpleMessage("Devre Kesicileri Sıfırla"),
    "dashboard_title": MessageLookupByLibrary.simpleMessage("Sistem Paneli"),
    "delete_confirmation": MessageLookupByLibrary.simpleMessage("Silmek istediğinize emin misiniz?"),
    "delete_user": MessageLookupByLibrary.simpleMessage("Kullanıcı Sil"),
    "dynamic_forms": MessageLookupByLibrary.simpleMessage("Dinamik Formlar"),
    "edit": MessageLookupByLibrary.simpleMessage("Düzenle"),
    "edit_user": MessageLookupByLibrary.simpleMessage("Kullanıcı Düzenle"),
    "email": MessageLookupByLibrary.simpleMessage("E-posta"),
    "email_pattern": MessageLookupByLibrary.simpleMessage("E-posta adresi geçerli değil"),
    "email_send": MessageLookupByLibrary.simpleMessage("E-posta Gönder"),
    "english": MessageLookupByLibrary.simpleMessage("İngilizce"),
    "error_account_password_required": MessageLookupByLibrary.simpleMessage("Mevcut ve yeni şifre alanları zorunludur"),
    "error_account_passwords_same": MessageLookupByLibrary.simpleMessage("Yeni şifre mevcut şifreden farklı olmalıdır"),
    "error_auth_invalid_access_token": MessageLookupByLibrary.simpleMessage("Geçersiz erişim belirteci"),
    "error_auth_login_failed": MessageLookupByLibrary.simpleMessage("Giriş başarısız"),
    "error_auth_otp_validation": MessageLookupByLibrary.simpleMessage("OTP doğrulaması başarısız"),
    "error_auth_send_otp_failed": MessageLookupByLibrary.simpleMessage("OTP kodu gönderilemedi"),
    "error_auth_session_persist_failed": MessageLookupByLibrary.simpleMessage("Oturum kaydedilemedi"),
    "error_generic": MessageLookupByLibrary.simpleMessage("Bir şeyler ters gitti"),
    "error_link_open_failed": m5,
    "error_network_cert_invalid": MessageLookupByLibrary.simpleMessage(
      "Bağlantının güvenli olduğu doğrulanamadığı için engellendi. Daha sonra ya da başka bir ağda tekrar deneyin.",
    ),
    "error_settings_change_language_failed": MessageLookupByLibrary.simpleMessage("Dil değiştirilemedi"),
    "error_user_cannot_delete_admin": MessageLookupByLibrary.simpleMessage("Yönetici kullanıcı silinemez"),
    "error_user_no_authorities": MessageLookupByLibrary.simpleMessage("Yetki bulunamadı"),
    "failed": MessageLookupByLibrary.simpleMessage("Başarısız"),
    "first_name": MessageLookupByLibrary.simpleMessage("İsim"),
    "forbidden_back_home": MessageLookupByLibrary.simpleMessage("Ana sayfaya dön"),
    "forbidden_message": MessageLookupByLibrary.simpleMessage("Bu sayfayı görüntüleme yetkiniz yok."),
    "forbidden_title": MessageLookupByLibrary.simpleMessage("Erişim engellendi"),
    "force_update_button": MessageLookupByLibrary.simpleMessage("Şimdi Güncelle"),
    "force_update_message": MessageLookupByLibrary.simpleMessage(
      "Yeni bir sürüm mevcut. Uygulamayı kullanmaya devam etmek için lütfen güncelleyin.",
    ),
    "force_update_no_store_link": MessageLookupByLibrary.simpleMessage(
      "En son sürümü yüklemek için uygulama mağazanızı açın.",
    ),
    "force_update_store_link_invalid": MessageLookupByLibrary.simpleMessage(
      "Güncelleme bağlantısı geçersiz. En son sürümü yüklemek için uygulama mağazanızı açın.",
    ),
    "force_update_title": MessageLookupByLibrary.simpleMessage("Güncelleme Gerekli"),
    "force_update_versions": m6,
    "forgot_password_description": MessageLookupByLibrary.simpleMessage(
      "E-posta adresinizi girin, şifrenizi sıfırlamanız için size bir bağlantı gönderelim.",
    ),
    "guest": MessageLookupByLibrary.simpleMessage("Kullanıcı"),
    "help_resources": MessageLookupByLibrary.simpleMessage("Yardım ve Kaynaklar"),
    "help_resources_subtitle": MessageLookupByLibrary.simpleMessage(
      "Dokümantasyon ve rehberler için web sitemizi ziyaret edin",
    ),
    "home": MessageLookupByLibrary.simpleMessage("Ana Sayfa"),
    "idle_timeout_signed_out": MessageLookupByLibrary.simpleMessage("Hareketsizlik nedeniyle oturumunuz kapatıldı."),
    "inactive": MessageLookupByLibrary.simpleMessage("Pasif"),
    "invalid_email": MessageLookupByLibrary.simpleMessage("Geçersiz e-posta adresi"),
    "language": MessageLookupByLibrary.simpleMessage("Dil"),
    "language_select": MessageLookupByLibrary.simpleMessage("Dil Seçimi"),
    "last_name": MessageLookupByLibrary.simpleMessage("Soyisim"),
    "list": MessageLookupByLibrary.simpleMessage("Listele"),
    "list_user": MessageLookupByLibrary.simpleMessage("Kullanıcılar"),
    "loading": MessageLookupByLibrary.simpleMessage("Yükleniyor..."),
    "login": MessageLookupByLibrary.simpleMessage("Kullanıcı Adı"),
    "login_brand_description": MessageLookupByLibrary.simpleMessage(
      "Kimlik doğrulama, rol tabanlı erişim, kullanıcı yönetimi,\ntema ve çoklu ortam desteği tek bir sağlam başlangıç projesinde.",
    ),
    "login_brand_headline": MessageLookupByLibrary.simpleMessage("Prototipten\nüretime ölçeklenin."),
    "login_brand_stat_bloc_ready": MessageLookupByLibrary.simpleMessage("BLoC Hazır"),
    "login_brand_stat_layers": MessageLookupByLibrary.simpleMessage("Temel Katman"),
    "login_brand_stat_platforms": MessageLookupByLibrary.simpleMessage("Platform"),
    "login_button": MessageLookupByLibrary.simpleMessage("Giriş Yap"),
    "login_feature_architecture_description": MessageLookupByLibrary.simpleMessage(
      "Sorumlulukları net biçimde ayıran BLoC + Repository deseni.",
    ),
    "login_feature_architecture_title": MessageLookupByLibrary.simpleMessage("Temiz Mimari"),
    "login_feature_auth_description": MessageLookupByLibrary.simpleMessage(
      "Rol tabanlı yönlendirme korumalarıyla şifre ve OTP ile giriş akışları.",
    ),
    "login_feature_auth_title": MessageLookupByLibrary.simpleMessage("Kimlik Doğrulama ve Erişim Kontrolü"),
    "login_feature_mock_api_description": MessageLookupByLibrary.simpleMessage(
      "Yerelde sahte verilerle geliştirin, ardından üretim uç noktalarına geçin.",
    ),
    "login_feature_mock_api_title": MessageLookupByLibrary.simpleMessage("Sahte Veriden Gerçek API\'ye"),
    "login_no_account": MessageLookupByLibrary.simpleMessage("Hesabınız yok mu? "),
    "login_or": MessageLookupByLibrary.simpleMessage("veya"),
    "login_otp_email_instructions": MessageLookupByLibrary.simpleMessage(
      "OTP kodunu almak için e-posta adresinizi girin",
    ),
    "login_password": MessageLookupByLibrary.simpleMessage("Şifre"),
    "login_switch_to_dark_mode": MessageLookupByLibrary.simpleMessage("Koyu temaya geç"),
    "login_switch_to_light_mode": MessageLookupByLibrary.simpleMessage("Açık temaya geç"),
    "login_user_name": MessageLookupByLibrary.simpleMessage("Kullanıcı adı"),
    "login_welcome_subtitle": MessageLookupByLibrary.simpleMessage("Hesabınıza erişmek için bilgilerinizi girin"),
    "login_welcome_title": MessageLookupByLibrary.simpleMessage("Tekrar hoş geldiniz"),
    "login_with_email": MessageLookupByLibrary.simpleMessage("E-posta ile Giriş"),
    "logout": MessageLookupByLibrary.simpleMessage("Çıkış Yap"),
    "logout_stored_data_left": MessageLookupByLibrary.simpleMessage(
      "Oturumunuz kapatıldı, ancak kayıtlı verilerin bir kısmı bu cihazdan silinemedi.",
    ),
    "logout_sure": MessageLookupByLibrary.simpleMessage("Çıkış yapmak istediğinize emin misiniz?"),
    "max_length_100": MessageLookupByLibrary.simpleMessage("Maksimum 100 karakter uzunluğunda olmalıdır"),
    "max_length_20": MessageLookupByLibrary.simpleMessage("Maksimum 20 karakter uzunluğunda olmalıdır"),
    "min_length_2": MessageLookupByLibrary.simpleMessage("Minimum 2 karakter uzunluğunda olmalıdır"),
    "min_length_4": MessageLookupByLibrary.simpleMessage("Minimum 4 karakter uzunluğunda olmalıdır"),
    "name": MessageLookupByLibrary.simpleMessage("İsim"),
    "new_item": MessageLookupByLibrary.simpleMessage("Yeni"),
    "new_password": MessageLookupByLibrary.simpleMessage("Yeni Şifre"),
    "new_user": MessageLookupByLibrary.simpleMessage("Yeni Kullanıcı Ekle"),
    "no": MessageLookupByLibrary.simpleMessage("Hayır"),
    "no_changes_made": MessageLookupByLibrary.simpleMessage("Değişiklik yapılmadı"),
    "no_data": MessageLookupByLibrary.simpleMessage("Veri Yok"),
    "not_found_message": MessageLookupByLibrary.simpleMessage("İstediğiniz sayfa bulunamadı."),
    "not_found_title": MessageLookupByLibrary.simpleMessage("Sayfa Bulunamadı"),
    "only_numbers": MessageLookupByLibrary.simpleMessage("Sadece sayılar kullanılabilir"),
    "otp_code": MessageLookupByLibrary.simpleMessage("OTP Kodu"),
    "otp_length": MessageLookupByLibrary.simpleMessage("OTP 6 haneli olmalıdır"),
    "otp_sent_to_email": m7,
    "password_forgot": MessageLookupByLibrary.simpleMessage("Şifremi unuttum"),
    "password_max_length": m8,
    "password_min_length": m9,
    "quick_actions": MessageLookupByLibrary.simpleMessage("Hızlı İşlemler"),
    "refresh": MessageLookupByLibrary.simpleMessage("Yenile"),
    "register": MessageLookupByLibrary.simpleMessage("Kayıt Ol"),
    "register_subtitle": MessageLookupByLibrary.simpleMessage("Hesabınızı oluşturun"),
    "required_field": MessageLookupByLibrary.simpleMessage("Zorunlu Alan"),
    "required_range": MessageLookupByLibrary.simpleMessage("Aralık gereklidir"),
    "resend_otp_code": MessageLookupByLibrary.simpleMessage("OTP Kodu Tekrar Gönder"),
    "retry": MessageLookupByLibrary.simpleMessage("Tekrar Dene"),
    "role": MessageLookupByLibrary.simpleMessage("Rol"),
    "save": MessageLookupByLibrary.simpleMessage("Kaydet"),
    "send_otp_code": MessageLookupByLibrary.simpleMessage("OTP Kodu Gönder"),
    "settings": MessageLookupByLibrary.simpleMessage("Ayarlar"),
    "settings_account_subtitle": MessageLookupByLibrary.simpleMessage(
      "Profil bilgilerinizi görüntüleyin veya düzenleyin",
    ),
    "settings_appearance": MessageLookupByLibrary.simpleMessage("Görünüm"),
    "settings_change_password_subtitle": MessageLookupByLibrary.simpleMessage("Şifrenizi güvenle güncelleyin"),
    "settings_subtitle": MessageLookupByLibrary.simpleMessage("Hesap tercihlerinizi yönetin"),
    "settings_theme_subtitle": MessageLookupByLibrary.simpleMessage("Tercih ettiğiniz tema stilini seçin"),
    "sidebar_collapse": MessageLookupByLibrary.simpleMessage("Daralt"),
    "sidebar_expand": MessageLookupByLibrary.simpleMessage("Genişlet"),
    "success": MessageLookupByLibrary.simpleMessage("Başarılı"),
    "theme": MessageLookupByLibrary.simpleMessage("Tema"),
    "theme_mode_dark": MessageLookupByLibrary.simpleMessage("Koyu"),
    "theme_mode_light": MessageLookupByLibrary.simpleMessage("Açık"),
    "translate_menu_title": m10,
    "turkish": MessageLookupByLibrary.simpleMessage("Türkçe"),
    "unsaved_changes": MessageLookupByLibrary.simpleMessage(
      "Kaydedilmemiş değişiklikleriniz var. Çıkmak istediğinize emin misiniz?",
    ),
    "user_delete_failed": MessageLookupByLibrary.simpleMessage("Kullanıcı silinemedi"),
    "user_editor_access": MessageLookupByLibrary.simpleMessage("Erişim"),
    "user_editor_access_description": MessageLookupByLibrary.simpleMessage("Hesap durumu ve rol yetkileri."),
    "user_editor_contact": MessageLookupByLibrary.simpleMessage("İletişim"),
    "user_editor_contact_description": MessageLookupByLibrary.simpleMessage("Birincil iletişim bilgileri."),
    "user_editor_create_subtitle": MessageLookupByLibrary.simpleMessage(
      "Yeni bir kullanıcı oluşturmak için bilgileri doldurun.",
    ),
    "user_editor_edit_subtitle": MessageLookupByLibrary.simpleMessage("Kullanıcı bilgilerini aşağıda güncelleyin."),
    "user_editor_identity": MessageLookupByLibrary.simpleMessage("Kimlik"),
    "user_editor_identity_description": MessageLookupByLibrary.simpleMessage("Temel hesap kimlik bilgileri."),
    "user_editor_info_description": MessageLookupByLibrary.simpleMessage(
      "Kimlik, iletişim ve erişim ayarlarını yönetin.",
    ),
    "user_editor_info_title": MessageLookupByLibrary.simpleMessage("Kullanıcı Bilgileri"),
    "user_editor_view_subtitle": MessageLookupByLibrary.simpleMessage("Kullanıcı ayrıntılarını görüntüleyin."),
    "user_extended_info_button": MessageLookupByLibrary.simpleMessage("Detaylar"),
    "user_extended_info_save_failed": m11,
    "user_extended_info_saved": MessageLookupByLibrary.simpleMessage("Kaydedildi"),
    "user_extended_info_title": MessageLookupByLibrary.simpleMessage("Genişletilmiş Bilgi"),
    "user_list_actions": MessageLookupByLibrary.simpleMessage("İşlemler"),
    "user_list_load_failed": MessageLookupByLibrary.simpleMessage("Kullanıcılar yüklenemedi"),
    "user_list_role_filter": MessageLookupByLibrary.simpleMessage("Rol filtresi"),
    "user_list_search_hint": MessageLookupByLibrary.simpleMessage("Kullanıcıları filtrele..."),
    "user_list_subtitle": MessageLookupByLibrary.simpleMessage(
      "Kullanıcılara tablo görünümünde göz atın ve onları yönetin.",
    ),
    "user_load_failed": MessageLookupByLibrary.simpleMessage("Kullanıcı yüklenemedi"),
    "users": MessageLookupByLibrary.simpleMessage("Kullanıcılar"),
    "verify_otp_code": MessageLookupByLibrary.simpleMessage("OTP Kodu Doğrula"),
    "view_user": MessageLookupByLibrary.simpleMessage("Kullanıcı Görüntüle"),
    "warning": MessageLookupByLibrary.simpleMessage("Uyarı"),
    "website": MessageLookupByLibrary.simpleMessage("Web Sitesi"),
    "yes": MessageLookupByLibrary.simpleMessage("Evet"),
  };
}
