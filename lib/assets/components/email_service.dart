import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class EmailService {
  // Railway backend URL
  static const String _baseUrl = 'https://email-backend-production-8783.up.railway.app';

  // Get current locale from context
  static String _getCurrentLocale(BuildContext context) {
    return Provider.of<LanguageProvider>(context, listen: false).currentLocale.languageCode;
  }

  // Generate HTML receipt template based on language
  static String _generateReceiptTemplate({
    required String customerName,
    required String orderNumber,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required DateTime orderDate,
    required String shippingAddress,
    required String languageCode,
  }) {
    final currencyFormat = NumberFormat.currency(symbol: '₺', decimalDigits: 2);
    final dateFormat = DateFormat('MMMM dd, yyyy');
    
    // Language-specific text
    final Map<String, Map<String, String>> translations = {
      'en': {
        'title': 'Thank You for Your Order!',
        'orderConfirmation': 'Order Confirmation',
        'orderDetails': 'Order Details',
        'orderNumber': 'Order Number',
        'date': 'Date',
        'customer': 'Customer',
        'deliveryAddress': 'Delivery Address',
        'product': 'Product',
        'quantity': 'Quantity',
        'price': 'Price',
        'total': 'Total',
        'totalAmount': 'Total Amount',
        'viewOrderStatus': 'View Order Status',
        'support': 'If you have any questions, please contact our support team.',
        'copyright': '© 2024 Paradise PC Components. All rights reserved.',
      },
      'tr': {
        'title': 'Siparişiniz İçin Teşekkürler!',
        'orderConfirmation': 'Sipariş Onayı',
        'orderDetails': 'Sipariş Detayları',
        'orderNumber': 'Sipariş Numarası',
        'date': 'Tarih',
        'customer': 'Müşteri',
        'deliveryAddress': 'Teslimat Adresi',
        'product': 'Ürün',
        'quantity': 'Adet',
        'price': 'Fiyat',
        'total': 'Toplam',
        'totalAmount': 'Toplam Tutar',
        'viewOrderStatus': 'Sipariş Durumunu Görüntüle',
        'support': 'Sorularınız için destek ekibimizle iletişime geçebilirsiniz.',
        'copyright': '© 2024 Paradise PC Components. Tüm hakları saklıdır.',
      },
      'ar': {
        'title': 'شكراً لطلبك!',
        'orderConfirmation': 'تأكيد الطلب',
        'orderDetails': 'تفاصيل الطلب',
        'orderNumber': 'رقم الطلب',
        'date': 'التاريخ',
        'customer': 'العميل',
        'deliveryAddress': 'عنوان التوصيل',
        'product': 'المنتج',
        'quantity': 'الكمية',
        'price': 'السعر',
        'total': 'المجموع',
        'totalAmount': 'المبلغ الإجمالي',
        'viewOrderStatus': 'عرض حالة الطلب',
        'support': 'إذا كان لديك أي أسئلة، يرجى الاتصال بفريق الدعم.',
        'copyright': '© 2024 Paradise PC Components. جميع الحقوق محفوظة.',
      },
    };

    final text = translations[languageCode] ?? translations['en']!;
    
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          line-height: 1.6;
          color: #333;
          margin: 0;
          padding: 0;
        }
        .container {
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }
        .header {
          background: linear-gradient(135deg, #ff4b4b 0%, #ff7676 100%);
          color: white;
          padding: 30px;
          text-align: center;
          border-radius: 10px 10px 0 0;
        }
        .content {
          background: #ffffff;
          padding: 30px;
          border: 1px solid #e0e0e0;
          border-radius: 0 0 10px 10px;
        }
        .order-info {
          margin-bottom: 30px;
        }
        .items-table {
          width: 100%;
          border-collapse: collapse;
          margin: 20px 0;
        }
        .items-table th, .items-table td {
          padding: 12px;
          text-align: left;
          border-bottom: 1px solid #e0e0e0;
        }
        .items-table th {
          background-color: #f8f9fa;
          font-weight: 600;
        }
        .total {
          text-align: right;
          font-size: 1.2em;
          font-weight: bold;
          margin-top: 20px;
        }
        .footer {
          text-align: center;
          margin-top: 30px;
          color: #666;
          font-size: 0.9em;
        }
        .button {
          display: inline-block;
          padding: 12px 24px;
          background: linear-gradient(135deg, #ff4b4b 0%, #ff7676 100%);
          color: white;
          text-decoration: none;
          border-radius: 5px;
          margin-top: 20px;
        }
        .logo-circle {
          background: #fff;
          border-radius: 50%;
          box-shadow: 0 4px 16px rgba(0,0,0,0.08);
          width: 80px;
          height: 80px;
          background-image: url('https://i.imgur.com/Chg9qcf.png');
          background-size: cover;
          background-position: center;
          background-repeat: no-repeat;
          display: flex;
          justify-content: center;
          align-items: center;
          margin: 0 auto 12px auto;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div style="text-align:center; margin-bottom: 20px;">
          <img src="https://i.imgur.com/Chg9qcf.png" alt="Logo" style="height: 60px;">
        </div>
        <div class="header">
          <div class="logo-circle"></div>
          <h1>${text['title']}</h1>
          <p>${text['orderConfirmation']}</p>
        </div>
        <div class="content">
          <div class="order-info">
            <h2>${text['orderDetails']}</h2>
            <p><strong>${text['orderNumber']}:</strong> $orderNumber</p>
            <p><strong>${text['date']}:</strong> ${dateFormat.format(orderDate)}</p>
            <p><strong>${text['customer']}:</strong> $customerName</p>
            <p><strong>${text['deliveryAddress']}:</strong> $shippingAddress</p>
          </div>
          
          <table class="items-table">
            <thead>
              <tr>
                <th>${text['product']}</th>
                <th>${text['quantity']}</th>
                <th>${text['price']}</th>
                <th>${text['total']}</th>
              </tr>
            </thead>
            <tbody>
              ${items.map((item) => '''
                <tr>
                  <td>${item['name']}</td>
                  <td>${item['quantity']}</td>
                  <td>${currencyFormat.format(double.parse(item['price'].toString()))}</td>
                  <td>${currencyFormat.format(double.parse(item['price'].toString()) * (item['quantity'] as num))}</td>
                </tr>
              ''').join('')}
            </tbody>
          </table>
          
          <div class="total">
            <p>${text['totalAmount']}: ${currencyFormat.format(totalAmount)}</p>
          </div>
          
          <div style="text-align: center;">
            <a href="#" class="button">${text['viewOrderStatus']}</a>
          </div>
        </div>
        
        <div class="footer">
          <p>${text['support']}</p>
          <p>${text['copyright']}</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  // Send receipt email
  static Future<void> sendReceipt({
    required BuildContext context,
    required String customerEmail,
    required String customerName,
    required String orderNumber,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required DateTime orderDate,
    required String shippingAddress,
  }) async {
    try {
      final languageCode = _getCurrentLocale(context);
      
      final htmlContent = _generateReceiptTemplate(
        customerName: customerName,
        orderNumber: orderNumber,
        items: items,
        totalAmount: totalAmount,
        orderDate: orderDate,
        shippingAddress: shippingAddress,
        languageCode: languageCode,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/api/send-email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'to': customerEmail,
          'subject': 'Sipariş Onayı - #$orderNumber',
          'customerEmail': customerEmail,
          'customerName': customerName,
          'orderNumber': orderNumber,
          'items': items,
          'totalAmount': totalAmount,
          'orderDate': orderDate.toIso8601String(),
          'shippingAddress': shippingAddress,
          'htmlContent': htmlContent,
        }),
      );

      if (response.statusCode != 200) {
        print('Email sending failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to send email: ${response.body}');
      }

      print('Email sent successfully: ${response.body}');
    } catch (e) {
      print('Error sending email: $e');
      throw Exception('Failed to send email: $e');
    }
  }

  // Generate welcome email template
  static String _generateWelcomeTemplate({
    required String userName,
    required String verificationToken,
    required String languageCode,
  }) {
    final verificationUrl = '$_baseUrl/api/verify-email?token=$verificationToken';
    
    // Language-specific text
    final Map<String, Map<String, String>> translations = {
      'en': {
        'title': 'Welcome to Paradise PC Components!',
        'subtitle': 'Your Account Has Been Created Successfully',
        'hello': 'Hello',
        'welcomeMessage': 'Thank you for joining Paradise PC Components! We\'re excited to have you on board.',
        'accountCreated': 'Your account has been successfully created and you can now access all our features.',
        'verifyEmail': 'Verify Your Email',
        'features': 'What you can do now:',
        'feature1': 'Browse our extensive product catalog',
        'feature2': 'Place orders with secure payment options',
        'feature3': 'Track your orders in real-time',
        'feature4': 'Manage your profile and preferences',
        'startShopping': 'Start Shopping Now',
        'support': 'If you have any questions, our support team is here to help.',
        'copyright': '© 2024 Paradise PC Components. All rights reserved.',
      },
      'tr': {
        'title': 'Paradise PC Components\'a Hoş Geldiniz!',
        'subtitle': 'Hesabınız Başarıyla Oluşturuldu',
        'hello': 'Merhaba',
        'welcomeMessage': 'Paradise PC Components\'a katıldığınız için teşekkür ederiz! Sizi aramızda görmekten mutluluk duyuyoruz.',
        'accountCreated': 'Hesabınız başarıyla oluşturuldu ve artık tüm özelliklere erişebilirsiniz.',
        'verifyEmail': 'E-posta Adresinizi Doğrulayın',
        'features': 'Şunları yapabilirsiniz:',
        'feature1': 'Geniş ürün kataloğumuzu inceleyin',
        'feature2': 'Güvenli ödeme seçenekleriyle sipariş verin',
        'feature3': 'Siparişlerinizi gerçek zamanlı takip edin',
        'feature4': 'Profilinizi ve tercihlerinizi yönetin',
        'startShopping': 'Hemen Alışverişe Başlayın',
        'support': 'Sorularınız için destek ekibimiz size yardımcı olmaktan mutluluk duyar.',
        'copyright': '© 2024 Paradise PC Components. Tüm hakları saklıdır.',
      },
      'ar': {
        'title': 'مرحباً بك في Paradise PC Components!',
        'subtitle': 'تم إنشاء حسابك بنجاح',
        'hello': 'مرحباً',
        'welcomeMessage': 'شكراً لانضمامك إلى Paradise PC Components! يسعدنا وجودك معنا.',
        'accountCreated': 'تم إنشاء حسابك بنجاح ويمكنك الآن الوصول إلى جميع الميزات.',
        'verifyEmail': 'تحقق من بريدك الإلكتروني',
        'features': 'ما يمكنك فعله الآن:',
        'feature1': 'تصفح كتالوج منتجاتنا الواسع',
        'feature2': 'تقديم الطلبات مع خيارات دفع آمنة',
        'feature3': 'تتبع طلباتك في الوقت الفعلي',
        'feature4': 'إدارة ملفك الشخصي وتفضيلاتك',
        'startShopping': 'ابدأ التسوق الآن',
        'support': 'إذا كان لديك أي أسئلة، فريق الدعم لدينا هنا للمساعدة.',
        'copyright': '© 2024 Paradise PC Components. جميع الحقوق محفوظة.',
      },
    };

    final text = translations[languageCode] ?? translations['en']!;
    
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          line-height: 1.6;
          color: #333;
          margin: 0;
          padding: 0;
        }
        .container {
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }
        .header {
          background: linear-gradient(135deg, #ff4b4b 0%, #ff7676 100%);
          color: white;
          padding: 30px;
          text-align: center;
          border-radius: 10px 10px 0 0;
        }
        .content {
          background: #ffffff;
          padding: 30px;
          border: 1px solid #e0e0e0;
          border-radius: 0 0 10px 10px;
        }
        .welcome-message {
          margin-bottom: 30px;
        }
        .features {
          margin: 30px 0;
        }
        .feature-item {
          margin: 15px 0;
          padding-left: 25px;
          position: relative;
        }
        .feature-item:before {
          content: "✓";
          color: #ff4b4b;
          position: absolute;
          left: 0;
          font-weight: bold;
        }
        .button {
          display: inline-block;
          padding: 12px 24px;
          background: linear-gradient(135deg, #ff4b4b 0%, #ff7676 100%);
          color: white;
          text-decoration: none;
          border-radius: 5px;
          margin-top: 20px;
        }
        .verify-button {
          display: inline-block;
          padding: 12px 24px;
          background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
          color: white;
          text-decoration: none;
          border-radius: 5px;
          margin: 20px 0;
        }
        .footer {
          text-align: center;
          margin-top: 30px;
          color: #666;
          font-size: 0.9em;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div style="text-align:center; margin-bottom: 20px;">
          <img src="https://i.imgur.com/Chg9qcf.png" alt="Logo" style="height: 60px;">
        </div>
        <div class="header">
          <div class="logo-circle"></div>
          <h1>${text['title']}</h1>
          <p>${text['subtitle']}</p>
        </div>
        <div class="content">
          <div class="welcome-message">
            <h2>${text['hello']} $userName,</h2>
            <p>${text['welcomeMessage']}</p>
            <p>${text['accountCreated']}</p>
          </div>
          
          <div style="text-align: center;">
            <a href="$verificationUrl" class="verify-button">${text['verifyEmail']}</a>
          </div>
          
          <div class="features">
            <h3>${text['features']}</h3>
            <div class="feature-item">${text['feature1']}</div>
            <div class="feature-item">${text['feature2']}</div>
            <div class="feature-item">${text['feature3']}</div>
            <div class="feature-item">${text['feature4']}</div>
          </div>
          
          <div style="text-align: center;">
            <a href="#" class="button">${text['startShopping']}</a>
          </div>
        </div>
        
        <div class="footer">
          <p>${text['support']}</p>
          <p>${text['copyright']}</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  // Send welcome email
  static Future<void> sendWelcomeEmail({
    required BuildContext context,
    required String userEmail,
    required String userName,
    required String userId,
  }) async {
    try {
      final languageCode = _getCurrentLocale(context);
      
      // Generate a verification token
      final verificationToken = DateTime.now().millisecondsSinceEpoch.toString() + userId;
      
      // Store the verification token in Firestore
      await FirebaseFirestore.instance
          .collection('emailVerifications')
          .doc(userId)
          .set({
            'token': verificationToken,
            'email': userEmail,
            'createdAt': FieldValue.serverTimestamp(),
            'verified': false,
          });

      final response = await http.post(
        Uri.parse('$_baseUrl/api/send-email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customerEmail': userEmail,
          'customerName': userName,
          'subject': 'Welcome to Paradise PC Components!',
          'htmlContent': _generateWelcomeTemplate(
            userName: userName,
            verificationToken: verificationToken,
            languageCode: languageCode,
          ),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send welcome email: ${response.body}');
      }

      print('Welcome email sent successfully: ${response.body}');
    } catch (e) {
      print('Error sending welcome email: $e');
      // Don't throw the error as the account was already created successfully
    }
  }

  // Verify email
  static Future<bool> verifyEmail(String token) async {
    try {
      // Find the verification document
      final verificationQuery = await FirebaseFirestore.instance
          .collection('emailVerifications')
          .where('token', isEqualTo: token)
          .get();

      if (verificationQuery.docs.isEmpty) {
        return false;
      }

      final verificationDoc = verificationQuery.docs.first;
      final userId = verificationDoc.id;
      final verificationData = verificationDoc.data();

      // Check if already verified
      if (verificationData['verified'] == true) {
        return true;
      }

      // Update user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'emailVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          });

      // Update verification document
      await verificationDoc.reference.update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error verifying email: $e');
      return false;
    }
  }

  // Generate verification email template
  static String _generateVerificationTemplate({
    required String userName,
    required String verificationLink,
    required String languageCode,
  }) {
    // Language-specific text
    final Map<String, Map<String, String>> translations = {
      'en': {
        'title': 'Verify Your Email',
        'subtitle': 'Paradise PC Components',
        'hello': 'Hello',
        'message': 'Thank you for registering with Paradise PC Components! To complete your registration and access all features, please verify your email address.',
        'verifyButton': 'Verify Email Address',
        'expiryNotice': 'This verification link will expire in 24 hours.',
        'manualLink': 'If the button above doesn\'t work, copy and paste this link into your browser:',
        'features': 'After verification, you can:',
        'feature1': 'Access your personalized dashboard',
        'feature2': 'Browse our product catalog',
        'feature3': 'Make secure purchases',
        'feature4': 'Track your orders',
        'ignore': 'If you didn\'t create an account, you can safely ignore this email.',
        'copyright': '© 2024 Paradise PC Components. All rights reserved.',
      },
      'tr': {
        'title': 'E-posta Adresinizi Doğrulayın',
        'subtitle': 'Paradise PC Components',
        'hello': 'Merhaba',
        'message': 'Paradise PC Components\'a kayıt olduğunuz için teşekkür ederiz! Kaydınızı tamamlamak ve tüm özelliklere erişmek için lütfen e-posta adresinizi doğrulayın.',
        'verifyButton': 'E-posta Adresini Doğrula',
        'expiryNotice': 'Bu doğrulama bağlantısı 24 saat içinde sona erecektir.',
        'manualLink': 'Yukarıdaki düğme çalışmazsa, bu bağlantıyı tarayıcınıza kopyalayıp yapıştırın:',
        'features': 'Doğrulamadan sonra şunları yapabilirsiniz:',
        'feature1': 'Kişiselleştirilmiş panelinize erişin',
        'feature2': 'Ürün kataloğumuzu inceleyin',
        'feature3': 'Güvenli alışveriş yapın',
        'feature4': 'Siparişlerinizi takip edin',
        'ignore': 'Bir hesap oluşturmadıysanız, bu e-postayı güvenle görmezden gelebilirsiniz.',
        'copyright': '© 2024 Paradise PC Components. Tüm hakları saklıdır.',
      },
      'ar': {
        'title': 'تحقق من بريدك الإلكتروني',
        'subtitle': 'Paradise PC Components',
        'hello': 'مرحباً',
        'message': 'شكراً لتسجيلك في Paradise PC Components! لإكمال تسجيلك والوصول إلى جميع الميزات، يرجى التحقق من عنوان بريدك الإلكتروني.',
        'verifyButton': 'تحقق من البريد الإلكتروني',
        'expiryNotice': 'ستنتهي صلاحية رابط التحقق هذا خلال 24 ساعة.',
        'manualLink': 'إذا لم يعمل الزر أعلاه، انسخ هذا الرابط والصقه في متصفحك:',
        'features': 'بعد التحقق، يمكنك:',
        'feature1': 'الوصول إلى لوحة التحكم الشخصية',
        'feature2': 'تصفح كتالوج المنتجات',
        'feature3': 'إجراء عمليات شراء آمنة',
        'feature4': 'تتبع طلباتك',
        'ignore': 'إذا لم تقم بإنشاء حساب، يمكنك تجاهل هذا البريد الإلكتروني بأمان.',
        'copyright': '© 2024 Paradise PC Components. جميع الحقوق محفوظة.',
      },
    };

    final text = translations[languageCode] ?? translations['en']!;
    
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          line-height: 1.6;
          color: #333;
          margin: 0;
          padding: 0;
        }
        .container {
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }
        .header {
          background: linear-gradient(135deg, #ff4b4b 0%, #ff7676 100%);
          color: white;
          padding: 30px;
          text-align: center;
          border-radius: 10px 10px 0 0;
        }
        .content {
          background: #ffffff;
          padding: 30px;
          border: 1px solid #e0e0e0;
          border-radius: 0 0 10px 10px;
        }
        .verification-message {
          margin-bottom: 30px;
          text-align: center;
        }
        .verify-button {
          display: inline-block;
          padding: 12px 24px;
          background: linear-gradient(135deg, #ff4b4b 0%, #ff7676 100%);
          color: white;
          text-decoration: none;
          border-radius: 5px;
          margin: 20px 0;
          font-weight: bold;
        }
        .steps {
          margin: 30px 0;
          padding: 0;
          list-style: none;
        }
        .step {
          margin: 15px 0;
          padding-left: 25px;
          position: relative;
        }
        .step:before {
          content: "✓";
          color: #ff4b4b;
          position: absolute;
          left: 0;
          font-weight: bold;
        }
        .footer {
          text-align: center;
          margin-top: 30px;
          color: #666;
          font-size: 0.9em;
        }
        .expiry-notice {
          background: #fff3cd;
          color: #856404;
          padding: 15px;
          border-radius: 5px;
          margin: 20px 0;
          text-align: center;
        }
        .manual-link {
          word-break: break-all;
          color: #666;
          font-size: 0.9em;
          margin-top: 20px;
          text-align: center;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div style="text-align:center; margin-bottom: 20px;">
          <img src="https://i.imgur.com/Chg9qcf.png" alt="Logo" style="height: 60px;">
        </div>
        <div class="header">
          <div class="logo-circle"></div>
          <h1>${text['title']}</h1>
          <p>${text['subtitle']}</p>
        </div>
        <div class="content">
          <div class="verification-message">
            <h2>${text['hello']} $userName,</h2>
            <p>${text['message']}</p>
          </div>
          
          <div style="text-align: center;">
            <a href="$verificationLink" class="verify-button">${text['verifyButton']}</a>
          </div>
          
          <div class="expiry-notice">
            ${text['expiryNotice']}
          </div>
          
          <div class="manual-link">
            ${text['manualLink']}<br>
            <a href="$verificationLink">$verificationLink</a>
          </div>
          
          <div class="steps">
            <h3>${text['features']}</h3>
            <div class="step">${text['feature1']}</div>
            <div class="step">${text['feature2']}</div>
            <div class="step">${text['feature3']}</div>
            <div class="step">${text['feature4']}</div>
          </div>
        </div>
        
        <div class="footer">
          <p>${text['ignore']}</p>
          <p>${text['copyright']}</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  // Send verification email
  static Future<void> sendVerificationEmail({
    required BuildContext context,
    required String userEmail,
    required String userName,
    required String verificationLink,
  }) async {
    try {
      final languageCode = _getCurrentLocale(context);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/send-email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customerEmail': userEmail,
          'customerName': userName,
          'subject': 'Verify Your Email - Paradise PC Components',
          'htmlContent': _generateVerificationTemplate(
            userName: userName,
            verificationLink: verificationLink,
            languageCode: languageCode,
          ),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send verification email: ${response.body}');
      }

      print('Verification email sent successfully: ${response.body}');
    } catch (e) {
      print('Error sending verification email: $e');
      throw Exception('Failed to send verification email: $e');
    }
  }
} 