"""
Push notification service using Firebase Cloud Messaging (FCM).

Sends notifications to Android and Web clients when stories are ready.
Gracefully handles missing Firebase credentials (logs warning, no crash).
"""

import logging
from typing import Optional

logger = logging.getLogger("worker.push")

# Firebase Admin SDK is imported lazily to avoid crashes
# when credentials are not configured
_firebase_app = None
_messaging = None


def _init_firebase():
    """Lazily initialize Firebase Admin SDK."""
    global _firebase_app, _messaging
    if _messaging is not None:
        return True

    try:
        import firebase_admin
        from firebase_admin import credentials, messaging

        if not firebase_admin._apps:
            # Try default credentials (GOOGLE_APPLICATION_CREDENTIALS env var)
            try:
                cred = credentials.ApplicationDefault()
                _firebase_app = firebase_admin.initialize_app(cred)
            except Exception:
                # No credentials available — push will be disabled
                logger.warning(
                    "Firebase credentials not found. "
                    "Push notifications are disabled. "
                    "Set GOOGLE_APPLICATION_CREDENTIALS to enable."
                )
                return False
        else:
            _firebase_app = firebase_admin.get_app()

        _messaging = messaging
        return True

    except ImportError:
        logger.warning("firebase-admin not installed. Push notifications disabled.")
        return False
    except Exception as e:
        logger.warning("Firebase initialization failed: %s", e)
        return False


class PushService:
    """Send push notifications via Firebase Cloud Messaging."""

    async def send_story_ready(
        self,
        tokens: list[str],
        story_title: str,
        story_id: str,
    ) -> int:
        """
        Send 'story ready' notification to device tokens.

        Returns number of successfully sent notifications.
        """
        if not _init_firebase() or _messaging is None:
            logger.info("Push disabled — skipping notification")
            return 0

        sent = 0
        for token in tokens:
            try:
                message = _messaging.Message(
                    notification=_messaging.Notification(
                        title="Сказка готова! ✨",
                        body=f'"{story_title}" ждёт вас!',
                    ),
                    data={
                        "type": "story_ready",
                        "story_id": story_id,
                    },
                    token=token,
                    android=_messaging.AndroidConfig(
                        priority="high",
                        notification=_messaging.AndroidNotification(
                            icon="ic_notification",
                            color="#6C5CE7",
                            channel_id="story_ready",
                        ),
                    ),
                    webpush=_messaging.WebpushConfig(
                        notification=_messaging.WebpushNotification(
                            icon="/icons/Icon-192.png",
                            badge="/icons/Icon-192.png",
                        ),
                    ),
                )

                _messaging.send(message)
                sent += 1

            except Exception as e:
                logger.warning("Failed to send push to token %s...: %s", token[:20], e)

        logger.info("Push notifications sent: %d/%d", sent, len(tokens))
        return sent
