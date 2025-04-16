const { onDocumentDeleted } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

// Initialize Firebase Admin
initializeApp();

// This function triggers when a user document is deleted from Firestore
exports.deleteUserAuth = onDocumentDeleted('users/{userId}', async (event) => {
  const userId = event.params.userId;
  console.log(`Attempting to delete user auth for: ${userId}`);
  
  try {
    // Delete the user from Firebase Authentication
    await getAuth().deleteUser(userId);
    console.log(`Successfully deleted user auth for: ${userId}`);
    return { success: true };
  } catch (error) {
    console.error(`Error deleting user auth for ${userId}:`, error);
    return { success: false, error: error.message };
  }
});