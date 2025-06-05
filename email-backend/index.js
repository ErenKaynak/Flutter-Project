const express = require('express');
const axios = require('axios');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Environment variables for OneSignal configuration
const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID || 'bb5b6419-07c9-4b72-9d85-e2c121f05591';
const ONESIGNAL_REST_API_KEY = process.env.ONESIGNAL_REST_API_KEY || 'os_v2_app_xnnwigihzffxfhmf4lasd4cvshp4lnkq7zsuoomolom6c6an5hh342rf54jd4eca3zykr2a6qbqo3cyls36fx27rzz3zh4rphqaaqty';

if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
  console.error('OneSignal configuration is missing. Please set ONESIGNAL_APP_ID and ONESIGNAL_REST_API_KEY environment variables.');
}

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'Notification Backend is running',
    timestamp: new Date().toISOString(),
    status: 'healthy'
  });
});

// Test endpoint to check if server is running
app.get('/test', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Server is running',
    oneSignalConfigured: {
      appId: !!ONESIGNAL_APP_ID,
      restApiKey: !!ONESIGNAL_REST_API_KEY
    }
  });
});

// Send notification to all users
app.post('/send-notification', async (req, res) => {
  try {
    const { title, message, userIds, additionalData, imageUrl } = req.body;

    console.log('Received notification request:', {
      title,
      message,
      userIds,
      hasAdditionalData: !!additionalData,
      hasImageUrl: !!imageUrl
    });

    if (!title || !message) {
      console.error('Missing required fields');
      return res.status(400).json({
        success: false,
        error: 'Title and message are required'
      });
    }

    if (!ONESIGNAL_REST_API_KEY || !ONESIGNAL_APP_ID) {
      console.error('OneSignal configuration missing');
      return res.status(500).json({
        success: false,
        error: 'OneSignal configuration is missing'
      });
    }

    const notificationData = {
      app_id: ONESIGNAL_APP_ID,
      headings: { en: title },
      contents: { en: message },
      data: additionalData || {},
    };

    // Add image if provided
    if (imageUrl) {
      notificationData.big_picture = imageUrl;
      notificationData.large_icon = imageUrl;
    }

    // Target specific users or all users
    if (userIds && userIds.length > 0) {
      notificationData.include_external_user_ids = userIds;
    } else {
      notificationData.included_segments = ['All'];
    }

    console.log('Sending notification to OneSignal:', JSON.stringify(notificationData, null, 2));

    const response = await axios.post(
      'https://onesignal.com/api/v1/notifications',
      notificationData,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`
        }
      }
    );

    console.log('OneSignal response:', response.data);

    res.json({
      success: true,
      data: response.data,
      message: 'Notification sent successfully'
    });

  } catch (error) {
    console.error('Error sending notification:', {
      message: error.message,
      response: error.response?.data,
      stack: error.stack
    });

    res.status(500).json({
      success: false,
      error: error.response?.data?.errors?.[0] || error.message,
      details: error.response?.data || error.message
    });
  }
});

// Send test notification
app.post('/test-notification', async (req, res) => {
  try {
    console.log('Received test notification request');

    if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
      console.error('OneSignal configuration is missing');
      return res.status(500).json({
        success: false,
        error: 'OneSignal configuration is missing'
      });
    }

    const notificationData = {
      app_id: ONESIGNAL_APP_ID,
      included_segments: ['All'],
      contents: { en: 'This is a test notification' },
      headings: { en: 'Test Notification' },
      data: { type: 'test' }
    };

    console.log('Sending test notification to OneSignal:', JSON.stringify(notificationData, null, 2));

    const response = await axios.post(
      'https://onesignal.com/api/v1/notifications',
      notificationData,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`
        }
      }
    );

    console.log('OneSignal test notification response:', response.data);

    res.json({
      success: true,
      data: response.data,
      message: 'Test notification sent successfully'
    });
  } catch (error) {
    console.error('Error sending test notification:', {
      message: error.message,
      response: error.response?.data,
      stack: error.stack
    });

    res.status(500).json({
      success: false,
      error: error.response?.data?.errors?.[0] || error.message,
      details: error.response?.data || error.message
    });
  }
});

// Send discount notification
app.post('/api/notify/discount', async (req, res) => {
  try {
    const { 
      title, 
      message, 
      discountCode, 
      discountPercentage, 
      expiryDate, 
      discountId 
    } = req.body;

    if (!title || !message || !discountCode || !discountId) {
      return res.status(400).json({
        success: false,
        error: 'Title, message, discountCode, and discountId are required'
      });
    }

    if (!ONESIGNAL_REST_API_KEY) {
      return res.status(500).json({
        success: false,
        error: 'OneSignal REST API key not configured'
      });
    }

    const notificationData = {
      app_id: ONESIGNAL_APP_ID,
      headings: { en: title },
      contents: { en: message },
      included_segments: ['All'],
      data: {
        type: 'discount',
        discountCode: discountCode,
        discountPercentage: discountPercentage,
        expiryDate: expiryDate,
        discountId: discountId,
        timestamp: new Date().toISOString()
      },
      buttons: [
        {
          id: 'save_discount',
          text: 'Save Discount'
        }
      ]
    };

    console.log('Sending discount notification:', JSON.stringify(notificationData, null, 2));

    const response = await axios.post(
      'https://onesignal.com/api/v1/notifications',
      notificationData,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`
        }
      }
    );

    console.log('OneSignal discount notification response:', response.data);

    res.json({
      success: true,
      data: response.data,
      message: 'Discount notification sent successfully'
    });

  } catch (error) {
    console.error('Error sending discount notification:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: error.response?.data || error.message,
      details: error.response?.data?.errors || []
    });
  }
});

// Get app statistics
app.get('/stats', async (req, res) => {
  try {
    if (!ONESIGNAL_REST_API_KEY) {
      return res.status(500).json({
        success: false,
        error: 'OneSignal REST API key not configured'
      });
    }

    const response = await axios.get(
      `https://onesignal.com/api/v1/apps/${ONESIGNAL_APP_ID}`,
      {
        headers: {
          'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`
        }
      }
    );

    res.json({
      success: true,
      data: {
        name: response.data.name,
        players: response.data.players,
        messageable_players: response.data.messageable_players,
        updated_at: response.data.updated_at
      }
    });

  } catch (error) {
    console.error('Error getting app stats:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: error.response?.data || error.message
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: error.message
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    path: req.path,
    method: req.method
  });
});

app.listen(PORT, () => {
  console.log(`Notification backend server running on port ${PORT}`);
  console.log(`OneSignal App ID: ${ONESIGNAL_APP_ID}`);
  console.log(`OneSignal API Key configured: ${!!ONESIGNAL_REST_API_KEY}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});