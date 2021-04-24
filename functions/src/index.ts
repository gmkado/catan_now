import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL: "https://catannow-20200-default-rtdb.firebaseio.com",
});

// Start writing Firebase Functions
// https://firebase.google.com/docs/functions/typescript

export var proposalChange = functions.firestore
  .document("/gamerooms/{roomId}/proposed/{proposalId}")
  .onWrite((change, context) => {
    try {
      if (change.after.exists) {
        // new or updated
        var gametime = change.after.data()?.timestamp.toDate().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
        if(!change.before.exists) {
          // new proposal, send notification
          sendNotification(context.params.roomId, "New proposal", "Catan at " + gametime + "?");
        }
        else if(change.after.data()?.criteriaMet != change.before.data()?.criteriaMet
          && change.after.data()?.criteriaMet){
          // game criteria met!
          sendNotification(context.params.roomId, "Gametime!", "We hit critical mass for " + gametime + "!");          
        }
      } else {
        console.log("Deleted", context.params.proposalId);
      }
    } catch (e) {
      console.error(e);
    }
    return null;
  });

function sendNotification(topic: string, title: string, body: string) {
  if(process.env.FUNCTIONS_EMULATOR === "true"){
    console.log("Topic:", topic);
    console.log("Title:", title);
    console.log("Body:", body);
    return null;
  }else{
    const payload = {
      notification: {
        title: title,
        body: body,
      },
    };
    return admin.messaging().sendToTopic(topic, payload);
  }

}
