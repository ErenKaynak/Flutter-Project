<div align="center">

# 🎮 Paradise PC Parts
### *AI-Assisted E-Commerce for PC Enthusiasts*

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org)
[![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)](https://developer.mozilla.org/en-US/docs/Web/JavaScript)

**An intelligent Flutter-based e-commerce platform for PC components with AI assistance, multi-language support, and advanced discount mechanisms.**

[🌐 Live Demo](https://engineering-project-23d2e.web.app) • [📂 GitHub Repository](https://github.com/ErenKaynak/Flutter-Project) • [📖 Documentation](https://docs.flutter.dev/)

---

### 🏆 Award-Winning Project
**🥇 Nominated as #1 Faculty Engineering Project**  
Beykoz University (2024-2025)

[📺 View Award Ceremony & Exhibition →](https://www.beykoz.edu.tr/haber/5620-2024–2025-yilin-muhendislik-projeleri-odul-toreni-ve-sergisi-gerceklesti)

</div>

---

## 📋 Project Overview

Paradise PC Parts is a comprehensive e-commerce application designed specifically for computer component shopping. Built with Flutter and Firebase, it combines modern UI/UX design with artificial intelligence capabilities to deliver a seamless shopping experience. The platform is scalable to support any product category while maintaining a focus on PC components.

**🎯 Key Distinction:** While designed for PC parts, Paradise's architecture is modular and interchangeable, allowing it to adapt to any product category with minimal modifications.

---

## ✨ Key Features

<table>
<tr>
<td width="50%" valign="top">

### 🔐 Authentication & Security
- **Google OAuth 2.0** - Secure sign-in integration
- **Biometric Auth** - Fingerprint/Face ID support*
- **Email Verification** - Robust validation system

### 🛍️ Shopping Experience
- **Dynamic Product Browsing** - Intuitive discovery
- **Smart Search** - Real-time product search
- **Cart Management** - Seamless checkout flow
- **Multi-tier Discounts** - Advanced pricing system
- **Discount Wheel** - Gamified rewards
- **Referral Program** - User acquisition incentives

### 🤖 AI-Powered Features
- **Tommy AI Assistant** - Personalized recommendations*
- **Stock Intelligence** - Real-time monitoring
- **PC Build Advisor** - Smart configuration suggestions*
  - Budget optimization
  - Performance matching
  - Compatibility checking

</td>
<td width="50%" valign="top">

### 👤 User Management
- **Personalized Profiles** - Custom account settings
- **Order Tracking** - Complete purchase history
- **Wishlists** - Save favorite items
- **Address Book** - Multiple shipping addresses
- **Digital Wallet** - In-app payment system
- **Reviews & Ratings** - Community feedback

### 💳 Payment & Transactions
- **In-App Wallet** - Digital payment method
- **Multiple Payment Options** - Flexible checkout
- **Transaction History** - Financial records
- **Auto Email Confirmations** - Order notifications

### 👨‍💼 Admin Dashboard
- **Inventory Management** - Stock monitoring
- **Low Stock Alerts** - Automated notifications
- **Sales Analytics** - Business insights
- **User Management** - Account controls
- **Campaign Management** - Discount creation

### 🎨 Customization
- **🌓 Dark Mode** - Eye-friendly interface
- **🎨 4 Color Themes** - Red, Yellow, Purple, Green
- **🌍 4 Languages** - EN, TR, AR, UR
- **📱 Adaptive UI** - Responsive design

</td>
</tr>
</table>

<sub>* Currently offline due to hosting limitations</sub>

---

## 🛠️ Tech Stack

<div align="center">

### Frontend Development
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)

### Backend & Cloud Services
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black)
![Node.js](https://img.shields.io/badge/Node.js-43853D?style=flat-square&logo=node.js&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=flat-square&logo=javascript&logoColor=black)

### Development Tools
![Android Studio](https://img.shields.io/badge/Android_Studio-3DDC84?style=flat-square&logo=android-studio&logoColor=white)
![VS Code](https://img.shields.io/badge/VS_Code-007ACC?style=flat-square&logo=visual-studio-code&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?style=flat-square&logo=git&logoColor=white)

</div>

### 🔥 Firebase Services
- **Firestore** - Real-time NoSQL database
- **Authentication** - Secure user management
- **Cloud Storage** - File storage solution
- **Hosting** - Application deployment
- **Admin SDK** - Backend operations
- **Cloud Functions** - Serverless logic

### ⚙️ Backend Architecture
- **Custom JavaScript Server** - Business logic implementation
- **Node.js Runtime** - Backend service execution
- **Email Service Integration** - Transactional emails
- **NorOk** - Additional backend service

---

## 🚀 Getting Started

### 📦 Prerequisites

```bash
✅ Flutter SDK (latest version)
✅ Dart SDK
✅ Android Studio or VS Code
✅ Git
✅ Firebase account
```

### 🔧 Installation

**1️⃣ Clone the Repository**
```bash
git clone https://github.com/ErenKaynak/Flutter-Project.git
cd Flutter-Project
```

**2️⃣ Install Dependencies**
```bash
flutter pub get
```

**3️⃣ Configure Firebase**
1. Create a Firebase project at [firebase.google.com](https://firebase.google.com)
2. Configure Firebase credentials for your platform
3. Download and add configuration files:
   - **Android**: `google-services.json` → `android/app/`
   - **iOS**: `GoogleService-Info.plist` → `ios/Runner/`

**4️⃣ Run the Application**
```bash
# Development mode
flutter run

# Production build
flutter build apk  # Android
flutter build ios  # iOS
flutter build web  # Web deployment
```

---

## 📱 Application Architecture

```
Paradise PC Parts/
│
├── 🏠 Home Screen
│   ├── Featured Products
│   ├── Active Discounts
│   └── Personalized Recommendations
│
├── 🔍 Search & Browse
│   ├── Advanced Filtering
│   ├── Category Navigation
│   └── Product Discovery
│
├── 🤖 AI Assistant (Tommy)
│   ├── Chat Interface
│   ├── Product Recommendations
│   └── PC Build Suggestions
│
├── 🛒 Shopping Cart
│   ├── Cart Management
│   ├── Discount Application
│   └── Checkout Flow
│
├── 💰 Wallet & Payments
│   ├── Balance Management
│   ├── Transaction History
│   └── Payment Methods
│
├── 👤 User Profile
│   ├── Account Settings
│   ├── Order History
│   ├── Wishlist
│   └── Addresses
│
├── 👨‍💼 Admin Dashboard
│   ├── Inventory Management
│   ├── Sales Analytics
│   ├── User Management
│   └── Discount Campaigns
│
└── ⚙️ Settings
    ├── Theme Selection
    ├── Language Settings
    └── UI Customization
```

---

## 💡 Notable Implementation Highlights

### 🎯 Technical Achievements

- **Real-time Synchronization** - Instant updates across all user sessions using Firestore
- **AI-Powered Recommendations** - Machine learning integration for personalized suggestions
- **Custom Backend Architecture** - Self-built JavaScript server for advanced business logic
- **Automated Email System** - Template-based order confirmations with tracking details
- **Passwordless Options** - Enhanced security with biometric authentication
- **Scalable Localization** - Modular multi-language support system
- **Responsive Cross-Platform** - Adaptive UI for mobile, tablet, and web
- **Comprehensive Admin Tools** - Full-featured business management dashboard
- **Gamification Strategy** - Engagement features like discount wheels and referrals

### 🏗️ Architecture Patterns

- **Provider State Management** - Efficient app-wide state handling
- **Repository Pattern** - Clean separation of data sources
- **Dependency Injection** - Loosely coupled, testable code
- **Modular Component Design** - Reusable UI widgets
- **Firebase Security Rules** - Backend data protection

---

## 📊 Project Statistics

<div align="center">

| Feature | Count |
|---------|-------|
| 🔐 Authentication Methods | 3+ (Google, Email, Biometric) |
| 🌍 Language Support | 4 Languages |
| 🎨 Theme Options | 4 Custom Themes |
| 🤖 AI Features | 3 Major Systems |
| 👨‍💼 Admin Functions | 10+ Tools |
| 📱 Supported Platforms | Android, iOS, Web |

</div>

---

## ⚠️ Current Status

### 🔴 Temporarily Offline Features
- **Biometric Sign-In** - Development complete, awaiting hosting activation
- **Tommy AI Assistant** - Fully developed, hosting service pending
- **PC Build Recommendations** - Complete implementation, server deployment needed

> These features are fully functional in development and will be activated once hosting services are configured.

---

## 👥 Development Team

<div align="center">

### 👨‍💻 Core Developers
**Eren Kaynak** & **Yasin Deniz Zeybek**

### 👩‍🏫 Academic Advisor
**İnal Begüm Turna Demirel**

### 🎓 Institution
**Beykoz University**  
Faculty of Engineering  
Academic Year: 2024-2025

</div>

---

## 🤝 Contributing

We welcome contributions! If you'd like to improve Paradise PC Parts:

1. 🍴 Fork the repository
2. 🌿 Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. 💾 Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. 📤 Push to the branch (`git push origin feature/AmazingFeature`)
5. 🔃 Open a Pull Request

---

## 📄 License

This project is part of an academic engineering project at Beykoz University.  
All rights reserved to the development team and academic institution.

---

## 🔗 Important Links

<div align="center">

[![Live Demo](https://img.shields.io/badge/🌐_Live_Demo-Visit_Site-blue?style=for-the-badge)](https://engineering-project-23d2e.web.app)
[![GitHub](https://img.shields.io/badge/📂_GitHub-View_Code-black?style=for-the-badge&logo=github)](https://github.com/ErenKaynak/Flutter-Project)
[![Flutter Docs](https://img.shields.io/badge/📖_Flutter-Documentation-02569B?style=for-the-badge&logo=flutter)](https://docs.flutter.dev/)
[![Firebase](https://img.shields.io/badge/🔥_Firebase-Console-FFCA28?style=for-the-badge&logo=firebase)](https://firebase.google.com)

</div>

---

## 📞 Support & Contact

<div align="center">

**Questions? Feedback? Get in touch!**

🎓 **University**: Beykoz University, Istanbul, Turkey  
📧 **Email**: Contact via GitHub repository  
🌐 **Website**: [Beykoz University Engineering Faculty](https://www.beykoz.edu.tr)

</div>

---

<div align="center">

### Made with ❤️ for the PC Gaming Community

**Paradise PC Parts** • *Your Ultimate PC Building Companion*

⭐ Star this repo if you found it helpful! ⭐

</div>