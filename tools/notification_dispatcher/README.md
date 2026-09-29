# MyClass Real-Time Notification Dispatcher

This background worker listens in real-time to Firestore updates (`sections/{sectionId}/updates`) and automatically broadcasts FCM push notifications to subscribed student topics (`section_<sectionId>`).

It can be deployed either:
1. **As a Cloud Function** (in the `functions/` directory) if your project has the Blaze plan.
2. **As a Standalone Daemon** (this directory) if running on the free Spark plan.

## How to Run Locally / On a Free Server

1. Download a Firebase Admin Service Account key:
   - Go to [Firebase Console -> Project Settings -> Service Accounts](https://console.firebase.google.com/project/myclass-12/settings/serviceaccounts/adminsdk)
   - Click **Generate new private key**
   - Save the downloaded JSON file as `service-account.json` in this directory (it is ignored by git).

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the dispatcher:
   ```bash
   npm start
   ```

Whenever a Class Representative shifts a class, cancels a class, or posts a new exam/viva in the app, this dispatcher instantly delivers the push notification to all students in that section!
