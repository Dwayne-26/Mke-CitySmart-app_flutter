import {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentWritten,
} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();

export const mirrorUserSightingToGlobal = onDocumentCreated(
  "users/{uid}/sightings/{sightingId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const uid = event.params.uid as string;
    const sightingId = event.params.sightingId as string;

    const data = snap.data() as any;
    const db = admin.firestore();

    const now = admin.firestore.Timestamp.now();
    const merged = {
      ...data,
      uid: data?.uid ?? uid,
      status: data?.status ?? "active",
      createdAt: data?.createdAt ?? now,
      expiresAt:
        data?.expiresAt ??
        admin.firestore.Timestamp.fromMillis(now.toMillis() + 2 * 60 * 60 * 1000),
      sourcePath: snap.ref.path,
      mirroredAt: now,
    };

    await db.collection("sightings").doc(sightingId).set(merged, {merge: true});
  }
);

export const helloWorld = onRequest((req, res) => {
  logger.info("helloWorld hit", {method: req.method, path: req.path});
  res.status(200).send("Hello from Firebase Functions!");
});

export const cleanupExpiredSightings = onSchedule("every 5 minutes", async () => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  const queries = [
    db
        .collectionGroup("sightings")
        .where("status", "==", "active")
        .where("expiresAt", "<=", now),
    db
        .collection("live_sightings")
        .where("status", "==", "active")
        .where("expiresAt", "<=", now),
  ];

  const snaps = await Promise.all(queries.map((q) => q.get()));
  let total = 0;
  const batch = db.batch();

  for (const snap of snaps) {
    snap.docs.forEach((doc) => {
      total++;
      batch.update(doc.ref, {
        status: "expired",
        expiredAt: now,
      });
    });
  }

  if (total === 0) return;

  await batch.commit();
});

