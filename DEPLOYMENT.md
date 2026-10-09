# Deploying FixManager

A step-by-step guide for a first deployment. No prior hosting experience needed.

There are two parts:

| Part | What it is | Where it runs |
|---|---|---|
| **Backend** | The Spring Boot API plus a PostgreSQL database. It stores every shop's orders and syncs phones. | [Render](https://render.com), a hosting service. The free plan works for trying it out. |
| **Mobile app** | The Flutter app the shop staff use. It works offline and syncs with the backend. | Staff phones. You install an APK file directly, or publish to the Play Store later. |

Deploy the backend first, because the app needs its web address.

---

## Part 1 — Put the code on GitHub

Render deploys straight from your GitHub repository (`winter000boy/Shop-Application-2`).

1. Commit everything and push it to `master` (the repository's default branch, which Render will deploy):
   ```bash
   git add -A
   git commit -m "Prepare for deployment"
   git push origin master
   ```
2. Never commit real secrets: `.env`, `android/key.properties` and `*.jks` files. They are already git-ignored. The keys in `application-dev.yml` are throwaway development keys and are never used in production.

---

## Part 2 — Deploy the backend on Render

The repository contains a [`render.yaml`](render.yaml) "Blueprint". It tells Render to create the database and the API together and connect them, so you don't configure them by hand.

### 2.1 Create the services
1. Sign up at [render.com](https://render.com) using **Sign in with GitHub**. Allow Render to access the repository.
2. In the dashboard, click **New → Blueprint**.
3. Pick the repository and the `master` branch. Render reads `render.yaml` and shows two resources:
   * `fixmanager-db` (PostgreSQL)
   * `fixmanager-api` (the backend, built from `backend/Dockerfile`)
4. Render asks for the optional mail settings (`SPRING_MAIL_*`, `PASSWORD_RESET_MAIL_FROM`). You can leave them empty for now; see 2.4.
5. Click **Apply**. The first build takes a few minutes. Watch it under **fixmanager-api → Logs**.
   * When it is done, the log shows `Started BackendApplication`.

### 2.2 Check that it works
1. Open **fixmanager-api**. At the top you'll see its address, something like `https://fixmanager-api.onrender.com`. **Write this down**: the app needs it.
2. Open `https://<your-address>/actuator/health` in a browser. You should see:
   ```json
   {"status":"UP"}
   ```

### 2.3 Save the encryption key (important)
Render generated two random keys for you: `JWT_SECRET` and `DEVICE_SECRET_KEY`.
* `DEVICE_SECRET_KEY` encrypts customers' phone passcodes in the database. **If it is ever lost or changed, stored passcodes can't be read again.**
* Go to **fixmanager-api → Environment** and copy `DEVICE_SECRET_KEY` into a password manager.

### 2.4 (Optional) Email for "Forgot password"
Without email settings, the 6-digit reset code is printed in **fixmanager-api → Logs**. You can read it there and pass it to the shop owner.

To email the code automatically from a Gmail account:
1. Turn on 2-Step Verification for the Google account. Then create an **App Password** (Google Account → Security → App passwords).
2. In **fixmanager-api → Environment**, set:

   | Key | Value |
   |---|---|
   | `SPRING_MAIL_HOST` | `smtp.gmail.com` |
   | `SPRING_MAIL_USERNAME` | `yourshop@gmail.com` |
   | `SPRING_MAIL_PASSWORD` | the 16-character app password |
   | `PASSWORD_RESET_MAIL_FROM` | `yourshop@gmail.com` |

3. Save. Render redeploys automatically.

### 2.5 Before real shop data goes in
The free plan is for trying things out. It has two limits:
* **The free database expires 30 days after it is created.** After that it can't be used unless you upgrade it. Upgrade `fixmanager-db` to a paid plan before you depend on it, and check that plan's backup options.
* **The free API sleeps after 15 minutes without traffic.** The first request after that takes about a minute while it wakes up. The app keeps working offline and syncs once the server is awake, but a paid instance avoids the delay.

You can change both plans in the dashboard (each resource → **Settings → Instance Type**). See [render.com/pricing](https://render.com/pricing) for current prices.

### 2.6 Updating the backend later
Push to the same branch and Render rebuilds and redeploys automatically. Database changes go in a new Flyway migration file, such as `backend/src/main/resources/db/migration/V2__something.sql`. It runs on the next deploy.

---

## Part 3 — Build and install the Android app

### 3.1 One-time setup on your Mac
1. Install [Android Studio](https://developer.android.com/studio). Open it once and let it install the Android SDK.
2. In a terminal:
   ```bash
   flutter doctor --android-licenses
   ```
   ```bash
   flutter doctor
   ```
   Accept the licenses. `flutter doctor` should show a ✓ next to "Android toolchain".

### 3.2 Build the APK for your server
Replace the address with yours from step 2.2. Keep `/api/v1` at the end:
```bash
cd mobile
```
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://fixmanager-api.onrender.com/api/v1
```
The file is created at `mobile/build/app/outputs/flutter-apk/app-release.apk`.

> The address is built into the app. If the server address ever changes, build a new APK.
> Release builds only talk to `https://` addresses. Render provides HTTPS automatically.

### 3.3 Install it on shop phones
1. Send `app-release.apk` to the phone, for example via WhatsApp, Google Drive or a USB cable.
2. Open it on the phone. Android asks you to allow **Install unknown apps** for the app you opened it from. Allow it, then install.
3. Open FixManager, tap **Register Now**, and create the shop account.

When you release an update, increase the version in `mobile/pubspec.yaml` first (e.g. `version: 1.0.1+2`; the number after `+` must go up). Then build and install again. Existing data stays.

### 3.4 Later: publishing on the Google Play Store
1. Create a Google Play Console developer account. There is a one-time registration fee.
2. Create your upload key once and keep it safe. **If you lose it, you can't update the app.**
   ```bash
   keytool -genkey -v -keystore ~/fixmanager-upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
3. Copy `mobile/android/key.properties.example` to `mobile/android/key.properties` and fill in the passwords and path.
4. Build an app bundle, which is the format the Play Store wants:
   ```bash
   flutter build appbundle --release --dart-define=API_BASE_URL=https://fixmanager-api.onrender.com/api/v1
   ```
5. Upload `build/app/outputs/bundle/release/app-release.aab` to an **Internal testing** track first.
   * The Play Store also requires a privacy policy URL and a "Data safety" form, because the app stores customer names, phone numbers and device passcodes.
6. The app ID `com.fixmanager.repair_shop_app` becomes permanent after the first upload. Change it in `mobile/android/app/build.gradle.kts` before then if you want a different one.

### 3.5 iPhone
Building for iPhone needs a Mac with Xcode and a paid Apple Developer Program membership. You then distribute through TestFlight or the App Store. The build command is the same idea: `flutter build ipa --dart-define=API_BASE_URL=...`.

---

## Environment variables reference

**Backend** (set on Render; most are created by `render.yaml` automatically):

| Variable | Required | What it does |
|---|---|---|
| `SPRING_PROFILES_ACTIVE` | yes | `prod`. Turns off dev-only features such as the H2 database console. |
| `DATABASE_URL` | yes | Database location. Render fills it in. A `jdbc:` URL also works, with `DATABASE_USERNAME` / `DATABASE_PASSWORD`. |
| `JWT_SECRET` | yes | Signs login sessions. Changing it signs everyone out (no data lost). |
| `DEVICE_SECRET_KEY` | yes | Encrypts customer device passcodes. **Back it up; never change it.** |
| `SPRING_MAIL_HOST`, `SPRING_MAIL_USERNAME`, `SPRING_MAIL_PASSWORD`, `PASSWORD_RESET_MAIL_FROM` | no | Email delivery of password-reset codes. |
| `SPRING_MAIL_PORT` | no | SMTP port, default `587`. |
| `CORS_ALLOWED_ORIGINS` | no | Only needed if a website (not the app) will call the API. |
| `PORT` | no | Set by Render automatically. |

The backend refuses to start if a required variable is missing. You'll see the variable's name in the logs.

**Mobile app** (passed at build time, not stored on a server):

| Setting | Example |
|---|---|
| `API_BASE_URL` | `--dart-define=API_BASE_URL=https://fixmanager-api.onrender.com/api/v1` |

To run the production setup on your own machine instead, see [`backend/.env.example`](backend/.env.example).

---

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| Render build fails | Open **Logs** for the failing deploy. Most often it's a compile error in a pushed change; run `mvn test` in `backend/` locally first. |
| Deploy fails with `Could not resolve placeholder 'X'` | A required environment variable is missing. Add `X` under **Environment**. |
| App says "Network error" on login | Wrong `API_BASE_URL` in the build (check `/api/v1` at the end and `https://`), or the free server is waking up (wait a minute and retry). |
| Forgot-password email never arrives | Check the mail variables; the backend log shows `Failed to send password reset email` with the reason. Until it's fixed, the code is also in the logs. |
| Data gone after a month on the free plan | The free database expired; upgrade it before relying on it (see 2.5). |
