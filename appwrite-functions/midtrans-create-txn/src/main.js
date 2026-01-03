import { throwIfMissing } from './utils.js';

export default async ({ req, res, log, error }) => {
  try {
    // Only allow POST
    if (req.method !== 'POST') {
      return res.json({ error: 'Method not allowed' }, 405);
    }

    // Parse request body - Appwrite sends it as req.body if called via SDK
    // or as req.bodyRaw/req.bodyJson if called via REST API
    let bodyData = req.body;
    
    // If body is a string, parse it
    if (typeof req.body === 'string') {
      try {
        bodyData = JSON.parse(req.body);
      } catch (e) {
        log('Failed to parse body as JSON, using as-is');
      }
    }
    
    // If bodyData has a nested 'body' field (from REST API execution), parse it
    if (bodyData && typeof bodyData.body === 'string') {
      try {
        bodyData = JSON.parse(bodyData.body);
      } catch (e) {
        log('Failed to parse nested body field');
      }
    }

    const {
      userId,
      email = 'user@tagihin.local',
      itemId = 'premium-1month',
      amount = 49000,
    } = bodyData || {};

    // Validate required fields
    if (!userId) {
      log('Missing userId in request');
      return res.json({ error: 'userId is required' }, 400);
    }

    // Get Midtrans server key from environment
    const serverKey = process.env.MIDTRANS_SERVER_KEY;
    throwIfMissing(serverKey, 'MIDTRANS_SERVER_KEY');

    // Use sandbox or production based on environment
    const isSandbox = process.env.MIDTRANS_ENV !== 'production';
    const baseUrl = isSandbox
      ? 'https://app.sandbox.midtrans.com'
      : 'https://app.midtrans.com';

    // Generate unique order ID
    const orderId = `PREMIUM-${userId}-${Date.now()}`;
    log(`Creating transaction for orderId: ${orderId}`);

    // Create Basic Auth header
    const basicAuth = Buffer.from(`${serverKey}:`).toString('base64');

    // Call Midtrans Snap API
    const snapResponse = await fetch(`${baseUrl}/snap/v1/transactions`, {
      method: 'POST',
      headers: {
        Authorization: `Basic ${basicAuth}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        transaction_details: {
          order_id: orderId,
          gross_amount: amount,
        },
        customer_details: {
          email: email,
        },
        item_details: [
          {
            id: itemId,
            price: amount,
            quantity: 1,
            name: 'Premium Subscription Tagihin (30 hari)',
          },
        ],
        enabled_payments: [
          'gopay',
          'shopeepay',
          'bca_va',
          'bni_va',
          'bri_va',
          'permata_va',
          'other_va',
          'qris',
        ],
      }),
    });

    // Check Midtrans response
    if (!snapResponse.ok) {
      const errorText = await snapResponse.text();
      error(`Midtrans API error (${snapResponse.status}): ${errorText}`);
      return res.json(
        {
          success: false,
          error: 'Failed to create Midtrans transaction',
          detail: errorText,
          status: snapResponse.status,
        },
        500
      );
    }

    const snapData = await snapResponse.json();
    log(`Snap transaction created successfully: ${snapData.token}`);

    // Return response to client
    return res.json({
      success: true,
      token: snapData.token,
      redirect_url: snapData.redirect_url,
      order_id: orderId,
      environment: isSandbox ? 'sandbox' : 'production',
    });
  } catch (err) {
    error(`Unhandled error: ${err.message}`);
    return res.json(
      {
        error: 'Internal server error',
        detail: err.message,
      },
      500
    );
  }
};