export const mirrorSightingsToAlerts = onDocumentWritten(
  "sightings/{sightingId}",
  async (event) => {
    const db = admin.firestore();
    const sightingId = event.params.sightingId as string;
    const after = event.data?.after;

    // Delete mirrored alert if the sighting was removed.
    if (after == null || !after.exists) {
      await db
        .collection("alerts")
        .doc(sightingId)
        .delete()
        .catch(() => {});
      return;
    }

    const data = (after.data() as any) ?? {};
    const type = (data.type ?? "").toString().toLowerCase();
    const isTow = type === "tow" || type === "towtruck";
    const loc = (data.location ?? "Nearby").toString();

    const title = data.title ?? (isTow ? "Tow sighting" : "Enforcer sighting");
    const message = data.message ??
        (isTow
            ? `Tow trucks spotted near ${loc}.`
            : `Enforcer spotted near ${loc}.`);

    const now = admin.firestore.Timestamp.now();
    const createdAt = data.createdAt ?? now;
    const expiresAt = data.expiresAt ?? null;

    const status = (data.status ?? "active").toString().toLowerCase();
    const isActive = status == "active";
    const alertDoc = {
      sourceType: "sighting",
      sourceId: sightingId,
      sightingId,
      type: isTow ? "tow" : "enforcer",
      title,
      message,
      location: loc,
      latitude: data.latitude ?? null,
      longitude: data.longitude ?? null,
      createdAt,
      expiresAt,
      status: isActive ? "active" : "inactive",
      active: isActive,
      sourcePath: after.ref.path,
      mirroredAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection("alerts").doc(sightingId).set(alertDoc, {merge: true});
  },
);

const RATE_LIMIT_MAX = 3;
const RATE_LIMIT_WINDOW_SECONDS = 60 * 60;

export const submitSighting = onCall(async (request) => {
  const uidBase =
    request.auth?.uid ?? `anonymous_${request.rawRequest.ip ?? "unknown"}`;
  const uidKey = uidBase.replace(/[^A-Za-z0-9_.-]/g, "_");

  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const rateRef = db.collection("rate_limits").doc(uidKey);

  const allowed = await db.runTransaction(async (tx) => {
    const snap = await tx.get(rateRef);
    const data = snap.data() as {count?: number; windowStart?: admin.firestore.Timestamp} | undefined;
    const windowStart = data?.windowStart ?? now;
    const elapsed =
      now.toMillis() - windowStart.toMillis();

    if (!snap.exists || elapsed >= RATE_LIMIT_WINDOW_SECONDS * 1000) {
      tx.set(rateRef, {count: 1, windowStart: now});
      return true;
    }

    const count = data?.count ?? 0;
    if (count >= RATE_LIMIT_MAX) return false;

    tx.update(rateRef, {count: count + 1});
    return true;
  });

  if (!allowed) {
    throw new HttpsError(
      "resource-exhausted",
      "Rate limit exceeded. Try again later.",
    );
  }

  const location = (request.data?.location ?? "").toString().trim();
  const notes = (request.data?.notes ?? "").toString();
  const isEnforcer = Boolean(request.data?.isEnforcer);
  const latitude = Number(request.data?.latitude);
  const longitude = Number(request.data?.longitude);
  const hasGeo = Number.isFinite(latitude) && Number.isFinite(longitude);

  if (!location || notes.length > 500) {
    throw new HttpsError("invalid-argument", "Invalid report");
  }

  const alertRef = db.collection("alerts").doc();
  await alertRef.set({
    title: isEnforcer ? "Enforcement Sighting" : "Tow Sighting",
    message: notes || "No notes",
    location,
    type: isEnforcer ? "enforcer" : "tow",
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    source: isEnforcer ? "parking_enforcer" : "tow_truck",
    reporterUid: uidBase,
    isPublic: false,
    geo: hasGeo ? new admin.firestore.GeoPoint(latitude, longitude) : null,
  });

  logger.info("submitSighting created alert", {alertId: alertRef.id, uid: uidBase});

  return {success: true, message: "Report submitted for review!"};
});

export const notifyOnApproval = onDocumentUpdated(
  "alerts/{alertId}",
  async (event) => {
    const before = event.data?.before.data() as any | undefined;
    const after = event.data?.after.data() as any | undefined;

    if (!before || !after) return;

    if (!before.isPublic && after.isPublic) {
      const title = (after.title ?? "Alert").toString();
      const message = (after.message ?? "").toString();
      const location = (after.location ?? "").toString();
      const body = [message, location ? `at ${location}` : ""]
        .filter((part) => part && part.trim().length > 0)
        .join(" ");

      await admin.messaging().send({
        topic: "alerts",
        notification: {
          title,
          body: body || "New alert approved.",
        },
      });
    }
  },
);

export const sendNearbyAlerts = onCall(async (request) => {
  const db = admin.firestore();

  const testMode = Boolean(request.data?.testMode);

  // Helper: minimal token validation
  const validateToken = (t: string) => {
    const s = t.toString().trim();
    if (!s) return false;
    if (s.length < 20 || s.length > 4096) return false;
    // allow common token chars (alphanumeric, -, _, :)
    if (!/^[A-Za-z0-9:_\-]+$/.test(s)) return false;
    return true;
  };

  if (testMode) {
    // Accept either `token` (string) or `tokens` (array)
    const tokensRaw = request.data?.tokens ?? request.data?.token ?? [];
    const tokens: string[] = Array.isArray(tokensRaw)
      ? tokensRaw.map(String)
      : [String(tokensRaw)].filter((v) => v && v !== 'undefined');

    if (tokens.length === 0) {
      throw new HttpsError('invalid-argument', 'At least one FCM token is required for test push.');
    }
    if (tokens.length > 10) {
      throw new HttpsError('invalid-argument', 'Too many target tokens (max 10).');
    }

    for (const t of tokens) {
      if (!validateToken(t)) {
        throw new HttpsError('invalid-argument', 'One or more FCM tokens appear invalid.');
      }
    }

    const reason = (request.data?.reason ?? '').toString().trim();
    if (!reason) {
      throw new HttpsError('invalid-argument', 'A short reason is required for test pushes.');
    }
    if (reason.length > 200) {
      throw new HttpsError('invalid-argument', 'Reason is too long (max 200 chars).');
    }

    // App Check: require it for unauthenticated callers (where possible)
    const rawHeaders = (request.rawRequest && (request.rawRequest as any).headers) || {};
    const appCheckToken = rawHeaders['x-firebase-appcheck'] || rawHeaders['x-firebase-app-check'];
    let appCheckVerified = false;

    if (!request.auth) {
      // If not running in emulator, require App Check
      const inEmulator = (process.env.FUNCTIONS_EMULATOR === 'true') || (process.env.FIREBASE_EMULATOR_HUB === 'true');
      if (!inEmulator) {
        if (!appCheckToken) {
          throw new HttpsError('permission-denied', 'Unauthenticated test push requires a valid App Check token.');
        }
        try {
          await admin.appCheck().verifyToken(appCheckToken as string);
          appCheckVerified = true;
        } catch (err) {
          throw new HttpsError('permission-denied', 'Invalid App Check token.');
        }
      }
    } else {
      // authenticated callers - if App Check provided, try to verify but do not require
      if (appCheckToken) {
        try {
          await admin.appCheck().verifyToken(appCheckToken as string);
          appCheckVerified = true;
        } catch (err) {
          // ignore and continue; we'll still permit authenticated test sends
          appCheckVerified = false;
        }
      }
    }

    // Rate-limit test sends per UID (if auth) otherwise per IP
    const now = admin.firestore.Timestamp.now();
    const windowSeconds = 60 * 60; // 1 hour
    const MAX_TEST_PER_WINDOW = 5;

    const requesterId = request.auth?.uid ? `uid_${request.auth.uid}` : `ip_${((request.rawRequest && (request.rawRequest as any).ip) || 'unknown').toString().replace(/[^A-Za-z0-9_.-]/g, '_')}`;
    const rateRef = db.collection('test_push_rate_limits').doc(requesterId);

    const allowed = await db.runTransaction(async (tx) => {
      const snap = await tx.get(rateRef);
      const data = snap.exists ? (snap.data() as any) : undefined;
      const windowStart = data?.windowStart ? data.windowStart.toMillis() : now.toMillis();
      const elapsed = now.toMillis() - windowStart;

      if (!snap.exists || elapsed >= windowSeconds * 1000) {
        tx.set(rateRef, {count: tokens.length, windowStart: now});
        return true;
      }

      const count = data?.count ?? 0;
      if (count + tokens.length > MAX_TEST_PER_WINDOW) return false;
      tx.update(rateRef, {count: count + tokens.length});
      return true;
    });

    if (!allowed) {
      throw new HttpsError('resource-exhausted', 'Test push rate limit exceeded. Try again later.');
    }

    // Send pushes (continue on partial failures)
    const sendPromises = tokens.map((tok) =>
      admin.messaging().send({
        token: tok,
        notification: {
          title: 'Test alert',
          body: reason,
        },
        data: {testMode: 'true'},
      }).then(() => ({tok, ok: true})).catch((e) => ({tok, ok: false, error: e}))
    );

    const results = await Promise.all(sendPromises);
    const sent = results.filter((r) => r.ok).length;

    logger.info('sendNearbyAlerts testMode', {
      requester: request.auth?.uid ?? null,
      requesterIp: (request.rawRequest && (request.rawRequest as any).ip) || null,
      tokens: tokens.length,
      sent,
      appCheckVerified,
      reason,
    });

    return {success: true, sent, total: tokens.length, testMode: true};
  }

  const radiusMiles = Number(request.data?.radiusMiles ?? 3);
  const windowMinutes = Number(request.data?.windowMinutes ?? 180);
  const limit = Math.min(Number(request.data?.limit ?? 25), 50);

  const now = Date.now();
  const since = admin.firestore.Timestamp.fromMillis(
    now - windowMinutes * 60 * 1000,
  );

  const snap = await admin
    .firestore()
    .collection("alerts")
    .where("status", "==", "active")
    .where("createdAt", ">=", since)
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();

  const haversineMiles = (
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ) => {
    const toRad = (deg: number) => (deg * Math.PI) / 180;
    const r = 3958.8;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRad(lat1)) *
        Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return r * c;
  };

  const matches = snap.docs
    .map((doc) => ({id: doc.id, data: doc.data()}))
    .filter(({data}) => {
      const geo = data.geo as admin.firestore.GeoPoint | undefined;
      const lat = Number(geo?.latitude ?? data.latitude);
      const lng = Number(geo?.longitude ?? data.longitude);
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) return false;
      const dist = haversineMiles(latitude, longitude, lat, lng);
      return dist <= radiusMiles;
    });

  const sendLimit = Math.min(matches.length, 5);
  for (let i = 0; i < sendLimit; i++) {
    const match = matches[i];
    const title = (match.data.title ?? "Alert").toString();
    const message = (match.data.message ?? "").toString();
    const location = (match.data.location ?? "").toString();
    const body = [message, location ? `at ${location}` : ""]
      .filter((part) => part && part.trim().length > 0)
      .join(" ");

    await admin.messaging().send({
      token,
      notification: {
        title,
        body: body || "Nearby alert.",
      },
      data: {
        alertId: match.id,
        type: (match.data.type ?? "").toString(),
      },
    });
  }

  return {
    success: true,
    sent: sendLimit,
    totalMatches: matches.length,
  };
});
