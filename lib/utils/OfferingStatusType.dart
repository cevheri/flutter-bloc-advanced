/// Enum for the status of an offering (e.g. open(1), closed(1, etc.)
sealed class  OfferingStatusType{
  static int get DRATF => 1;
  static String get DRAFT_DEFAULT_COMMENT=> "Yeni Kayıt";

  static int get CANCELLED => 2;
  static String get CANCELLED_DEFAULT_COMMENT=> "İptal Edildi";

  static int get APPROVAL_IN_PROGRESS => 3;
  static String get APPROVAL_IN_PROGRESS_DEFAULT_COMMENT=> "Onay Bekliyor";

  static int get APPROVAL_REJECTED => 4;
  static String get APPROVAL_REJECTED_DEFAULT_COMMENT=> "Onay Reddedildi";

  static int get APPROVED => 5;
  static String get APPROVED_DEFAULT_COMMENT=> "Onaylandı";

  static int get IN_NEGOTIATION => 6;
  static String get IN_NEGOTIATION_DEFAULT_COMMENT=> "Pazarlık Aşamasında";

  static int get RESCINDED => 7;
  static String get RESCINDED_DEFAULT_COMMENT=> "Geri Çekildi";

  static int get ACCEPTED => 8;
  static String get ACCEPTED_DEFAULT_COMMENT=> "Kabul Edildi";

  static int get TO_BE_ORDERED => 9;
  static String get TO_BE_ORDERED_DEFAULT_COMMENT=> "Sipariş Edilecek";

  static int get ORDERED => 10;
  static String get ORDERED_DEFAULT_COMMENT=> "Sipariş Edildi";

  static int get SHIPPED => 11;
  static String get SHIPPED_DEFAULT_COMMENT=> "Sevk Edildi";

  static int get CALCULATED => 12;
  static String get CALCULATED_DEFAULT_COMMENT=> "Hesaplandı";
}