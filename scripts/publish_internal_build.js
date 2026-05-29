#!/usr/bin/env node
/*
 * Upload the freshly built internal-flavor APK to Firebase Storage and
 * write the `app_config/latest_internal` Firestore manifest doc.
 * Together these two writes are what the on-device AppUpdateService
 * polls to discover new builds.
 *
 * Invoked from release.ps1 as:
 *   node scripts/publish_internal_build.js \
 *     <version> <buildNumber> <apkPath> <releaseNotesFile> \
 *     <serviceAccountKeyPath> [bucketName]
 *
 * Requirements:
 *   - Node 18+ (globalThis.fetch + node:crypto signing + node:fs streams).
 *   - Service-account JSON with at minimum:
 *       - Storage Object Admin (or Editor) on the Storage bucket
 *       - Cloud Datastore User (or Editor) on the Firestore database
 *     The simplest setup is to grant the SA `Editor` on the project.
 *
 * No `npm install` required — uses Node built-ins only.
 *
 * Exit codes:
 *   0  upload + manifest write both succeeded
 *   2  CLI usage error
 *   3  service-account JSON malformed
 *   4  Google OAuth token exchange failed
 *   5  Storage upload failed
 *   6  Firestore manifest write failed
 *   7  APK file missing or unreadable
 *   8  release notes file missing
 */
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const https = require('node:https');

const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const TOKEN_SCOPE = 'https://www.googleapis.com/auth/cloud-platform';

function die(code, message) {
  console.error(`publish_internal_build: ${message}`);
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

// Cloud Storage simple media upload caps at 32 MB. Our APK is ~258 MB, so
// we must use the resumable-upload protocol (initiate → PUT). The initiate
// step is a trivial fetch; the data PUT goes through node:https because
// undici's fetch has had quirks with very large request bodies. Combined
// they're more robust than fetch-with-stream for hundreds of MB at a time.
async function uploadApk({ bucket, objectName, apkPath, accessToken }) {
  const size = fs.statSync(apkPath).size;
  const initUrl =
    `https://storage.googleapis.com/upload/storage/v1/b/${encodeURIComponent(bucket)}` +
    `/o?uploadType=resumable&name=${encodeURIComponent(objectName)}`;

  const initRes = await fetch(initUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'X-Upload-Content-Type': 'application/vnd.android.package-archive',
      'X-Upload-Content-Length': String(size),
      'Content-Length': '0',
    },
  });

  if (!initRes.ok) {
    const text = await initRes.text();
    die(5, `Resumable upload initiate failed (${initRes.status}): ${text}`);
  }
  const sessionUrl = initRes.headers.get('location');
  if (!sessionUrl) {
    die(5, 'Resumable upload session URL missing (no Location header)');
  }

  const sessionParsed = new URL(sessionUrl);
  const stream = fs.createReadStream(apkPath);
  const sizeMB = (size / 1024 / 1024).toFixed(1);
  let uploaded = 0;
  let lastPrintAt = 0;
  const tty = process.stderr.isTTY;

  stream.on('data', (chunk) => {
    uploaded += chunk.length;
    const now = Date.now();
    if (now - lastPrintAt < 200 && uploaded < size) return;
    lastPrintAt = now;
    const pct = ((uploaded / size) * 100).toFixed(1);
    const uploadedMB = (uploaded / 1024 / 1024).toFixed(1);
    const line = `publish_internal_build: uploading… ${pct}% (${uploadedMB} / ${sizeMB} MB)`;
    if (tty) {
      process.stderr.write(`\r${line}`);
    } else {
      process.stderr.write(`${line}\n`);
    }
  });

  const responseBody = await new Promise((resolve, reject) => {
    const req = https.request(
      {
        method: 'PUT',
        hostname: sessionParsed.hostname,
        path: sessionParsed.pathname + sessionParsed.search,
        headers: {
          'Content-Length': size,
          'Content-Type': 'application/vnd.android.package-archive',
        },
      },
      (res) => {
        let body = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => {
          body += chunk;
        });
        res.on('end', () => {
          if (res.statusCode === 200 || res.statusCode === 201) {
            resolve(body);
          } else {
            reject(new Error(`PUT failed (${res.statusCode}): ${body}`));
          }
        });
      },
    );
    req.on('error', reject);
    stream.on('error', reject);
    stream.pipe(req);
  });

  if (tty) process.stderr.write('\n');

  let parsed;
  try {
    parsed = JSON.parse(responseBody);
  } catch {
    die(5, `Storage upload response not JSON: ${responseBody}`);
  }
  console.log(
    `publish_internal_build: uploaded ${apkPath} → gs://${bucket}/${objectName} (${parsed.size} bytes)`,
  );
}

