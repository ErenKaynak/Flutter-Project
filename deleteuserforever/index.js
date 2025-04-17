const {onCall} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.deleteUserCompletely = onCall({
  enforceAppCheck: false, // Disable App Check requirement
}, async (request) => {
  try {
    const {data, auth} = request;

    if (!auth) {
      throw new Error("Unauthenticated");
    }

    const callerUid = auth.uid;
    const callerDoc = await admin
        .firestore()
        .collection("users")
        .doc(callerUid)
        .get();

    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      throw new Error("Only admins can delete users");
    }

    const userToDeleteUid = data.uid;
    await admin.auth().deleteUser(userToDeleteUid);
    await admin.firestore().collection("users").doc(userToDeleteUid).delete();

    return {
      success: true,
      message: "User deleted successfully",
    };
  } catch (error) {
    console.error("Error deleting user:", error);
    throw new Error(error.message);
  }
});
