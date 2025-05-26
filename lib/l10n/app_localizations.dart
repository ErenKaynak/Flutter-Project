import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Paradise PC Parts'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @notAMember.
  ///
  /// In en, this message translates to:
  /// **'Not a member?'**
  String get notAMember;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @specialMode.
  ///
  /// In en, this message translates to:
  /// **'Special Mode'**
  String get specialMode;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'ADD TO CART'**
  String get addToCart;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'OUT OF STOCK'**
  String get outOfStock;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get searchProducts;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @bestDeals.
  ///
  /// In en, this message translates to:
  /// **'Best Deals'**
  String get bestDeals;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String products(int count);

  /// No description provided for @productQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get productQuantity;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No description provided for @tryDifferentCategory.
  ///
  /// In en, this message translates to:
  /// **'Try selecting a different category'**
  String get tryDifferentCategory;

  /// No description provided for @viewCart.
  ///
  /// In en, this message translates to:
  /// **'VIEW CART'**
  String get viewCart;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'{productName} added to cart'**
  String addedToCart(String productName);

  /// No description provided for @errorAddingToCart.
  ///
  /// In en, this message translates to:
  /// **'Failed to add item to cart'**
  String get errorAddingToCart;

  /// No description provided for @pleaseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue'**
  String get pleaseSignIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @surname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @myAddresses.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get myAddresses;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addNewAddress;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @yourAddresses.
  ///
  /// In en, this message translates to:
  /// **'Your Addresses'**
  String get yourAddresses;

  /// No description provided for @noAddressesFound.
  ///
  /// In en, this message translates to:
  /// **'No addresses found.'**
  String get noAddressesFound;

  /// No description provided for @recipientInfo.
  ///
  /// In en, this message translates to:
  /// **'Recipient Info'**
  String get recipientInfo;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @addressType.
  ///
  /// In en, this message translates to:
  /// **'Address Type'**
  String get addressType;

  /// No description provided for @addressDetails.
  ///
  /// In en, this message translates to:
  /// **'Address Details'**
  String get addressDetails;

  /// No description provided for @streetAvenue.
  ///
  /// In en, this message translates to:
  /// **'Street / Avenue'**
  String get streetAvenue;

  /// No description provided for @neighborhood.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood'**
  String get neighborhood;

  /// No description provided for @buildingNo.
  ///
  /// In en, this message translates to:
  /// **'Building No'**
  String get buildingNo;

  /// No description provided for @apartmentName.
  ///
  /// In en, this message translates to:
  /// **'Apartment Name'**
  String get apartmentName;

  /// No description provided for @floorNo.
  ///
  /// In en, this message translates to:
  /// **'Floor No'**
  String get floorNo;

  /// No description provided for @doorNo.
  ///
  /// In en, this message translates to:
  /// **'Door No'**
  String get doorNo;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address Label'**
  String get addressLabel;

  /// No description provided for @addressLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Home, Work, etc.'**
  String get addressLabelHint;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get saveAddress;

  /// No description provided for @savingAddress.
  ///
  /// In en, this message translates to:
  /// **'Saving address...'**
  String get savingAddress;

  /// No description provided for @addressSaved.
  ///
  /// In en, this message translates to:
  /// **'Address saved successfully'**
  String get addressSaved;

  /// No description provided for @userNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User not logged in.'**
  String get userNotLoggedIn;

  /// No description provided for @errorSavingAddress.
  ///
  /// In en, this message translates to:
  /// **'Error saving address: {error}'**
  String errorSavingAddress(String error);

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get fillAllFields;

  /// No description provided for @pleaseEnterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Please enter first name'**
  String get pleaseEnterFirstName;

  /// No description provided for @pleaseEnterLastName.
  ///
  /// In en, this message translates to:
  /// **'Please enter last name'**
  String get pleaseEnterLastName;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @pleaseEnterStreetName.
  ///
  /// In en, this message translates to:
  /// **'Please enter street name'**
  String get pleaseEnterStreetName;

  /// No description provided for @pleaseEnterNeighborhood.
  ///
  /// In en, this message translates to:
  /// **'Please enter neighborhood'**
  String get pleaseEnterNeighborhood;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @pleaseEnterAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Please enter an address label'**
  String get pleaseEnterAddressLabel;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get selectCity;

  /// No description provided for @pleaseSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Please select a city'**
  String get pleaseSelectCity;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get delete;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get setAsDefault;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @myWallet.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get myWallet;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get referralCode;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @changeProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Picture'**
  String get changeProfilePicture;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @addFromUrl.
  ///
  /// In en, this message translates to:
  /// **'Add from URL'**
  String get addFromUrl;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @enterImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter Image URL'**
  String get enterImageUrl;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @priceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get priceLowToHigh;

  /// No description provided for @priceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get priceHighToLow;

  /// No description provided for @nameAToZ.
  ///
  /// In en, this message translates to:
  /// **'Name: A to Z'**
  String get nameAToZ;

  /// No description provided for @nameZToA.
  ///
  /// In en, this message translates to:
  /// **'Name: Z to A'**
  String get nameZToA;

  /// Title for special offers section
  ///
  /// In en, this message translates to:
  /// **'Special Offers'**
  String get specialOffers;

  /// Description text for special offers
  ///
  /// In en, this message translates to:
  /// **'Get up to 20% off on selected products'**
  String get specialOffersDescription;

  /// Button text for shopping action
  ///
  /// In en, this message translates to:
  /// **'Shop Now'**
  String get shopNow;

  /// No description provided for @authentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get authentication;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @addYourName.
  ///
  /// In en, this message translates to:
  /// **'Add Your Name'**
  String get addYourName;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get admin;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestUser;

  /// No description provided for @signInToAccess.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access all features'**
  String get signInToAccess;

  /// No description provided for @yourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get yourReferralCode;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @itemsYouFavorite.
  ///
  /// In en, this message translates to:
  /// **'Items you mark as favorite will appear here'**
  String get itemsYouFavorite;

  /// No description provided for @yourCart.
  ///
  /// In en, this message translates to:
  /// **'Your Cart'**
  String get yourCart;

  /// No description provided for @emptyCart.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get emptyCart;

  /// No description provided for @addItemsToCheckout.
  ///
  /// In en, this message translates to:
  /// **'Add items to your cart to checkout'**
  String get addItemsToCheckout;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// No description provided for @clearCartConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all items?'**
  String get clearCartConfirmation;

  /// No description provided for @discountCode.
  ///
  /// In en, this message translates to:
  /// **'Discount Code'**
  String get discountCode;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get enterCode;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'APPLY'**
  String get apply;

  /// No description provided for @discountApplied.
  ///
  /// In en, this message translates to:
  /// **'Discount applied: {code}'**
  String discountApplied(String code);

  /// No description provided for @percentOff.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off'**
  String percentOff(int percent);

  /// No description provided for @invalidDiscountCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired discount code'**
  String get invalidDiscountCode;

  /// No description provided for @notApplicableDiscount.
  ///
  /// In en, this message translates to:
  /// **'This code is not applicable to items in your cart'**
  String get notApplicableDiscount;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount ({percent}%)'**
  String discount(int percent);

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total: ₺{amount}'**
  String totalAmount(String amount);

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'CHECKOUT'**
  String get checkout;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful!'**
  String get paymentSuccessful;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid: ₺{amount}'**
  String amountPaid(String amount);

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Your order has been placed successfully.'**
  String get orderPlaced;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID: {id}'**
  String orderId(String id);

  /// No description provided for @viewOrders.
  ///
  /// In en, this message translates to:
  /// **'VIEW ORDERS'**
  String get viewOrders;

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE SHOPPING'**
  String get continueShopping;

  /// No description provided for @cardExpired.
  ///
  /// In en, this message translates to:
  /// **'Your card is expired, please try again'**
  String get cardExpired;

  /// No description provided for @pleaseSelectAddress.
  ///
  /// In en, this message translates to:
  /// **'Please select an address'**
  String get pleaseSelectAddress;

  /// No description provided for @pleaseSelectCard.
  ///
  /// In en, this message translates to:
  /// **'Please select a credit card'**
  String get pleaseSelectCard;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// No description provided for @noSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses'**
  String get noSavedAddresses;

  /// No description provided for @creditCards.
  ///
  /// In en, this message translates to:
  /// **'Credit Cards'**
  String get creditCards;

  /// No description provided for @noSavedCards.
  ///
  /// In en, this message translates to:
  /// **'No saved cards'**
  String get noSavedCards;

  /// No description provided for @payWithCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Pay with credit card'**
  String get payWithCreditCard;

  /// No description provided for @payWithWallet.
  ///
  /// In en, this message translates to:
  /// **'Pay with Wallet'**
  String get payWithWallet;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance: ₺{amount}'**
  String availableBalance(String amount);

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get insufficientBalance;

  /// No description provided for @addMoreForFreeShipping.
  ///
  /// In en, this message translates to:
  /// **'Add ₺{amount} more to get free shipping!'**
  String addMoreForFreeShipping(String amount);

  /// No description provided for @freeShippingOver.
  ///
  /// In en, this message translates to:
  /// **'Free over ₺10,000'**
  String get freeShippingOver;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get free;

  /// No description provided for @shipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'PLACE ORDER'**
  String get placeOrder;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method:'**
  String get paymentMethod;

  /// No description provided for @addNewCard.
  ///
  /// In en, this message translates to:
  /// **'Add New Card'**
  String get addNewCard;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// No description provided for @cardNumberHint.
  ///
  /// In en, this message translates to:
  /// **'1234 5678 9012 3456'**
  String get cardNumberHint;

  /// No description provided for @cardHolderName.
  ///
  /// In en, this message translates to:
  /// **'Card Holder Name'**
  String get cardHolderName;

  /// No description provided for @cardHolderHint.
  ///
  /// In en, this message translates to:
  /// **'JOHN DOE'**
  String get cardHolderHint;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @expiryDateHint.
  ///
  /// In en, this message translates to:
  /// **'MM/YY'**
  String get expiryDateHint;

  /// No description provided for @cardIsExpired.
  ///
  /// In en, this message translates to:
  /// **'Card is expired'**
  String get cardIsExpired;

  /// No description provided for @cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @cvvHint.
  ///
  /// In en, this message translates to:
  /// **'123'**
  String get cvvHint;

  /// No description provided for @deleteCard.
  ///
  /// In en, this message translates to:
  /// **'Delete Card'**
  String get deleteCard;

  /// No description provided for @deleteCardConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this card?'**
  String get deleteCardConfirmation;

  /// No description provided for @defaultCard.
  ///
  /// In en, this message translates to:
  /// **'Default Card'**
  String get defaultCard;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String expires(String date);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cannotReorder.
  ///
  /// In en, this message translates to:
  /// **'Cannot Reorder'**
  String get cannotReorder;

  /// No description provided for @outOfStockItems.
  ///
  /// In en, this message translates to:
  /// **'The following items are out of stock:\n• {items}'**
  String outOfStockItems(String items);

  /// No description provided for @insufficientStockItems.
  ///
  /// In en, this message translates to:
  /// **'Insufficient stock for:\n• {items}'**
  String insufficientStockItems(String items);

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @exploreProducts.
  ///
  /// In en, this message translates to:
  /// **'Explore Products'**
  String get exploreProducts;

  /// No description provided for @failedToRemove.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove from favorites'**
  String get failedToRemove;

  /// No description provided for @pleaseLoginToAdd.
  ///
  /// In en, this message translates to:
  /// **'Please log in to add items to cart'**
  String get pleaseLoginToAdd;

  /// No description provided for @failedToAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Failed to add item to cart'**
  String get failedToAddToCart;

  /// Title for the admin dashboard
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// Title for admin controls section
  ///
  /// In en, this message translates to:
  /// **'Admin Controls'**
  String get adminControls;

  /// Title for user management section
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// Description for user management section
  ///
  /// In en, this message translates to:
  /// **'View and manage users'**
  String get viewAndManageUsers;

  /// Title for product management section
  ///
  /// In en, this message translates to:
  /// **'Product Management'**
  String get productManagement;

  /// Description for product management section
  ///
  /// In en, this message translates to:
  /// **'Manage products'**
  String get manageProducts;

  /// Title for order management section
  ///
  /// In en, this message translates to:
  /// **'Order Management'**
  String get orderManagement;

  /// Description for order management section
  ///
  /// In en, this message translates to:
  /// **'View and process orders'**
  String get viewAndProcessOrders;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @cashbackInfo.
  ///
  /// In en, this message translates to:
  /// **'1% Cashback on all purchases'**
  String get cashbackInfo;

  /// No description provided for @addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add Money'**
  String get addMoney;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @transactionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String transactionsCount(int count);

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @transactionsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Your transaction history will appear here'**
  String get transactionsWillAppear;

  /// No description provided for @moneyAdded.
  ///
  /// In en, this message translates to:
  /// **'Money added successfully'**
  String get moneyAdded;

  /// No description provided for @errorAddingBalance.
  ///
  /// In en, this message translates to:
  /// **'Error adding balance: {error}'**
  String errorAddingBalance(String error);

  /// No description provided for @addMoneyToWallet.
  ///
  /// In en, this message translates to:
  /// **'Add Money to Wallet'**
  String get addMoneyToWallet;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @selectCard.
  ///
  /// In en, this message translates to:
  /// **'Select Card'**
  String get selectCard;

  /// No description provided for @useCard.
  ///
  /// In en, this message translates to:
  /// **'Use Saved Card'**
  String get useCard;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @fillCardDetails.
  ///
  /// In en, this message translates to:
  /// **'Please fill all card details correctly'**
  String get fillCardDetails;

  /// No description provided for @cardNumberError.
  ///
  /// In en, this message translates to:
  /// **'Card number must be 16 digits'**
  String get cardNumberError;

  /// No description provided for @invalidCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid card number'**
  String get invalidCardNumber;

  /// No description provided for @onlyLettersAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only letters allowed'**
  String get onlyLettersAllowed;

  /// No description provided for @useMMYYFormat.
  ///
  /// In en, this message translates to:
  /// **'Use MM/YY format'**
  String get useMMYYFormat;

  /// No description provided for @invalidCVV.
  ///
  /// In en, this message translates to:
  /// **'Invalid CVV'**
  String get invalidCVV;

  /// No description provided for @amountMustBeGreater.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get amountMustBeGreater;

  /// No description provided for @maximumAmount.
  ///
  /// In en, this message translates to:
  /// **'Maximum amount is ₺10,000'**
  String get maximumAmount;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @cardSaved.
  ///
  /// In en, this message translates to:
  /// **'Card saved successfully'**
  String get cardSaved;

  /// No description provided for @errorSavingCard.
  ///
  /// In en, this message translates to:
  /// **'Error saving card: {error}'**
  String errorSavingCard(String error);

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @yourOrders.
  ///
  /// In en, this message translates to:
  /// **'Your Orders'**
  String get yourOrders;

  /// No description provided for @ordersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} orders'**
  String ordersCount(int count);

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by Status'**
  String get filterByStatus;

  /// No description provided for @allOrders.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allOrders;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @onDelivery.
  ///
  /// In en, this message translates to:
  /// **'On Delivery'**
  String get onDelivery;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @noOrdersWithStatus.
  ///
  /// In en, this message translates to:
  /// **'No orders with \'{status}\' status'**
  String noOrdersWithStatus(String status);

  /// No description provided for @tryDifferentFilter.
  ///
  /// In en, this message translates to:
  /// **'Try selecting a different filter'**
  String get tryDifferentFilter;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String orderNumber(String number);

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items:'**
  String get items;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String quantity(int count, String price);

  /// No description provided for @itemTotal.
  ///
  /// In en, this message translates to:
  /// **'Item Total: ₺{amount}'**
  String itemTotal(String amount);

  /// No description provided for @trackingNumber.
  ///
  /// In en, this message translates to:
  /// **'Tracking Number:'**
  String get trackingNumber;

  /// No description provided for @shippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address:'**
  String get shippingAddress;

  /// No description provided for @noAddressProvided.
  ///
  /// In en, this message translates to:
  /// **'No address provided'**
  String get noAddressProvided;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @confirmCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order?'**
  String get confirmCancelOrder;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled successfully'**
  String get orderCancelled;

  /// No description provided for @failedToCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel order: {error}'**
  String failedToCancelOrder(String error);

  /// No description provided for @rateProduct.
  ///
  /// In en, this message translates to:
  /// **'Rate this product'**
  String get rateProduct;

  /// No description provided for @alreadyReviewed.
  ///
  /// In en, this message translates to:
  /// **'Already reviewed'**
  String get alreadyReviewed;

  /// No description provided for @canReviewAfterDelivery.
  ///
  /// In en, this message translates to:
  /// **'Can review after delivery'**
  String get canReviewAfterDelivery;

  /// No description provided for @selectRating.
  ///
  /// In en, this message translates to:
  /// **'Select Rating'**
  String get selectRating;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @veryGood.
  ///
  /// In en, this message translates to:
  /// **'Very Good'**
  String get veryGood;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write your review (optional)'**
  String get writeReview;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @thankYouForReview.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your review!'**
  String get thankYouForReview;

  /// No description provided for @failedToSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit review'**
  String get failedToSubmitReview;

  /// No description provided for @productNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Product is no longer available'**
  String get productNoLongerAvailable;

  /// No description provided for @errorCheckingAvailability.
  ///
  /// In en, this message translates to:
  /// **'Error checking product availability. Please try again.'**
  String get errorCheckingAvailability;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get tryAgain;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @yourOrderHistoryWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your order history will appear here'**
  String get yourOrderHistoryWillAppearHere;

  /// No description provided for @startShopping.
  ///
  /// In en, this message translates to:
  /// **'START SHOPPING'**
  String get startShopping;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @orderPrefix.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get orderPrefix;

  /// No description provided for @itemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Items:'**
  String get itemsLabel;

  /// No description provided for @quantityPrefix.
  ///
  /// In en, this message translates to:
  /// **'Qty:'**
  String get quantityPrefix;

  /// No description provided for @itemTotalPrefix.
  ///
  /// In en, this message translates to:
  /// **'Item Total:'**
  String get itemTotalPrefix;

  /// No description provided for @shippingAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address:'**
  String get shippingAddressLabel;

  /// No description provided for @defaultShippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Default Shipping Address'**
  String get defaultShippingAddress;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method:'**
  String get paymentMethodLabel;

  /// No description provided for @cardPayment.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get cardPayment;

  /// No description provided for @reorderButton.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorderButton;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'MMM dd, yyyy - HH:mm'**
  String get dateFormat;

  /// No description provided for @totalPrefix.
  ///
  /// In en, this message translates to:
  /// **'Total: ₺{amount}'**
  String totalPrefix(String amount);

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String inStock(int count);

  /// No description provided for @addedToCartMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} x{quantity} added to cart'**
  String addedToCartMessage(String name, int quantity);

  /// No description provided for @mustBeLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to add to cart'**
  String get mustBeLoggedIn;

  /// No description provided for @cannotAddMoreThanStock.
  ///
  /// In en, this message translates to:
  /// **'Cannot add more than available stock ({count})'**
  String cannotAddMoreThanStock(int count);

  /// No description provided for @productDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get productDescription;

  /// No description provided for @specifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get specifications;

  /// No description provided for @customerReviews.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get customerReviews;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @couldNotLoadReviews.
  ///
  /// In en, this message translates to:
  /// **'Could not load reviews'**
  String get couldNotLoadReviews;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @failedToUpdateFavorites.
  ///
  /// In en, this message translates to:
  /// **'Failed to update favorites'**
  String get failedToUpdateFavorites;

  /// No description provided for @pleaseLoginToAddFavorites.
  ///
  /// In en, this message translates to:
  /// **'Please log in to add favorites'**
  String get pleaseLoginToAddFavorites;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(int count);

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get categoryAll;

  /// No description provided for @categoryCPU.
  ///
  /// In en, this message translates to:
  /// **'CPUs'**
  String get categoryCPU;

  /// No description provided for @categoryGPU.
  ///
  /// In en, this message translates to:
  /// **'GPUs'**
  String get categoryGPU;

  /// No description provided for @categoryRAM.
  ///
  /// In en, this message translates to:
  /// **'RAM'**
  String get categoryRAM;

  /// No description provided for @categoryMotherboard.
  ///
  /// In en, this message translates to:
  /// **'Motherboards'**
  String get categoryMotherboard;

  /// No description provided for @categoryStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get categoryStorage;

  /// No description provided for @categoryCase.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get categoryCase;

  /// No description provided for @categoryPSU.
  ///
  /// In en, this message translates to:
  /// **'Power Supplies'**
  String get categoryPSU;

  /// No description provided for @categoryPreBuilt.
  ///
  /// In en, this message translates to:
  /// **'Pre-Built PCs'**
  String get categoryPreBuilt;

  /// No description provided for @aiChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant Tommy'**
  String get aiChatTitle;

  /// No description provided for @askMeAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask Me Anything...'**
  String get askMeAnything;

  /// No description provided for @howCanIHelp.
  ///
  /// In en, this message translates to:
  /// **'How can I help you today?'**
  String get howCanIHelp;

  /// No description provided for @iNeedAssistance.
  ///
  /// In en, this message translates to:
  /// **'I need assistance'**
  String get iNeedAssistance;

  /// No description provided for @recommendCheapestPC.
  ///
  /// In en, this message translates to:
  /// **'Recommend me the cheapest PC build'**
  String get recommendCheapestPC;

  /// No description provided for @lookingForGamingPC.
  ///
  /// In en, this message translates to:
  /// **'Looking for a gaming PC build'**
  String get lookingForGamingPC;

  /// No description provided for @addNewProduct.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addNewProduct;

  /// No description provided for @updateProduct.
  ///
  /// In en, this message translates to:
  /// **'Update Product'**
  String get updateProduct;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @productPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productPrice;

  /// No description provided for @productStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get productStock;

  /// No description provided for @productCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get productCategory;

  /// No description provided for @mainImage.
  ///
  /// In en, this message translates to:
  /// **'Main Image'**
  String get mainImage;

  /// No description provided for @additionalImages.
  ///
  /// In en, this message translates to:
  /// **'Additional Images'**
  String get additionalImages;

  /// No description provided for @generateAIDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate AI Description'**
  String get generateAIDescription;

  /// No description provided for @pleaseEnterProductName.
  ///
  /// In en, this message translates to:
  /// **'Please enter product name first'**
  String get pleaseEnterProductName;

  /// No description provided for @errorGeneratingDescription.
  ///
  /// In en, this message translates to:
  /// **'Error generating description: {error}'**
  String errorGeneratingDescription(String error);

  /// No description provided for @searchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search Product'**
  String get searchProduct;

  /// No description provided for @selectProductToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Select Product to Update'**
  String get selectProductToUpdate;

  /// No description provided for @imageRequired.
  ///
  /// In en, this message translates to:
  /// **'Main image is required'**
  String get imageRequired;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully'**
  String get productUpdated;

  /// No description provided for @errorUpdatingProduct.
  ///
  /// In en, this message translates to:
  /// **'Error updating product: {error}'**
  String errorUpdatingProduct(String error);

  /// No description provided for @onVacation.
  ///
  /// In en, this message translates to:
  /// **'I\'m currently on vacation!! Try to talk to me later :P'**
  String get onVacation;

  /// No description provided for @adminOnly.
  ///
  /// In en, this message translates to:
  /// **'Only admin users can add products'**
  String get adminOnly;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @stockRemaining.
  ///
  /// In en, this message translates to:
  /// **'{stock} items remaining'**
  String stockRemaining(int stock);

  /// No description provided for @updateStock.
  ///
  /// In en, this message translates to:
  /// **'Update stock for {productName}'**
  String updateStock(String productName);

  /// No description provided for @newStockAmount.
  ///
  /// In en, this message translates to:
  /// **'New Stock Amount'**
  String get newStockAmount;

  /// No description provided for @enterNewStockAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter new stock amount'**
  String get enterNewStockAmount;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @checkingStockLevels.
  ///
  /// In en, this message translates to:
  /// **'Checking stock levels...'**
  String get checkingStockLevels;

  /// No description provided for @lowStockAlerts.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alerts'**
  String get lowStockAlerts;

  /// No description provided for @noLowStockProducts.
  ///
  /// In en, this message translates to:
  /// **'No products with low stock'**
  String get noLowStockProducts;

  /// No description provided for @lowStockProductsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products with low stock'**
  String lowStockProductsCount(int count);

  /// No description provided for @promoCodes.
  ///
  /// In en, this message translates to:
  /// **'Promo Codes'**
  String get promoCodes;

  /// No description provided for @createPromocodesAndDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Create Promocodes and Discounts'**
  String get createPromocodesAndDiscounts;

  /// No description provided for @salesStatistics.
  ///
  /// In en, this message translates to:
  /// **'Sales Statistics'**
  String get salesStatistics;

  /// No description provided for @viewSalesAnalytics.
  ///
  /// In en, this message translates to:
  /// **'View sales analytics and charts'**
  String get viewSalesAnalytics;

  /// No description provided for @assistantTommySettings.
  ///
  /// In en, this message translates to:
  /// **'Assistant Tommy\'s Settings'**
  String get assistantTommySettings;

  /// No description provided for @configureTommyAvailability.
  ///
  /// In en, this message translates to:
  /// **'Configure Tommy\'s availability'**
  String get configureTommyAvailability;

  /// No description provided for @enableAssistantTommy.
  ///
  /// In en, this message translates to:
  /// **'Enable Assistant Tommy'**
  String get enableAssistantTommy;

  /// No description provided for @tommyAvailable.
  ///
  /// In en, this message translates to:
  /// **'Tommy is currently available'**
  String get tommyAvailable;

  /// No description provided for @tommyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Tommy is currently disabled'**
  String get tommyDisabled;

  /// No description provided for @hideTommy.
  ///
  /// In en, this message translates to:
  /// **'Hide Tommy'**
  String get hideTommy;

  /// No description provided for @allEyesOnTommy.
  ///
  /// In en, this message translates to:
  /// **'All Eyes On Tommy !'**
  String get allEyesOnTommy;

  /// No description provided for @tommyHiding.
  ///
  /// In en, this message translates to:
  /// **'Tommy is hiding in the closet !'**
  String get tommyHiding;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @photoUploader.
  ///
  /// In en, this message translates to:
  /// **'Photo Uploader'**
  String get photoUploader;

  /// No description provided for @configureAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Configure app settings'**
  String get configureAppSettings;

  /// No description provided for @ratingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ratings'**
  String ratingCount(int count);

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report Bug'**
  String get reportBug;

  /// No description provided for @bugReports.
  ///
  /// In en, this message translates to:
  /// **'Bug Reports'**
  String get bugReports;

  /// No description provided for @viewAndManageBugReports.
  ///
  /// In en, this message translates to:
  /// **'View and manage bug reports'**
  String get viewAndManageBugReports;

  /// No description provided for @bugTitle.
  ///
  /// In en, this message translates to:
  /// **'Bug Title'**
  String get bugTitle;

  /// No description provided for @enterBugTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a title for the bug'**
  String get enterBugTitle;

  /// No description provided for @bugDescription.
  ///
  /// In en, this message translates to:
  /// **'Bug Description'**
  String get bugDescription;

  /// No description provided for @describeBugInDetail.
  ///
  /// In en, this message translates to:
  /// **'Please describe the bug in detail'**
  String get describeBugInDetail;

  /// No description provided for @pleaseEnterBugDetails.
  ///
  /// In en, this message translates to:
  /// **'Please enter both title and description'**
  String get pleaseEnterBugDetails;

  /// No description provided for @bugReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Bug report submitted successfully'**
  String get bugReportSubmitted;

  /// No description provided for @errorSubmittingBugReport.
  ///
  /// In en, this message translates to:
  /// **'Error submitting bug report'**
  String get errorSubmittingBugReport;

  /// No description provided for @reportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported by'**
  String get reportedBy;

  /// No description provided for @reportedOn.
  ///
  /// In en, this message translates to:
  /// **'Reported on'**
  String get reportedOn;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @dismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get dismissed;

  /// No description provided for @markAsInProgress.
  ///
  /// In en, this message translates to:
  /// **'Mark as In Progress'**
  String get markAsInProgress;

  /// No description provided for @markAsResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark as Resolved'**
  String get markAsResolved;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @noBugReports.
  ///
  /// In en, this message translates to:
  /// **'No bug reports found'**
  String get noBugReports;

  /// No description provided for @requestRefund.
  ///
  /// In en, this message translates to:
  /// **'Request Refund'**
  String get requestRefund;

  /// No description provided for @confirmRefundRequest.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to request a refund for this order?'**
  String get confirmRefundRequest;

  /// No description provided for @orderTotal.
  ///
  /// In en, this message translates to:
  /// **'Order Total'**
  String get orderTotal;

  /// No description provided for @refundRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Refund request submitted successfully'**
  String get refundRequestSubmitted;

  /// No description provided for @failedToRequestRefund.
  ///
  /// In en, this message translates to:
  /// **'Failed to request refund: {error}'**
  String failedToRequestRefund(String error);

  /// No description provided for @refundRequested.
  ///
  /// In en, this message translates to:
  /// **'Refund Requested'**
  String get refundRequested;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @processRefund.
  ///
  /// In en, this message translates to:
  /// **'Process Refund'**
  String get processRefund;

  /// No description provided for @refundProcessed.
  ///
  /// In en, this message translates to:
  /// **'Refund processed successfully'**
  String get refundProcessed;

  /// No description provided for @failedToProcessRefund.
  ///
  /// In en, this message translates to:
  /// **'Failed to process refund: {error}'**
  String failedToProcessRefund(String error);

  /// No description provided for @setupWalletPin.
  ///
  /// In en, this message translates to:
  /// **'Setup Wallet PIN'**
  String get setupWalletPin;

  /// No description provided for @createWalletPin.
  ///
  /// In en, this message translates to:
  /// **'Create Wallet PIN'**
  String get createWalletPin;

  /// No description provided for @walletPinDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a 6-digit PIN to secure your wallet'**
  String get walletPinDescription;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @useBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use Biometrics'**
  String get useBiometrics;

  /// No description provided for @biometricsDescription.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face recognition to access your wallet'**
  String get biometricsDescription;

  /// No description provided for @setupPin.
  ///
  /// In en, this message translates to:
  /// **'Setup PIN'**
  String get setupPin;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @invalidPin.
  ///
  /// In en, this message translates to:
  /// **'Invalid PIN'**
  String get invalidPin;

  /// No description provided for @orLogInWith.
  ///
  /// In en, this message translates to:
  /// **'Or Log in With'**
  String get orLogInWith;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password Requirements:'**
  String get passwordRequirements;

  /// No description provided for @atLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8Characters;

  /// No description provided for @maximum20Characters.
  ///
  /// In en, this message translates to:
  /// **'Maximum 20 characters'**
  String get maximum20Characters;

  /// No description provided for @oneUppercaseLetter.
  ///
  /// In en, this message translates to:
  /// **'One uppercase letter'**
  String get oneUppercaseLetter;

  /// No description provided for @oneLowercaseLetter.
  ///
  /// In en, this message translates to:
  /// **'One lowercase letter'**
  String get oneLowercaseLetter;

  /// No description provided for @oneSpecialCharacter.
  ///
  /// In en, this message translates to:
  /// **'One special character'**
  String get oneSpecialCharacter;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @noNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'New notifications will appear here'**
  String get noNotificationsDesc;

  /// No description provided for @clearAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications'**
  String get clearAllNotifications;

  /// No description provided for @allNotificationsCleared.
  ///
  /// In en, this message translates to:
  /// **'All notifications cleared'**
  String get allNotificationsCleared;

  /// No description provided for @notificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notificationDeleted;

  /// No description provided for @welcomeNotification.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeNotification;

  /// No description provided for @welcomeNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Welcome to our store. We have great offers for you.'**
  String get welcomeNotificationDesc;

  /// No description provided for @newProductNotification.
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get newProductNotification;

  /// No description provided for @newProductNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'RTX 4090 is in stock! Check it out now.'**
  String get newProductNotificationDesc;

  /// No description provided for @discountNotification.
  ///
  /// In en, this message translates to:
  /// **'Special Discount'**
  String get discountNotification;

  /// No description provided for @discountNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'20% off on all RAM products!'**
  String get discountNotificationDesc;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @notificationManagement.
  ///
  /// In en, this message translates to:
  /// **'Notification Management'**
  String get notificationManagement;

  /// No description provided for @newNotification.
  ///
  /// In en, this message translates to:
  /// **'Create New Notification'**
  String get newNotification;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Title'**
  String get notificationTitle;

  /// No description provided for @notificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Notification Message'**
  String get notificationMessage;

  /// No description provided for @sendToAllUsers.
  ///
  /// In en, this message translates to:
  /// **'Send to All Users'**
  String get sendToAllUsers;

  /// No description provided for @sendNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get sendNotification;

  /// No description provided for @notificationSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent successfully'**
  String get notificationSent;

  /// No description provided for @notificationError.
  ///
  /// In en, this message translates to:
  /// **'Error occurred: {error}'**
  String notificationError(String error);

  /// No description provided for @pleaseEnterTitleAndMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter title and message'**
  String get pleaseEnterTitleAndMessage;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
