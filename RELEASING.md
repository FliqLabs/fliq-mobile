# Releasing fliq for Android

## Before the first release

1. **Pick the app ID with the Fliq team.** It is still `com.example.flip_mobile`
   in `android/app/build.gradle.kts` (`namespace` and `applicationId`) and in
   `android/app/src/main/kotlin/...`. Google Play never lets it change after
   the first upload, so agree on it first (for example `cash.fliq.android`).
2. **Make the upload key**, once, on your Mac. Keep the file and passwords
   somewhere safe (a password manager). Losing them means you can't update the
   app.

   ```sh
   keytool -genkey -v -keystore ~/fliq-upload.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```

3. **Point the build at it.** Create `android/key.properties` (git ignores it):

   ```properties
   storePassword=the password you chose
   keyPassword=the password you chose
   keyAlias=upload
   storeFile=/Users/YOU/fliq-upload.jks
   ```

## Every release

1. Bump `version:` in `pubspec.yaml` (for example `1.0.1+2`; the number after
   `+` must go up every upload).
2. Run the tests: `flutter test`.
3. Build for the **live** server:

   ```sh
   flutter build appbundle --release \
     --dart-define=FLIQ_API_BASE_URL=https://api-mainnet-64d65ef4.up.railway.app/v1
   ```

4. Upload `build/app/outputs/bundle/release/app-release.aab` in the Google
   Play Console.

Without `--dart-define`, the build talks to the **test** server.

## Icons and launch screen

Both come from `assets/icon/app_icon.png` (the official fliq icon). After
changing it:

```sh
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
