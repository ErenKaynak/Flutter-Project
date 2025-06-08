// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'پیراڈائس پی سی پارٹس';

  @override
  String get welcome => 'خوش آمدید';

  @override
  String get login => 'لاگ ان';

  @override
  String get signIn => 'سائن ان';

  @override
  String get register => 'رجسٹر';

  @override
  String get guest => 'مہمان کے طور پر جاری رکھیں';

  @override
  String get email => 'ای میل';

  @override
  String get password => 'پاس ورڈ';

  @override
  String get confirmPassword => 'پاس ورڈ کی تصدیق کریں';

  @override
  String get forgotPassword => 'پاس ورڈ بھول گئے؟';

  @override
  String get notAMember => 'رکن نہیں ہیں؟';

  @override
  String get alreadyHaveAccount => 'پہلے سے اکاؤنٹ ہے؟';

  @override
  String get profile => 'پروفائل';

  @override
  String get home => 'ہوم';

  @override
  String get favorites => 'پسندیدہ';

  @override
  String get cart => 'کارٹ';

  @override
  String get settings => 'ترتیبات';

  @override
  String get language => 'زبان';

  @override
  String get english => 'انگریزی';

  @override
  String get turkish => 'ترکی';

  @override
  String get arabic => 'عربی';

  @override
  String get urdu => 'Urdu';

  @override
  String get darkMode => 'ڈارک موڈ';

  @override
  String get specialMode => 'خصوصی موڈ';

  @override
  String get passwordlessSignIn => 'پاس ورڈ کے بغیر سائن ان';

  @override
  String get wheelOfDiscount => 'ڈسکاؤنٹ وہیل';

  @override
  String get addToCart => 'کارٹ میں شامل کریں';

  @override
  String get outOfStock => 'اسٹاک میں نہیں';

  @override
  String get removeFromFavorites => 'پسندیدہ سے ہٹائیں';

  @override
  String get addedToFavorites => 'پسندیدہ میں شامل کر دیا گیا';

  @override
  String get removedFromFavorites => 'پسندیدہ سے ہٹا دیا گیا';

  @override
  String get searchProducts => 'پروڈکٹس تلاش کریں';

  @override
  String get categories => 'زمرے';

  @override
  String get allCategories => 'تمام زمرے';

  @override
  String get bestDeals => 'بہترین ڈیلز';

  @override
  String products(int count) {
    return '$count پروڈکٹس';
  }

  @override
  String get productQuantity => 'مقدار';

  @override
  String get noProductsFound => 'کوئی پروڈکٹ نہیں ملا';

  @override
  String get tryDifferentSearch => 'مختلف تلاش کی اصطلاح آزمائیں';

  @override
  String get tryDifferentCategory => 'مختلف زمرہ منتخب کرنے کی کوشش کریں';

  @override
  String get viewCart => 'کارٹ دیکھیں';

  @override
  String get off => 'کم';

  @override
  String addedToCart(String productName) {
    return '$productName کارٹ میں شامل کر دیا گیا';
  }

  @override
  String get errorAddingToCart => 'کارٹ میں آئٹم شامل کرنے میں ناکام';

  @override
  String get pleaseSignIn => 'براہ کرم جاری رکھنے کے لیے سائن ان کریں';

  @override
  String get signOut => 'سائن آؤٹ';

  @override
  String get editProfile => 'پروفائل میں ترمیم کریں';

  @override
  String get name => 'نام';

  @override
  String get surname => 'خاندانی نام';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get cancel => 'منسوخ کریں';

  @override
  String get accountSettings => 'اکاؤنٹ کی ترتیبات';

  @override
  String get myAddresses => 'میرے پتے';

  @override
  String get addNewAddress => 'نیا پتہ شامل کریں';

  @override
  String get hello => 'ہیلو';

  @override
  String get yourAddresses => 'آپ کے پتے';

  @override
  String get noAddressesFound => 'کوئی پتہ نہیں ملا۔';

  @override
  String get recipientInfo => 'وصول کنندہ کی معلومات';

  @override
  String get firstName => 'پہلا نام';

  @override
  String get lastName => 'آخری نام';

  @override
  String get phoneNumber => 'فون نمبر';

  @override
  String get addressType => 'پتے کی قسم';

  @override
  String get addressDetails => 'پتے کی تفصیلات';

  @override
  String get streetAvenue => 'گلی / ایونیو';

  @override
  String get neighborhood => 'محلہ';

  @override
  String get buildingNo => 'عمارت نمبر';

  @override
  String get apartmentName => 'اپارٹمنٹ کا نام';

  @override
  String get floorNo => 'منزل نمبر';

  @override
  String get doorNo => 'دروازہ نمبر';

  @override
  String get city => 'شہر';

  @override
  String get addressLabel => 'پتے کا لیبل';

  @override
  String get addressLabelHint => 'مثال: گھر، دفتر، وغیرہ';

  @override
  String get saveAddress => 'پتہ محفوظ کریں';

  @override
  String get savingAddress => 'پتہ محفوظ کر رہا ہے...';

  @override
  String get addressSaved => 'پتہ کامیابی سے محفوظ کر دیا گیا';

  @override
  String get userNotLoggedIn => 'صارف لاگ ان نہیں ہے۔';

  @override
  String errorSavingAddress(String error) {
    return 'پتہ محفوظ کرنے میں خرابی: $error';
  }

  @override
  String get fillAllFields => 'براہ کرم تمام مطلوبہ فیلڈز بھریں';

  @override
  String get pleaseEnterFirstName => 'براہ کرم پہلا نام درج کریں';

  @override
  String get pleaseEnterLastName => 'براہ کرم آخری نام درج کریں';

  @override
  String get pleaseEnterPhoneNumber => 'براہ کرم فون نمبر درج کریں';

  @override
  String get invalidPhoneNumber => 'براہ کرم درست فون نمبر درج کریں';

  @override
  String get pleaseEnterStreetName => 'براہ کرم گلی کا نام درج کریں';

  @override
  String get pleaseEnterNeighborhood => 'براہ کرم محلہ درج کریں';

  @override
  String get required => 'ضروری';

  @override
  String get pleaseEnterAddressLabel => 'براہ کرم پتے کا لیبل درج کریں';

  @override
  String get selectCity => 'شہر منتخب کریں';

  @override
  String get pleaseSelectCity => 'براہ کرم شہر منتخب کریں';

  @override
  String get work => 'دفتر';

  @override
  String get delete => 'حذف کریں';

  @override
  String get setAsDefault => 'ڈیفالٹ کے طور پر سیٹ کریں';

  @override
  String get myOrders => 'میرے آرڈرز';

  @override
  String get myWallet => 'میری والیٹ';

  @override
  String get appearance => 'ظاہری شکل';

  @override
  String get adminPanel => 'ایڈمن پینل';

  @override
  String get referralCode => 'آپ کا ریفرل کوڈ';

  @override
  String get copiedToClipboard => 'کلپ بورڈ پر کاپی کر دیا گیا';

  @override
  String get changeProfilePicture => 'پروفائل تصویر تبدیل کریں';

  @override
  String get takePhoto => 'تصویر لیں';

  @override
  String get chooseFromGallery => 'گیلری سے منتخب کریں';

  @override
  String get addFromUrl => 'URL سے شامل کریں';

  @override
  String get removePhoto => 'تصویر ہٹائیں';

  @override
  String get enterImageUrl => 'تصویر کا URL درج کریں';

  @override
  String get imageUrl => 'Image URL';

  @override
  String get add => 'شامل کریں';

  @override
  String get sort => 'ترتیب دیں';

  @override
  String get priceLowToHigh => 'قیمت: کم سے زیادہ';

  @override
  String get priceHighToLow => 'قیمت: زیادہ سے کم';

  @override
  String get nameAToZ => 'نام: A سے Z';

  @override
  String get nameZToA => 'نام: Z سے A';

  @override
  String get specialOffers => 'خصوصی پیشکشیں';

  @override
  String get specialOffersDescription => 'منتخب پروڈکٹس پر 20% تک کی چھوٹ';

  @override
  String get shopNow => 'ابھی خریدیں';

  @override
  String get authentication => 'تصدیق';

  @override
  String get createAccount => 'اکاؤنٹ بنائیں';

  @override
  String get addYourName => 'اپنا نام شامل کریں';

  @override
  String get admin => 'ایڈمن';

  @override
  String get guestUser => 'مہمان';

  @override
  String get signInToAccess => 'تمام خصوصیات تک رسائی کے لیے سائن ان کریں';

  @override
  String get yourReferralCode => 'آپ کا ریفرل کوڈ';

  @override
  String get loading => 'لوڈ ہو رہا ہے...';

  @override
  String get noFavoritesYet => 'ابھی تک کوئی پسندیدہ نہیں';

  @override
  String get itemsYouFavorite => 'آپ کی پسندیدہ آئٹمز یہاں ظاہر ہوں گی';

  @override
  String get yourCart => 'آپ کا کارٹ';

  @override
  String get emptyCart => 'آپ کا کارٹ خالی ہے';

  @override
  String get addItemsToCheckout => 'چیک آؤٹ کے لیے کارٹ میں آئٹمز شامل کریں';

  @override
  String get clearCart => 'کارٹ صاف کریں';

  @override
  String get clearCartConfirmation => 'کیا آپ واقعی تمام آئٹمز ہٹانا چاہتے ہیں؟';

  @override
  String get discountCode => 'ڈسکاؤنٹ کوڈ';

  @override
  String get enterCode => 'کوڈ درج کریں';

  @override
  String discountApplied(Object code) {
    return 'ڈسکاؤنٹ لاگو کیا گیا: $code';
  }

  @override
  String percentOff(int percent) {
    return '$percent% کم';
  }

  @override
  String get invalidDiscountCode => 'غلط ڈسکاؤنٹ کوڈ';

  @override
  String get notApplicableDiscount => 'یہ کوڈ آپ کے کارٹ میں موجود آئٹمز پر لاگو نہیں ہوتا';

  @override
  String get subtotal => 'سب ٹوٹل';

  @override
  String discount(int percent) {
    return 'ڈسکاؤنٹ ($percent%)';
  }

  @override
  String get total => 'کل';

  @override
  String totalAmount(String amount) {
    return 'کل: ₺$amount';
  }

  @override
  String get checkout => 'چیک آؤٹ';

  @override
  String get paymentSuccessful => 'ادائیگی کامیاب!';

  @override
  String amountPaid(String amount) {
    return 'ادائیگی کی گئی رقم: ₺$amount';
  }

  @override
  String get orderPlaced => 'آپ کا آرڈر کامیابی سے رکھ دیا گیا ہے۔';

  @override
  String orderId(String id) {
    return 'آرڈر آئی ڈی: $id';
  }

  @override
  String get viewOrders => 'آرڈرز دیکھیں';

  @override
  String get continueShopping => 'خریداری جاری رکھیں';

  @override
  String get cardExpired => 'آپ کا کارڈ ختم ہو گیا ہے، براہ کرم دوبارہ کوشش کریں';

  @override
  String get pleaseSelectAddress => 'براہ کرم پتہ منتخب کریں';

  @override
  String get pleaseSelectCard => 'براہ کرم کریڈٹ کارڈ منتخب کریں';

  @override
  String get deliveryAddress => 'ترسیل کا پتہ';

  @override
  String get addNew => 'نیا شامل کریں';

  @override
  String get noSavedAddresses => 'کوئی محفوظ شدہ پتے نہیں';

  @override
  String get creditCards => 'کریڈٹ کارڈز';

  @override
  String get noSavedCards => 'کوئی محفوظ شدہ کارڈز نہیں';

  @override
  String get myCards => 'My Cards';

  @override
  String get payWithCreditCard => 'کریڈٹ کارڈ سے ادائیگی کریں';

  @override
  String get payWithWallet => 'والیٹ سے ادائیگی کریں';

  @override
  String availableBalance(String amount) {
    return 'دستیاب بیلنس: ₺$amount';
  }

  @override
  String get insufficientBalance => 'ناکافی بیلنس';

  @override
  String addMoreForFreeShipping(String amount) {
    return 'مفت شپنگ کے لیے ₺$amount مزید شامل کریں!';
  }

  @override
  String get freeShippingOver => '₺10,000 سے زیادہ پر مفت';

  @override
  String get free => 'مفت';

  @override
  String get shipping => 'شپنگ';

  @override
  String get placeOrder => 'آرڈر دیں';

  @override
  String get address => 'پتہ';

  @override
  String get payment => 'ادائیگی';

  @override
  String get confirm => 'تصدیق کریں';

  @override
  String get paymentMethod => 'ادائیگی کا طریقہ:';

  @override
  String get addNewCard => 'نیا کارڈ شامل کریں';

  @override
  String get orderSummary => 'آرڈر کا خلاصہ';

  @override
  String get cardNumber => 'کارڈ نمبر';

  @override
  String get cardNumberHint => '1234 5678 9012 3456';

  @override
  String get cardHolderName => 'کارڈ ہولڈر کا نام';

  @override
  String get cardHolderHint => 'JOHN DOE';

  @override
  String get expiryDate => 'ختم ہونے کی تاریخ';

  @override
  String get expiryDateHint => 'MM/YY';

  @override
  String get cardIsExpired => 'کارڈ ختم ہو گیا ہے';

  @override
  String get cvv => 'CVV';

  @override
  String get cvvHint => '123';

  @override
  String get deleteCard => 'کارڈ حذف کریں';

  @override
  String get deleteCardConfirmation => 'کیا آپ واقعی اس کارڈ کو حذف کرنا چاہتے ہیں؟';

  @override
  String get defaultCard => 'ڈیفالٹ کارڈ';

  @override
  String expires(String date) {
    return 'میعاد ختم ہونے کی تاریخ: $date';
  }

  @override
  String get ok => 'ٹھیک ہے';

  @override
  String get cannotReorder => 'دوبارہ آرڈر نہیں کر سکتے';

  @override
  String outOfStockItems(String items) {
    return 'مندرجہ ذیل آئٹمز اسٹاک میں نہیں ہیں:\n• $items';
  }

  @override
  String insufficientStockItems(String items) {
    return 'ناکافی اسٹاک:\n• $items';
  }

  @override
  String get myFavorites => 'میری پسندیدہ';

  @override
  String get refresh => 'ریفریش';

  @override
  String get exploreProducts => 'پروڈکٹس دریافت کریں';

  @override
  String get failedToRemove => 'پسندیدہ سے ہٹانے میں ناکام';

  @override
  String get pleaseLoginToAdd => 'براہ کرم کارٹ میں آئٹمز شامل کرنے کے لیے لاگ ان کریں';

  @override
  String get failedToAddToCart => 'کارٹ میں آئٹم شامل کرنے میں ناکام';

  @override
  String get adminDashboard => 'ایڈمن ڈیش بورڈ';

  @override
  String get adminControls => 'ایڈمن کنٹرولز';

  @override
  String get userManagement => 'صارف مینجمنٹ';

  @override
  String get viewAndManageUsers => 'صارفین کو دیکھیں اور مینج کریں';

  @override
  String get productManagement => 'پروڈکٹ مینجمنٹ';

  @override
  String get manageProducts => 'پروڈکٹس مینج کریں';

  @override
  String get orderManagement => 'آرڈر مینجمنٹ';

  @override
  String get viewAndProcessOrders => 'آرڈرز دیکھیں اور پروسیس کریں';

  @override
  String get currentBalance => 'موجودہ بیلنس';

  @override
  String get cashbackInfo => 'تمام خریداری پر 1% کیش بیک';

  @override
  String get addMoney => 'رقم شامل کریں';

  @override
  String get transactionHistory => 'لین دین کی تاریخ';

  @override
  String transactionsCount(int count) {
    return '$count لین دین';
  }

  @override
  String get noTransactions => 'ابھی تک کوئی لین دین نہیں';

  @override
  String get transactionsWillAppear => 'آپ کی لین دین کی تاریخ یہاں ظاہر ہوگی';

  @override
  String get moneyAdded => 'رقم کامیابی سے شامل کر دی گئی';

  @override
  String errorAddingBalance(String error) {
    return 'بیلنس شامل کرنے میں خرابی: $error';
  }

  @override
  String get addMoneyToWallet => 'والیٹ میں رقم شامل کریں';

  @override
  String get amount => 'رقم';

  @override
  String get selectCard => 'کارڈ منتخب کریں';

  @override
  String get useCard => 'محفوظ شدہ کارڈ استعمال کریں';

  @override
  String get enterValidAmount => 'براہ کرم درست رقم درج کریں';

  @override
  String get fillCardDetails => 'براہ کرم تمام کارڈ کی تفصیلات درست طریقے سے بھریں';

  @override
  String get cardNumberError => 'کارڈ نمبر 16 ہندسوں کا ہونا چاہیے';

  @override
  String get invalidCardNumber => 'غلط کارڈ نمبر';

  @override
  String get onlyLettersAllowed => 'صرف حروف کی اجازت ہے';

  @override
  String get useMMYYFormat => 'MM/YY فارمیٹ استعمال کریں';

  @override
  String get invalidCVV => 'غلط CVV';

  @override
  String get amountMustBeGreater => 'رقم 0 سے زیادہ ہونی چاہیے';

  @override
  String get maximumAmount => 'زیادہ سے زیادہ رقم ₺10,000 ہے';

  @override
  String get invalidAmount => 'غلط رقم';

  @override
  String get cardSaved => 'کارڈ کامیابی سے محفوظ کر دیا گیا';

  @override
  String errorSavingCard(String error) {
    return 'کارڈ محفوظ کرنے میں خرابی: $error';
  }

  @override
  String get transactionDetails => 'لین دین کی تفصیلات';

  @override
  String get type => 'قسم';

  @override
  String get deposit => 'ڈپازٹ';

  @override
  String get purchase => 'خریداری';

  @override
  String get date => 'تاریخ';

  @override
  String get status => 'حیثیت';

  @override
  String get method => 'طریقہ';

  @override
  String get reference => 'حوالہ';

  @override
  String get description => 'تفصیل';

  @override
  String get orderHistory => 'آرڈر کی تاریخ';

  @override
  String get yourOrders => 'آپ کے آرڈرز';

  @override
  String ordersCount(int count) {
    return '$count آرڈرز';
  }

  @override
  String get filterByStatus => 'حیثیت کے لحاظ سے فلٹر کریں';

  @override
  String get allOrders => 'تمام';

  @override
  String get pending => 'زیر التوا';

  @override
  String get preparing => 'تیار ہو رہا ہے';

  @override
  String get onDelivery => 'ترسیل پر';

  @override
  String get delivered => 'ترسیل شدہ';

  @override
  String get cancelled => 'منسوخ';

  @override
  String noOrdersWithStatus(String status) {
    return '\'$status\' حیثیت کے ساتھ کوئی آرڈر نہیں';
  }

  @override
  String get tryDifferentFilter => 'مختلف فلٹر منتخب کرنے کی کوشش کریں';

  @override
  String orderNumber(String number) {
    return 'آرڈر #$number';
  }

  @override
  String get items => 'آئٹمز:';

  @override
  String quantity(int count, String price) {
    return 'مقدار';
  }

  @override
  String itemTotal(String amount) {
    return 'آئٹم کا کل: ₺$amount';
  }

  @override
  String get trackingNumber => 'ٹریکنگ نمبر:';

  @override
  String get shippingAddress => 'ترسیل کا پتہ:';

  @override
  String get noAddressProvided => 'کوئی پتہ فراہم نہیں کیا گیا';

  @override
  String get notSpecified => 'متعلق نہیں';

  @override
  String get reorder => 'دوبارہ آرڈر کریں';

  @override
  String get cancelOrder => 'آرڈر منسوخ کریں';

  @override
  String get confirmCancelOrder => 'کیا آپ واقعی اس آرڈر کو منسوخ کرنا چاہتے ہیں؟';

  @override
  String get orderCancelled => 'آرڈر کامیابی سے منسوخ کر دیا گیا';

  @override
  String failedToCancelOrder(String error) {
    return 'آرڈر منسوخ کرنے میں ناکام: $error';
  }

  @override
  String get rateProduct => 'اس پروڈکٹ کو ریٹ کریں';

  @override
  String get alreadyReviewed => 'پہلے سے ریویو کیا گیا';

  @override
  String get canReviewAfterDelivery => 'ترسیل کے بعد ریویو کر سکتے ہیں';

  @override
  String get selectRating => 'ریٹنگ منتخب کریں';

  @override
  String get poor => 'خراب';

  @override
  String get fair => 'اوسط';

  @override
  String get good => 'اچھا';

  @override
  String get veryGood => 'بہت اچھا';

  @override
  String get excellent => 'بہترین';

  @override
  String get writeReview => 'اپنا ریویو لکھیں (اختیاری)';

  @override
  String get submitReview => 'ریویو جمع کروائیں';

  @override
  String get thankYouForReview => 'آپ کے ریویو کا شکریہ!';

  @override
  String get failedToSubmitReview => 'ریویو جمع کرانے میں ناکام';

  @override
  String get productNoLongerAvailable => 'پروڈکٹ اب دستیاب نہیں ہے';

  @override
  String get errorCheckingAvailability => 'پروڈکٹ کی دستیابی چیک کرنے میں خرابی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get tryAgain => 'دوبارہ کوشش کریں';

  @override
  String get noOrdersYet => 'ابھی تک کوئی آرڈر نہیں';

  @override
  String get yourOrderHistoryWillAppearHere => 'آپ کی آرڈر کی تاریخ یہاں ظاہر ہوگی';

  @override
  String get startShopping => 'خریداری شروع کریں';

  @override
  String get somethingWentWrong => 'کچھ غلط ہو گیا';

  @override
  String get orderPrefix => 'آرڈر #';

  @override
  String get itemsLabel => 'آئٹمز:';

  @override
  String get quantityPrefix => 'مقدار:';

  @override
  String get itemTotalPrefix => 'آئٹم کا کل:';

  @override
  String get shippingAddressLabel => 'ترسیل کا پتہ:';

  @override
  String get defaultShippingAddress => 'ڈیفالٹ ترسیل کا پتہ';

  @override
  String get paymentMethodLabel => 'ادائیگی کا طریقہ:';

  @override
  String get cardPayment => 'کارڈ';

  @override
  String get reorderButton => 'دوبارہ آرڈر کریں';

  @override
  String get dateFormat => 'MMM dd, yyyy - HH:mm';

  @override
  String totalPrefix(String amount) {
    return 'کل: ₺$amount';
  }

  @override
  String get productNotFound => 'پروڈکٹ نہیں ملا';

  @override
  String inStock(int count) {
    return '$count اسٹاک میں';
  }

  @override
  String addedToCartMessage(String name, int quantity) {
    return '$name x$quantity کارٹ میں شامل کر دیا گیا';
  }

  @override
  String get mustBeLoggedIn => 'کارٹ میں شامل کرنے کے لیے آپ کو لاگ ان ہونا ہوگا';

  @override
  String cannotAddMoreThanStock(int count) {
    return 'دستیاب اسٹاک ($count) سے زیادہ شامل نہیں کر سکتے';
  }

  @override
  String get productDescription => 'تفصیل';

  @override
  String get specifications => 'خصوصیات';

  @override
  String get customerReviews => 'گاہکوں کے ریویوز';

  @override
  String get noReviewsYet => 'ابھی تک کوئی ریویو نہیں';

  @override
  String get couldNotLoadReviews => 'ریویوز لوڈ نہیں کر سکے';

  @override
  String get anonymous => 'گمنام';

  @override
  String get failedToUpdateFavorites => 'پسندیدہ اپڈیٹ کرنے میں ناکام';

  @override
  String get pleaseLoginToAddFavorites => 'پسندیدہ شامل کرنے کے لیے براہ کرم لاگ ان کریں';

  @override
  String get justNow => 'ابھی';

  @override
  String minutesAgo(int count) {
    return '$count منٹ پہلے';
  }

  @override
  String hoursAgo(int count) {
    return '$count گھنٹے پہلے';
  }

  @override
  String get categoryAll => 'تمام زمرے';

  @override
  String get categoryCPU => 'سی پی یوز';

  @override
  String get categoryGPU => 'جی پی یوز';

  @override
  String get categoryRAM => 'ریم';

  @override
  String get categoryMotherboard => 'مدر بورڈز';

  @override
  String get categoryStorage => 'اسٹوریج';

  @override
  String get categoryCase => 'کیسز';

  @override
  String get categoryPSU => 'پاور سپلائز';

  @override
  String get categoryPreBuilt => 'پہلے سے بنے پی سیز';

  @override
  String get aiChatTitle => 'اسسٹنٹ ٹامی';

  @override
  String get askMeAnything => 'مجھ سے کچھ بھی پوچھیں...';

  @override
  String get howCanIHelp => 'آج میں آپ کی کیا مدد کر سکتا ہوں؟';

  @override
  String get iNeedAssistance => 'مجھے مدد کی ضرورت ہے';

  @override
  String get recommendCheapestPC => 'مجھے سب سے سستا پی سی بلڈ تجویز کریں';

  @override
  String get lookingForGamingPC => 'گیمنگ پی سی بلڈ کی تلاش میں ہوں';

  @override
  String get addNewProduct => 'نیا پروڈکٹ شامل کریں';

  @override
  String get updateProduct => 'پروڈکٹ اپڈیٹ کریں';

  @override
  String get productDetails => 'پروڈکٹ کی تفصیلات';

  @override
  String get productName => 'پروڈکٹ کا نام';

  @override
  String get productPrice => 'قیمت';

  @override
  String get productStock => 'اسٹاک';

  @override
  String get productCategory => 'زمرہ';

  @override
  String get mainImage => 'مین تصویر';

  @override
  String get additionalImages => 'اضافی تصاویر';

  @override
  String get generateAIDescription => 'AI تفصیل بنائیں';

  @override
  String get pleaseEnterProductName => 'براہ کرم پہلے پروڈکٹ کا نام درج کریں';

  @override
  String errorGeneratingDescription(String error) {
    return 'تفصیل بنانے میں خرابی: $error';
  }

  @override
  String get searchProduct => 'پروڈکٹ تلاش کریں';

  @override
  String get selectProductToUpdate => 'اپڈیٹ کرنے کے لیے پروڈکٹ منتخب کریں';

  @override
  String get imageRequired => 'مین تصویر ضروری ہے';

  @override
  String get productUpdated => 'پروڈکٹ کامیابی سے اپڈیٹ کر دیا گیا';

  @override
  String errorUpdatingProduct(String error) {
    return 'پروڈکٹ اپڈیٹ کرنے میں خرابی: $error';
  }

  @override
  String get onVacation => 'میں ابھی چھٹی پر ہوں!! بعد میں بات کرنے کی کوشش کریں :P';

  @override
  String get adminOnly => 'صرف ایڈمن صارفین پروڈکٹس شامل کر سکتے ہیں';

  @override
  String get price => 'قیمت';

  @override
  String get stock => 'اسٹاک';

  @override
  String get selectCategory => 'زمرہ منتخب کریں';

  @override
  String get update => 'اپڈیٹ کریں';

  @override
  String stockRemaining(int stock) {
    return '$stock آئٹمز باقی ہیں';
  }

  @override
  String updateStock(Object productName) {
    return '$productName کے لیے اسٹاک اپڈیٹ کریں';
  }

  @override
  String get newStockAmount => 'نئی اسٹاک مقدار';

  @override
  String get enterNewStockAmount => 'نئی اسٹاک مقدار درج کریں';

  @override
  String get pleaseEnterValidNumber => 'براہ کرم درست نمبر درج کریں۔';

  @override
  String get checkingStockLevels => 'اسٹاک کی سطحیں چیک کر رہا ہے...';

  @override
  String get lowStockAlerts => 'کم اسٹاک کی اطلاعات';

  @override
  String get noLowStockProducts => 'کم اسٹاک والی کوئی پروڈکٹس نہیں۔';

  @override
  String lowStockProductsCount(int count) {
    return '$count کم اسٹاک والی پروڈکٹس';
  }

  @override
  String get promoCodes => 'پرومو کوڈز اور ڈسکاؤنٹس';

  @override
  String get createPromocodesAndDiscounts => 'پرومو کوڈز اور ڈسکاؤنٹس بنائیں اور مینج کریں۔';

  @override
  String get salesStatistics => 'سیلز کے اعدادوشمار';

  @override
  String get viewSalesAnalytics => 'سیلز کے تجزیات دیکھیں۔';

  @override
  String get assistantTommySettings => 'اسسٹنٹ ٹامی کی ترتیبات';

  @override
  String get configureTommyAvailability => 'اسسٹنٹ ٹامی کی دستیابی کی ترتیب کریں۔';

  @override
  String get enableAssistantTommy => 'اسسٹنٹ ٹامی کو فعال کریں';

  @override
  String get tommyAvailable => 'ٹامی فی الحال دستیاب ہے';

  @override
  String get tommyDisabled => 'ٹامی فی الحال غیر فعال ہے';

  @override
  String get hideTommy => 'ٹامی کو چھپائیں';

  @override
  String get allEyesOnTommy => 'سب کی نظریں ٹامی پر!';

  @override
  String get tommyHiding => 'ٹامی الماری میں چھپا ہوا ہے!';

  @override
  String get close => 'بند کریں';

  @override
  String get photoUploader => 'تصویر اپلوڈر';

  @override
  String get configureAppSettings => 'ایپلیکیشن کی ترتیبات کی ترتیب کریں۔';

  @override
  String ratingCount(int count) {
    return '$count ریٹنگز';
  }

  @override
  String get reportBug => 'بگ رپورٹ کریں';

  @override
  String get bugReports => 'بگ رپورٹس';

  @override
  String get viewAndManageBugReports => 'بگ رپورٹس دیکھیں اور مینج کریں۔';

  @override
  String get bugTitle => 'بگ کا عنوان';

  @override
  String get enterBugTitle => 'بگ کے لیے عنوان درج کریں';

  @override
  String get bugDescription => 'بگ کی تفصیل';

  @override
  String get describeBugInDetail => 'براہ کرم بگ کی تفصیل سے وضاحت کریں';

  @override
  String get pleaseEnterBugDetails => 'براہ کرم عنوان اور تفصیل دونوں درج کریں';

  @override
  String get bugReportSubmitted => 'بگ رپورٹ کامیابی سے جمع کر دی گئی';

  @override
  String get errorSubmittingBugReport => 'بگ رپورٹ جمع کرانے میں خرابی';

  @override
  String get reportedBy => 'رپورٹ کرنے والا';

  @override
  String get reportedOn => 'رپورٹ کی تاریخ';

  @override
  String get inProgress => 'جاری ہے';

  @override
  String get resolved => 'حل ہو گیا';

  @override
  String get dismissed => 'مسترد';

  @override
  String get markAsInProgress => 'جاری کے طور پر نشان زد کریں';

  @override
  String get markAsResolved => 'حل شدہ کے طور پر نشان زد کریں';

  @override
  String get dismiss => 'مسترد کریں';

  @override
  String get noBugReports => 'کوئی بگ رپورٹس نہیں ملیں';

  @override
  String get requestRefund => 'ریفنڈ کی درخواست کریں';

  @override
  String get confirmRefundRequest => 'کیا آپ واقعی اس آرڈر کے لیے رفیند کی درخواست کرنا چاہتے ہیں؟';

  @override
  String get orderTotal => 'آرڈر کا کل';

  @override
  String get refundRequestSubmitted => 'ریفنڈ کی درخواست کامیابی سے جمع کر دی گئی';

  @override
  String failedToRequestRefund(String error) {
    return 'ریفنڈ کی درخواست کرنے میں ناکام: $error';
  }

  @override
  String get refundRequested => 'ریفنڈ کی درخواست کی گئی';

  @override
  String get refunded => 'ریفنڈ کر دیا گیا';

  @override
  String get processRefund => 'ریفنڈ پروسیس کریں';

  @override
  String get refundProcessed => 'ریفنڈ کامیابی سے پروسیس کر دیا گیا';

  @override
  String failedToProcessRefund(String error) {
    return 'ریفنڈ پروسیس کرنے میں ناکام: $error';
  }

  @override
  String get setupWalletPin => 'والیٹ پن سیٹ کریں';

  @override
  String get createWalletPin => 'والیٹ پن بنائیں';

  @override
  String get walletPinDescription => 'اپنی والیٹ کو محفوظ کرنے کے لیے 6 ہندسوں کا پن بنائیں';

  @override
  String get enterPin => 'پن درج کریں';

  @override
  String get confirmPin => 'پن کی تصدیق کریں';

  @override
  String get useBiometrics => 'بائیومیٹرکس استعمال کریں';

  @override
  String get biometricsDescription => 'اپنی والیٹ تک رسائی کے لیے فنگر پرنٹ یا چہرے کی پہچان استعمال کریں';

  @override
  String get setupPin => 'پن سیٹ کریں';

  @override
  String get verify => 'تصدیق کریں';

  @override
  String get invalidPin => 'غلط پن';

  @override
  String get orLogInWith => 'یا اس کے ساتھ لاگ ان کریں';

  @override
  String get passwordRequirements => 'پاس ورڈ کی ضروریات:';

  @override
  String get atLeast8Characters => 'کم از کم 8 حروف';

  @override
  String get maximum20Characters => 'زیادہ سے زیادہ 20 حروف';

  @override
  String get oneUppercaseLetter => 'ایک بڑا حرف';

  @override
  String get oneLowercaseLetter => 'ایک چھوٹا حرف';

  @override
  String get oneSpecialCharacter => 'ایک خاص حرف';

  @override
  String get notifications => 'اطلاعات';

  @override
  String get noNotifications => 'ابھی تک کوئی اطلاعات نہیں';

  @override
  String get noNotificationsDesc => 'نئی اطلاعات یہاں ظاہر ہوں گی';

  @override
  String get clearAllNotifications => 'تمام اطلاعات صاف کریں';

  @override
  String get allNotificationsCleared => 'تمام اطلاعات صاف کر دی گئیں';

  @override
  String get notificationDeleted => 'اطلاع حذف کر دی گئی';

  @override
  String get welcomeNotification => 'خوش آمدید!';

  @override
  String get welcomeNotificationDesc => 'ہماری دکان میں خوش آمدید۔ ہمارے پاس آپ کے لیے بہترین پیشکشیں ہیں۔';

  @override
  String get newProductNotification => 'نیا پروڈکٹ';

  @override
  String get newProductNotificationDesc => 'RTX 4090 اسٹاک میں ہے! ابھی چیک کریں۔';

  @override
  String get discountNotification => 'خصوصی ڈسکاؤنٹ';

  @override
  String get discountNotificationDesc => 'تمام ریم پروڈکٹس پر 20% کی چھوٹ!';

  @override
  String daysAgo(int days, Object count) {
    return '$count دن پہلے';
  }

  @override
  String get notificationManagement => 'اطلاعات کی مینجمنٹ';

  @override
  String get newNotification => 'نئی اطلاعات بنائیں';

  @override
  String get notificationTitle => 'اطلاع کا عنوان';

  @override
  String get notificationMessage => 'اطلاع کا پیغام';

  @override
  String get sendToAllUsers => 'تمام صارفین کو بھیجیں';

  @override
  String get sendNotification => 'اطلاع بھیجیں';

  @override
  String get notificationSent => 'اطلاع کامیابی سے بھیج دی گئی';

  @override
  String notificationError(String error) {
    return 'خرابی پیش آگئی: $error';
  }

  @override
  String get pleaseEnterTitleAndMessage => 'براہ کرم عنوان اور پیغام درج کریں';

  @override
  String get bannerManagement => 'بینر مینجمنٹ';

  @override
  String get noBannersFound => 'کوئی بینر نہیں ملا';

  @override
  String get addFirstBanner => 'اپنا پہلا بینر شامل کریں';

  @override
  String get bannerAddedSuccessfully => 'بینر کامیابی سے شامل کر دیا گیا';

  @override
  String get bannerUpdatedSuccessfully => 'بینر کامیابی سے اپڈیٹ کر دیا گیا';

  @override
  String get bannerDeletedSuccessfully => 'بینر کامیابی سے حذف کر دیا گیا';

  @override
  String get confirmDelete => 'حذف کرنے کی تصدیق کریں';

  @override
  String get deleteBannerConfirmation => 'کیا آپ واقعی اس بینر کو حذف کرنا چاہتے ہیں؟';

  @override
  String get selectUsersFirst => 'براہ کرم کم از کم ایک صارف منتخب کریں';

  @override
  String get uploadingImage => 'تصویر اپلوڈ ہو رہی ہے...';

  @override
  String get savedDiscounts => 'محفوظ شدہ ڈسکاؤنٹس';

  @override
  String get use => 'استعمال کریں';

  @override
  String get noSavedDiscountCodes => 'کوئی محفوظ شدہ ڈسکاؤنٹ کوڈز نہیں';

  @override
  String get savedDiscountCodes => 'محفوظ شدہ ڈسکاؤنٹ کوڈز';

  @override
  String get discountOffers => 'دستیاب ڈسکاؤنٹس';

  @override
  String get discountAndPromotionCodes => 'ڈسکاؤنٹس اور پروموشنز';

  @override
  String get enterDiscountCode => 'ڈسکاؤنٹ کوڈ درج کریں';

  @override
  String get enterValidDiscountCode => 'براہ کرم درست ڈسکاؤنٹ کوڈ درج کریں';

  @override
  String get apply => 'لاگو کریں';

  @override
  String minOrderAmount(String amount) {
    return 'کم از کم آرڈر کی رقم: $amount';
  }

  @override
  String currency(String amount) {
    return '₺$amount';
  }

  @override
  String get noDiscountsAvailable => 'کوئی ڈسکاؤنٹس دستیاب نہیں';

  @override
  String get newDiscount => 'نیا ڈسکاؤنٹ!';

  @override
  String get discountCodeAvailable => 'ایک نیا ڈسکاؤنٹ کوڈ دستیاب ہے';

  @override
  String get discountSaved => 'ڈسکاؤنٹ کوڈ کامیابی سے محفوظ کر دیا گیا';

  @override
  String get saveDiscount => 'ڈسکاؤنٹ محفوظ کریں';

  @override
  String get myDiscounts => 'میرے ڈسکاؤنٹس';

  @override
  String get noDiscounts => 'کوئی ڈسکاؤنٹ کوڈز دستیاب نہیں';

  @override
  String validUntil(String date) {
    return '$date تک درست';
  }

  @override
  String get discountExpired => 'ختم ہو گیا';

  @override
  String get discountUsed => 'استعمال کیا گیا';

  @override
  String get wheelManagement => 'وہیل مینجمنٹ';

  @override
  String get wheelItemsDescription => 'ڈسکاؤنٹ وہیل آئٹمز اور ان کی احتمالات کو مینج کریں';

  @override
  String get probability => 'احتمال';

  @override
  String get addNewDiscount => 'نیا ڈسکاؤنٹ شامل کریں';

  @override
  String get discountValue => 'ڈسکاؤنٹ کی قیمت';

  @override
  String get pleaseEnterValue => 'براہ کرم قیمت درج کریں';

  @override
  String get enterValidNumber => 'براہ کرم 1 سے 100 کے درمیان درست نمبر درج کریں';

  @override
  String get congratulations => 'مبارک ہو!';

  @override
  String get betterLuckNextTime => 'اگلی بار کوشش کریں!';

  @override
  String get youWonDiscount => 'آپ نے جیت لیا';

  @override
  String get settingsSaved => 'ترتیبات کامیابی سے محفوظ کر دی گئیں';

  @override
  String get comeBackNextWeek => 'اگلے ہفتے دوبارہ آئیں!';

  @override
  String get spinning => 'گھوم رہا ہے...';

  @override
  String get spinTheWheel => 'وہیل گھمائیں!';

  @override
  String get mostViewed => 'سب سے زیادہ دیکھی جانے والی پروڈکٹس';

  @override
  String get country => 'ملک';

  @override
  String get selectCountry => 'ملک منتخب کریں';

  @override
  String get pleaseSelectCountry => 'براہ کرم ملک منتخب کریں';

  @override
  String get homepageLayout => 'ہوم پیج لے آؤٹ';

  @override
  String get cashbackReversal => 'Cashback Reversal';

  @override
  String get cardHolder => 'کارڈ ہولڈر';
}
