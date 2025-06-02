// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Paradise PC Parts';

  @override
  String get welcome => 'Welcome';

  @override
  String get login => 'Login';

  @override
  String get signIn => 'Sign In';

  @override
  String get register => 'Register';

  @override
  String get guest => 'Continue as Guest';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get notAMember => 'Not a member?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get profile => 'Profile';

  @override
  String get home => 'Home';

  @override
  String get favorites => 'Favorites';

  @override
  String get cart => 'Cart';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Turkish';

  @override
  String get arabic => 'Arabic';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get specialMode => 'Special Mode';

  @override
  String get addToCart => 'ADD TO CART';

  @override
  String get outOfStock => 'OUT OF STOCK';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get searchProducts => 'Search products';

  @override
  String get categories => 'Categories';

  @override
  String get allCategories => 'All Categories';

  @override
  String get bestDeals => 'Best Deals';

  @override
  String products(int count) {
    return '$count products';
  }

  @override
  String get productQuantity => 'Quantity';

  @override
  String get noProductsFound => 'No products found';

  @override
  String get tryDifferentSearch => 'Try a different search term';

  @override
  String get tryDifferentCategory => 'Try selecting a different category';

  @override
  String get viewCart => 'VIEW CART';

  @override
  String addedToCart(String productName) {
    return '$productName added to cart';
  }

  @override
  String get errorAddingToCart => 'Failed to add item to cart';

  @override
  String get pleaseSignIn => 'Please sign in to continue';

  @override
  String get signOut => 'Sign Out';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get name => 'Name';

  @override
  String get surname => 'Surname';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get myAddresses => 'My Addresses';

  @override
  String get addNewAddress => 'Add New Address';

  @override
  String get hello => 'Hello';

  @override
  String get yourAddresses => 'Your Addresses';

  @override
  String get noAddressesFound => 'No addresses found.';

  @override
  String get recipientInfo => 'Recipient Info';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get addressType => 'Address Type';

  @override
  String get addressDetails => 'Address Details';

  @override
  String get streetAvenue => 'Street / Avenue';

  @override
  String get neighborhood => 'Neighborhood';

  @override
  String get buildingNo => 'Building No';

  @override
  String get apartmentName => 'Apartment Name';

  @override
  String get floorNo => 'Floor No';

  @override
  String get doorNo => 'Door No';

  @override
  String get city => 'City';

  @override
  String get addressLabel => 'Address Label';

  @override
  String get addressLabelHint => 'Example: Home, Work, etc.';

  @override
  String get saveAddress => 'Save Address';

  @override
  String get savingAddress => 'Saving address...';

  @override
  String get addressSaved => 'Address saved successfully';

  @override
  String get userNotLoggedIn => 'User not logged in.';

  @override
  String errorSavingAddress(String error) {
    return 'Error saving address: $error';
  }

  @override
  String get fillAllFields => 'Please fill all required fields';

  @override
  String get pleaseEnterFirstName => 'Please enter first name';

  @override
  String get pleaseEnterLastName => 'Please enter last name';

  @override
  String get pleaseEnterPhoneNumber => 'Please enter phone number';

  @override
  String get invalidPhoneNumber => 'Please enter a valid phone number';

  @override
  String get pleaseEnterStreetName => 'Please enter street name';

  @override
  String get pleaseEnterNeighborhood => 'Please enter neighborhood';

  @override
  String get required => 'Required';

  @override
  String get pleaseEnterAddressLabel => 'Please enter an address label';

  @override
  String get selectCity => 'Select City';

  @override
  String get pleaseSelectCity => 'Please select a city';

  @override
  String get work => 'Work';

  @override
  String get delete => 'Delete';

  @override
  String get setAsDefault => 'Set as Default';

  @override
  String get myOrders => 'My Orders';

  @override
  String get myWallet => 'My Wallet';

  @override
  String get appearance => 'Appearance';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get referralCode => 'Your Referral Code';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get changeProfilePicture => 'Change Profile Picture';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get addFromUrl => 'Add from URL';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get enterImageUrl => 'Enter Image URL';

  @override
  String get add => 'Add';

  @override
  String get sort => 'Sort';

  @override
  String get priceLowToHigh => 'Price: Low to High';

  @override
  String get priceHighToLow => 'Price: High to Low';

  @override
  String get nameAToZ => 'Name: A to Z';

  @override
  String get nameZToA => 'Name: Z to A';

  @override
  String get specialOffers => 'Special Offers';

  @override
  String get specialOffersDescription => 'Get up to 20% off on selected products';

  @override
  String get shopNow => 'Shop Now';

  @override
  String get authentication => 'Authentication';

  @override
  String get createAccount => 'Create Account';

  @override
  String get addYourName => 'Add Your Name';

  @override
  String get admin => 'ADMIN';

  @override
  String get guestUser => 'Guest';

  @override
  String get signInToAccess => 'Sign in to access all features';

  @override
  String get yourReferralCode => 'Your Referral Code';

  @override
  String get loading => 'Loading...';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get itemsYouFavorite => 'Items you mark as favorite will appear here';

  @override
  String get yourCart => 'Your Cart';

  @override
  String get emptyCart => 'Your cart is empty';

  @override
  String get addItemsToCheckout => 'Add items to your cart to checkout';

  @override
  String get clearCart => 'Clear Cart';

  @override
  String get clearCartConfirmation => 'Are you sure you want to remove all items?';

  @override
  String get discountCode => 'Discount Code';

  @override
  String get enterCode => 'Enter code';

  @override
  String get apply => 'APPLY';

  @override
  String discountApplied(String code) {
    return 'Discount applied: $code';
  }

  @override
  String percentOff(int percent) {
    return '$percent% off';
  }

  @override
  String get invalidDiscountCode => 'Invalid or expired discount code';

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
  String get pleaseLoginToAdd => 'Please log in to add items to cart';

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
    return 'Quantity';
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
  String get productNotFound => 'Product not found';

  @override
  String inStock(int count) {
    return '$count in stock';
  }

  @override
  String addedToCartMessage(String name, int quantity) {
    return '$name x$quantity added to cart';
  }

  @override
  String get mustBeLoggedIn => 'You must be logged in to add to cart';

  @override
  String cannotAddMoreThanStock(int count) {
    return 'Cannot add more than available stock ($count)';
  }

  @override
  String get productDescription => 'Description';

  @override
  String get specifications => 'Specifications';

  @override
  String get customerReviews => 'Customer Reviews';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get couldNotLoadReviews => 'Could not load reviews';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get failedToUpdateFavorites => 'Failed to update favorites';

  @override
  String get pleaseLoginToAddFavorites => 'Please log in to add favorites';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
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
  String updateStock(String productName) {
    return 'Update stock for $productName';
  }

  @override
  String get newStockAmount => 'New Stock Amount';

  @override
  String get enterNewStockAmount => 'Enter new stock amount';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get checkingStockLevels => 'Checking stock levels...';

  @override
  String get lowStockAlerts => 'Low Stock Alerts';

  @override
  String get noLowStockProducts => 'No products with low stock';

  @override
  String lowStockProductsCount(int count) {
    return '$count products with low stock';
  }

  @override
  String get promoCodes => 'Promo Codes';

  @override
  String get createPromocodesAndDiscounts => 'Create Promocodes and Discounts';

  @override
  String get salesStatistics => 'Sales Statistics';

  @override
  String get viewSalesAnalytics => 'View sales analytics and charts';

  @override
  String get assistantTommySettings => 'Assistant Tommy\'s Settings';

  @override
  String get configureTommyAvailability => 'Configure Tommy\'s availability';

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
  String get configureAppSettings => 'Configure app settings';

  @override
  String ratingCount(int count) {
    return '$count ratings';
  }

  @override
  String get reportBug => 'Report Bug';

  @override
  String get bugReports => 'Bug Reports';

  @override
  String get viewAndManageBugReports => 'View and manage bug reports';

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
}