async function writeManifest({
  projectId,
  accessToken,
  version,
  buildNumber,
  apkStoragePath,
  notes,
}) {
  const docPath = `projects/${projectId}/databases/(default)/documents/app_config/latest_internal`;
  const url =
    `https://firestore.googleapis.com/v1/${docPath}` +
    `?updateMask.fieldPaths=version` +
    `&updateMask.fieldPaths=buildNumber` +
    `&updateMask.fieldPaths=apkStoragePath` +
    `&updateMask.fieldPaths=notes` +
    `&updateMask.fieldPaths=releasedAt`;

  const body = {
    fields: {
      version: { stringValue: version },
      buildNumber: { integerValue: String(buildNumber) },
      apkStoragePath: { stringValue: apkStoragePath },
      notes: { stringValue: notes },
      releasedAt: { timestampValue: new Date().toISOString() },
    },
  };

  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const text = await res.text();
    die(6, `Firestore manifest PATCH failed (${res.status}): ${text}`);
  }
  console.log(
    `publish_internal_build: manifest written ${docPath.replace(/^projects\/[^/]+\/databases\/[^/]+\/documents\//, '')}`,
  );
}

async function main() {
  const [, , version, buildNumber, apkPath, releaseNotesFile, keyPath, bucketArg] =
    process.argv;
  if (!version || !buildNumber || !apkPath || !releaseNotesFile || !keyPath) {
    die(
      2,
      'usage: node scripts/publish_internal_build.js <version> <buildNumber> <apkPath> <releaseNotesFile> <serviceAccountKeyPath> [bucketName]',
    );
  }

  if (!fs.existsSync(apkPath)) {
    die(7, `APK not found at "${apkPath}"`);
  }
  if (!fs.existsSync(releaseNotesFile)) {
    die(8, `release notes file not found at "${releaseNotesFile}"`);
  }
  if (!fs.existsSync(keyPath)) {
    die(3, `service-account key not found at "${keyPath}"`);
  }

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
  } catch (e) {
    die(3, `failed to read service-account JSON: ${e.message}`);
  }
  if (
    !serviceAccount.client_email ||
    !serviceAccount.private_key ||
    !serviceAccount.project_id
  ) {
    die(3, 'service-account JSON missing client_email / private_key / project_id');
  }

  // Default bucket follows the newer Firebase Storage naming convention
  // (`<projectId>.firebasestorage.app`). Older projects created before
  // 2024 may still be on `<projectId>.appspot.com`; pass the legacy
  // bucket name as the 6th CLI arg in that case.
  const bucket = bucketArg || `${serviceAccount.project_id}.firebasestorage.app`;
  const objectName = `internal-builds/forgetrack-${version}-${buildNumber}.apk`;
  const notes = fs.readFileSync(releaseNotesFile, 'utf8').trim();

  const accessToken = await getAccessToken(serviceAccount);

  await uploadApk({ bucket, objectName, apkPath, accessToken });
  await writeManifest({
    projectId: serviceAccount.project_id,
    accessToken,
    version,
    buildNumber: Number(buildNumber),
    apkStoragePath: objectName,
    notes,
  });

  console.log('publish_internal_build: done');
}

main().catch((e) => {
  die(5, `unexpected: ${e.stack || e.message || e}`);
});
