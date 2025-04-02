const functions = require('firebase-functions');
const stripe = require('stripe')('your_stripe_secret_key'); // Replace with your Stripe secret key

exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  try {
    console.log('Received data:', data); // Add logging
    // Validate required parameters
    const { amount, currency, description } = data;
    if (!amount || !currency) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required parameters: amount and currency are required.'
      );
    }

    // Create the payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: parseInt(amount), // Amount in cents (smallest unit for USD)
      currency: currency.toLowerCase(), // Should be 'usd'
      description: description || 'Payment from app',
      payment_method_types: ['card'],
    });

    return {
      clientSecret: paymentIntent.client_secret,
    };
  } catch (error) {
    throw new functions.https.HttpsError('invalid-argument', error.message);
  }
});