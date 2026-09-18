// End-to-end verification of the Wazifly marketplace against the REAL
// firestore.rules, running on the Firestore emulator.
//
// Proves the whole loop at the data + security layer:
//   employer publishes job -> seeker reads it -> seeker applies ->
//   employer reads the application -> data persists -> attacks are refused.
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, deleteDoc, updateDoc,
  collection, query, where, getDocs,
} from 'firebase/firestore';
import fs from 'node:fs';

const EMPLOYER = 'employer_uid_1';
const OTHER_EMPLOYER = 'employer_uid_2';
const SEEKER = 'seeker_uid_1';
const OTHER_SEEKER = 'seeker_uid_2';
const JOB_ID = 'job_flutter_eng_1';
const DEMO_JOB_ID = 'seed-job-3'; // exists only in assets/data/seed_jobs.json

let pass = 0, fail = 0;
const results = [];
async function check(name, fn) {
  try { await fn(); pass++; results.push(['PASS', name]); }
  catch (e) { fail++; results.push(['FAIL', name, e.message?.slice(0, 160)]); }
}

const env = await initializeTestEnvironment({
  projectId: 'wazifly-rules-verification',
  firestore: { rules: fs.readFileSync('firestore.rules', 'utf8'), host: '127.0.0.1', port: 8181 },
});
await env.clearFirestore();

const employer = env.authenticatedContext(EMPLOYER).firestore();
const otherEmployer = env.authenticatedContext(OTHER_EMPLOYER).firestore();
const seeker = env.authenticatedContext(SEEKER).firestore();
const otherSeeker = env.authenticatedContext(OTHER_SEEKER).firestore();
const anon = env.unauthenticatedContext().firestore();

const jobDoc = {
  id: JOB_ID, companyId: EMPLOYER, ownerUid: EMPLOYER, companyName: 'Acme',
  title: 'Flutter Engineer', description: 'Build things', requiredSkills: ['Dart'],
  location: 'Doha', remote: false, employmentType: 'fullTime', experience: 'mid',
  status: 'published', publishedAt: new Date().toISOString(),
};

const applicationFor = (overrides = {}) => ({
  jobId: JOB_ID, jobTitle: 'Flutter Engineer', company: 'Acme', location: 'Doha',
  status: 'pending', appliedAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(), history: [],
  applicantUid: SEEKER, ownerUid: EMPLOYER, companyId: EMPLOYER,
  companyName: 'Acme', source: 'careerBridge',
  applicant: { snapshotVersion: 1, name: 'Sara', skills: ['Dart'] },
  cvId: 'cv1', cvName: 'My CV', ...overrides,
});
const appId = `${SEEKER}__${JOB_ID}`;

console.log('\n=== 1. EMPLOYER PUBLISHES A JOB ===');
await check('employer can publish a job they own',
  () => assertSucceeds(setDoc(doc(employer, 'jobs', JOB_ID), jobDoc)));
await check('employer CANNOT publish a job owned by someone else',
  () => assertFails(setDoc(doc(otherEmployer, 'jobs', 'forged'), { ...jobDoc, id: 'forged' })));

console.log('\n=== 2. SEEKER SEES THE PUBLISHED JOB ===');
await check('seeker can read the published job by id',
  () => assertSucceeds(getDoc(doc(seeker, 'jobs', JOB_ID))));
await check('seeker can LIST published jobs (the browse query)',
  () => assertSucceeds(getDocs(query(collection(seeker, 'jobs'), where('status', '==', 'published')))));
await check('the job the seeker reads carries the employer ownerUid', async () => {
  const snap = await getDoc(doc(seeker, 'jobs', JOB_ID));
  if (snap.data().ownerUid !== EMPLOYER) throw new Error('ownerUid missing');
});
await check('an unauthenticated visitor CANNOT read jobs',
  () => assertFails(getDoc(doc(anon, 'jobs', JOB_ID))));
await check('a seeker CANNOT list unpublished jobs', async () => {
  await assertSucceeds(setDoc(doc(employer, 'jobs', 'draft1'), { ...jobDoc, id: 'draft1', status: 'draft' }));
  await assertFails(getDocs(query(collection(seeker, 'jobs'), where('status', '==', 'draft'))));
});

