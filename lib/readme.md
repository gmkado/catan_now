NOTE TO SELF: Steps required here

- database:
  - users:
    - user
      - name (e.g. user A)
      - email
      - app token [nullable]  https://stackoverflow.com/questions/37700995/how-to-send-notification-to-specific-users-with-fcm
  - events:
    - event
      - name (e.g. Catan)
      - datetime (e.g. today 8pm)
      - responses 
        - user (e.g. Grant)
        - response (e.g. accepted, pending)
        - proposed time (e.g. 9pm)
      - status (locked, past time)

- Create Event Definition
  - Define name of event ("CATAN")
  - Define user names
- Propose event
  - Update triggers fcm to all users in event responses list 
    - docs https://firebase.google.com/docs/functions/database-events?authuser=0
    - example https://github.com/firebase/functions-samples/tree/master/fcm-notifications
  - Clicking on notification opens app to the event's view
  - Clicking yes will update all users and creator
- Negotiation
  - Users propose new times
  - Creator can accept new time
  - Everyone needs to re-approve?
- Lock Event - this tells everyone "event is a go"
  - messages (i.e. for sending catan link)
- Unlock Event
  - Can only create one event at a time, if locked that means this group is playing
  - What if creator forgets to unlock?  Can anyone in the group unl


- Useful link maybe? https://github.com/FirebaseExtended/firechat
