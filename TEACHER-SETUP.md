# Teacher view — one-time setup (≈5 minutes)

The tracker can sync every student's logs to a free cloud database so the teacher
sees everyone live. This uses **Supabase** (free tier). Do this once.

## 1. Create a free Supabase project
1. Go to **https://supabase.com** → sign up (free) → **New project**.
2. Give it any name, set a database password, pick a region close to you, create it.
3. Wait ~1 minute for it to finish setting up.

## 2. Create the database
1. In the project, open **SQL Editor** (left sidebar) → **New query**.
2. Open the file **`supabase-setup.sql`** (in this folder), copy everything, paste it in.
3. **Change the passcode**: find the line `if pass = 'changeme123'` and replace
   `changeme123` with your own secret teacher passcode.
4. Click **Run**. You should see "Success".

## 3. Get your two keys
1. Open **Project Settings** (gear, bottom-left) → **API**.
2. Copy the **Project URL** (looks like `https://abcd1234.supabase.co`).
3. Copy the **anon public** key (a long string — the one labelled *anon* / *public*).

## 4. Send me those two values (or paste them in yourself)
Open `index.html`, find the `CLOUD` block near the top of the `<script>` and fill in:
```js
const CLOUD = {
  url:     'https://abcd1234.supabase.co',   // your Project URL
  anonKey: 'eyJhbGciOi...',                  // your anon public key
};
```
Save, commit, push — and sync is live.

## How students use it
- Nothing extra: as soon as a student writes their name (first screen) and logs,
  their data auto-uploads. They never need to "send" anything.

## How the teacher opens the admin view
- Open the app and tap **“Teacher view”** at the bottom (or add `#teacher` to the URL),
  enter the passcode from step 2.3, and you'll see every student and all their logs.

## Updating later (e.g. to enable "Delete student")
If you set this up before the delete feature existed, just re-run the setup:
1. **SQL Editor** → **New query** → paste **all** of `supabase-setup.sql` again
   (re-running is safe — it replaces the functions, your data is untouched).
2. Remember to change `changeme123` to your passcode on every line that has it.
3. Click **Run**. The teacher view's **Delete student** and **Delete all students**
   buttons will now work.

## Notes
- The **anon key is safe to be public** — the database only lets students add/update
  their own row, and only the passcode-protected functions can read or delete data.
- Students restoring on a new device still use **Export/Import** (cloud is upload-only
  for them, by design, so no one but the teacher can read the class data).
