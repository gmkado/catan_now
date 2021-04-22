import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL: "https://catannow-20200-default-rtdb.firebaseio.com",
});
// Start writing Firebase Functions
// https://firebase.google.com/docs/functions/typescript

export var proposalChange2 = functions.firestore
  .document("/gamerooms/{roomId}/proposed/{proposalId}")
  .onWrite((change, context) => {
    try {
      if (change.after.exists) {
        console.log("New proposal:", change.after.data());
        sendNotification(context.params.roomId, "New proposal", "lalala");
      } else {
        console.log("Deleted", context.params.proposalId);
      }
    } catch (e) {
      console.error(e);
    }
    return null;
  });

function sendNotification(topic: string, title: string, body: string) {
  const payload = {
    notification: {
      title: title,
      body: body,
    },
  };

  return admin.messaging().sendToTopic(topic, payload);
}
