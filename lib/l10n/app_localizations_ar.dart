// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'قطع غيار كمبيوتر الفردوس';

  @override
  String get welcome => 'مرحباً';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get signIn => 'تسجيل';

  @override
  String get register => 'تسجيل';

  @override
  String get guest => 'ضيف';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get notAMember => 'لست عضواً؟';

  @override
  String get alreadyHaveAccount => 'هل لديك حساب بالفعل؟';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get home => 'المنزل';

  @override
  String get favorites => 'المفضلة';

  @override
  String get cart => 'السلة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get turkish => 'التركية';

  @override
  String get arabic => 'العربية';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get specialMode => 'الوضع الخاص';

  @override
  String get addToCart => 'أضف إلى السلة';

  @override
  String get outOfStock => 'نفذ من المخزون';

  @override
  String get removeFromFavorites => 'إزالة من المفضلة';

  @override
  String get addedToFavorites => 'تمت الإضافة إلى المفضلة';

  @override
  String get removedFromFavorites => 'تمت الإزالة من المفضلة';

  @override
  String get searchProducts => 'البحث عن المنتجات';

  @override
  String get categories => 'الفئات';

  @override
  String get allCategories => 'جميع الفئات';

  @override
  String get bestDeals => 'أفضل العروض';

  @override
  String products(int count) {
    return '$count منتج';
  }

  @override
  String get productQuantity => 'الكمية';

  @override
  String get noProductsFound => 'لم يتم العثور على منتجات';

  @override
  String get tryDifferentSearch => 'جرب البحث بكلمة مختلفة';

  @override
  String get tryDifferentCategory => 'جرب اختيار فئة مختلفة';

  @override
  String get viewCart => 'عرض السلة';

  @override
  String addedToCart(String productName) {
    return 'تمت إضافة $productName إلى السلة';
  }

  @override
  String get errorAddingToCart => 'فشل في إضافة المنتج إلى السلة';

  @override
  String get pleaseSignIn => 'يرجى تسجيل الدخول للمتابعة';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get name => 'الاسم';

  @override
  String get surname => 'اللقب';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get accountSettings => 'إعدادات الحساب';

  @override
  String get myAddresses => 'عناويني';

  @override
  String get addNewAddress => 'إضافة عنوان جديد';

  @override
  String get hello => 'مرحباً';

  @override
  String get yourAddresses => 'عناوينك';

  @override
  String get noAddressesFound => 'لم يتم العثور على عناوين.';

  @override
  String get recipientInfo => 'معلومات المستلم';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get lastName => 'اسم العائلة';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get addressType => 'نوع العنوان';

  @override
  String get addressDetails => 'تفاصيل العنوان';

  @override
  String get streetAvenue => 'الشارع / الجادة';

  @override
  String get neighborhood => 'الحي';

  @override
  String get buildingNo => 'رقم المبنى';

  @override
  String get apartmentName => 'اسم العمارة';

  @override
  String get floorNo => 'رقم الطابق';

  @override
  String get doorNo => 'رقم الشقة';

  @override
  String get city => 'المدينة';

  @override
  String get addressLabel => 'تسمية العنوان';

  @override
  String get addressLabelHint => 'مثال: المنزل، العمل، إلخ.';

  @override
  String get saveAddress => 'حفظ العنوان';

  @override
  String get savingAddress => 'جاري حفظ العنوان...';

  @override
  String get addressSaved => 'تم حفظ العنوان بنجاح';

  @override
  String get userNotLoggedIn => 'المستخدم غير مسجل الدخول.';

  @override
  String errorSavingAddress(String error) {
    return 'خطأ في حفظ العنوان: $error';
  }

  @override
  String get fillAllFields => 'يرجى ملء جميع الحقول';

  @override
  String get pleaseEnterFirstName => 'يرجى إدخال الاسم الأول';

  @override
  String get pleaseEnterLastName => 'يرجى إدخال اسم العائلة';

  @override
  String get pleaseEnterPhoneNumber => 'يرجى إدخال رقم الهاتف';

  @override
  String get invalidPhoneNumber => 'يرجى إدخال رقم هاتف صحيح';

  @override
  String get pleaseEnterStreetName => 'يرجى إدخال اسم الشارع';

  @override
  String get pleaseEnterNeighborhood => 'يرجى إدخال اسم الحي';

  @override
  String get required => 'مطلوب';

  @override
  String get pleaseEnterAddressLabel => 'يرجى إدخال تسمية العنوان';

  @override
  String get selectCity => 'اختر المدينة';

  @override
  String get pleaseSelectCity => 'يرجى اختيار مدينة';

  @override
  String get work => 'العمل';

  @override
  String get delete => 'حذف';

  @override
  String get setAsDefault => 'تعيين كافتراضي';

  @override
  String get myOrders => 'طلباتي';

  @override
  String get myWallet => 'محفظتي';

  @override
  String get appearance => 'المظهر';

  @override
  String get adminPanel => 'لوحة الإدارة';

  @override
  String get referralCode => 'رمز الإحالة الخاص بك';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get changeProfilePicture => 'تغيير صورة الملف الشخصي';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get addFromUrl => 'إضافة من رابط';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get enterImageUrl => 'أدخل رابط الصورة';

  @override
  String get add => 'إضافة';

  @override
  String get sort => 'ترتيب';

  @override
  String get priceLowToHigh => 'السعر: من الأقل إلى الأعلى';

  @override
  String get priceHighToLow => 'السعر: من الأعلى إلى الأقل';

  @override
  String get nameAToZ => 'الاسم: من أ إلى ي';

  @override
  String get nameZToA => 'الاسم: من ي إلى أ';

  @override
  String get specialOffers => 'عروض خاصة';

  @override
  String get specialOffersDescription => 'خصم يصل إلى 20% على المنتجات المختارة';

  @override
  String get shopNow => 'تسوق الآن';

  @override
  String get authentication => 'المصادقة';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get addYourName => 'أضف اسمك';

  @override
  String get admin => 'المدير';

  @override
  String get guestUser => 'مستخدم زائر';

  @override
  String get signInToAccess => 'سجل الدخول للوصول إلى جميع الميزات';

  @override
  String get yourReferralCode => 'رمز الإحالة الخاص بك';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get noFavoritesYet => 'لا توجد مفضلات حتى الآن';

  @override
  String get itemsYouFavorite => 'العناصر التي تفضلها ستظهر هنا';

  @override
  String get yourCart => 'سلة التسوق الخاصة بك';

  @override
  String get emptyCart => 'سلة التسوق فارغة';

  @override
  String get addItemsToCheckout => 'أضف عناصر إلى سلة التسوق للدفع';

  @override
  String get clearCart => 'تفريغ السلة';

  @override
  String get clearCartConfirmation => 'هل أنت متأكد من إزالة جميع العناصر؟';

  @override
  String get discountCode => 'رمز الخصم';

  @override
  String get enterCode => 'أدخل الرمز';

  @override
  String get apply => 'تطبيق';

  @override
  String discountApplied(String code) {
    return 'تم تطبيق الخصم: $code';
  }

  @override
  String percentOff(int percent) {
    return 'خصم $percent%';
  }

  @override
  String get invalidDiscountCode => 'رمز خصم غير صالح أو منتهي الصلاحية';

  @override
  String get notApplicableDiscount => 'هذا الرمز غير قابل للتطبيق على العناصر في سلة التسوق';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String discount(int percent) {
    return 'الخصم ($percent%)';
  }

  @override
  String get total => 'المجموع';

  @override
  String totalAmount(String amount) {
    return 'المجموع: $amount ريال';
  }

  @override
  String get checkout => 'إتمام الشراء';

  @override
  String get paymentSuccessful => 'تم الدفع بنجاح!';

  @override
  String amountPaid(String amount) {
    return 'المبلغ المدفوع: $amount ريال';
  }

  @override
  String get orderPlaced => 'تم تقديم طلبك بنجاح';

  @override
  String orderId(String id) {
    return 'رقم الطلب: $id';
  }

  @override
  String get viewOrders => 'عرض الطلبات';

  @override
  String get continueShopping => 'مواصلة التسوق';

  @override
  String get cardExpired => 'البطاقة منتهية الصلاحية';

  @override
  String get pleaseSelectAddress => 'يرجى اختيار عنوان التوصيل';

  @override
  String get pleaseSelectCard => 'يرجى اختيار بطاقة';

  @override
  String get deliveryAddress => 'عنوان التوصيل';

  @override
  String get addNew => 'إضافة جديد';

  @override
  String get noSavedAddresses => 'لا توجد عناوين محفوظة';

  @override
  String get creditCards => 'بطاقات الائتمان';

  @override
  String get noSavedCards => 'لا توجد بطاقات محفوظة';

  @override
  String get payWithCreditCard => 'الدفع ببطاقة الائتمان';

  @override
  String get payWithWallet => 'الدفع بالمحفظة';

  @override
  String availableBalance(String amount) {
    return 'الرصيد المتاح: $amount ريال';
  }

  @override
  String get insufficientBalance => 'رصيد غير كافٍ';

  @override
  String addMoreForFreeShipping(String amount) {
    return 'أضف $amount ريال للحصول على شحن مجاني';
  }

  @override
  String get freeShippingOver => 'شحن مجاني للطلبات فوق 10,000 ريال';

  @override
  String get free => 'مجاناً';

  @override
  String get shipping => 'الشحن';

  @override
  String get placeOrder => 'تأكيد الطلب';

  @override
  String get address => 'العنوان';

  @override
  String get payment => 'الدفع';

  @override
  String get confirm => 'التأكيد';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get addNewCard => 'إضافة بطاقة جديدة';

  @override
  String get orderSummary => 'ملخص الطلب';

  @override
  String get cardNumber => 'رقم البطاقة';

  @override
  String get cardNumberHint => 'رقم البطاقة';

  @override
  String get cardHolderName => 'اسم حامل البطاقة';

  @override
  String get cardHolderHint => 'اسم حامل البطاقة';

  @override
  String get expiryDate => 'تاريخ الانتهاء';

  @override
  String get expiryDateHint => 'شهر/سنة';

  @override
  String get cardIsExpired => 'البطاقة منتهية الصلاحية';

  @override
  String get cvv => 'رمز التحقق';

  @override
  String get cvvHint => '3 أرقام';

  @override
  String get deleteCard => 'حذف البطاقة';

  @override
  String get deleteCardConfirmation => 'هل أنت متأكد من حذف هذه البطاقة؟';

  @override
  String get defaultCard => 'البطاقة الافتراضية';

  @override
  String expires(String date) {
    return 'تنتهي الصلاحية: $date';
  }

  @override
  String get ok => 'موافق';

  @override
  String get cannotReorder => 'لا يمكن إعادة الطلب';

  @override
  String outOfStockItems(String items) {
    return 'المنتجات التالية غير متوفرة في المخزون:\n\n• $items';
  }

  @override
  String insufficientStockItems(String items) {
    return 'الكمية المتوفرة غير كافية للمنتجات التالية:\n\n• $items';
  }

  @override
  String get myFavorites => 'المفضلة';

  @override
  String get refresh => 'تحديث';

  @override
  String get exploreProducts => 'استكشف المنتجات';

  @override
  String get failedToRemove => 'فشل في الإزالة';

  @override
  String get pleaseLoginToAdd => 'يرجى تسجيل الدخول للإضافة إلى المفضلة';

  @override
  String get failedToAddToCart => 'فشل في الإضافة إلى السلة';

  @override
  String get adminDashboard => 'لوحة تحكم المسؤول';

  @override
  String get adminControls => 'أدوات المسؤول';

  @override
  String get userManagement => 'إدارة المستخدمين';

  @override
  String get viewAndManageUsers => 'عرض وإدارة المستخدمين';

  @override
  String get productManagement => 'إدارة المنتجات';

  @override
  String get manageProducts => 'إدارة المنتجات';

  @override
  String get orderManagement => 'إدارة الطلبات';

  @override
  String get viewAndProcessOrders => 'عرض ومعالجة الطلبات';

  @override
  String get currentBalance => 'الرصيد الحالي';

  @override
  String get cashbackInfo => 'احصل على استرداد نقدي يصل إلى 2% على كل عملية شراء';

  @override
  String get addMoney => 'إضافة رصيد';

  @override
  String get transactionHistory => 'سجل المعاملات';

  @override
  String transactionsCount(int count) {
    return '$count معاملة';
  }

  @override
  String get noTransactions => 'لا توجد معاملات حتى الآن';

  @override
  String get transactionsWillAppear => 'ستظهر معاملاتك هنا';

  @override
  String get moneyAdded => 'تمت إضافة المال';

  @override
  String errorAddingBalance(String error) {
    return 'خطأ في إضافة الرصيد';
  }

  @override
  String get addMoneyToWallet => 'إضافة رصيد إلى المحفظة';

  @override
  String get amount => 'المبلغ';

  @override
  String get selectCard => 'اختر البطاقة';

  @override
  String get useCard => 'استخدام البطاقة المحفوظة';

  @override
  String get enterValidAmount => 'يرجى إدخال مبلغ صحيح';

  @override
  String get fillCardDetails => 'يرجى ملء تفاصيل البطاقة';

  @override
  String get cardNumberError => 'يجب أن يتكون رقم البطاقة من 16 رقماً';

  @override
  String get invalidCardNumber => 'رقم البطاقة غير صالح';

  @override
  String get onlyLettersAllowed => 'يُسمح بالحروف فقط';

  @override
  String get useMMYYFormat => 'استخدم تنسيق شش/سس';

  @override
  String get invalidCVV => 'رمز CVV غير صالح';

  @override
  String get amountMustBeGreater => 'يجب أن يكون المبلغ أكبر من 0';

  @override
  String get maximumAmount => 'الحد الأقصى للمبلغ هو 10,000 ريال';

  @override
  String get invalidAmount => 'مبلغ غير صالح';

  @override
  String get cardSaved => 'تم حفظ البطاقة بنجاح';

  @override
  String errorSavingCard(String error) {
    return 'خطأ في حفظ البطاقة: $error';
  }

  @override
  String get transactionDetails => 'تفاصيل المعاملة';

  @override
  String get type => 'النوع';

  @override
  String get deposit => 'إيداع';

  @override
  String get purchase => 'شراء';

  @override
  String get date => 'التاريخ';

  @override
  String get status => 'الحالة';

  @override
  String get method => 'الطريقة';

  @override
  String get reference => 'المرجع';

  @override
  String get description => 'الوصف';

  @override
  String get orderHistory => 'سجل الطلبات';

  @override
  String get yourOrders => 'طلباتك';

  @override
  String ordersCount(int count) {
    return '$count طلب';
  }

  @override
  String get filterByStatus => 'تصفية حسب الحالة';

  @override
  String get allOrders => 'الكل';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get preparing => 'قيد التحضير';

  @override
  String get onDelivery => 'قيد التوصيل';

  @override
  String get delivered => 'تم التوصيل';

  @override
  String get cancelled => 'ملغي';

  @override
  String noOrdersWithStatus(String status) {
    return 'لا توجد طلبات بحالة $status';
  }

  @override
  String get tryDifferentFilter => 'جرب تصفية مختلفة';

  @override
  String orderNumber(String number) {
    return 'رقم الطلب';
  }

  @override
  String get items => 'المنتجات';

  @override
  String quantity(int count, String price) {
    return 'الكمية';
  }

  @override
  String itemTotal(String amount) {
    return 'إجمالي العناصر';
  }

  @override
  String get trackingNumber => 'رقم التتبع';

  @override
  String get shippingAddress => 'عنوان الشحن';

  @override
  String get noAddressProvided => 'لم يتم تقديم عنوان';

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get reorder => 'إعادة الطلب';

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get confirmCancelOrder => 'هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟';

  @override
  String get orderCancelled => 'تم إلغاء الطلب';

  @override
  String failedToCancelOrder(String error) {
    return 'فشل إلغاء الطلب: $error';
  }

  @override
  String get rateProduct => 'تقييم المنتج';

  @override
  String get alreadyReviewed => 'لقد قمت بتقييم هذا المنتج مسبقاً';

  @override
  String get canReviewAfterDelivery => 'يمكنك تقييم المنتج بعد استلامه';

  @override
  String get selectRating => 'اختر التقييم';

  @override
  String get poor => 'سيء';

  @override
  String get fair => 'مقبول';

  @override
  String get good => 'جيد';

  @override
  String get veryGood => 'جيد جداً';

  @override
  String get excellent => 'ممتاز';

  @override
  String get writeReview => 'كتابة تقييم';

  @override
  String get submitReview => 'إرسال التقييم';

  @override
  String get thankYouForReview => 'شكراً لتقييمك';

  @override
  String get failedToSubmitReview => 'فشل إرسال التقييم';

  @override
  String get productNoLongerAvailable => 'هذا المنتج لم يعد متوفراً';

  @override
  String get errorCheckingAvailability => 'حدث خطأ أثناء التحقق من المخزون';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get noOrdersYet => 'لا توجد طلبات حتى الآن';

  @override
  String get yourOrderHistoryWillAppearHere => 'سيظهر سجل طلباتك هنا';

  @override
  String get startShopping => 'ابدأ التسوق';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get orderPrefix => 'طلب #';

  @override
  String get itemsLabel => 'العناصر';

  @override
  String get quantityPrefix => 'الكمية:';

  @override
  String get itemTotalPrefix => 'المجموع:';

  @override
  String get shippingAddressLabel => 'عنوان التوصيل';

  @override
  String get defaultShippingAddress => 'عنوان التوصيل الافتراضي';

  @override
  String get paymentMethodLabel => 'طريقة الدفع';

  @override
  String get cardPayment => 'الدفع بالبطاقة';

  @override
  String get reorderButton => 'إعادة الطلب';

  @override
  String get dateFormat => 'dd/MM/yyyy HH:mm';

  @override
  String totalPrefix(String amount) {
    return 'الإجمالي:';
  }

  @override
  String get productNotFound => 'المنتج غير موجود';

  @override
  String inStock(int count) {
    return 'متوفر في المخزون: $count قطعة';
  }

  @override
  String addedToCartMessage(String name, int quantity) {
    return 'تمت الإضافة إلى السلة';
  }

  @override
  String get mustBeLoggedIn => 'يجب تسجيل الدخول';

  @override
  String cannotAddMoreThanStock(int count) {
    return 'لا يمكن إضافة أكثر من المخزون المتوفر ($count)';
  }

  @override
  String get productDescription => 'وصف المنتج';

  @override
  String get specifications => 'المواصفات';

  @override
  String get customerReviews => 'تقييمات العملاء';

  @override
  String get noReviewsYet => 'لا توجد تقييمات حتى الآن';

  @override
  String get couldNotLoadReviews => 'تعذر تحميل التقييمات';

  @override
  String get anonymous => 'مجهول';

  @override
  String get failedToUpdateFavorites => 'فشل في تحديث المفضلة';

  @override
  String get pleaseLoginToAddFavorites => 'الرجاء تسجيل الدخول لإضافة المفضلة';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String hoursAgo(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String get categoryAll => 'جميع الفئات';

  @override
  String get categoryCPU => 'المعالجات';

  @override
  String get categoryGPU => 'بطاقات الرسومات';

  @override
  String get categoryRAM => 'الذاكرة';

  @override
  String get categoryMotherboard => 'اللوحات الأم';

  @override
  String get categoryStorage => 'التخزين';

  @override
  String get categoryCase => 'الهياكل';

  @override
  String get categoryPSU => 'وحدات الطاقة';

  @override
  String get categoryPreBuilt => 'أجهزة جاهزة';

  @override
  String get aiChatTitle => 'المساعد الذكي';

  @override
  String get askMeAnything => 'اسألني أي شيء';

  @override
  String get howCanIHelp => 'كيف يمكنني المساعدة؟';

  @override
  String get iNeedAssistance => 'أحتاج إلى مساعدة';

  @override
  String get recommendCheapestPC => 'أوصي بأرخص كمبيوتر';

  @override
  String get lookingForGamingPC => 'أبحث عن كمبيوتر للألعاب';

  @override
  String get addNewProduct => 'إضافة منتج جديد';

  @override
  String get updateProduct => 'تحديث المنتج';

  @override
  String get productDetails => 'تفاصيل المنتج';

  @override
  String get productName => 'اسم المنتج';

  @override
  String get productPrice => 'سعر المنتج';

  @override
  String get productStock => 'المخزون المتوفر';

  @override
  String get productCategory => 'فئة المنتج';

  @override
  String get mainImage => 'الصورة الرئيسية';

  @override
  String get additionalImages => 'صور إضافية';

  @override
  String get generateAIDescription => 'توليد وصف بالذكاء الاصطناعي';

  @override
  String get pleaseEnterProductName => 'الرجاء إدخال اسم المنتج أولاً';

  @override
  String errorGeneratingDescription(String error) {
    return 'خطأ في إنشاء الوصف';
  }

  @override
  String get searchProduct => 'البحث عن منتج';

  @override
  String get selectProductToUpdate => 'اختر منتجاً للتحديث';

  @override
  String get imageRequired => 'الصورة مطلوبة';

  @override
  String get productUpdated => 'تم تحديث المنتج';

  @override
  String errorUpdatingProduct(String error) {
    return 'خطأ في تحديث المنتج';
  }

  @override
  String get onVacation => 'أنا في إجازة حالياً!! حاول التحدث معي لاحقاً :P';

  @override
  String get adminOnly => 'يمكن للمسؤولين فقط إضافة المنتجات';

  @override
  String get price => 'السعر';

  @override
  String get stock => 'المخزون';

  @override
  String get selectCategory => 'اختر الفئة';

  @override
  String get update => 'تحديث';

  @override
  String stockRemaining(int stock) {
    return 'باقي $stock قطعة';
  }

  @override
  String updateStock(String productName) {
    return 'تحديث المخزون لـ $productName';
  }

  @override
  String get newStockAmount => 'كمية المخزون الجديدة';

  @override
  String get enterNewStockAmount => 'أدخل كمية المخزون الجديدة';

  @override
  String get pleaseEnterValidNumber => 'الرجاء إدخال رقم صحيح';

  @override
  String get checkingStockLevels => 'جاري التحقق من مستويات المخزون...';

  @override
  String get lowStockAlerts => 'تنبيهات المخزون المنخفض';

  @override
  String get noLowStockProducts => 'لا توجد منتجات بمخزون منخفض';

  @override
  String lowStockProductsCount(int count) {
    return '$count منتج بمخزون منخفض';
  }

  @override
  String get promoCodes => 'رموز الخصم';

  @override
  String get createPromocodesAndDiscounts => 'إنشاء رموز وخصومات ترويجية';

  @override
  String get salesStatistics => 'إحصائيات المبيعات';

  @override
  String get viewSalesAnalytics => 'عرض تحليلات ورسوم بيانية للمبيعات';

  @override
  String get assistantTommySettings => 'إعدادات المساعد تومي';

  @override
  String get configureTommyAvailability => 'تكوين توفر تومي';

  @override
  String get enableAssistantTommy => 'تفعيل المساعد تومي';

  @override
  String get tommyAvailable => 'تومي متاح حالياً';

  @override
  String get tommyDisabled => 'تومي معطل حالياً';

  @override
  String get hideTommy => 'إخفاء تومي';

  @override
  String get allEyesOnTommy => 'كل العيون على تومي !';

  @override
  String get tommyHiding => 'تومي مختبئ في الخزانة !';

  @override
  String get close => 'إغلاق';

  @override
  String get photoUploader => 'رفع الصور';

  @override
  String get configureAppSettings => 'تكوين إعدادات التطبيق';

  @override
  String ratingCount(int count) {
    return '$count تقييم';
  }

  @override
  String get reportBug => 'الإبلاغ عن خطأ';

  @override
  String get bugReports => 'تقارير الأخطاء';

  @override
  String get viewAndManageBugReports => 'عرض وإدارة تقارير الأخطاء';

  @override
  String get bugTitle => 'عنوان الخطأ';

  @override
  String get enterBugTitle => 'أدخل عنواناً للخطأ';

  @override
  String get bugDescription => 'وصف الخطأ';

  @override
  String get describeBugInDetail => 'يرجى وصف الخطأ بالتفصيل';

  @override
  String get pleaseEnterBugDetails => 'يرجى إدخال العنوان والوصف';

  @override
  String get bugReportSubmitted => 'تم إرسال تقرير الخطأ بنجاح';

  @override
  String get errorSubmittingBugReport => 'حدث خطأ أثناء إرسال التقرير';

  @override
  String get reportedBy => 'تم الإبلاغ بواسطة';

  @override
  String get reportedOn => 'تاريخ الإبلاغ';

  @override
  String get inProgress => 'قيد المعالجة';

  @override
  String get resolved => 'تم الحل';

  @override
  String get dismissed => 'تم الرفض';

  @override
  String get markAsInProgress => 'تحديد كقيد المعالجة';

  @override
  String get markAsResolved => 'تحديد كتم الحل';

  @override
  String get dismiss => 'رفض';

  @override
  String get noBugReports => 'لا توجد تقارير أخطاء';

  @override
  String get requestRefund => 'Request Refund';

  @override
  String get confirmRefundRequest => 'Are you sure you want to request a refund for this order?';

  @override
  String get orderTotal => 'إجمالي الطلب';

  @override
  String get refundRequestSubmitted => 'Refund request submitted successfully';

  @override
  String failedToRequestRefund(String error) {
    return 'Failed to request refund: $error';
  }

  @override
  String get refundRequested => 'Refund Requested';

  @override
  String get refunded => 'Refunded';

  @override
  String get processRefund => 'Process Refund';

  @override
  String get refundProcessed => 'Refund processed successfully';

  @override
  String failedToProcessRefund(String error) {
    return 'Failed to process refund: $error';
  }
}
