import { initializeApp } from "firebase-admin/app";
import { getMessaging } from "firebase-admin/messaging";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

// Initialize Firebase Admin SDK
initializeApp();

function sanitizeTopic(sectionId) {
  // FCM topics must match regex: [a-zA-Z0-9-_.~%]+
  return `section_${sectionId.replace(/[^a-zA-Z0-9-_.~%]/g, "_")}`;
}

/**
 * Cloud Function triggered when a new update is posted to a section's timeline feed.
 * This handles:
 *  - Cancelled classes
 *  - Shifted / Rescheduled classes
 *  - Temporary classes
 *  - New or updated academic events (exams, quizzes, vivas, deadlines)
 */
export const onAcademicUpdateCreated = onDocumentCreated(
  "sections/{sectionId}/updates/{updateId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("No snapshot data found for update trigger.");
      return;
    }

    const data = snapshot.data();
    const sectionId = event.params.sectionId;
    const updateId = event.params.updateId;
    const topic = sanitizeTopic(sectionId);

    const title = data.title || "Academic Update";
    const body = data.detail || "A new update has been posted for your section.";

    logger.info(`Dispatching FCM notification to topic: ${topic} for update: ${updateId}`, {
      title,
      body,
      sectionId,
    });

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
        updateId: updateId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "myclass_academic_updates",
          priority: "high",
          defaultSound: true,
          defaultVibrateTimings: true,
          visibility: "public",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    try {
      const response = await getMessaging().send(message);
      logger.info(`Successfully sent FCM notification [${response}] to topic: ${topic}`);
    } catch (error) {
      logger.error(`Failed to send FCM notification to topic ${topic}:`, error);
    }
  }
);