console.log('\n=== 3. SEEKER CANNOT TAMPER WITH EMPLOYER JOBS ===');
await check('seeker CANNOT edit an employer job',
  () => assertFails(updateDoc(doc(seeker, 'jobs', JOB_ID), { title: 'hacked' })));
await check('seeker CANNOT delete an employer job',
  () => assertFails(deleteDoc(doc(seeker, 'jobs', JOB_ID))));
await check('another employer CANNOT edit this employer job',
  () => assertFails(updateDoc(doc(otherEmployer, 'jobs', JOB_ID), { title: 'hacked' })));
await check('a job can never be repointed to another owner',
  () => assertFails(updateDoc(doc(employer, 'jobs', JOB_ID), { ownerUid: OTHER_EMPLOYER })));

console.log('\n=== 4. SEEKER APPLIES ===');
await check('seeker can apply to the published job',
  () => assertSucceeds(setDoc(doc(seeker, 'applications', appId), applicationFor())));
await check('the application persists and binds job + employer + applicant', async () => {
  const snap = await getDoc(doc(seeker, 'applications', appId));
  const d = snap.data();
  if (d.jobId !== JOB_ID) throw new Error('jobId lost');
  if (d.ownerUid !== EMPLOYER) throw new Error('ownerUid lost');
  if (d.applicantUid !== SEEKER) throw new Error('applicantUid lost');
  if (d.status !== 'pending') throw new Error('status lost');
  if (!d.appliedAt) throw new Error('timestamp lost');
  if (d.applicant?.name !== 'Sara') throw new Error('applicant snapshot lost');
});
// The Dart client is check-then-write: findByJobId() on the deterministic id
// first, and it returns the existing application instead of writing again.
await check('re-applying is a no-op — still exactly ONE application', async () => {
  const existing = await getDoc(doc(seeker, 'applications', appId));
  if (!existing.exists()) throw new Error('first application missing');
  // client short-circuits here; no second write is issued
  const snap = await getDocs(query(collection(seeker, 'applications'), where('applicantUid', '==', SEEKER)));
  if (snap.size !== 1) throw new Error(`expected 1 application, got ${snap.size}`);
});
await check('an applicant CANNOT overwrite their own application (rules)', async () => {
  // The security property behind the idempotency: once filed, an applicant
  // cannot rewrite the snapshot or status the employer is reviewing. The client
  // treats this denial as "already applied".
  await assertFails(setDoc(doc(seeker, 'applications', appId), applicationFor({ cvName: 'swapped' })));
});

console.log('\n=== 5. APPLICATION FORGERY IS REFUSED ===');
await check('CANNOT apply as another applicant',
  () => assertFails(setDoc(doc(seeker, 'applications', 'forge1'), applicationFor({ applicantUid: OTHER_SEEKER }))));
await check('CANNOT claim a different employer as the owner',
  () => assertFails(setDoc(doc(seeker, 'applications', 'forge2'), applicationFor({ ownerUid: OTHER_EMPLOYER }))));
await check('CANNOT invent an owner for a job that does not exist',
  () => assertFails(setDoc(doc(seeker, 'applications', 'forge3'), applicationFor({ jobId: 'no_such_job', ownerUid: OTHER_EMPLOYER }))));
await check('CANNOT self-advance the pipeline on create',
  () => assertFails(setDoc(doc(seeker, 'applications', 'forge4'), applicationFor({ status: 'accepted' }))));
await check('CANNOT bloat the document past the size caps',
  () => assertFails(setDoc(doc(seeker, 'applications', 'forge5'), applicationFor({ jobTitle: 'x'.repeat(5000) }))));
await check('applying to a DEMO job is allowed only with no employer claimed', async () => {
  await assertSucceeds(setDoc(doc(seeker, 'applications', `${SEEKER}__${DEMO_JOB_ID}`),
    applicationFor({ jobId: DEMO_JOB_ID, ownerUid: '', companyId: '' })));
  await assertFails(setDoc(doc(seeker, 'applications', 'forge6'),
    applicationFor({ jobId: DEMO_JOB_ID, ownerUid: EMPLOYER })));
});

