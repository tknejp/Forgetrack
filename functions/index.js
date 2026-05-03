const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');

initializeApp();

// ─── Localised strings ────────────────────────────────────────────────────────

const strings = {
  cs: {
    someone: 'Někdo',
    friendRequestTitle: 'Žádost o přátelství',
    friendRequestBody: (name) => `${name} ti poslal/a žádost o přátelství`,
    friendAcceptedTitle: 'Žádost o přátelství přijata',
    friendAcceptedBody: (name) => `${name} přijal/a tvoji žádost`,
    reactionTitle: (name, emoji) => `${name} reagoval/a ${emoji}`,
  },
  en: {
    someone: 'Someone',
    friendRequestTitle: 'Friend request',
    friendRequestBody: (name) => `${name} sent you a friend request`,
    friendAcceptedTitle: 'Friend request accepted',
    friendAcceptedBody: (name) => `${name} accepted your friend request`,
    reactionTitle: (name, emoji) => `${name} reacted ${emoji}`,
  },
};

function t(locale) {
  return strings[locale] ?? strings.cs;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

async function getUserData(uid) {
  const doc = await getFirestore().doc(`users/${uid}`).get();
  const data = doc.data() ?? {};
  const notificationsEnabled = data.notificationsEnabled !== false;
  const token = data.fcmToken ?? null;
  console.log(`getUserData: uid=${uid} hasToken=${token !== null} notificationsEnabled=${notificationsEnabled} locale=${data.locale ?? 'cs'} displayName=${data.displayName ?? null}`);
  return {
    token: notificationsEnabled ? token : null,
    notificationsEnabled,
    locale: data.locale ?? 'cs',
    displayName: data.displayName ?? null,
  };
}

async function sendPush(token, title, body, type, targetUid) {
  if (!token) {
    console.warn(`sendPush: no FCM token for type=${type} targetUid=${targetUid ?? 'unknown'}`);
    return;
  }
  try {
    const result = await getMessaging().send({
      token,
      notification: { title, body },
      data: { type },
      android: { priority: 'high' },
    });
    console.log(`sendPush: sent type=${type} targetUid=${targetUid ?? 'unknown'} messageId=${result}`);
  } catch (err) {
    console.error(`sendPush: failed type=${type} targetUid=${targetUid ?? 'unknown'} err=${err.message} code=${err.code}`);
  }
}

// ─── Functions ────────────────────────────────────────────────────────────────

exports.onFriendRequestCreated = onDocumentCreated(
  'friend_requests/{requestId}',
  async (event) => {
    const data = event.data?.data();
    if (!data || data.status !== 'pending') return;

    const toUid = data.toUid;
    const fromUid = data.fromUid;
    if (!toUid || !fromUid) return;

    console.log(`onFriendRequestCreated: requestId=${event.params.requestId} fromUid=${fromUid} toUid=${toUid}`);

    const [toData, fromData] = await Promise.all([
      getUserData(toUid),
      getUserData(fromUid),
    ]);

    const s = t(toData.locale);
    const fromName = fromData.displayName ?? s.someone;
    await sendPush(toData.token, s.friendRequestTitle, s.friendRequestBody(fromName), 'friend_request', toUid);
  }
);

exports.onFriendRequestUpdated = onDocumentUpdated(
  'friend_requests/{requestId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    console.log(`onFriendRequestUpdated: requestId=${event.params.requestId} status ${before.status} → ${after.status}`);

    if (before.status === after.status) return;
    if (after.status !== 'accepted') return;

    const fromUid = after.fromUid;
    const toUid = after.toUid;
    if (!fromUid || !toUid) return;

    const [fromData, toData] = await Promise.all([
      getUserData(fromUid),
      getUserData(toUid),
    ]);

    const s = t(fromData.locale);
    const byName = toData.displayName ?? s.someone;
    await sendPush(fromData.token, s.friendAcceptedTitle, s.friendAcceptedBody(byName), 'friend_request', fromUid);
  }
);

exports.onReactionNotificationCreated = onDocumentCreated(
  'users/{uid}/notifications/{notifId}',
  async (event) => {
    const uid = event.params.uid;
    const data = event.data?.data();
    if (!data || data.type !== 'reaction') return;

    console.log(`onReactionNotificationCreated: uid=${uid} notifId=${event.params.notifId}`);

    const userData = await getUserData(uid);
    const s = t(userData.locale);
    const actorName = data.actorName ?? s.someone;
    const emoji = data.emoji ?? '👍';
    const achievementTitle = data.achievementTitle ?? '';
    await sendPush(userData.token, s.reactionTitle(actorName, emoji), achievementTitle, 'reaction', uid);
  }
);
