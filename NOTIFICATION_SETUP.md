# Notification System Setup Guide

This guide will help you set up the complete notification system for your Flutter app using OneSignal and Railway backend.

## Prerequisites

1. OneSignal account
2. Railway account (for backend deployment)
3. Flutter project with Firebase setup

## Step 1: OneSignal Configuration

### 1.1 Create OneSignal App

1. Go to [OneSignal](https://onesignal.com) and sign in
2. Click "New App/Website"
3. Enter your app name
4. Select "Google Android (FCM)" and "Apple iOS (APNs)" platforms
5. Follow the platform-specific setup guides

### 1.2 Get OneSignal Credentials

1. Go to Settings > Keys & IDs in your OneSignal dashboard
2. Copy the following values:
   - **App ID**: (e.g., `bb5b6419-07c9-4b72-9d85-e2c121f05591`)
   - **REST API Key**: (starts with `Basic ` or just the key itself)

## Step 2: Backend Deployment on Railway

### 2.1 Deploy Backend

1. Install Railway CLI:
   ```bash
   npm install -g @railway/cli
   ```

2. Navigate to the backend directory:
   ```bash
   cd Flutter-Project/email-backend
   ```

3. Install dependencies:
   ```bash
   npm install
   ```

4. Login to Railway:
   ```bash
   railway login
   ```

5. Initialize Railway project:
   ```bash
   railway init
   ```

6. Set environment variables in Railway:
   ```bash
   railway variables set ONESIGNAL_APP_ID=your_app_id_here
   railway variables set ONESIGNAL_REST_API_KEY=your_rest_api_key_here
   railway variables set NODE_ENV=production
   ```

7. Deploy to Railway:
   ```bash
   railway up
   ```

8. Note your Railway deployment URL (e.g., `https://your-app-name.up.railway.app`)

### 2.2 Update Flutter App URLs

Update the backend URL in your Flutter notification services:

1. In `lib/assets/components/notification_service.dart`, update:
   ```dart
   static const String _backendUrl = 'https://your-railway-app.up.railway.app';
   ```

2. In `lib/services/notification_service.dart`, update:
   ```dart
   static const String _baseUrl = 'https://your-railway-app.up.railway.app';
   ```

## Step 3: Flutter App Configuration

### 3.1 Update OneSignal Credentials

1. In `lib/services/notification_init.dart`, update:
   ```dart
   static const String _oneSignalAppId = 'your_app_id_here';
   static const String _oneSignalRestApiKey = 'your_rest_api_key_here';
   ```

### 3.2 Verify Dependencies

Ensure your `pubspec.yaml` includes:
```yaml
dependencies:
  onesignal_flutter: ^5.0.0
  http: ^1.1.0
  cloud_firestore: ^4.13.0
  firebase_auth: ^4.15.0
```

## Step 4: Testing

### 4.1 Test Backend

1. Test the health endpoint:
   ```bash
   curl https://your-railway-app.up.railway.app/
   ```

2. Test configuration:
   ```bash
   curl https://your-railway-app.up.railway.app/test
   ```

3. Send test notification:
   ```bash
   curl -X POST https://your-railway-app.up.railway.app/test-notification \
        -H "Content-Type: application/json"
   ```

### 4.2 Test Flutter App

1. Run your Flutter app
2. Sign in with a user account
3. Go to notifications page
4. Test subscription/unsubscription
5. Send test notifications from admin panel

## Step 5: Admin Panel Usage

### 5.1 General Notifications

Use `AdminNotificationManagement` to:
- Send notifications to all users
- Send notifications to specific users
- Include images in notifications
- Track delivery status

### 5.2 Discount Notifications

Use `DiscountAdminPage` to:
- Send discount codes to all users
- Include expiry dates
- Track discount usage
- Save discount codes to user accounts

## Troubleshooting

### Common Issues

1. **"OneSignal not initialized"**
   - Check if `NotificationInitializer.initialize()` is called in `main()`
   - Verify OneSignal App ID and REST API Key

2. **"No subscribers found"**
   - Ensure users have subscribed to notifications
   - Check if notification permission is granted

3. **Backend connection issues**
   - Verify Railway deployment URL is correct
   - Check environment variables in Railway dashboard
   - Monitor Railway logs: `railway logs`

4. **Notifications not received**
   - Check OneSignal delivery reports
   - Verify device tokens in OneSignal dashboard
   - Ensure app is in foreground/background for testing

### Debug Commands

1. Check Railway logs:
   ```bash
   railway logs
   ```

2. Check OneSignal configuration in Flutter:
   ```dart
   print('Initialized: ${NotificationInitializer.isInitialized}');
   print('Configured: ${NotificationInitializer.isConfigured}');
   ```

3. Test notification API directly:
   ```bash
   curl -X POST https://your-railway-app.up.railway.app/send-notification \
        -H "Content-Type: application/json" \
        -d '{"title":"Test","message":"Hello World"}'
   ```

## Security Notes

1. Never commit your OneSignal REST API Key to version control
2. Use Railway environment variables for sensitive data
3. Consider implementing authentication for admin endpoints
4. Monitor notification usage to prevent abuse

## Production Checklist

- [ ] OneSignal app configured for production
- [ ] Railway backend deployed and tested
- [ ] Environment variables set correctly
- [ ] Flutter app updated with production URLs
- [ ] Notification permissions tested on both iOS and Android
- [ ] Admin panel access restricted
- [ ] Monitoring and logging enabled
- [ ] Backup notification delivery method configured