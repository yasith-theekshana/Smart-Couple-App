import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';

const project = 'demo-smart-couple';
const auth = 'http://127.0.0.1:9099';
const database = 'projects/' + project + '/databases/(default)/documents';
const firestore = 'http://127.0.0.1:8080/v1/' + database;

async function request(label, url, status, { method = 'GET', body, token } = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: 'Bearer ' + token } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(15000),
  });
  const result = await response.json();
  assert.equal(response.status, status, label + ': ' + JSON.stringify(result));
  return result;
}

function identity(method, body) {
  return request(method, auth + '/identitytoolkit.googleapis.com/v1/accounts:' +
    method + '?key=fake-api-key', 200, { method: 'POST', body });
}

async function account(verified) {
  const email = randomUUID() + '@example.test';
  const password = 'emulator-only-password';
  const created = await identity('signUp', { email, password, returnSecureToken: true });
  if (!verified) return { email, uid: created.localId, token: created.idToken };
  await identity('sendOobCode', { requestType: 'VERIFY_EMAIL', idToken: created.idToken });
  const { oobCodes } = await request('verification codes', auth +
    '/emulator/v1/projects/' + project + '/oobCodes', 200);
  const { oobCode } = oobCodes.find(code => code.email === email);
  await identity('update', { oobCode });
  const signedIn = await identity('signInWithPassword', { email, password, returnSecureToken: true });
  return { email, uid: signedIn.localId, token: signedIn.idToken };
}

const text = value => ({ stringValue: value });
const serverTime = fieldPath => ({ fieldPath, setToServerValue: 'REQUEST_TIME' });
const doc = uid => firestore + '/users/' + uid;
const path = uid => database + '/users/' + uid;

function create(owner, fields = {}, transforms = ['createdAt', 'updatedAt']) {
  return {
    update: {
      name: path(owner.uid),
      fields: {
        uid: text(owner.uid), username: text('Camille'), email: text(owner.email),
        coupleId: { nullValue: null }, preferredLanguage: text('en'), ...fields,
      },
    },
    updateTransforms: transforms.map(serverTime),
    currentDocument: { exists: false },
  };
}

function update(owner, fields, transforms = ['updatedAt']) {
  return {
    update: { name: path(owner.uid), fields },
    updateMask: { fieldPaths: Object.keys(fields) },
    updateTransforms: transforms.map(serverTime),
    currentDocument: { exists: true },
  };
}

let checks = 0;
async function check(label, url, status, options) {
  await request(label, url, status, options);
  checks++;
  console.log('PASS ' + label);
}

function commit(label, write, status, token) {
  return check(label, firestore + ':commit', status, {
    method: 'POST', body: { writes: [write] }, token,
  });
}

const owner = await account(true);
const other = await account(true);
const unverified = await account(false);

await check('owner can look up missing profile', doc(owner.uid), 404, { token: owner.token });
await commit('unverified create denied', create(unverified), 403, unverified.token);
await check('unverified get denied', doc(unverified.uid), 403, { token: unverified.token });
await commit('anonymous create denied', create(owner), 403);
await commit('cross-account create denied', create(owner), 403, other.token);
await commit('mismatched UID denied on create', create(owner, { uid: text(other.uid) }), 403, owner.token);
await commit('mismatched email denied on create', create(owner, { email: text(other.email) }), 403, owner.token);
await commit('initial coupleId denied', create(owner, { coupleId: text('couple') }), 403, owner.token);
await commit('extra field denied', create(owner, { admin: { booleanValue: true } }), 403, owner.token);
await commit('invalid language denied', create(owner, { preferredLanguage: text('es') }), 403, owner.token);
await commit('non-string username denied', create(owner, { username: { integerValue: '1' } }), 403, owner.token);
await commit('blank username denied', create(owner, { username: text('   ') }), 403, owner.token);
await commit('oversized username denied', create(owner, { username: text('x'.repeat(51)) }), 403, owner.token);
await commit('client timestamp denied', create(owner, { createdAt: { timestampValue: '2025-01-01T00:00:00Z' } }, ['updatedAt']), 403, owner.token);
await commit('owner can create valid profile', create(owner), 200, owner.token);
await check('owner can read profile', doc(owner.uid), 200, { token: owner.token });
await check('anonymous read denied', doc(owner.uid), 403);
await check('cross-account read denied', doc(owner.uid), 403, { token: other.token });
await check('unverified read of existing profile denied', doc(owner.uid), 403, { token: unverified.token });
await check('profile listing denied', firestore + '/users', 403, { token: owner.token });
await commit('permitted fields can be updated', update(owner, {
  username: text('Camille Roy'), preferredLanguage: text('fr'),
}), 200, owner.token);
await commit('cross-account update denied', update(owner, { username: text('Other') }), 403, other.token);
await commit('coupleId change denied', update(owner, { coupleId: text('couple') }), 403, owner.token);
await commit('UID change denied', update(owner, { uid: text(other.uid) }), 403, owner.token);
await commit('email change denied', update(owner, { email: text(other.email) }), 403, owner.token);
await commit('createdAt change denied', update(owner, { createdAt: { timestampValue: '2025-01-01T00:00:00Z' } }), 403, owner.token);
await commit('update without server timestamp denied', update(owner, { username: text('Other') }, []), 403, owner.token);
await check('deletion denied', doc(owner.uid), 403, { method: 'DELETE', token: owner.token });
await check('other collections denied', firestore + '/couples/example', 403, { token: owner.token });
console.log(checks + ' Firestore rules checks passed.');
