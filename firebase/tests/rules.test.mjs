import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, serverTimestamp, setDoc, updateDoc, writeBatch } from 'firebase/firestore';

const projectId = 'demo-culturebox-rules';
let env;
const item = (changes = {}) => ({ title: 'Test book', kind: 'Kitap', status: 'queued', progress: 0, updatedAt: serverTimestamp(), ...changes });
const dbFor = (uid) => uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
const itemRef = (db, uid = 'alice') => doc(db, `users/${uid}/items/book-1`);

before(async () => {
  // A demo project and explicit localhost emulator prevent touching live data.
  const address = process.env.FIRESTORE_EMULATOR_HOST;
  if (!address || !/^(127\.0\.0\.1|localhost):\d+$/.test(address)) {
    throw new Error('Run npm run test:emulator; only a local Firestore emulator is accepted.');
  }
  const [host, port] = address.split(':');
  env = await initializeTestEnvironment({
    projectId,
    firestore: { host, port: Number(port), rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/alice'), { username: 'alice', displayName: 'Alice', library: { visible: false } });
    await setDoc(doc(db, 'users/bob'), { username: 'bob', library: { visible: false } });
  });
});
after(async () => { if (env) await env.cleanup(); });

test('owner can create, read, update, list and delete a valid library item', async () => {
  const db = dbFor('alice');
  await assertSucceeds(setDoc(itemRef(db), item()));
  await assertSucceeds(getDoc(itemRef(db)));
  await assertSucceeds(updateDoc(itemRef(db), { status: 'done', progress: 1 }));
  await assertSucceeds(getDocs(collection(db, 'users/alice/items')));
  await assertSucceeds(deleteDoc(itemRef(db)));
});
test('guest and another user cannot access a private library or write its items', async () => {
  await setDoc(itemRef(dbFor('alice')), item());
  for (const uid of [null, 'bob']) {
    const db = dbFor(uid);
    await assertFails(getDoc(itemRef(db)));
    await assertFails(getDocs(collection(db, 'users/alice/items')));
    await assertFails(setDoc(itemRef(db), item()));
    await assertFails(deleteDoc(itemRef(db)));
  }
});
test('public library visibility permits reads and can be revoked by the owner', async () => {
  const owner = dbFor('alice');
  await setDoc(itemRef(owner), item());
  await updateDoc(doc(owner, 'users/alice'), { 'library.visible': true });
  await assertSucceeds(getDoc(itemRef(dbFor(null))));
  await assertSucceeds(getDocs(collection(dbFor('bob'), 'users/alice/items')));
  await assertFails(updateDoc(doc(dbFor('bob'), 'users/alice'), { 'library.visible': true }));
  await updateDoc(doc(owner, 'users/alice'), { 'library.visible': false });
  await assertFails(getDoc(itemRef(dbFor(null))));
});
test('invalid categories, status, progress and timestamps are rejected', async () => {
  const db = dbFor('alice');
  for (const changes of [{ kind: 'Music' }, { status: 'invalid' }, { progress: -1 }, { progress: 2 }, { progress: 'half' }, { updatedAt: 'yesterday' }, { title: '' }]) {
    await assertFails(setDoc(itemRef(db), item(changes)));
  }
  for (const kind of ['Film', 'Dizi', 'Oyun', 'Kitap']) {
    await assertSucceeds(setDoc(itemRef(db), item({ kind })));
  }
});
test('optional provider metadata remains compatible with sync', async () => {
  await assertSucceeds(setDoc(itemRef(dbFor('alice')), item({
    externalId: 'book:1', rating: 4.5, description: 'Summary', creator: 'Author', pageCount: 210,
    publishedYear: 2026, descriptionIsTurkish: true, platforms: [], previewUrl: '', meta: '', imageUrl: '',
  })));
});
test('preferences are private and all unknown collections deny access', async () => {
  await assertSucceeds(setDoc(doc(dbFor('alice'), 'users/alice/preferences/app'), { mode: 'read' }));
  for (const uid of [null, 'bob']) {
    await assertFails(getDoc(doc(dbFor(uid), 'users/alice/preferences/app')));
    await assertFails(setDoc(doc(dbFor(uid), 'users/alice/preferences/app'), { mode: 'play' }));
  }
  await assertFails(setDoc(doc(dbFor('alice'), 'admin/settings'), { role: 'admin' }));
});
test('username claims require their owner, valid spelling, and the matching atomic profile', async () => {
  const db = dbFor('alice');
  await assertFails(setDoc(doc(db, 'usernames/alice'), { uid: 'bob' }));
  await assertFails(setDoc(doc(db, 'usernames/UPPER'), { uid: 'alice' }));
  await assertFails(setDoc(doc(db, 'usernames/other_name'), { uid: 'alice' }));
  await assertSucceeds(setDoc(doc(db, 'usernames/alice'), { uid: 'alice' }));
  await assertFails(updateDoc(doc(db, 'usernames/alice'), { uid: 'bob' }));
  await assertFails(deleteDoc(doc(db, 'usernames/alice')));
});

function reviewBatch(db, { uid = 'alice', rating = 4, count = 1, sum = rating, text = 'Good', username = uid, kind = 'Kitap', remove = false } = {}) {
  const batch = writeBatch(db);
  batch.set(doc(db, 'content/book-1'), { title: 'Book', kind, imageUrl: '', reviewCount: count, ratingSum: sum });
  const ref = doc(db, `content/book-1/reviews/${uid}`);
  if (remove) batch.delete(ref);
  else batch.set(ref, { uid, username, contentId: 'book-1', contentKind: kind, contentTitle: 'Book', contentImageUrl: '', rating, text, createdAt: serverTimestamp(), updatedAt: serverTimestamp() });
  return batch.commit();
}
test('review creation, editing and deletion keep totals consistent atomically', async () => {
  const db = dbFor('alice');
  await assertSucceeds(reviewBatch(db));
  await assertSucceeds(reviewBatch(db, { rating: 2 }));
  await assertSucceeds(reviewBatch(dbFor('bob'), { uid: 'bob', rating: 5, count: 2, sum: 7 }));
  await assertSucceeds(reviewBatch(db, { remove: true, count: 1, sum: 5 }));
});
test('review impersonation, invalid rating and oversized text are denied', async () => {
  const db = dbFor('alice');
  for (const changes of [{ uid: 'bob' }, { username: 'bob' }, { rating: 0 }, { rating: 6 }, { rating: 2.5 }, { text: 'a'.repeat(2001) }, { kind: 'Music' }]) {
    await assertFails(reviewBatch(db, changes));
  }
  await assertFails(reviewBatch(dbFor(null)));
});
test('clients cannot forge totals or delete reviews without adjusting aggregates', async () => {
  const db = dbFor('alice');
  await assertFails(reviewBatch(db, { count: 100, sum: 400 }));
  await assertSucceeds(reviewBatch(db));
  await assertFails(updateDoc(doc(db, 'content/book-1'), { ratingSum: 5 }));
  await assertFails(deleteDoc(doc(db, 'content/book-1/reviews/alice')));
  await assertFails(reviewBatch(db, { rating: 3, count: 1, sum: 5 }));
  await assertSucceeds(getDoc(doc(dbFor(null), 'content/book-1/reviews/alice')));
});
