import crypto from 'crypto';
import { Client, Databases, Query, ID } from 'node-appwrite';
import { throwIfMissing } from './utils.js';

export default async ({ req, res, log, error }) => {
  try {
    // Handle GET for health check
    if (req.method === 'GET') {
      return res.json({ status: 'ok', message: 'Webhook is running' }, 200);
    }
    
    // Only allow POST for actual notifications
    if (req.method !== 'POST') {
      return res.json({ error: 'Method not allowed' }, 405);
    }

    // Parse notification body from Midtrans
    const notification = req.body || {};
    log(`Received notification: ${JSON.stringify(notification)}`);

    const {
      order_id,
      status_code,
      gross_amount,
      signature_key,
      transaction_status,
      fraud_status,
      payment_type,
      transaction_time,
    } = notification;

    // Validate required fields
    if (!order_id || !status_code || !gross_amount || !signature_key) {
      error('Missing required fields in notification');
      return res.json({ error: 'Invalid notification format' }, 400);
    }

    // Get Midtrans server key
    const serverKey = process.env.MIDTRANS_SERVER_KEY;
    throwIfMissing(serverKey, 'MIDTRANS_SERVER_KEY');

    // Verify signature
    const expectedSignature = crypto
      .createHash('sha512')
      .update(`${order_id}${status_code}${gross_amount}${serverKey}`)
      .digest('hex');

    if (expectedSignature !== signature_key) {
      error('Invalid signature - potential fraud!');
      return res.json({ error: 'Invalid signature' }, 401);
    }

    log('Signature verified successfully');

    // Check if transaction is successful
    const isSuccess =
      transaction_status === 'settlement' ||
      transaction_status === 'capture';
    const isFraud = fraud_status === 'challenge' || fraud_status === 'deny';

    if (!isSuccess || isFraud) {
      log(
        `Transaction not successful: status=${transaction_status}, fraud=${fraud_status}`
      );
      return res.json({
        success: true,
        message: 'Notification received but not activated',
        status: transaction_status,
      });
    }

    // Extract userId from order_id (format: PREMIUM-{userId}-{timestamp})
    const orderParts = String(order_id).split('-');
    if (orderParts.length < 3) {
      error(`Invalid order_id format: ${order_id}`);
      return res.json({ error: 'Invalid order_id format' }, 400);
    }
    const userId = orderParts[1];
    log(`Activating premium for userId: ${userId}`);

    // Initialize Appwrite client
    const appwriteEndpoint = process.env.APPWRITE_ENDPOINT;
    const appwriteProject = process.env.APPWRITE_PROJECT_ID;
    const appwriteApiKey = process.env.APPWRITE_API_KEY;
    const databaseId = process.env.APPWRITE_DATABASE_ID;
    const profilesCollectionId =
      process.env.APPWRITE_COLLECTION_USER_PROFILES || 'user_profiles';

    throwIfMissing(appwriteEndpoint, 'APPWRITE_ENDPOINT');
    throwIfMissing(appwriteProject, 'APPWRITE_PROJECT_ID');
    throwIfMissing(appwriteApiKey, 'APPWRITE_API_KEY');
    throwIfMissing(databaseId, 'APPWRITE_DATABASE_ID');

    const client = new Client()
      .setEndpoint(appwriteEndpoint)
      .setProject(appwriteProject)
      .setKey(appwriteApiKey);

    const databases = new Databases(client);

    // Calculate premium expiry (30 days from now)
    const premiumUntil = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    const waResetDate = new Date(
      new Date().getFullYear(),
      new Date().getMonth() + 1,
      1
    );

    // Find existing user profile
    const profilesList = await databases.listDocuments(
      databaseId,
      profilesCollectionId,
      [Query.equal('userId', userId)]
    );

    if (profilesList.documents.length === 0) {
      // Create new profile
      log(`Creating new profile for userId: ${userId}`);
      await databases.createDocument(
        databaseId,
        profilesCollectionId,
        ID.unique(),
        {
          userId: userId,
          plan: 'premium',
          premiumUntil: premiumUntil.toISOString(),
          waReminderCount: 0,
          waResetDate: waResetDate.toISOString(),
        }
      );
    } else {
      // Update existing profile
      const profileDocId = profilesList.documents[0].$id;
      log(`Updating existing profile: ${profileDocId}`);
      await databases.updateDocument(
        databaseId,
        profilesCollectionId,
        profileDocId,
        {
          plan: 'premium',
          premiumUntil: premiumUntil.toISOString(),
          waReminderCount: 0,
        }
      );
    }

    log(`Premium activated successfully until: ${premiumUntil.toISOString()}`);

    // Return success response
    return res.json({
      success: true,
      message: 'Premium activated',
      userId: userId,
      orderId: order_id,
      premiumUntil: premiumUntil.toISOString(),
      transactionStatus: transaction_status,
      paymentType: payment_type,
    });
  } catch (err) {
    error(`Unhandled error: ${err.message}`);
    error(err.stack);
    return res.json(
      {
        error: 'Internal server error',
        detail: err.message,
      },
      500
    );
  }
};
