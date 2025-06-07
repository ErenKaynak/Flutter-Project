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
  String get off => 'خصم';

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
  String get loading => 'جارٍ التحميل...';

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
  String get enterCode => 'Enter code';

  @override
  String discountApplied(Object code) {
    return 'Discount Applied: $code';
  }

  @override
  String percentOff(int percent) {
    return '$percent% off';
  }

  @override
  String get invalidDiscountCode => 'رمز الخصم غير صالح أو منتهي الصلاحية';

  @override
  String get notApplicableDiscount => 'This code is not applicable to items in your cart';

  @override
  String get subtotal => 'Subtotal';

  @override
  String discount(int percent) {
    return 'Discount ($percent%)';
  }

  @override
  String get total => 'Total';

  @override
  String totalAmount(String amount) {
    return 'Total: ₺$amount';
  }

  @override
  String get checkout => 'CHECKOUT';

  @override
  String get paymentSuccessful => 'Payment Successful!';

  @override
  String amountPaid(String amount) {
    return 'Amount Paid: ₺$amount';
  }

  @override
  String get orderPlaced => 'Your order has been placed successfully.';

  @override
  String orderId(String id) {
    return 'Order ID: $id';
  }

  @override
  String get viewOrders => 'VIEW ORDERS';

  @override
  String get continueShopping => 'CONTINUE SHOPPING';

  @override
  String get cardExpired => 'Your card is expired, please try again';

  @override
  String get pleaseSelectAddress => 'Please select an address';

  @override
  String get pleaseSelectCard => 'Please select a credit card';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get addNew => 'Add New';

  @override
  String get noSavedAddresses => 'No saved addresses';

  @override
  String get creditCards => 'Credit Cards';

  @override
  String get noSavedCards => 'No saved cards';

  @override
  String get payWithCreditCard => 'Pay with credit card';

  @override
  String get payWithWallet => 'Pay with Wallet';

  @override
  String availableBalance(String amount) {
    return 'Available Balance: ₺$amount';
  }

  @override
  String get insufficientBalance => 'Insufficient balance';

  @override
  String addMoreForFreeShipping(String amount) {
    return 'Add ₺$amount more to get free shipping!';
  }

  @override
  String get freeShippingOver => 'Free over ₺10,000';

  @override
  String get free => 'FREE';

  @override
  String get shipping => 'Shipping';

  @override
  String get placeOrder => 'PLACE ORDER';

  @override
  String get address => 'Address';

  @override
  String get payment => 'Payment';

  @override
  String get confirm => 'Confirm';

  @override
  String get paymentMethod => 'Payment Method:';

  @override
  String get addNewCard => 'Add New Card';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get cardNumber => 'Card Number';

  @override
  String get cardNumberHint => '1234 5678 9012 3456';

  @override
  String get cardHolderName => 'Card Holder Name';

  @override
  String get cardHolderHint => 'JOHN DOE';

  @override
  String get expiryDate => 'Expiry Date';

  @override
  String get expiryDateHint => 'MM/YY';

  @override
  String get cardIsExpired => 'Card is expired';

  @override
  String get cvv => 'CVV';

  @override
  String get cvvHint => '123';

  @override
  String get deleteCard => 'Delete Card';

  @override
  String get deleteCardConfirmation => 'Are you sure you want to delete this card?';

  @override
  String get defaultCard => 'Default Card';

  @override
  String expires(String date) {
    return 'Expires: $date';
  }

  @override
  String get ok => 'OK';

  @override
  String get cannotReorder => 'Cannot Reorder';

  @override
  String outOfStockItems(String items) {
    return 'The following items are out of stock:\n• $items';
  }

  @override
  String insufficientStockItems(String items) {
    return 'Insufficient stock for:\n• $items';
  }

  @override
  String get myFavorites => 'My Favorites';

  @override
  String get refresh => 'Refresh';

  @override
  String get exploreProducts => 'Explore Products';

  @override
  String get failedToRemove => 'Failed to remove from favorites';

  @override
  String get pleaseLoginToAdd => 'يرجى تسجيل الدخول للإضافة إلى المفضلة';

  @override
  String get failedToAddToCart => 'Failed to add item to cart';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get adminControls => 'Admin Controls';

  @override
  String get userManagement => 'User Management';

  @override
  String get viewAndManageUsers => 'View and manage users';

  @override
  String get productManagement => 'Product Management';

  @override
  String get manageProducts => 'Manage products';

  @override
  String get orderManagement => 'Order Management';

  @override
  String get viewAndProcessOrders => 'View and process orders';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get cashbackInfo => '1% Cashback on all purchases';

  @override
  String get addMoney => 'Add Money';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String transactionsCount(int count) {
    return '$count transactions';
  }

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get transactionsWillAppear => 'Your transaction history will appear here';

  @override
  String get moneyAdded => 'Money added successfully';

  @override
  String errorAddingBalance(String error) {
    return 'Error adding balance: $error';
  }

  @override
  String get addMoneyToWallet => 'Add Money to Wallet';

  @override
  String get amount => 'Amount';

  @override
  String get selectCard => 'Select Card';

  @override
  String get useCard => 'Use Saved Card';

  @override
  String get enterValidAmount => 'Please enter a valid amount';

  @override
  String get fillCardDetails => 'Please fill all card details correctly';

  @override
  String get cardNumberError => 'Card number must be 16 digits';

  @override
  String get invalidCardNumber => 'Invalid card number';

  @override
  String get onlyLettersAllowed => 'Only letters allowed';

  @override
  String get useMMYYFormat => 'Use MM/YY format';

  @override
  String get invalidCVV => 'Invalid CVV';

  @override
  String get amountMustBeGreater => 'Amount must be greater than 0';

  @override
  String get maximumAmount => 'Maximum amount is ₺10,000';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get cardSaved => 'Card saved successfully';

  @override
  String errorSavingCard(String error) {
    return 'Error saving card: $error';
  }

  @override
  String get transactionDetails => 'Transaction Details';

  @override
  String get type => 'Type';

  @override
  String get deposit => 'Deposit';

  @override
  String get purchase => 'Purchase';

  @override
  String get date => 'Date';

  @override
  String get status => 'Status';

  @override
  String get method => 'Method';

  @override
  String get reference => 'Reference';

  @override
  String get description => 'Description';

  @override
  String get orderHistory => 'Order History';

  @override
  String get yourOrders => 'Your Orders';

  @override
  String ordersCount(int count) {
    return '$count orders';
  }

  @override
  String get filterByStatus => 'Filter by Status';

  @override
  String get allOrders => 'All';

  @override
  String get pending => 'Pending';

  @override
  String get preparing => 'Preparing';

  @override
  String get onDelivery => 'On Delivery';

  @override
  String get delivered => 'Delivered';

  @override
  String get cancelled => 'Cancelled';

  @override
  String noOrdersWithStatus(String status) {
    return 'No orders with \'$status\' status';
  }

  @override
  String get tryDifferentFilter => 'Try selecting a different filter';

  @override
  String orderNumber(String number) {
    return 'Order #$number';
  }

  @override
  String get items => 'Items:';

  @override
  String quantity(int count, String price) {
    return 'الكمية';
  }

  @override
  String itemTotal(String amount) {
    return 'Item Total: ₺$amount';
  }

  @override
  String get trackingNumber => 'Tracking Number:';

  @override
  String get shippingAddress => 'Shipping Address:';

  @override
  String get noAddressProvided => 'No address provided';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get reorder => 'Reorder';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get confirmCancelOrder => 'Are you sure you want to cancel this order?';

  @override
  String get orderCancelled => 'Order cancelled successfully';

  @override
  String failedToCancelOrder(String error) {
    return 'Failed to cancel order: $error';
  }

  @override
  String get rateProduct => 'Rate this product';

  @override
  String get alreadyReviewed => 'Already reviewed';

  @override
  String get canReviewAfterDelivery => 'Can review after delivery';

  @override
  String get selectRating => 'Select Rating';

  @override
  String get poor => 'Poor';

  @override
  String get fair => 'Fair';

  @override
  String get good => 'Good';

  @override
  String get veryGood => 'Very Good';

  @override
  String get excellent => 'Excellent';

  @override
  String get writeReview => 'Write your review (optional)';

  @override
  String get submitReview => 'Submit Review';

  @override
  String get thankYouForReview => 'Thank you for your review!';

  @override
  String get failedToSubmitReview => 'Failed to submit review';

  @override
  String get productNoLongerAvailable => 'Product is no longer available';

  @override
  String get errorCheckingAvailability => 'Error checking product availability. Please try again.';

  @override
  String get tryAgain => 'TRY AGAIN';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get yourOrderHistoryWillAppearHere => 'Your order history will appear here';

  @override
  String get startShopping => 'START SHOPPING';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get orderPrefix => 'Order #';

  @override
  String get itemsLabel => 'Items:';

  @override
  String get quantityPrefix => 'Qty:';

  @override
  String get itemTotalPrefix => 'Item Total:';

  @override
  String get shippingAddressLabel => 'Shipping Address:';

  @override
  String get defaultShippingAddress => 'Default Shipping Address';

  @override
  String get paymentMethodLabel => 'Payment Method:';

  @override
  String get cardPayment => 'Card';

  @override
  String get reorderButton => 'Reorder';

  @override
  String get dateFormat => 'MMM dd, yyyy - HH:mm';

  @override
  String totalPrefix(String amount) {
    return 'Total: ₺$amount';
  }

  @override
  String get productNotFound => 'المنتج غير موجود';

  @override
  String inStock(int count) {
    return 'متوفر في المخزون: $count قطعة';
  }

  @override
  String addedToCartMessage(String name, int quantity) {
    return '$name x$quantity added to cart';
  }

  @override
  String get mustBeLoggedIn => 'You must be logged in to add to cart';

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
  String get pleaseLoginToAddFavorites => 'Please log in to add favorites';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String hoursAgo(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String get categoryAll => 'All Categories';

  @override
  String get categoryCPU => 'CPUs';

  @override
  String get categoryGPU => 'GPUs';

  @override
  String get categoryRAM => 'RAM';

  @override
  String get categoryMotherboard => 'Motherboards';

  @override
  String get categoryStorage => 'Storage';

  @override
  String get categoryCase => 'Cases';

  @override
  String get categoryPSU => 'Power Supplies';

  @override
  String get categoryPreBuilt => 'Pre-Built PCs';

  @override
  String get aiChatTitle => 'Assistant Tommy';

  @override
  String get askMeAnything => 'Ask Me Anything...';

  @override
  String get howCanIHelp => 'How can I help you today?';

  @override
  String get iNeedAssistance => 'I need assistance';

  @override
  String get recommendCheapestPC => 'Recommend me the cheapest PC build';

  @override
  String get lookingForGamingPC => 'Looking for a gaming PC build';

  @override
  String get addNewProduct => 'Add New Product';

  @override
  String get updateProduct => 'Update Product';

  @override
  String get productDetails => 'Product Details';

  @override
  String get productName => 'Product Name';

  @override
  String get productPrice => 'Price';

  @override
  String get productStock => 'Stock';

  @override
  String get productCategory => 'Category';

  @override
  String get mainImage => 'Main Image';

  @override
  String get additionalImages => 'Additional Images';

  @override
  String get generateAIDescription => 'Generate AI Description';

  @override
  String get pleaseEnterProductName => 'Please enter product name first';

  @override
  String errorGeneratingDescription(String error) {
    return 'Error generating description: $error';
  }

  @override
  String get searchProduct => 'Search Product';

  @override
  String get selectProductToUpdate => 'Select Product to Update';

  @override
  String get imageRequired => 'Main image is required';

  @override
  String get productUpdated => 'Product updated successfully';

  @override
  String errorUpdatingProduct(String error) {
    return 'Error updating product: $error';
  }

  @override
  String get onVacation => 'I\'m currently on vacation!! Try to talk to me later :P';

  @override
  String get adminOnly => 'Only admin users can add products';

  @override
  String get price => 'Price';

  @override
  String get stock => 'Stock';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get update => 'Update';

  @override
  String stockRemaining(int stock) {
    return '$stock items remaining';
  }

  @override
  String updateStock(Object productName) {
    return 'Update Stock for $productName';
  }

  @override
  String get newStockAmount => 'New Stock Amount';

  @override
  String get enterNewStockAmount => 'Enter new stock amount';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number.';

  @override
  String get checkingStockLevels => 'Checking stock levels...';

  @override
  String get lowStockAlerts => 'Low Stock Alerts';

  @override
  String get noLowStockProducts => 'No low stock products.';

  @override
  String lowStockProductsCount(int count) {
    return '$count product(s) with low stock';
  }

  @override
  String get promoCodes => 'Promo Codes & Discounts';

  @override
  String get createPromocodesAndDiscounts => 'Create and manage promocodes and discounts.';

  @override
  String get salesStatistics => 'Sales Statistics';

  @override
  String get viewSalesAnalytics => 'View sales analytics.';

  @override
  String get assistantTommySettings => 'Assistant Tommy Settings';

  @override
  String get configureTommyAvailability => 'Configure Assistant Tommy availability.';

  @override
  String get enableAssistantTommy => 'Enable Assistant Tommy';

  @override
  String get tommyAvailable => 'Tommy is currently available';

  @override
  String get tommyDisabled => 'Tommy is currently disabled';

  @override
  String get hideTommy => 'Hide Tommy';

  @override
  String get allEyesOnTommy => 'All Eyes On Tommy !';

  @override
  String get tommyHiding => 'Tommy is hiding in the closet !';

  @override
  String get close => 'Close';

  @override
  String get photoUploader => 'Photo Uploader';

  @override
  String get configureAppSettings => 'Configure application settings.';

  @override
  String ratingCount(int count) {
    return '$count ratings';
  }

  @override
  String get reportBug => 'Report Bug';

  @override
  String get bugReports => 'Bug Reports';

  @override
  String get viewAndManageBugReports => 'View and manage bug reports.';

  @override
  String get bugTitle => 'Bug Title';

  @override
  String get enterBugTitle => 'Enter a title for the bug';

  @override
  String get bugDescription => 'Bug Description';

  @override
  String get describeBugInDetail => 'Please describe the bug in detail';

  @override
  String get pleaseEnterBugDetails => 'Please enter both title and description';

  @override
  String get bugReportSubmitted => 'Bug report submitted successfully';

  @override
  String get errorSubmittingBugReport => 'Error submitting bug report';

  @override
  String get reportedBy => 'Reported by';

  @override
  String get reportedOn => 'Reported on';

  @override
  String get inProgress => 'In Progress';

  @override
  String get resolved => 'Resolved';

  @override
  String get dismissed => 'Dismissed';

  @override
  String get markAsInProgress => 'Mark as In Progress';

  @override
  String get markAsResolved => 'Mark as Resolved';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get noBugReports => 'No bug reports found';

  @override
  String get requestRefund => 'Request Refund';

  @override
  String get confirmRefundRequest => 'Are you sure you want to request a refund for this order?';

  @override
  String get orderTotal => 'Order Total';

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

  @override
  String get setupWalletPin => 'Setup Wallet PIN';

  @override
  String get createWalletPin => 'Create Wallet PIN';

  @override
  String get walletPinDescription => 'Create a 6-digit PIN to secure your wallet';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get useBiometrics => 'Use Biometrics';

  @override
  String get biometricsDescription => 'Use fingerprint or face recognition to access your wallet';

  @override
  String get setupPin => 'Setup PIN';

  @override
  String get verify => 'Verify';

  @override
  String get invalidPin => 'Invalid PIN';

  @override
  String get orLogInWith => 'Or Log in With';

  @override
  String get passwordRequirements => 'Password Requirements:';

  @override
  String get atLeast8Characters => 'At least 8 characters';

  @override
  String get maximum20Characters => 'Maximum 20 characters';

  @override
  String get oneUppercaseLetter => 'One uppercase letter';

  @override
  String get oneLowercaseLetter => 'One lowercase letter';

  @override
  String get oneSpecialCharacter => 'One special character';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get noNotificationsDesc => 'New notifications will appear here';

  @override
  String get clearAllNotifications => 'Clear all notifications';

  @override
  String get allNotificationsCleared => 'All notifications cleared';

  @override
  String get notificationDeleted => 'Notification deleted';

  @override
  String get welcomeNotification => 'Welcome!';

  @override
  String get welcomeNotificationDesc => 'Welcome to our store. We have great offers for you.';

  @override
  String get newProductNotification => 'New Product';

  @override
  String get newProductNotificationDesc => 'RTX 4090 is in stock! Check it out now.';

  @override
  String get discountNotification => 'Special Discount';

  @override
  String get discountNotificationDesc => '20% off on all RAM products!';

  @override
  String daysAgo(int days, Object count) {
    return '$count days ago';
  }

  @override
  String get notificationManagement => 'Notification Management';

  @override
  String get newNotification => 'Create New Notification';

  @override
  String get notificationTitle => 'Notification Title';

  @override
  String get notificationMessage => 'Notification Message';

  @override
  String get sendToAllUsers => 'Send to All Users';

  @override
  String get sendNotification => 'Send Notification';

  @override
  String get notificationSent => 'Notification sent successfully';

  @override
  String notificationError(String error) {
    return 'Error occurred: $error';
  }

  @override
  String get pleaseEnterTitleAndMessage => 'Please enter title and message';

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
  String get savedDiscounts => 'Saved Discounts';

  @override
  String get use => 'Use';

  @override
  String get noSavedDiscountCodes => 'لا توجد رموز خصم محفوظة';

  @override
  String get savedDiscountCodes => 'رموز الخصم المحفوظة';

  @override
  String get discountOffers => 'Available Discounts';

  @override
  String get discountAndPromotionCodes => 'Discounts & Promotions';

  @override
  String get enterDiscountCode => 'أدخل رمز الخصم';

  @override
  String get enterValidDiscountCode => 'الرجاء إدخال رمز خصم صالح';

  @override
  String get apply => 'Apply';

  @override
  String minOrderAmount(String amount) {
    return 'Minimum order amount: $amount';
  }

  @override
  String currency(String amount) {
    return '$amount ₺';
  }

  @override
  String get noDiscountsAvailable => 'لا توجد خصومات متاحة';

  @override
  String get newDiscount => 'خصم جديد!';

  @override
  String get discountCodeAvailable => 'يتوفر رمز خصم جديد';

  @override
  String get discountSaved => 'تم حفظ رمز الخصم بنجاح';

  @override
  String get saveDiscount => 'حفظ الخصم';

  @override
  String get myDiscounts => 'خصوماتي';

  @override
  String get noDiscounts => 'لا توجد رموز خصم متاحة';

  @override
  String validUntil(String date) {
    return 'صالح حتى $date';
  }

  @override
  String get discountExpired => 'Expired';

  @override
  String get discountUsed => 'Used';

  @override
  String get wheelManagement => 'إدارة العجلة';

  @override
  String get wheelItemsDescription => 'إدارة عناصر عجلة الخصم واحتمالاتها';

  @override
  String get probability => 'احتمال';

  @override
  String get addNewDiscount => 'إضافة خصم جديد';

  @override
  String get discountValue => 'قيمة الخصم';

  @override
  String get pleaseEnterValue => 'الرجاء إدخال قيمة';

  @override
  String get enterValidNumber => 'الرجاء إدخال رقم صحيح بين 1 و 100';

  @override
  String get congratulations => 'تهانينا!';

  @override
  String get betterLuckNextTime => 'حظاً أوفر في المرة القادمة!';

  @override
  String get youWonDiscount => 'لقد ربحت';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات بنجاح';

  @override
  String get comeBackNextWeek => 'عد في الأسبوع القادم!';

  @override
  String get spinning => 'يدور...';

  @override
  String get spinTheWheel => 'أدر العجلة!';

  @override
  String get mostViewed => 'المنتجات الأكثر مشاهدة';

  @override
  String get country => 'Country';

  @override
  String get selectCountry => 'Select Country';

  @override
  String get pleaseSelectCountry => 'Please select a country';

  @override
  String get homepageLayout => 'Homepage Layout';
}
