/**
 * Standalone Notification Dispatcher for MyClass.
 *
 * This daemon listens in real-time to Firestore updates across all sections
 * and broadcasts Firebase Cloud Messaging (FCM) push notifications to student
 * topics (e.g. `section_bsc-cse-64-I`).
 *
 * It runs 100% free without needing the Google Cloud Blaze plan.
 */
import { initializeApp, cert, applicationDefault } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { existsSync, readFileSync } from "fs";
import { resolve } from "path";

const projectId = process.env.FIREBASE_PROJECT_ID || "myclass-12";
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || "./service-account.json";

let app;
if (existsSync(resolve(serviceAccountPath))) {
  console.log(`[Dispatcher] Initializing with service account key: ${serviceAccountPath}`);
  const serviceAccount = JSON.parse(readFileSync(resolve(serviceAccountPath), "utf8"));
  app = initializeApp({
    credential: cert(serviceAccount),
    projectId: projectId,
  });
} else {
  console.log(`[Dispatcher] Initializing with application default credentials for project: ${projectId}`);
  app = initializeApp({
    credential: applicationDefault(),
    projectId: projectId,
  });
}

const db = getFirestore(app);
const messaging = getMessaging(app);

function sanitizeTopic(sectionId) {
  return `section_${sectionId.replace(/[^a-zA-Z0-9-_.~%]/g, "_")}`;
}

const startTime = new Date();
console.log(`[Dispatcher] Started at ${startTime.toISOString()}. Listening for new academic updates...`);

// Listen to all 'updates' subcollections in real-time
db.collectionGroup("updates").onSnapshot(
  (snapshot) => {
    snapshot.docChanges().forEach(async (change) => {
      if (change.type !== "added") return;

      const doc = change.doc;
      const data = doc.data();

      // Skip past updates created before the dispatcher started
      const updateAt = data.at ? new Date(data.at) : null;
      if (updateAt && updateAt.getTime() < startTime.getTime() - 60000) {
        return;
      }

      // Check if already dispatched
      if (data.dispatchedAt) {
        return;
      }

      // Extract sectionId from path: sections/{sectionId}/updates/{updateId}
      const sectionDoc = doc.ref.parent.parent;
      const sectionId = sectionDoc ? sectionDoc.id : data.sectionId;

      if (!sectionId) {
        console.warn(`[Dispatcher] Skipping update ${doc.id}: could not resolve sectionId.`);
        return;
      }

      const topic = sanitizeTopic(sectionId);
      const title = data.title || "Academic Update";
      const body = data.detail || "New update posted for your section.";

      console.log(`[Dispatcher] Broadcasting update "${title}" to topic "${topic}"...`);

      const message = {
        topic: topic,
        notification: {
          title: title,
          body: body,
        },
        data: {
          sectionId: sectionId,
          eventId: data.eventId || "",
          sessionId: data.sessionId || "",
          updateId: doc.id,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "myclass_academic_updates",
            priority: "high",
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
      };

      try {
        const response = await messaging.send(message);
        console.log(`[Dispatcher] Push notification sent successfully! MessageId: ${response}`);

        // Mark as dispatched in Firestore
        await doc.ref.update({ dispatchedAt: new Date().toISOString() }).catch(() => {});
      } catch (err) {
        console.error(`[Dispatcher] Failed to send push notification to ${topic}:`, err.message);
      }
    });
  },
  (error) => {
    console.error("[Dispatcher] Firestore subscription error:", error);
  }
);
