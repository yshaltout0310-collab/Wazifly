# Firestore rules verification

End-to-end verification of `firestore.rules` and the marketplace data flow,
executed against the **Firestore emulator**.

Dart unit tests can pin the *shape* of the rules
(`test/firestore_rules_guard_test.dart`), but only a real Firestore evaluation
engine can prove they actually permit and refuse the right things. This harness
does that: it publishes a job as an employer, reads and applies to it as a
seeker, reads the application back as the employer, and then attempts every
forgery the rules are supposed to stop.

It lives outside the Flutter package on purpose — it adds **no Dart dependency**
to the app, and it is not part of `flutter test`.

## Running it

Requires Node 18+, the Firebase CLI, and a JDK (the emulator is a Java process).

```bash
cd tool/firestore_rules_test
npm install
npm run verify
```

On Windows the JDK bundled with Android Studio works:

```bash
export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH"
```

## What it asserts

33 checks across the whole loop:

| Stage | Covers |
|---|---|
| 1. Employer publishes | owner can publish; cannot publish as another employer |
| 2. Seeker sees the job | reads a published job by id; **lists** published jobs (the browse query); the `ownerUid` survives; drafts stay private; anonymous users are refused |
| 3. Job tampering | a seeker cannot edit or delete an employer's job; another employer cannot either; a posting can never be repointed to a new owner |
| 4. Seeker applies | the application persists and binds job + employer + applicant + status + timestamp + snapshot; re-applying leaves exactly one |
| 5. Forgery | cannot apply as another applicant, cannot claim a different employer, cannot invent an owner for a non-existent job, cannot self-advance the pipeline, cannot exceed the size caps; a demo job may only be applied to with **no** employer claimed |
| 6. Employer receives | the owner lists applications addressed to them and sees the applicant snapshot and CV; a different employer is refused; the owner can advance status but cannot repoint the applicant or job |
| 7. Seeker history | lists their own applications; sees the employer's status change; **cannot** set their own status; cannot touch another seeker's application; can withdraw their own |
| 8. Persistence | a brand-new client session still sees the application and the job, with the employer's status change intact (the restart / logout case) |

The last stage is the one that matters most: it is the difference between "the
UI looked right during the demo" and "the data is actually in the database".
