const express = require('express');
const fetch = require('node-fetch');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Enable CORS and JSON parsing
app.use(cors());
app.use(express.json());

// Environment variables for OneSignal configuration
const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID;
const ONESIGNAL_REST_API_KEY = process.env.ONESIGNAL_REST_API_KEY;

// Utility function for sending OneSignal notifications
async function sendOneSignalNotification(notificationBody) {
  const response = await fetch('https://onesignal.com/api/v1/notifications', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
    },
    body: JSON.stringify({
      app_id: ONESIGNAL_APP_ID,
      ...notificationBody
    }),
  });

  const data = await response.json();
  
  if (!response.ok) {
    throw new Error(JSON.stringify(data));
  }

  return data;
}

// Middleware to validate OneSignal configuration
app.use((req, res, next) => {
  if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
    return res.status(500).json({ 
      success: false,
      error: 'OneSignal configuration missing. Please set ONESIGNAL_APP_ID and ONESIGNAL_REST_API_KEY environment variables.' 
    });
  }
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok',
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV || 'development'
  });
});

/**
 * Validate OneSignal configuration
 * GET /validate
 */
app.get('/validate', async (req, res) => {
  try {
    const response = await fetch(`https://onesignal.com/api/v1/apps/${ONESIGNAL_APP_ID}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
    });

    const data = await response.json();
    
    if (!response.ok) {
      return res.status(response.status).json({
        success: false,
        error: 'Failed to validate OneSignal configuration',
        details: data
      });
    }

    res.json({
      success: true,
      data: {
        name: data.name,
        players: data.players,
        messageable_players: data.messageable_players
      }
    });
  } catch (error) {
    console.error('Error validating configuration:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Internal server error during validation',
      details: error.message 
    });
  }
});

/**
 * Send notification endpoint
 * POST /send-notification
 * 
 * Request body:
 * {
 *   "title": "Optional notification title",
 *   "message": "Required notification message",
 *   "userIds": ["optional", "array", "of", "user", "ids"],
 *   "additionalData": { "optional": "custom data object" }
 * }
 */
app.post('/send-notification', async (req, res) => {
  const { title, message, userIds, additionalData } = req.body;
  
  if (!message) {
    return res.status(400).json({ 
      success: false, 
      error: 'Missing message in request body' 
    });
  }

  try {
    const notificationBody = {
      contents: { en: message },
      headings: title ? { en: title } : undefined,
      data: additionalData
    };

    // If userIds are provided, target specific users
    if (userIds?.length > 0) {
      notificationBody.include_external_user_ids = userIds;
    } else {
      notificationBody.included_segments = ['Total Subscriptions'];
    }

    const data = await sendOneSignalNotification(notificationBody);
    res.json({ success: true, data });
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to send notification',
      details: error.message 
    });
  }
});

/**
 * Test notification endpoint - sends a simple test notification
 * POST /test-notification
 */
app.post('/test-notification', async (req, res) => {
  try {
    const data = await sendOneSignalNotification({
      included_segments: ['Subscribed Users'],
      contents: { en: 'This is a test notification' },
      headings: { en: 'Test Notification' },
      data: { type: 'test' }
    });

    res.json({ success: true, data });
  } catch (error) {
    console.error('Error sending test notification:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to send test notification',
      details: error.message 
    });
  }
});

/**
 * Send discount notification endpoint
 * POST /send-discount-notification
 * 
 * Request body:
 * {
 *   "discountCode": {
 *     "id": "string",
 *     "code": "string",
 *     "name": "string",
 *     "description": "string",
 *     "discountPercentage": number,
 *     "expiryDate": "ISO date string",
 *     "perUserLimit": number,
 *     "usageLimit": number
 *   }
 * }
 */
app.post('/send-discount-notification', async (req, res) => {
  const { discountCode } = req.body;
  
  if (!discountCode?.code) {
    return res.status(400).json({ 
      success: false, 
      error: 'Missing discount code details' 
    });
  }

  try {
    const data = await sendOneSignalNotification({
      included_segments: ['Subscribed Users'],
      contents: {
        en: `Use code ${discountCode.code} to get ${discountCode.discountPercentage}% off!`
      },
      headings: { 
        en: 'New Discount Available!' 
      },
      data: {
        type: 'discount',
        discountId: discountCode.id,
        code: discountCode.code,
        percentage: discountCode.discountPercentage,
        expiryDate: discountCode.expiryDate,
        name: discountCode.name,
        description: discountCode.description
      },
      buttons: [{
        id: "save-discount",
        text: "Save Discount",
        url: "app://save-discount"
      }],
      android_channel_id: "discount_notifications",
      android_group: "discounts",
      thread_id: "discounts",
      priority: 10,
      ttl: discountCode.expiryDate ? new Date(discountCode.expiryDate).getTime() - Date.now() : 2592000 // 30 days if no expiry
    });

    res.json({ success: true, data });
  } catch (error) {
    console.error('Error sending discount notification:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to send discount notification',
      details: error.message 
    });
  }
});

/**
 * Save discount for user endpoint
 * POST /save-discount
 * 
 * Request body:
 * {
 *   "userId": "string",
 *   "discountId": "string"
 * }
 */
app.post('/save-discount', async (req, res) => {
  const { userId, discountId } = req.body;

  if (!userId || !discountId) {
    return res.status(400).json({ 
      success: false, 
      error: 'Missing userId or discountId' 
    });
  }

  try {
    const data = await sendOneSignalNotification({
      include_external_user_ids: [userId],
      contents: {
        en: 'Discount code has been saved to your account!'
      },
      headings: {
        en: 'Discount Saved'
      },
      data: {
        type: 'discount_saved',
        discountId: discountId
      }
    });

    res.json({ success: true, data });
  } catch (error) {
    console.error('Error saving discount:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to save discount',
      details: error.message 
    });
  }
});

/**
 * API endpoint for discount notifications
 * POST /api/notify/discount
 */
app.post('/api/notify/discount', async (req, res) => {
  const { title, message, discountCode, discountPercentage, expiryDate, discountId } = req.body;
  
  if (!discountCode || !discountPercentage || !discountId) {
    return res.status(400).json({ 
      success: false, 
      error: 'Missing required discount details' 
    });
  }

  try {
    const data = await sendOneSignalNotification({
      included_segments: ['Subscribed Users'],
      contents: {
        en: message || `Use code ${discountCode} to get ${discountPercentage}% off!`
      },
      headings: { 
        en: title || 'New Discount Available!' 
      },
      data: {
        type: 'discount',
        discountId: discountId,
        code: discountCode,
        percentage: discountPercentage,
        expiryDate: expiryDate,
      },
      buttons: [{
        id: "save-discount",
        text: "Save Discount",
        url: "app://save-discount"
      }],
      android_channel_id: "discount_notifications",
      android_group: "discounts",
      thread_id: "discounts",
      priority: 10,
      ttl: discountCode.expiryDate ? new Date(discountCode.expiryDate).getTime() - Date.now() : 2592000
    });

    res.json({ success: true, data });
  } catch (error) {
    console.error('Error sending discount notification:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to send notification',
      details: error.message 
    });
  }
});

// Start server with improved configuration
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0'; // Listen on all network interfaces

app.listen(PORT, HOST, () => {
  console.log(`OneSignal notification server listening on ${HOST}:${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log('Ready to handle notification requests');
});