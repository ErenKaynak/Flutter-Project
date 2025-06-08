// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Paradise PC Bileşenleri';

  @override
  String get welcome => 'Hoş Geldiniz';

  @override
  String get login => 'Giriş Yap';

  @override
  String get signIn => 'Giriş';

  @override
  String get register => 'Kayıt Ol';

  @override
  String get guest => 'Misafir';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get confirmPassword => 'Şifreyi Onayla';

  @override
  String get forgotPassword => 'Şifremi Unuttum?';

  @override
  String get notAMember => 'Üye değil misiniz?';

  @override
  String get alreadyHaveAccount => 'Zaten hesabınız var mı?';

  @override
  String get profile => 'Profil';

  @override
  String get home => 'Ev';

  @override
  String get favorites => 'Favoriler';

  @override
  String get cart => 'Sepet';

  @override
  String get settings => 'Ayarlar';

  @override
  String get language => 'Dil';

  @override
  String get english => 'İngilizce';

  @override
  String get turkish => 'Türkçe';

  @override
  String get arabic => 'Arapça';

  @override
  String get urdu => 'Urdu';

  @override
  String get darkMode => 'Karanlık Mod';

  @override
  String get specialMode => 'Özel Mod';

  @override
  String get passwordlessSignIn => 'Şifresiz Giriş';

  @override
  String get wheelOfDiscount => 'İndirim Çarkı';

  @override
  String get addToCart => 'SEPETE EKLE';

  @override
  String get outOfStock => 'STOKTA YOK';

  @override
  String get removeFromFavorites => 'Favorilerden Kaldır';

  @override
  String get addedToFavorites => 'Favorilere Eklendi';

  @override
  String get removedFromFavorites => 'Favorilerden Kaldırıldı';

  @override
  String get searchProducts => 'Ürün Ara';

  @override
  String get categories => 'Kategoriler';

  @override
  String get allCategories => 'Tüm Kategoriler';

  @override
  String get bestDeals => 'En İyi Fırsatlar';

  @override
  String products(int count) {
    return '$count ürün';
  }

  @override
  String get productQuantity => 'Quantity';

  @override
  String get noProductsFound => 'Ürün bulunamadı';

  @override
  String get tryDifferentSearch => 'Farklı bir arama deneyin';

  @override
  String get tryDifferentCategory => 'Farklı bir kategori seçin';

  @override
  String get viewCart => 'Sepeti Görüntüle';

  @override
  String get off => 'indirim';

  @override
  String addedToCart(String productName) {
    return '$productName sepete eklendi';
  }

  @override
  String get errorAddingToCart => 'Sepete eklenirken hata oluştu';

  @override
  String get pleaseSignIn => 'Lütfen devam etmek için giriş yapın';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get name => 'Ad';

  @override
  String get surname => 'Soyad';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'İPTAL';

  @override
  String get accountSettings => 'Hesap Ayarları';

  @override
  String get myAddresses => 'Adreslerim';

  @override
  String get addNewAddress => 'Yeni Adres Ekle';

  @override
  String get hello => 'Merhaba';

  @override
  String get yourAddresses => 'Adresleriniz';

  @override
  String get noAddressesFound => 'Adres bulunamadı.';

  @override
  String get recipientInfo => 'Alıcı Bilgileri';

  @override
  String get firstName => 'Ad';

  @override
  String get lastName => 'Soyad';

  @override
  String get phoneNumber => 'Telefon Numarası';

  @override
  String get addressType => 'Adres Tipi';

  @override
  String get addressDetails => 'Adres Detayları';

  @override
  String get streetAvenue => 'Sokak / Cadde';

  @override
  String get neighborhood => 'Mahalle';

  @override
  String get buildingNo => 'Bina No';

  @override
  String get apartmentName => 'Apartman Adı';

  @override
  String get floorNo => 'Kat No';

  @override
  String get doorNo => 'Daire No';

  @override
  String get city => 'Şehir';

  @override
  String get addressLabel => 'Adres Etiketi';

  @override
  String get addressLabelHint => 'Örnek: Ev, İş vb.';

  @override
  String get saveAddress => 'Adresi Kaydet';

  @override
  String get savingAddress => 'Adres kaydediliyor...';

  @override
  String get addressSaved => 'Adres başarıyla kaydedildi';

  @override
  String get userNotLoggedIn => 'Kullanıcı giriş yapmamış.';

  @override
  String errorSavingAddress(String error) {
    return 'Adres kaydedilirken hata oluştu: $error';
  }

  @override
  String get fillAllFields => 'Lütfen tüm alanları doldurun';

  @override
  String get pleaseEnterFirstName => 'Lütfen adınızı girin';

  @override
  String get pleaseEnterLastName => 'Lütfen soyadınızı girin';

  @override
  String get pleaseEnterPhoneNumber => 'Lütfen telefon numaranızı girin';

  @override
  String get invalidPhoneNumber => 'Lütfen geçerli bir telefon numarası girin';

  @override
  String get pleaseEnterStreetName => 'Lütfen sokak adını girin';

  @override
  String get pleaseEnterNeighborhood => 'Lütfen mahalle adını girin';

  @override
  String get required => 'Zorunlu';

  @override
  String get pleaseEnterAddressLabel => 'Lütfen adres etiketi girin';

  @override
  String get selectCity => 'Şehir Seçin';

  @override
  String get pleaseSelectCity => 'Lütfen bir şehir seçin';

  @override
  String get work => 'İş';

  @override
  String get delete => 'SİL';

  @override
  String get setAsDefault => 'Varsayılan Yap';

  @override
  String get myOrders => 'Siparişlerim';

  @override
  String get myWallet => 'Cüzdanım';

  @override
  String get appearance => 'Görünüm';

  @override
  String get adminPanel => 'Yönetici Paneli';

  @override
  String get referralCode => 'Referans Kodunuz';

  @override
  String get copiedToClipboard => 'Panoya kopyalandı';

  @override
  String get changeProfilePicture => 'Profil Resmini Değiştir';

  @override
  String get takePhoto => 'Fotoğraf çek';

  @override
  String get chooseFromGallery => 'Galeriden seç';

  @override
  String get addFromUrl => 'URL\'den ekle';

  @override
  String get removePhoto => 'Fotoğrafı Kaldır';

  @override
  String get enterImageUrl => 'Resim URL\'sini girin';

  @override
  String get imageUrl => 'Image URL';

  @override
  String get add => 'Ekle';

  @override
  String get sort => 'Sırala';

  @override
  String get priceLowToHigh => 'Fiyat: Düşükten Yükseğe';

  @override
  String get priceHighToLow => 'Fiyat: Yüksekten Düşüğe';

  @override
  String get nameAToZ => 'İsim: A\'dan Z\'ye';

  @override
  String get nameZToA => 'İsim: Z\'den A\'ya';

  @override
  String get specialOffers => 'Özel Teklifler';

  @override
  String get specialOffersDescription => 'Seçili ürünlerde %20\'ye varan indirimler';

  @override
  String get shopNow => 'Hemen Alışveriş Yap';

  @override
  String get authentication => 'Kimlik Doğrulama';

  @override
  String get createAccount => 'Hesap Oluştur';

  @override
  String get addYourName => 'Adınızı Ekleyin';

  @override
  String get admin => 'YÖNETİCİ';

  @override
  String get guestUser => 'Misafir Kullanıcı';

  @override
  String get signInToAccess => 'Tüm özelliklere erişmek için giriş yapın';

  @override
  String get yourReferralCode => 'Referans Kodunuz';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get noFavoritesYet => 'Henüz favori yok';

  @override
  String get itemsYouFavorite => 'Favoriye eklediğiniz ürünler burada görünecek';

  @override
  String get yourCart => 'Sepetiniz';

  @override
  String get emptyCart => 'Sepetiniz boş';

  @override
  String get addItemsToCheckout => 'Ödeme yapmak için sepetinize ürün ekleyin';

  @override
  String get clearCart => 'Sepeti Temizle';

  @override
  String get clearCartConfirmation => 'Tüm ürünleri kaldırmak istediğinizden emin misiniz?';

  @override
  String get discountCode => 'İndirim Kodu';

  @override
  String get enterCode => 'Kodu girin';

  @override
  String discountApplied(Object code) {
    return 'İndirim Uygulandı: $code';
  }

  @override
  String percentOff(int percent) {
    return '%$percent indirim';
  }

  @override
  String get invalidDiscountCode => 'Geçersiz indirim kodu';

  @override
  String get notApplicableDiscount => 'This code is not applicable to items in your cart';

  @override
  String get subtotal => 'Ara Toplam';

  @override
  String discount(int percent) {
    return 'İndirim (%$percent)';
  }

  @override
  String get total => 'Toplam';

  @override
  String totalAmount(String amount) {
    return 'Toplam: ₺$amount';
  }

  @override
  String get checkout => 'ÖDEME YAP';

  @override
  String get paymentSuccessful => 'Ödeme Başarılı!';

  @override
  String amountPaid(String amount) {
    return 'Ödenen Tutar: ₺$amount';
  }

  @override
  String get orderPlaced => 'Siparişiniz başarıyla verildi';

  @override
  String orderId(String id) {
    return 'Sipariş No: $id';
  }

  @override
  String get viewOrders => 'Siparişleri Görüntüle';

  @override
  String get continueShopping => 'Alışverişe Devam Et';

  @override
  String get cardExpired => 'Kartın süresi dolmuş';

  @override
  String get pleaseSelectAddress => 'Lütfen bir teslimat adresi seçin';

  @override
  String get pleaseSelectCard => 'Lütfen bir kart seçin';

  @override
  String get deliveryAddress => 'Teslimat Adresi';

  @override
  String get addNew => 'Yeni Ekle';

  @override
  String get noSavedAddresses => 'Kayıtlı adres bulunamadı';

  @override
  String get creditCards => 'Kredi Kartları';

  @override
  String get noSavedCards => 'Kayıtlı kart bulunamadı';

  @override
  String get myCards => 'Kartlarım';

  @override
  String get payWithCreditCard => 'Kredi kartı ile öde';

  @override
  String get payWithWallet => 'Cüzdan ile öde';

  @override
  String availableBalance(String amount) {
    return 'Kullanılabilir Bakiye: ₺$amount';
  }

  @override
  String get insufficientBalance => 'Yetersiz bakiye';

  @override
  String addMoreForFreeShipping(String amount) {
    return '₺$amount daha ekleyin, ücretsiz kargo fırsatından yararlanın';
  }

  @override
  String get freeShippingOver => '₺10.000 üzeri ücretsiz kargo';

  @override
  String get free => 'Ücretsiz';

  @override
  String get shipping => 'Kargo';

  @override
  String get placeOrder => 'SİPARİŞİ TAMAMLA';

  @override
  String get address => 'Adres';

  @override
  String get payment => 'Ödeme';

  @override
  String get confirm => 'Onay';

  @override
  String get paymentMethod => 'Ödeme Yöntemi';

  @override
  String get addNewCard => 'Yeni Kart Ekle';

  @override
  String get orderSummary => 'Sipariş Özeti';

  @override
  String get cardNumber => 'Kart Numarası';

  @override
  String get cardNumberHint => 'Kart Numarası';

  @override
  String get cardHolderName => 'Kart Sahibinin Adı';

  @override
  String get cardHolderHint => 'Kart Sahibinin Adı';

  @override
  String get expiryDate => 'Son Kullanma Tarihi';

  @override
  String get expiryDateHint => 'AA/YY';

  @override
  String get cardIsExpired => 'Kartınızın süresi dolmuş';

  @override
  String get cvv => 'CVV';

  @override
  String get cvvHint => '3 haneli kod';

  @override
  String get deleteCard => 'Kartı Sil';

  @override
  String get deleteCardConfirmation => 'Bu kartı silmek istediğinizden emin misiniz?';

  @override
  String get defaultCard => 'Varsayılan Kart';

  @override
  String expires(String date) {
    return 'Son Kullanma Tarihi: $date';
  }

  @override
  String get ok => 'Tamam';

  @override
  String get cannotReorder => 'Sipariş Tekrarlanamıyor';

  @override
  String outOfStockItems(String items) {
    return 'Aşağıdaki ürünler stokta yok:\n\n• $items';
  }

  @override
  String insufficientStockItems(String items) {
    return 'Aşağıdaki ürünlerin stok miktarı yetersiz:\n\n• $items';
  }

  @override
  String get myFavorites => 'Favorilerim';

  @override
  String get refresh => 'Yenile';

  @override
  String get exploreProducts => 'Ürünleri Keşfet';

  @override
  String get failedToRemove => 'Kaldırma başarısız';

  @override
  String get pleaseLoginToAdd => 'Favorilere eklemek için lütfen giriş yapın';

  @override
  String get failedToAddToCart => 'Sepete ekleme başarısız';

  @override
  String get adminDashboard => 'Yönetici Paneli';

  @override
  String get adminControls => 'Yönetici Kontrolleri';

  @override
  String get userManagement => 'Kullanıcı Yönetimi';

  @override
  String get viewAndManageUsers => 'Kullanıcıları Görüntüle ve Yönet';

  @override
  String get productManagement => 'Ürün Yönetimi';

  @override
  String get manageProducts => 'Ürünleri Yönet';

  @override
  String get orderManagement => 'Sipariş Yönetimi';

  @override
  String get viewAndProcessOrders => 'Siparişleri Görüntüle ve İşle';

  @override
  String get currentBalance => 'Mevcut Bakiye';

  @override
  String get cashbackInfo => 'Her alışverişte %2\'ye varan nakit iade kazanın';

  @override
  String get addMoney => 'Para Ekle';

  @override
  String get transactionHistory => 'İşlem Geçmişi';

  @override
  String transactionsCount(int count) {
    return '$count işlem';
  }

  @override
  String get noTransactions => 'Henüz işlem yok';

  @override
  String get transactionsWillAppear => 'İşlemleriniz burada görünecek';

  @override
  String get moneyAdded => 'Para eklendi';

  @override
  String errorAddingBalance(String error) {
    return 'Bakiye ekleme hatası';
  }

  @override
  String get addMoneyToWallet => 'Cüzdana Para Ekle';

  @override
  String get amount => 'Tutar';

  @override
  String get selectCard => 'Kart Seçin';

  @override
  String get useCard => 'Kayıtlı Kartı Kullan';

  @override
  String get enterValidAmount => 'Lütfen geçerli bir tutar girin';

  @override
  String get fillCardDetails => 'Lütfen kart bilgilerini doldurun';

  @override
  String get cardNumberError => 'Kart numarası 16 haneli olmalıdır';

  @override
  String get invalidCardNumber => 'Geçersiz kart numarası';

  @override
  String get onlyLettersAllowed => 'Sadece harf kullanılabilir';

  @override
  String get useMMYYFormat => 'AA/YY formatını kullanın';

  @override
  String get invalidCVV => 'Geçersiz CVV';

  @override
  String get amountMustBeGreater => 'Tutar 0\'dan büyük olmalıdır';

  @override
  String get maximumAmount => 'Maksimum tutar 10.000₺\'dir';

  @override
  String get invalidAmount => 'Geçersiz tutar';

  @override
  String get cardSaved => 'Kart başarıyla kaydedildi';

  @override
  String errorSavingCard(String error) {
    return 'Kart kaydedilirken hata oluştu: $error';
  }

  @override
  String get transactionDetails => 'İşlem Detayları';

  @override
  String get type => 'Tür';

  @override
  String get deposit => 'Para Yükleme';

  @override
  String get purchase => 'Alışveriş';

  @override
  String get date => 'Tarih';

  @override
  String get status => 'Durum';

  @override
  String get method => 'Yöntem';

  @override
  String get reference => 'Referans';

  @override
  String get description => 'Açıklama';

  @override
  String get orderHistory => 'Sipariş Geçmişi';

  @override
  String get yourOrders => 'Siparişleriniz';

  @override
  String ordersCount(int count) {
    return '$count sipariş';
  }

  @override
  String get filterByStatus => 'Duruma Göre Filtrele';

  @override
  String get allOrders => 'Tümü';

  @override
  String get pending => 'Beklemede';

  @override
  String get preparing => 'Hazırlanıyor';

  @override
  String get onDelivery => 'Yolda';

  @override
  String get delivered => 'Teslim Edildi';

  @override
  String get cancelled => 'İptal Edildi';

  @override
  String noOrdersWithStatus(String status) {
    return '$status durumunda sipariş bulunamadı';
  }

  @override
  String get tryDifferentFilter => 'Farklı bir filtre deneyin';

  @override
  String orderNumber(String number) {
    return 'Sipariş Numarası';
  }

  @override
  String get items => 'Ürünler';

  @override
  String quantity(int count, String price) {
    return 'Adet';
  }

  @override
  String itemTotal(String amount) {
    return 'Ürün Toplamı';
  }

  @override
  String get trackingNumber => 'Takip Numarası';

  @override
  String get shippingAddress => 'Teslimat Adresi';

  @override
  String get noAddressProvided => 'Adres belirtilmedi';

  @override
  String get notSpecified => 'Belirtilmedi';

  @override
  String get reorder => 'Tekrar Sipariş Ver';

  @override
  String get cancelOrder => 'Siparişi İptal Et';

  @override
  String get confirmCancelOrder => 'Bu siparişi iptal etmek istediğinizden emin misiniz?';

  @override
  String get orderCancelled => 'Sipariş İptal Edildi';

  @override
  String failedToCancelOrder(String error) {
    return 'Sipariş iptal edilemedi: $error';
  }

  @override
  String get rateProduct => 'Ürünü Değerlendir';

  @override
  String get alreadyReviewed => 'Bu ürünü zaten değerlendirdiniz';

  @override
  String get canReviewAfterDelivery => 'Ürünü teslim aldıktan sonra değerlendirebilirsiniz';

  @override
  String get selectRating => 'Değerlendirme seçin';

  @override
  String get poor => 'Kötü';

  @override
  String get fair => 'Orta';

  @override
  String get good => 'İyi';

  @override
  String get veryGood => 'Çok İyi';

  @override
  String get excellent => 'Mükemmel';

  @override
  String get writeReview => 'Yorum Yaz';

  @override
  String get submitReview => 'Değerlendirmeyi Gönder';

  @override
  String get thankYouForReview => 'Değerlendirmeniz için teşekkür ederiz';

  @override
  String get failedToSubmitReview => 'Değerlendirme gönderilemedi';

  @override
  String get productNoLongerAvailable => 'Bu ürün artık mevcut değil';

  @override
  String get errorCheckingAvailability => 'Stok kontrolü sırasında bir hata oluştu';

  @override
  String get tryAgain => 'Tekrar Dene';

  @override
  String get noOrdersYet => 'Henüz sipariş yok';

  @override
  String get yourOrderHistoryWillAppearHere => 'Sipariş geçmişiniz burada görünecek';

  @override
  String get startShopping => 'Alışverişe Başla';

  @override
  String get somethingWentWrong => 'Bir şeyler yanlış gitti';

  @override
  String get orderPrefix => 'Sipariş #';

  @override
  String get itemsLabel => 'Ürünler';

  @override
  String get quantityPrefix => 'Adet:';

  @override
  String get itemTotalPrefix => 'Toplam:';

  @override
  String get shippingAddressLabel => 'Teslimat Adresi';

  @override
  String get defaultShippingAddress => 'Varsayılan teslimat adresi';

  @override
  String get paymentMethodLabel => 'Ödeme Yöntemi';

  @override
  String get cardPayment => 'Kart ile Ödeme';

  @override
  String get reorderButton => 'Tekrar Sipariş Ver';

  @override
  String get dateFormat => 'dd.MM.yyyy HH:mm';

  @override
  String totalPrefix(String amount) {
    return 'Toplam:';
  }

  @override
  String get productNotFound => 'Ürün bulunamadı';

  @override
  String inStock(int count) {
    return 'Stokta: $count adet';
  }

  @override
  String addedToCartMessage(String name, int quantity) {
    return 'Sepete eklendi';
  }

  @override
  String get mustBeLoggedIn => 'Giriş yapmalısınız';

  @override
  String cannotAddMoreThanStock(int count) {
    return 'Stoktan fazla ürün eklenemez (Stok: $count)';
  }

  @override
  String get productDescription => 'Açıklama';

  @override
  String get specifications => 'Özellikler';

  @override
  String get customerReviews => 'Müşteri Değerlendirmeleri';

  @override
  String get noReviewsYet => 'Henüz değerlendirme yok';

  @override
  String get couldNotLoadReviews => 'Değerlendirmeler yüklenemedi';

  @override
  String get anonymous => 'Anonim';

  @override
  String get failedToUpdateFavorites => 'Favoriler güncellenemedi';

  @override
  String get pleaseLoginToAddFavorites => 'Favorilere eklemek için lütfen giriş yapın';

  @override
  String get justNow => 'Az önce';

  @override
  String minutesAgo(int count) {
    return '$count dakika önce';
  }

  @override
  String hoursAgo(int count) {
    return '$count saat önce';
  }

  @override
  String get categoryAll => 'Tüm Kategoriler';

  @override
  String get categoryCPU => 'İşlemciler';

  @override
  String get categoryGPU => 'Ekran Kartları';

  @override
  String get categoryRAM => 'RAM';

  @override
  String get categoryMotherboard => 'Anakartlar';

  @override
  String get categoryStorage => 'Depolama';

  @override
  String get categoryCase => 'Kasalar';

  @override
  String get categoryPSU => 'Güç Kaynakları';

  @override
  String get categoryPreBuilt => 'Hazır Sistemler';

  @override
  String get aiChatTitle => 'Asistan Tommy';

  @override
  String get askMeAnything => 'Bana Her Şeyi Sorabilirsin...';

  @override
  String get howCanIHelp => 'Bugün size nasıl yardımcı olabilirim?';

  @override
  String get iNeedAssistance => 'Yardıma ihtiyacım var';

  @override
  String get recommendCheapestPC => 'Bana en ucuz PC yapılandırmasını öner';

  @override
  String get lookingForGamingPC => 'Oyun bilgisayarı yapılandırması arıyorum';

  @override
  String get addNewProduct => 'Yeni Ürün Ekle';

  @override
  String get updateProduct => 'Ürünü Güncelle';

  @override
  String get productDetails => 'Ürün Detayları';

  @override
  String get productName => 'Ürün Adı';

  @override
  String get productPrice => 'Fiyat';

  @override
  String get productStock => 'Stok';

  @override
  String get productCategory => 'Kategori';

  @override
  String get mainImage => 'Ana Görsel';

  @override
  String get additionalImages => 'Ek Görseller';

  @override
  String get generateAIDescription => 'Yapay Zeka ile Açıklama Oluştur';

  @override
  String get pleaseEnterProductName => 'Lütfen önce ürün adını girin';

  @override
  String errorGeneratingDescription(String error) {
    return 'Açıklama oluşturulurken hata: $error';
  }

  @override
  String get searchProduct => 'Ürün Ara';

  @override
  String get selectProductToUpdate => 'Güncellenecek Ürünü Seçin';

  @override
  String get imageRequired => 'Ana görsel gereklidir';

  @override
  String get productUpdated => 'Ürün başarıyla güncellendi';

  @override
  String errorUpdatingProduct(String error) {
    return 'Ürün güncellenirken hata: $error';
  }

  @override
  String get onVacation => 'Şu anda tatildeyim!! Daha sonra tekrar deneyin :P';

  @override
  String get adminOnly => 'Sadece yöneticiler ürün ekleyebilir';

  @override
  String get price => 'Fiyat';

  @override
  String get stock => 'Stok';

  @override
  String get selectCategory => 'Kategori Seç';

  @override
  String get update => 'Güncelle';

  @override
  String stockRemaining(int stock) {
    return '$stock ürün kaldı';
  }

  @override
  String updateStock(Object productName) {
    return '$productName için Stok Güncelle';
  }

  @override
  String get newStockAmount => 'Yeni Stok Miktarı';

  @override
  String get enterNewStockAmount => 'Yeni stok miktarını girin';

  @override
  String get pleaseEnterValidNumber => 'Lütfen geçerli bir sayı girin';

  @override
  String get checkingStockLevels => 'Stok seviyeleri kontrol ediliyor...';

  @override
  String get lowStockAlerts => 'Düşük Stok Uyarıları';

  @override
  String get noLowStockProducts => 'Düşük stoklu ürün yok';

  @override
  String lowStockProductsCount(int count) {
    return '$count ürün düşük stokta';
  }

  @override
  String get promoCodes => 'Promosyon Kodları';

  @override
  String get createPromocodesAndDiscounts => 'Promosyon Kodları ve İndirimler Oluştur';

  @override
  String get salesStatistics => 'Satış İstatistikleri';

  @override
  String get viewSalesAnalytics => 'Satış analizlerini ve grafiklerini görüntüle';

  @override
  String get assistantTommySettings => 'Tommy Asistan Ayarları';

  @override
  String get configureTommyAvailability => 'Tommy\'nin kullanılabilirliğini yapılandır';

  @override
  String get enableAssistantTommy => 'Tommy Asistanı Etkinleştir';

  @override
  String get tommyAvailable => 'Tommy şu anda kullanılabilir';

  @override
  String get tommyDisabled => 'Tommy şu anda devre dışı';

  @override
  String get hideTommy => 'Tommy\'yi Gizle';

  @override
  String get allEyesOnTommy => 'Tüm Gözler Tommy\'de !';

  @override
  String get tommyHiding => 'Tommy dolabında saklanıyor !';

  @override
  String get close => 'Kapat';

  @override
  String get photoUploader => 'Fotoğraf Yükleyici';

  @override
  String get configureAppSettings => 'Uygulama ayarlarını yapılandır';

  @override
  String ratingCount(int count) {
    return '$count değerlendirme';
  }

  @override
  String get reportBug => 'Hata Bildir';

  @override
  String get bugReports => 'Hata Raporları';

  @override
  String get viewAndManageBugReports => 'Hata raporlarını görüntüle ve yönet';

  @override
  String get bugTitle => 'Hata Başlığı';

  @override
  String get enterBugTitle => 'Hata için bir başlık girin';

  @override
  String get bugDescription => 'Hata Açıklaması';

  @override
  String get describeBugInDetail => 'Lütfen hatayı detaylı bir şekilde açıklayın';

  @override
  String get pleaseEnterBugDetails => 'Lütfen başlık ve açıklama giriniz';

  @override
  String get bugReportSubmitted => 'Hata raporu başarıyla gönderildi';

  @override
  String get errorSubmittingBugReport => 'Hata raporu gönderilirken bir sorun oluştu';

  @override
  String get reportedBy => 'Bildiren';

  @override
  String get reportedOn => 'Bildirim Tarihi';

  @override
  String get inProgress => 'İşleniyor';

  @override
  String get resolved => 'Çözüldü';

  @override
  String get dismissed => 'Reddedildi';

  @override
  String get markAsInProgress => 'İşleniyor Olarak İşaretle';

  @override
  String get markAsResolved => 'Çözüldü Olarak İşaretle';

  @override
  String get dismiss => 'Reddet';

  @override
  String get noBugReports => 'Hata raporu bulunamadı';

  @override
  String get requestRefund => 'İade Talep Et';

  @override
  String get confirmRefundRequest => 'Bu sipariş için iade talep etmek istediğinizden emin misiniz?';

  @override
  String get orderTotal => 'Sipariş Toplamı';

  @override
  String get refundRequestSubmitted => 'İade talebi başarıyla gönderildi';

  @override
  String failedToRequestRefund(String error) {
    return 'İade talebi gönderilemedi: $error';
  }

  @override
  String get refundRequested => 'İade Talep Edildi';

  @override
  String get refunded => 'İade Edildi';

  @override
  String get processRefund => 'İadeyi İşle';

  @override
  String get refundProcessed => 'İade başarıyla işlendi';

  @override
  String failedToProcessRefund(String error) {
    return 'İade işlenemedi: $error';
  }

  @override
  String get setupWalletPin => 'Cüzdan PIN Kodu Oluştur';

  @override
  String get createWalletPin => 'Yeni PIN Kodu Oluştur';

  @override
  String get walletPinDescription => 'Lütfen cüzdanınız için 4 haneli bir PIN kodu oluşturun';

  @override
  String get enterPin => 'PIN Kodunu Girin';

  @override
  String get confirmPin => 'PIN Kodunu Onaylayın';

  @override
  String get useBiometrics => 'Parmak İzi Kullan';

  @override
  String get biometricsDescription => 'Cüzdana erişmek için parmak izi veya yüz tanıma kullanın';

  @override
  String get setupPin => 'PIN Kodu Oluştur';

  @override
  String get verify => 'Doğrula';

  @override
  String get invalidPin => 'Geçersiz PIN Kodu';

  @override
  String get orLogInWith => 'Veya ile giriş yap';

  @override
  String get passwordRequirements => 'Şifre Gereksinimleri:';

  @override
  String get atLeast8Characters => 'En az 8 karakter';

  @override
  String get maximum20Characters => 'En fazla 20 karakter';

  @override
  String get oneUppercaseLetter => 'Bir büyük harf';

  @override
  String get oneLowercaseLetter => 'Bir küçük harf';

  @override
  String get oneSpecialCharacter => 'Bir özel karakter';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get noNotifications => 'Henüz bildirim yok';

  @override
  String get noNotificationsDesc => 'Yeni bildirimler burada görünecek';

  @override
  String get clearAllNotifications => 'Tüm bildirimleri temizle';

  @override
  String get allNotificationsCleared => 'Tüm bildirimler temizlendi';

  @override
  String get notificationDeleted => 'Bildirim silindi';

  @override
  String get welcomeNotification => 'Hoş Geldiniz!';

  @override
  String get welcomeNotificationDesc => 'Mağazamıza hoş geldiniz. Sizin için harika tekliflerimiz var.';

  @override
  String get newProductNotification => 'Yeni Ürün';

  @override
  String get newProductNotificationDesc => 'RTX 4090 stokta! Hemen inceleyin.';

  @override
  String get discountNotification => 'İndirim Fırsatı';

  @override
  String get discountNotificationDesc => 'Tüm RAM\'lerde %20 indirim başladı!';

  @override
  String daysAgo(int days, Object count) {
    return '$count gün önce';
  }

  @override
  String get notificationManagement => 'Bildirim Yönetimi';

  @override
  String get newNotification => 'Yeni Bildirim Oluştur';

  @override
  String get notificationTitle => 'Bildirim Başlığı';

  @override
  String get notificationMessage => 'Bildirim Mesajı';

  @override
  String get sendToAllUsers => 'Tüm Kullanıcılara Gönder';

  @override
  String get sendNotification => 'Bildirimi Gönder';

  @override
  String get notificationSent => 'Bildirim başarıyla gönderildi';

  @override
  String notificationError(String error) {
    return 'Hata oluştu: $error';
  }

  @override
  String get pleaseEnterTitleAndMessage => 'Lütfen başlık ve mesaj alanlarını doldurun';

  @override
  String get bannerManagement => 'Banner Management';

  @override
  String get noBannersFound => 'No Banners Found';

  @override
  String get addFirstBanner => 'Add your first banner';

  @override
  String get bannerAddedSuccessfully => 'Banner added successfully';

  @override
  String get bannerUpdatedSuccessfully => 'Banner updated successfully';

  @override
  String get bannerDeletedSuccessfully => 'Banner deleted successfully';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get deleteBannerConfirmation => 'Are you sure you want to delete this banner?';

  @override
  String get selectUsersFirst => 'Please select at least one user';

  @override
  String get uploadingImage => 'Uploading image...';

  @override
  String get savedDiscounts => 'Kayıtlı İndirimler';

  @override
  String get use => 'Kullan';

  @override
  String get noSavedDiscountCodes => 'Kayıtlı İndirim Kodu Bulunamadı';

  @override
  String get savedDiscountCodes => 'Kayıtlı İndirim Kodları';

  @override
  String get discountOffers => 'Mevcut İndirimler';

  @override
  String get discountAndPromotionCodes => 'İndirimler ve Promosyonlar';

  @override
  String get enterDiscountCode => 'İndirim kodunu girin';

  @override
  String get enterValidDiscountCode => 'Lütfen geçerli bir indirim kodu girin';

  @override
  String get apply => 'Uygula';

  @override
  String minOrderAmount(String amount) {
    return 'Minimum sepet tutarı: $amount';
  }

  @override
  String currency(String amount) {
    return '₺$amount';
  }

  @override
  String get noDiscountsAvailable => 'Mevcut indirim bulunmuyor';

  @override
  String get newDiscount => 'Yeni İndirim!';

  @override
  String get discountCodeAvailable => 'Yeni bir indirim kodu mevcut';

  @override
  String get discountSaved => 'İndirim kodu başarıyla kaydedildi';

  @override
  String get saveDiscount => 'İndirimi Kaydet';

  @override
  String get myDiscounts => 'İndirimlerim';

  @override
  String get noDiscounts => 'İndirim kodu bulunmuyor';

  @override
  String validUntil(String date) {
    return '$date tarihine kadar geçerli';
  }

  @override
  String get discountExpired => 'Expired';

  @override
  String get discountUsed => 'Used';

  @override
  String get wheelManagement => 'Çark Yönetimi';

  @override
  String get wheelItemsDescription => 'İndirim çarkı öğelerini ve olasılıklarını yönetin';

  @override
  String get probability => 'Olasılık';

  @override
  String get addNewDiscount => 'Yeni İndirim Ekle';

  @override
  String get discountValue => 'İndirim Değeri';

  @override
  String get pleaseEnterValue => 'Lütfen bir değer girin';

  @override
  String get enterValidNumber => 'Lütfen 1 ile 100 arasında geçerli bir sayı girin';

  @override
  String get congratulations => 'Tebrikler!';

  @override
  String get betterLuckNextTime => 'Bir dahaki sefere!';

  @override
  String get youWonDiscount => 'Kazandınız';

  @override
  String get settingsSaved => 'Ayarlar başarıyla kaydedildi';

  @override
  String get comeBackNextWeek => 'Gelecek hafta tekrar gel!';

  @override
  String get spinning => 'Çevriliyor...';

  @override
  String get spinTheWheel => 'Çarkı Çevir!';

  @override
  String get mostViewed => 'En Çok Görüntülenen Ürünler';

  @override
  String get country => 'Country';

  @override
  String get selectCountry => 'Select Country';

  @override
  String get pleaseSelectCountry => 'Please select a country';

  @override
  String get homepageLayout => 'Homepage Layout';

  @override
  String get cashbackReversal => 'Cashback Reversal';

  @override
  String get cardHolder => 'Kart Sahibi';

  @override
  String get invalidExpiryDate => 'Geçersiz son kullanma tarihi';

  @override
  String get invalidCvv => 'Geçersiz CVV';

  @override
  String get deliveryFee => 'Kargo Ücreti';

  @override
  String get edit => 'Düzenle';
}
