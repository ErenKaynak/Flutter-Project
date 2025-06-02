const express = require('express');
const fetch = require('node-fetch');
const cors = require('cors');
require('dotenv').config();

const app = express();

app.use(cors());
app.use(express.json());

// Environment variables for OneSignal configuration
const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID;
const ONESIGNAL_REST_API_KEY = process.env.ONESIGNAL_REST_API_KEY;

// Middleware to validate OneSignal configuration
app.use((req, res, next) => {
  if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
    return res.status(500).json({ 
      error: 'OneSignal configuration missing. Please set ONESIGNAL_APP_ID and ONESIGNAL_REST_API_KEY environment variables.' 
    });
  }
  next();
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
 * 
 * Response:
 * {
 *   "success": true,
 *   "data": { OneSignal API response }
 * }
 */

app.post('/send-notification', async (req, res) => {
  const { title, message, userIds, additionalData } = req.body;
  if (!message) {
    return res.status(400).json({ error: 'Missing message in request body' });
  }

  try {
    const notificationBody = {
      app_id: ONESIGNAL_APP_ID,
      contents: { en: message },
      headings: title ? { en: title } : undefined,
      data: additionalData
    };

    // If userIds are provided, target specific users
    if (userIds && Array.isArray(userIds) && userIds.length > 0) {
      notificationBody.include_external_user_ids = userIds;
    } else {
      notificationBody.included_segments = ['Total Subscriptions'];
    }

    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify(notificationBody),
    });

    const data = await response.json();

    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    res.json({ success: true, data });
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
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
    res.status(500).json({ error: 'Internal server error during validation' });
  }
});

/**
 * Test notification endpoint - sends a simple test notification
 * POST /test-notification
 */
app.post('/test-notification', async (req, res) => {
  try {
    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        included_segments: ['Subscribed Users'],
        contents: { en: 'This is a test notification' },
        headings: { en: 'Test Notification' },
        data: { type: 'test' }
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      return res.status(response.status).json({
        success: false,
        error: 'Failed to send test notification',
        details: data
      });
    }

    res.json({ success: true, data });
  } catch (error) {
    console.error('Error sending test notification:', error);
    res.status(500).json({ error: 'Internal server error while sending test notification' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`OneSignal notification server listening on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
