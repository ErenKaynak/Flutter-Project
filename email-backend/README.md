# Notification Backend for Flutter App

This is a Node.js backend service for handling OneSignal push notifications, deployed on Railway.

## Setup Instructions

### 1. OneSignal Configuration

1. Go to [OneSignal](https://onesignal.com) and create an account
2. Create a new app for your Flutter project
3. Get your **App ID** and **REST API Key** from the OneSignal dashboard:
   - App ID: Found in Settings > Keys & IDs
   - REST API Key: Found in Settings > Keys & IDs

### 2. Environment Variables

Update the `.env` file with your OneSignal credentials:

```env
ONESIGNAL_APP_ID=your_app_id_here
ONESIGNAL_REST_API_KEY=your_rest_api_key_here
PORT=3000
NODE_ENV=production
```

### 3. Railway Deployment

1. Install Railway CLI:
   ```bash
   npm install -g @railway/cli
   ```

2. Login to Railway:
   ```bash
   railway login
   ```

3. Initialize Railway project (run from email-backend directory):
   ```bash
   railway init
   ```

4. Set environment variables in Railway:
   ```bash
   railway variables set ONESIGNAL_APP_ID=your_app_id_here
   railway variables set ONESIGNAL_REST_API_KEY=your_rest_api_key_here
   railway variables set NODE_ENV=production
   ```

5. Deploy to Railway:
   ```bash
   railway up
   ```

### 4. Update Flutter App

After deployment, update your Flutter app's notification service URLs to point to your Railway deployment URL.

## API Endpoints

### Health Check
- `GET /` - Check if the service is running

### Test
- `GET /test` - Test endpoint with configuration status

### Send Notifications
- `POST /send-notification` - Send notification to all users or specific users
- `POST /test-notification` - Send a test notification

### Discount Notifications
- `POST /api/notify/discount` - Send discount-specific notifications

### Statistics
- `GET /stats` - Get OneSignal app statistics

## Request Examples

### Send Notification to All Users
```json
POST /send-notification
{
  "title": "Hello World",
  "message": "This is a test notification",
  "additionalData": {
    "type": "general"
  }
}
```

### Send Notification to Specific Users
```json
POST /send-notification
{
  "title": "Personal Message",
  "message": "This is for specific users",
  "userIds": ["user1", "user2"],
  "additionalData": {
    "type": "targeted"
  }
}
```

### Send Discount Notification
```json
POST /api/notify/discount
{
  "title": "Special Discount!",
  "message": "Get 20% off your next purchase",
  "discountCode": "SAVE20",
  "discountPercentage": 20,
  "discountId": "discount_123",
  "expiryDate": "2024-12-31T23:59:59Z"
}
```

## Troubleshooting

1. **Invalid REST API Key**: Ensure your OneSignal REST API key is correct and has the necessary permissions
2. **No Subscribers**: Make sure users have subscribed to notifications in your Flutter app
3. **CORS Issues**: The backend includes CORS middleware for cross-origin requests
4. **Environment Variables**: Double-check that all required environment variables are set in Railway

## Monitoring

- Check Railway logs for debugging: `railway logs`
- Monitor OneSignal delivery reports in the OneSignal dashboard
- Use the `/stats` endpoint to check subscriber counts