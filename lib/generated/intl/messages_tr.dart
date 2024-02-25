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
            'station': 'Alt Firmalar',
            'maturityCalculate': 'Vade Hesaplama',
            'stationMaturity': 'Alt Firma Vadeleri',
            'corporation': 'Ana Firmaları',
            'corporationMaturity': 'Ana Firma Vadeleri',
            'refinery': 'Üreticiler',
            'offer': 'Teklifler',
            'customer': 'Müşteriler',
            'salesPerson': 'Satış Temsilcisi',
            'account': 'Hesabım',
            'settings': 'Ayarlar',
            'dashboard': 'Grafikler',
            'reports': 'Raporlar',
            'logout': 'Çıkış',
            'info': 'Bilgiler',
            'language': 'Diller',
            'theme': 'Tema',
            'create': 'Oluştur',
            'list': 'Listele/Düzenle ',
            'other': 'Diğer',
          })}";

  static String m1(translate) => "${Intl.select(translate, {
            'selected': 'Tümü',
            'CALCULATED': 'Hesaplanan Teklif',
            'APPROVAL_IN_PROGRESS': 'Teklif Onay',
            'TO_BE_ORDERED': 'Teklif onaylandı',
            'APPROVAL_REJECTED': 'Teklif reddedildi',
            'IN_NEGOTIATION': 'Güncel teklif müşteriye önerildi',
            'ACCEPTED': 'Güncel teklifi müşteri kabul etti',
            'RESCINDED': 'Güncel teklifi müşteri red etti',
            'SHIPPED': 'Tamamlandı',
            'CANCELLED': 'Teklif geri çekildi ve iptal edildi',
            'DRAFT': 'Kaydet',
            'APPROVED': 'Teklif müşteriye gönderilmeye hazır',
            'ORDERED': 'Sipariş hazırlandı',
            'other': 'Diğer',
          })}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about_us": MessageLookupByLibrary.simpleMessage("Hakkımızda"),
        "about_us_detail": MessageLookupByLibrary.simpleMessage(
            "Firmamız, 2024 yılında kurulmuş olup, endüstriyel dönüşümün öncüsü olarak, müşterilerimize rekabet avantajı sağlamak için sürekli olarak yenilikçi çözümler sunmaktadır. Deneyimli bir ekip ve güçlü bir Ar-Ge altyapısıyla, endüstriyel IoT, makine öğrenimi ve yapay zeka teknolojilerinin sınırlarını zorluyoruz. Müşterilerimizin ihtiyaçlarına odaklanarak, ölçeklenebilir, güvenilir ve kullanıcı dostu çözümler sunmayı amaçlıyoruz."),
        "account": MessageLookupByLibrary.simpleMessage("Hesabım"),
        "active": MessageLookupByLibrary.simpleMessage("Aktif"),
        "address": MessageLookupByLibrary.simpleMessage("Address"),
        "admin": MessageLookupByLibrary.simpleMessage("Admin"),
        "approved_status": MessageLookupByLibrary.simpleMessage("Teklif Onay"),
        "authorities": MessageLookupByLibrary.simpleMessage("Yetkiler"),
        "authorities_required":
            MessageLookupByLibrary.simpleMessage("Yetki gereklidir"),
        "birim": MessageLookupByLibrary.simpleMessage("birim"),
        "birim_numeric":
            MessageLookupByLibrary.simpleMessage("birim sayısal olmalıdır"),
        "birim_required":
            MessageLookupByLibrary.simpleMessage("birim gereklidir"),
        "calculate": MessageLookupByLibrary.simpleMessage("Hesapla"),
        "calculated_maturity_screen":
            MessageLookupByLibrary.simpleMessage("Vade Hesaplama"),
        "calculated_status": MessageLookupByLibrary.simpleMessage("Hesaplanan"),
        "cancel": MessageLookupByLibrary.simpleMessage("İptal"),
        "cancelled_status":
            MessageLookupByLibrary.simpleMessage("İptal Edildi"),
        "cari_kod": MessageLookupByLibrary.simpleMessage("Müşteri Kodu"),
        "change": MessageLookupByLibrary.simpleMessage("Change Password"),
        "change_nothing":
            MessageLookupByLibrary.simpleMessage("Değişiklik bulunamadı"),
        "change_password":
            MessageLookupByLibrary.simpleMessage("Şifre Değiştir"),
        "cities": MessageLookupByLibrary.simpleMessage("Şehirler"),
        "city": MessageLookupByLibrary.simpleMessage("Şehir"),
        "city_required":
            MessageLookupByLibrary.simpleMessage("Şehir gereklidir"),
        "code": MessageLookupByLibrary.simpleMessage("Code"),
        "company_name": MessageLookupByLibrary.simpleMessage("Firma ismi"),
        "completed_status": MessageLookupByLibrary.simpleMessage("Tamamlandı"),
        "confirm": MessageLookupByLibrary.simpleMessage("Onaylandı"),
        "confirm_new":
            MessageLookupByLibrary.simpleMessage("Şifre değiştirildi"),
        "confirmation_status":
            MessageLookupByLibrary.simpleMessage("Teklif Onaylandı"),
        "corporation": MessageLookupByLibrary.simpleMessage("Dağıtım Firması"),
        "corporation_required":
            MessageLookupByLibrary.simpleMessage("Dağıtım Firması gereklidir"),
        "corporations": MessageLookupByLibrary.simpleMessage("Ana Firmaları"),
        "cost": MessageLookupByLibrary.simpleMessage("Maliyet"),
        "create": MessageLookupByLibrary.simpleMessage("Oluştur"),
        "createNewOffer":
            MessageLookupByLibrary.simpleMessage("Yeni Teklif Oluştur"),
        "create_corporation":
            MessageLookupByLibrary.simpleMessage("Dağıtım Firması Oluştur"),
        "create_corporation_maturity":
            MessageLookupByLibrary.simpleMessage("Ana Firma Vade Oluştur"),
        "create_offer": MessageLookupByLibrary.simpleMessage("Teklif Oluştur"),
        "create_record_error": MessageLookupByLibrary.simpleMessage(
            "Kayıt Oluşturulamadı. Bilgileri kontrol ediniz.!"),
        "create_refinery":
            MessageLookupByLibrary.simpleMessage("Üretici Oluştur"),
        "create_station":
            MessageLookupByLibrary.simpleMessage("Alt Firma Oluştur"),
        "create_station_maturity":
            MessageLookupByLibrary.simpleMessage("Alt Firma Vade Oluştur"),
        "create_user":
            MessageLookupByLibrary.simpleMessage("Kullanıcı Oluştur"),
        "credit": MessageLookupByLibrary.simpleMessage("Kredi"),
        "credit_card": MessageLookupByLibrary.simpleMessage("Kredi Kartı"),
        "currentPassword":
            MessageLookupByLibrary.simpleMessage("Current Password"),
        "customer": MessageLookupByLibrary.simpleMessage("Müşteri"),
        "customers": MessageLookupByLibrary.simpleMessage("Müşteriler"),
        "daily": MessageLookupByLibrary.simpleMessage("Günlük"),
        "darkLight": MessageLookupByLibrary.simpleMessage("Dark/Light Mode"),
        "dashboard": MessageLookupByLibrary.simpleMessage("Dashboard"),
        "date": MessageLookupByLibrary.simpleMessage("Tarih"),
        "day": MessageLookupByLibrary.simpleMessage("Gün"),
        "debt": MessageLookupByLibrary.simpleMessage("Borç"),
        "delete": MessageLookupByLibrary.simpleMessage("Sil"),
        "delete_confirmation": MessageLookupByLibrary.simpleMessage(
            "Silmek istediğinize emin misiniz?"),
        "description": MessageLookupByLibrary.simpleMessage("CRM"),
        "description_max_length": MessageLookupByLibrary.simpleMessage(
            "Açıklama en fazla 20 karakter uzunluğunda olmalıdır"),
        "description_min_length": MessageLookupByLibrary.simpleMessage(
            "Açıklama en az 5 karakter uzunluğunda olmalıdır"),
        "description_offer": MessageLookupByLibrary.simpleMessage("Açıklama"),
        "description_regex_pattern":
            MessageLookupByLibrary.simpleMessage("Açıklama geçerli değil"),
        "description_required":
            MessageLookupByLibrary.simpleMessage("Açıklama gereklidir"),
        "destination_address":
            MessageLookupByLibrary.simpleMessage("Varış Yeri"),
        "destination_city":
            MessageLookupByLibrary.simpleMessage("Varış Yeri İl"),
        "destination_city_required":
            MessageLookupByLibrary.simpleMessage("Varış Şehri gereklidir"),
        "destination_district":
            MessageLookupByLibrary.simpleMessage("Varış Yeri İlçe"),
        "detail": MessageLookupByLibrary.simpleMessage("Detay"),
        "district": MessageLookupByLibrary.simpleMessage("İlçe"),
        "districts": MessageLookupByLibrary.simpleMessage("İlçeler"),
        "document": MessageLookupByLibrary.simpleMessage("Döküman"),
        "edit": MessageLookupByLibrary.simpleMessage("Düzenle"),
        "edit_corporation":
            MessageLookupByLibrary.simpleMessage("Dağıtım Firması Düzenle"),
        "edit_corporation_maturity": MessageLookupByLibrary.simpleMessage(
            "Dağıtım Şirketi Vade Düzenle"),
        "edit_offer": MessageLookupByLibrary.simpleMessage("Teklif Düzenle"),
        "edit_refinery":
            MessageLookupByLibrary.simpleMessage("Üretici Düzenle"),
        "edit_station":
            MessageLookupByLibrary.simpleMessage("Alt Firma Düzenle"),
        "edit_station_maturity":
            MessageLookupByLibrary.simpleMessage("Alt Firma Vade Düzenle"),
        "edit_user": MessageLookupByLibrary.simpleMessage("Kullanıcı Düzenle"),
        "email": MessageLookupByLibrary.simpleMessage("E-posta"),
        "email_error":
            MessageLookupByLibrary.simpleMessage("E-posta gönderilemedi"),
        "email_pattern": MessageLookupByLibrary.simpleMessage(
            "E-posta adresi geçerli değil"),
        "email_required":
            MessageLookupByLibrary.simpleMessage("E-posta gereklidir"),
        "email_reset_password_error": MessageLookupByLibrary.simpleMessage(
            "Şifre sıfırlama e-postası gönderilemedi"),
        "email_reset_password_sending": MessageLookupByLibrary.simpleMessage(
            "Şifre sıfırlama e-postası gönderiliyor..."),
        "email_reset_password_success": MessageLookupByLibrary.simpleMessage(
            "Şifre sıfırlama e-postası başarıyla gönderildi"),
        "email_send": MessageLookupByLibrary.simpleMessage("E-posta Gönder"),
        "email_success": MessageLookupByLibrary.simpleMessage(
            "E-posta başarıyla gönderildi"),
        "empty": MessageLookupByLibrary.simpleMessage(
            "Password cannot be left blank"),
        "english": MessageLookupByLibrary.simpleMessage("İngilizce"),
        "error":
            MessageLookupByLibrary.simpleMessage("Email address not found"),
        "exit": MessageLookupByLibrary.simpleMessage("Çıkış"),
        "faq": MessageLookupByLibrary.simpleMessage("SSS"),
        "find": MessageLookupByLibrary.simpleMessage(" Ara "),
        "first_name": MessageLookupByLibrary.simpleMessage("İsim"),
        "firstname_max_length": MessageLookupByLibrary.simpleMessage(
            "İsim en fazla 20 karakter uzunluğunda olmalıdır"),
        "firstname_min_length": MessageLookupByLibrary.simpleMessage(
            "İsim en az 5 karakter uzunluğunda olmalıdır"),
        "firstname_required":
            MessageLookupByLibrary.simpleMessage("İsim gereklidir"),
        "forgot": MessageLookupByLibrary.simpleMessage("Forgot Password"),
        "global": MessageLookupByLibrary.simpleMessage("CRM"),
        "home": MessageLookupByLibrary.simpleMessage("Ana Sayfa"),
        "home_page": MessageLookupByLibrary.simpleMessage("Anasayfa"),
        "http_400": MessageLookupByLibrary.simpleMessage("Bad Request"),
        "http_401": MessageLookupByLibrary.simpleMessage("Unauthorized"),
        "http_402": MessageLookupByLibrary.simpleMessage("Payment Required"),
        "http_403": MessageLookupByLibrary.simpleMessage("Forbidden"),
        "http_404": MessageLookupByLibrary.simpleMessage("Not Found"),
        "http_405": MessageLookupByLibrary.simpleMessage("Method Not Allowed"),
        "http_406": MessageLookupByLibrary.simpleMessage("Not Acceptable"),
        "http_407": MessageLookupByLibrary.simpleMessage(
            "Proxy Authentication Required"),
        "http_408": MessageLookupByLibrary.simpleMessage("Request Timeout"),
        "http_409": MessageLookupByLibrary.simpleMessage("Conflict"),
        "http_410": MessageLookupByLibrary.simpleMessage("Gone"),
        "http_411": MessageLookupByLibrary.simpleMessage("Length Required"),
        "http_412": MessageLookupByLibrary.simpleMessage("Precondition Failed"),
        "http_413": MessageLookupByLibrary.simpleMessage("Payload Too Large"),
        "http_414": MessageLookupByLibrary.simpleMessage("URI Too Long"),
        "http_415":
            MessageLookupByLibrary.simpleMessage("Unsupported Media Type"),
        "http_416":
            MessageLookupByLibrary.simpleMessage("Range Not Satisfiable"),
        "http_417": MessageLookupByLibrary.simpleMessage("Expectation Failed"),
        "http_422":
            MessageLookupByLibrary.simpleMessage("Unprocessable Entity"),
        "http_425": MessageLookupByLibrary.simpleMessage("Too Early"),
        "http_426": MessageLookupByLibrary.simpleMessage("Upgrade Required"),
        "http_428":
            MessageLookupByLibrary.simpleMessage("Precondition Required"),
        "http_429": MessageLookupByLibrary.simpleMessage("Too Many Requests"),
        "http_431": MessageLookupByLibrary.simpleMessage(
            "Request Header Fields Too Large"),
        "http_451": MessageLookupByLibrary.simpleMessage(
            "Unavailable For Legal Reasons"),
        "http_500":
            MessageLookupByLibrary.simpleMessage("Internal Server Error"),
        "id": MessageLookupByLibrary.simpleMessage("ID"),
        "increase": MessageLookupByLibrary.simpleMessage("Revize"),
        "increase_unit_price":
            MessageLookupByLibrary.simpleMessage("Revize Fiyat"),
        "indicator": MessageLookupByLibrary.simpleMessage("Loading..."),
        "language_select": MessageLookupByLibrary.simpleMessage("Dil Seçimi"),
        "last_name": MessageLookupByLibrary.simpleMessage("Soyisim"),
        "lastname_max_length": MessageLookupByLibrary.simpleMessage(
            "Soyisim en fazla 20 karakter uzunluğunda olmalıdır"),
        "lastname_min_length": MessageLookupByLibrary.simpleMessage(
            "Soyisim en az 5 karakter uzunluğunda olmalıdır"),
        "lastname_required":
            MessageLookupByLibrary.simpleMessage("Soyisim gereklidir"),
        "list": MessageLookupByLibrary.simpleMessage("Listele"),
        "listOffer": MessageLookupByLibrary.simpleMessage("Teklifler"),
        "list_corporation":
            MessageLookupByLibrary.simpleMessage("Ana Firmaları"),
        "list_offer": MessageLookupByLibrary.simpleMessage("Teklifler"),
        "list_refinery": MessageLookupByLibrary.simpleMessage("Üreticiler"),
        "list_station": MessageLookupByLibrary.simpleMessage("Alt Firmalar"),
        "list_user": MessageLookupByLibrary.simpleMessage("Kullanıcılar"),
        "loading": MessageLookupByLibrary.simpleMessage("Yükleniyor..."),
        "logging_in":
            MessageLookupByLibrary.simpleMessage("Giriş yapılıyor..."),
        "login": MessageLookupByLibrary.simpleMessage("Kullanıcı Adı"),
        "login_button": MessageLookupByLibrary.simpleMessage("Giriş Yap"),
        "login_error":
            MessageLookupByLibrary.simpleMessage("Giriş yapılamadı."),
        "login_password": MessageLookupByLibrary.simpleMessage("Şifre"),
        "login_user_name":
            MessageLookupByLibrary.simpleMessage("Kullanıcı adı"),
        "logout": MessageLookupByLibrary.simpleMessage("Çıkış Yap"),
        "logout_sure": MessageLookupByLibrary.simpleMessage(
            "Çıkış yapmak istediğinize emin misiniz?"),
        "maturity": MessageLookupByLibrary.simpleMessage("Vade"),
        "maturity_type": MessageLookupByLibrary.simpleMessage("Vade Tipi"),
        "maturity_types": MessageLookupByLibrary.simpleMessage("Vade Tipleri"),
        "menu": MessageLookupByLibrary.simpleMessage("Menu"),
        "messages": MessageLookupByLibrary.simpleMessage(
            "Kayıt Oluşturulamadı. Bilgileri kontrol ediniz.!"),
        "monthly": MessageLookupByLibrary.simpleMessage("Aylık"),
        "name": MessageLookupByLibrary.simpleMessage("İsim"),
        "name_max_length": MessageLookupByLibrary.simpleMessage(
            "İsim en fazla 20 karakter uzunluğunda olmalıdır"),
        "name_min_length": MessageLookupByLibrary.simpleMessage(
            "İsim en az 5 karakter uzunluğunda olmalıdır"),
        "name_regex_pattern":
            MessageLookupByLibrary.simpleMessage("İsim geçerli değil"),
        "name_required":
            MessageLookupByLibrary.simpleMessage("İsim gereklidir"),
        "new_increase":
            MessageLookupByLibrary.simpleMessage("Yeni Bindirim Oranı"),
        "no": MessageLookupByLibrary.simpleMessage("Hayır"),
        "not_match":
            MessageLookupByLibrary.simpleMessage("Passwords do not match"),
        "offer_form": MessageLookupByLibrary.simpleMessage("Teklif Formu"),
        "offers": MessageLookupByLibrary.simpleMessage("Teklifler"),
        "ok": MessageLookupByLibrary.simpleMessage("Tamam"),
        "our_references":
            MessageLookupByLibrary.simpleMessage("Referanslarımız"),
        "our_references_detail": MessageLookupByLibrary.simpleMessage(
            "Firmamız, çeşitli endüstrilerden birçok müşteriye hizmet sunmaktadır. Geçmiş projelerimiz ve müşteri memnuniyeti hakkında daha fazla bilgi edinmek için bizimle iletişime geçebilirsiniz. Size, işbirliği yaptığımız firmaların referanslarıyla ilgili detaylı bilgileri sağlamaktan memnuniyet duyarız.\nİletişim için lütfen sekoyatech@gmail.com üzerinden bize ulaşın veya +905077438321 numaralı telefonu arayın. Uzman ekibimiz, sizinle en kısa sürede iletişime geçecektir."),
        "password": MessageLookupByLibrary.simpleMessage("Password"),
        "password_forgot":
            MessageLookupByLibrary.simpleMessage("Şifremi unuttum"),
        "password_max_length": MessageLookupByLibrary.simpleMessage(
            "Şifre en fazla 20 karakter uzunluğunda olmalıdır"),
        "password_min_length": MessageLookupByLibrary.simpleMessage(
            "Şifre en az 6 karakter uzunluğunda olmalıdır"),
        "password_new": MessageLookupByLibrary.simpleMessage("New Password"),
        "password_required":
            MessageLookupByLibrary.simpleMessage("Şifre gereklidir"),
        "password_success": MessageLookupByLibrary.simpleMessage(
            "Password changed successfully"),
        "phone": MessageLookupByLibrary.simpleMessage("Phone"),
        "phone_number": MessageLookupByLibrary.simpleMessage("Tel No"),
        "plasiyer": MessageLookupByLibrary.simpleMessage("Plasiyer"),
        "price": MessageLookupByLibrary.simpleMessage("Fiyat"),
        "price_empty": MessageLookupByLibrary.simpleMessage("Fiyat boş olamaz"),
        "price_max_length": MessageLookupByLibrary.simpleMessage(
            "Fiyat en fazla 10 karakter uzunluğunda olmalıdır"),
        "price_min_length": MessageLookupByLibrary.simpleMessage(
            "Fiyat en az 1 karakter uzunluğunda olmalıdır"),
        "price_regex_pattern":
            MessageLookupByLibrary.simpleMessage("Fiyat geçerli değil"),
        "price_required":
            MessageLookupByLibrary.simpleMessage("Fiyat gereklidir"),
        "price_with_vat":
            MessageLookupByLibrary.simpleMessage("Vergi dahil Fiyat"),
        "price_with_vat_empty": MessageLookupByLibrary.simpleMessage(
            "Vergi dahil Fiyat boş olamaz"),
        "price_with_vat_max_length": MessageLookupByLibrary.simpleMessage(
            "Vergi dahil Fiyat en fazla 10 karakter uzunluğunda olmalıdır"),
        "price_with_vat_min_length": MessageLookupByLibrary.simpleMessage(
            "Vergi dahil Fiyat en az 1 karakter uzunluğunda olmalıdır"),
        "price_with_vat_regex_pattern": MessageLookupByLibrary.simpleMessage(
            "Vergi dahil Fiyat geçerli değil"),
        "price_with_vat_required": MessageLookupByLibrary.simpleMessage(
            "Vergi dahil Fiyat gereklidir"),
        "products": MessageLookupByLibrary.simpleMessage("Ürünlerimiz"),
        "products_detail": MessageLookupByLibrary.simpleMessage(
            "Firmamız, endüstriyel sektörler için özelleştirilmiş yazılım ve donanım ürünleri sunmaktadır. Bunlar arasında, fabrikaların üretim süreçlerini izlemelerine, verileri analiz etmelerine ve karar almalarına yardımcı olan IoT cihazları ve sensörler bulunmaktadır. Ayrıca, makine öğrenimi algoritmaları ve yapay zeka teknolojileri kullanarak fabrikaların otomasyonunu ve verimliliğini artıran yazılım çözümleri geliştiriyoruz."),
        "range": MessageLookupByLibrary.simpleMessage("Aralık"),
        "rate": MessageLookupByLibrary.simpleMessage("Oran"),
        "refineries": MessageLookupByLibrary.simpleMessage("Üreticiler"),
        "refineries_description":
            MessageLookupByLibrary.simpleMessage("Açıklama"),
        "refinery": MessageLookupByLibrary.simpleMessage("Üretici"),
        "refinery_required":
            MessageLookupByLibrary.simpleMessage("Üretici gereklidir"),
        "rejected_status": MessageLookupByLibrary.simpleMessage("Reddedilen"),
        "reports": MessageLookupByLibrary.simpleMessage("Raporlar"),
        "required_cost":
            MessageLookupByLibrary.simpleMessage("Maliyet gereklidir"),
        "required_maturity":
            MessageLookupByLibrary.simpleMessage("Vade gereklidir"),
        "required_phone_type": MessageLookupByLibrary.simpleMessage(
            "Telefon numarası 5** *** ** ** formatında ve 10 karakter olmalıdır"),
        "required_range":
            MessageLookupByLibrary.simpleMessage("Aralık gereklidir"),
        "required_rate":
            MessageLookupByLibrary.simpleMessage("Oran gereklidir"),
        "required_salesPerson":
            MessageLookupByLibrary.simpleMessage("Plasiyer gereklidir"),
        "reset": MessageLookupByLibrary.simpleMessage(
            "Reset Email Address Password"),
        "role": MessageLookupByLibrary.simpleMessage("Rol"),
        "salesPerson": MessageLookupByLibrary.simpleMessage("Plasiyer"),
        "sales_person_code":
            MessageLookupByLibrary.simpleMessage("Plasiyer Kodu"),
        "save": MessageLookupByLibrary.simpleMessage("Kaydet"),
        "screen_size_error":
            MessageLookupByLibrary.simpleMessage("Ekran boyutu çok küçük."),
        "select": MessageLookupByLibrary.simpleMessage("Seçiniz"),
        "select_customer":
            MessageLookupByLibrary.simpleMessage("Müşteri Seçiniz"),
        "send": MessageLookupByLibrary.simpleMessage("Gönder"),
        "send_offer":
            MessageLookupByLibrary.simpleMessage("Teklifi Onaya Gönder"),
        "services": MessageLookupByLibrary.simpleMessage("Hizmetlerimiz"),
        "services_detail": MessageLookupByLibrary.simpleMessage(
            "Firmamız, 2024 yılında kurulmuş olup, endüstriyel IoT (Nesnelerin İnterneti), Makine Öğrenimi ve Yapay Zeka gibi ileri teknolojileri entegre ederek fabrikalar için özelleştirilmiş sistemler geliştirmektedir. Bu sistemler, müşterilerimizin üretim süreçlerini optimize etmelerine, maliyetleri düşürmelerine ve verimliliği artırmalarına yardımcı olmaktadır. Ayrıca, mobil uygulama ve web tabanlı çözümlerimiz aracılığıyla fabrika operasyonlarını daha da iyileştiriyoruz."),
        "settings": MessageLookupByLibrary.simpleMessage("Ayarlar"),
        "station": MessageLookupByLibrary.simpleMessage("Dolum Tesisi"),
        "station_rate":
            MessageLookupByLibrary.simpleMessage("Alt Firmalar Oran"),
        "station_required":
            MessageLookupByLibrary.simpleMessage("Alt Firma gereklidir"),
        "stations": MessageLookupByLibrary.simpleMessage("Alt Firmalar"),
        "status": MessageLookupByLibrary.simpleMessage("Durum"),
        "success":
            MessageLookupByLibrary.simpleMessage("Password reset successfully"),
        "tax_number": MessageLookupByLibrary.simpleMessage("Vergi Numarası"),
        "tax_office": MessageLookupByLibrary.simpleMessage("Tax Office"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "title": MessageLookupByLibrary.simpleMessage("Sekoya"),
        "todoList": MessageLookupByLibrary.simpleMessage("Yapılacak İşler"),
        "total_price": MessageLookupByLibrary.simpleMessage("Toplam Fiyat"),
        "translate_menu_title": m0,
        "translate_status_title": m1,
        "transport_cost":
            MessageLookupByLibrary.simpleMessage("Taşıma Maliyeti TL"),
        "transport_cost_numeric": MessageLookupByLibrary.simpleMessage(
            "Taşıma Maliyeti sayısal olmalıdır"),
        "transport_cost_required":
            MessageLookupByLibrary.simpleMessage("Taşıma Maliyeti gereklidir"),
        "transport_cost_tl": MessageLookupByLibrary.simpleMessage("Nakliye"),
        "transport_date": MessageLookupByLibrary.simpleMessage("Sevk Tarihi"),
        "transport_date_required":
            MessageLookupByLibrary.simpleMessage("Sevk Tarihi gereklidir"),
        "transport_distance":
            MessageLookupByLibrary.simpleMessage("Taşıma Mesafesi Km"),
        "transport_distance_numeric": MessageLookupByLibrary.simpleMessage(
            "Taşıma Mesafesi sayısal olmalıdır"),
        "transport_distance_required":
            MessageLookupByLibrary.simpleMessage("Taşıma Mesafesi gereklidir"),
        "turkish": MessageLookupByLibrary.simpleMessage("Türkçe"),
        "unit_price": MessageLookupByLibrary.simpleMessage("Birim Fiyat"),
        "unit_price_update":
            MessageLookupByLibrary.simpleMessage("Son Fiyatı Güncelle"),
        "update": MessageLookupByLibrary.simpleMessage("Güncelle"),
        "update_description":
            MessageLookupByLibrary.simpleMessage("Açıklamayı Güncelle"),
        "username_max_length": MessageLookupByLibrary.simpleMessage(
            "Kullanıcı adı en fazla 20 karakter uzunluğunda olmalıdır"),
        "username_min_length": MessageLookupByLibrary.simpleMessage(
            "Kullanıcı adı en az 5 karakter uzunluğunda olmalıdır"),
        "username_regex_pattern":
            MessageLookupByLibrary.simpleMessage("Kullanıcı adı geçerli değil"),
        "username_required":
            MessageLookupByLibrary.simpleMessage("Kullanıcı adı gereklidir"),
        "users": MessageLookupByLibrary.simpleMessage("Kullanıcılar"),
        "vat_no": MessageLookupByLibrary.simpleMessage("Vergi No"),
        "weekly": MessageLookupByLibrary.simpleMessage("Haftalık"),
        "welcome": MessageLookupByLibrary.simpleMessage("Hoş geldiniz"),
        "yes": MessageLookupByLibrary.simpleMessage("Evet")
      };
}