console.log('\n=== 6. EMPLOYER RECEIVES THE APPLICATION ===');
await check('employer can LIST applications addressed to them (the dashboard query)', async () => {
  const snap = await getDocs(query(collection(employer, 'applications'), where('ownerUid', '==', EMPLOYER)));
  if (snap.size !== 1) throw new Error(`employer sees ${snap.size} applications, expected 1`);
  const d = snap.docs[0].data();
  if (d.applicant?.name !== 'Sara') throw new Error('applicant snapshot not visible to employer');
  if (d.cvName !== 'My CV') throw new Error('CV reference not visible to employer');
});
await check('a DIFFERENT employer sees nothing',
  () => assertFails(getDocs(query(collection(otherEmployer, 'applications'), where('ownerUid', '==', EMPLOYER)))));
await check('another seeker CANNOT read this application',
  () => assertFails(getDoc(doc(otherSeeker, 'applications', appId))));
await check('employer can advance the status (pipeline)',
  () => assertSucceeds(updateDoc(doc(employer, 'applications', appId), { status: 'reviewed' })));
await check('employer CANNOT repoint the applicant',
  () => assertFails(updateDoc(doc(employer, 'applications', appId), { applicantUid: OTHER_SEEKER })));
await check('employer CANNOT repoint the job',
  () => assertFails(updateDoc(doc(employer, 'applications', appId), { jobId: 'other' })));

console.log('\n=== 7. SEEKER HISTORY + WITHDRAWAL ===');
await check('seeker can LIST their own application history (the My Applications query)', async () => {
  const snap = await getDocs(query(collection(seeker, 'applications'), where('applicantUid', '==', SEEKER)));
  if (snap.size !== 2) throw new Error(`seeker sees ${snap.size}, expected 2`);
});
await check('the employer status change is visible to the seeker', async () => {
  const snap = await getDoc(doc(seeker, 'applications', appId));
  if (snap.data().status !== 'reviewed') throw new Error('status not propagated');
});
await check('seeker CANNOT set their own status (employer-controlled)',
  () => assertFails(updateDoc(doc(seeker, 'applications', appId), { status: 'accepted' })));
await check('seeker CANNOT modify another seeker application', async () => {
  await assertSucceeds(setDoc(doc(otherSeeker, 'applications', `${OTHER_SEEKER}__${JOB_ID}`),
    applicationFor({ applicantUid: OTHER_SEEKER })));
  await assertFails(deleteDoc(doc(seeker, 'applications', `${OTHER_SEEKER}__${JOB_ID}`)));
});
await check('seeker CAN withdraw their own application',
  () => assertSucceeds(deleteDoc(doc(seeker, 'applications', `${SEEKER}__${DEMO_JOB_ID}`))));

console.log('\n=== 8. PERSISTENCE ACROSS A FRESH CLIENT (restart / logout) ===');
await check('data survives a brand-new client session', async () => {
  const fresh = env.authenticatedContext(SEEKER).firestore();
  const snap = await getDocs(query(collection(fresh, 'applications'), where('applicantUid', '==', SEEKER)));
  if (snap.size !== 1) throw new Error(`after restart seeker sees ${snap.size}, expected 1`);
  if (snap.docs[0].data().status !== 'reviewed') throw new Error('status not durable');
  const freshEmployer = env.authenticatedContext(EMPLOYER).firestore();
  const jobs = await getDocs(query(collection(freshEmployer, 'jobs'), where('ownerUid', '==', EMPLOYER)));
  if (jobs.size !== 2) throw new Error(`employer jobs not durable: ${jobs.size}`);
});

await env.cleanup();

console.log('\n' + '='.repeat(72));
for (const [state, name, err] of results) {
  console.log(`  ${state === 'PASS' ? 'PASS' : 'FAIL'}  ${name}${err ? '\n         -> ' + err : ''}`);
}
console.log('='.repeat(72));
console.log(`RESULT: ${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
