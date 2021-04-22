Some notes about testing:

to use emulator, run:
`firebase emulators:start`

to use emulator with exported data:
`firebase emulators:export` to initially export the data then
`firebase emulators:start --import ./firestore_export`

to pickup changes to the functions stored in `index.js` (see https://stackoverflow.com/questions/51416536/firebase-serve-in-firebase-functions-is-not-running-the-latest-changes)
`cd .\functions`
`npm run build`

better yet, watch for changes: https://firebase.googleblog.com/2018/01/streamline-typescript-development-cloud-functions.html


to get app writing to local instance instead of cloud:
database.dart -> `USE_FIRESTORE_EMULATOR = true`

haven't tried this but you can trigger manually with functions shell:
https://firebase.google.com/docs/functions/local-shell#invoke_firestore_functions
`firebase functions:shell`

To push to the cloud run:
`firebase deploy`

If failures occur, check that eslint is passing and fix any errors.
Also check that you are logged in (https://stackoverflow.com/a/57941356/3525158)

# Known issues
## TODO: only works for emulators listening to 10.0.2.2:
    if (USE_FIRESTORE_EMULATOR) {
      // This only works for emulator, not real device
      // See https://firebase.flutter.dev/docs/firestore/usage/#emulator-usage
      var host = '10.0.2.2:8080';
      FirebaseFirestore.instance.settings =
          Settings(host: host, sslEnabled: false, persistenceEnabled: false);
    }

## TODO: can't get admin working, I set up credentials as per 
https://firebase.google.com/docs/functions/local-emulator#set_up_admin_credentials_optional

But am getting the following error at  admin.messaging().sendToTopic(topic, payload);

 FirebaseMessagingError: An error occurred when trying to authenticate to the FCM servers. Make sure the credential used 
to authenticate this SDK has the proper permissions. See https://firebase.google.com/docs/admin/setup for setup instructions. Raw server response: "<HTML>
>  <HEAD>
>  <TITLE>Unauthorized</TITLE>
>  </HEAD>
>  <BODY BGCOLOR="#FFFFFF" TEXT="#000000">
>  <H1>Unauthorized</H1>
>  <H2>Error 401</H2>
>  </BODY>
>  </HTML>
>  ". Status code: 401.
>      at FirebaseMessagingError.FirebaseError [as constructor] (C:\Users\gkado\source\repos\catan_now\functions\node_modules\firebase-admin\lib\utils\error.js:44:28)
>      at FirebaseMessagingError.PrefixedFirebaseError [as constructor] (C:\Users\gkado\source\repos\catan_now\functions\node_modules\firebase-admin\lib\utils\error.js:90:28)
>      at new FirebaseMessagingError (C:\Users\gkado\source\repos\catan_now\functions\node_modules\firebase-admin\lib\utils\error.js:256:16)
>      at Object.createFirebaseError (C:\Users\gkado\source\repos\catan_now\functions\node_modules\firebase-admin\lib\messaging\messaging-errors-internal.js:57:12)
>      at C:\Users\gkado\source\repos\catan_now\functions\node_modules\firebase-admin\lib\messaging\messaging-api-request-internal.js:79:51
>      at processTicksAndRejections (node:internal/process/task_queues:94:5) {
>    errorInfo: {
>      code: 'messaging/authentication-error',
>      message: 'An error occurred when trying to authenticate to the FCM servers. Make sure the credential used to authenticate this SDK has the proper permissions. See https://firebase.google.com/docs/admin/setup for setup instructions. Raw server response: "<HTML>\n' +
>        '<HEAD>\n' +
>        '<TITLE>Unauthorized</TITLE>\n' +
>        '</HEAD>\n' +
>        '<BODY BGCOLOR="#FFFFFF" TEXT="#000000">\n' +
>        '<H1>Unauthorized</H1>\n' +
>        '<H2>Error 401</H2>\n' +
>        '</BODY>\n' +
>        '</HTML>\n' +
>        '". Status code: 401.'
>    },
>  }