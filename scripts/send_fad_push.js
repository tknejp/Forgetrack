#!/usr/bin/env node
/*
 * Send the "new internal build available" FCM push to the
 * `forgetrack-internal-builds` topic after `scripts/release.ps1`
 * finishes uploading to Firebase App Distribution.
 *
 * Invoked from release.ps1 as:
 *   node scripts/send_fad_push.js <version> <buildNumber> <serviceAccountKeyPath>
 *
 * Requirements:
 *   - Node 18+ (globalThis.fetch + node:crypto sign).
 *   - Service-account JSON (gitignored) with the
 *     `cloudmessaging.messages.create` IAM permission, e.g.:
 *       - Firebase Cloud Messaging API Admin
 *       - or Firebase Admin SDK (full)
 *
 * No `npm install` required — uses Node built-ins only.
 *
 * Exit codes:
 *   0  push delivered (or skipped because key file missing — release
 *      continues; tester can still install via FAD email link)
 *   2  CLI usage error (missing args)
 *   3  service-account JSON malformed
 *   4  Google OAuth token exchange failed
 *   5  FCM v1 send failed
 */
'use strict';

const fs = require('node:fs');
const crypto = require('node:crypto');

const FCM_TOPIC = 'forgetrack-internal-builds';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const TOKEN_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const ANDROID_CHANNEL_ID = 'social';

function die(code, message) {
  console.error(`send_fad_push: ${message}`);
  process.exit(code);
}

function b64url(buf) {
  return Buffer.from(buf)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

async function getAccessToken(serviceAccount) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claims = {
    iss: serviceAccount.client_email,
    scope: TOKEN_SCOPE,
    aud: TOKEN_URL,
    iat: now,
    exp: now + 3600,
  };

  const signingInput = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(claims))}`;
  const signature = crypto
    .createSign('RSA-SHA256')
    .update(signingInput)
    .sign(serviceAccount.private_key);
  const assertion = `${signingInput}.${b64url(signature)}`;

  const body = new URLSearchParams({
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion,
  });

  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body.toString(),
  });

  if (!res.ok) {
    const text = await res.text();
    die(4, `OAuth token exchange failed (${res.status}): ${text}`);
  }
  const json = await res.json();
  return json.access_token;
}

async function sendPush({ projectId, accessToken, version, buildNumber }) {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const payload = {
    message: {
      topic: FCM_TOPIC,
      notification: {
        title: `Forgetrack ${version} k dispozici`,
        body: `Build ${buildNumber} — otevři app pro instalaci`,
      },
      android: {
        priority: 'NORMAL',
        notification: { channel_id: ANDROID_CHANNEL_ID },
      },
      data: {
        type: 'fad-update-available',
        version: String(version),
        buildNumber: String(buildNumber),
      },
    },
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const text = await res.text();
    die(5, `FCM v1 send failed (${res.status}): ${text}`);
  }
  const json = await res.json();
  console.log(`send_fad_push: ok, name=${json.name}`);
}

async function main() {
  const [, , version, buildNumber, keyPath] = process.argv;
  if (!version || !buildNumber || !keyPath) {
    die(
      2,
      'usage: node scripts/send_fad_push.js <version> <buildNumber> <serviceAccountKeyPath>',
    );
  }

  if (!fs.existsSync(keyPath)) {
    console.warn(
      `send_fad_push: service-account key not found at "${keyPath}" — skipping push`,
    );
    process.exit(0);
  }

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
  } catch (e) {
    die(3, `failed to read service-account JSON: ${e.message}`);
  }
  if (!serviceAccount.client_email || !serviceAccount.private_key || !serviceAccount.project_id) {
    die(3, 'service-account JSON missing client_email / private_key / project_id');
  }

  const accessToken = await getAccessToken(serviceAccount);
  await sendPush({
    projectId: serviceAccount.project_id,
    accessToken,
    version,
    buildNumber,
  });
}

main().catch((e) => {
  die(5, `unexpected: ${e.stack || e.message || e}`);
});
