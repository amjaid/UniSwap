# Push Notifications (Sprint 3)

## Overview
UniSwap uses Firebase Cloud Messaging (FCM) for push notifications and flutter_local_notifications for local display.

## App Setup
1. Ensure firebase_messaging and flutter_local_notifications are in pubspec.yaml.
2. Initialize notifications in lib/main.dart via NotificationService.
3. Store FCM tokens in Firestore on sign-in.

## Firestore Fields
- users/{userId}/fcm_token

## Data Payload
Notifications should include a route to navigate on tap:

```
{
  "route": "/chat/<swapId>"
}
```

## Cloud Functions (Node.js 20)
Below is sample code for sending notifications on new messages or swap updates.

```js
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();
const db = getFirestore();

export const notifyNewMessage = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    const conversationId = event.params.conversationId;
    const convoSnap = await db.collection("conversations").doc(conversationId).get();
    const convo = convoSnap.data();
    if (!convo) return;

    const recipients = (convo.participants || []).filter((id) => id !== message.sender_id);
    if (!recipients.length) return;

    const tokens = [];
    for (const userId of recipients) {
      const userSnap = await db.collection("users").doc(userId).get();
      const token = userSnap.data()?.fcm_token;
      if (token) tokens.push(token);
    }

    if (!tokens.length) return;

    await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "New message",
        body: message.text || "You have a new message",
      },
      data: {
        route: `/chat/${convo.swap_id || conversationId}`,
      },
    });
  }
);

export const notifySwapStatus = onDocumentUpdated(
  "swaps/{swapId}",
  async (event) => {
    const after = event.data?.after.data();
    const before = event.data?.before.data();
    if (!after || !before) return;

    if (after.status === before.status) return;

    const participants = after.participants || [];
    const tokens = [];
    for (const userId of participants) {
      const userSnap = await db.collection("users").doc(userId).get();
      const token = userSnap.data()?.fcm_token;
      if (token) tokens.push(token);
    }

    if (!tokens.length) return;

    await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "Swap updated",
        body: `Status changed to ${after.status}`,
      },
      data: {
        route: `/swap-hub/${event.params.swapId}`,
      },
    });
  }
);
```

## Notes
- For iOS, enable APNs and upload your APNs key in Firebase.
- For Android, ensure notification permission is handled on Android 13+.
- Web push requires VAPID keys and HTTPS.
