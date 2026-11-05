# Tic-Tac-Toe App



This is a Tic-Tac-Toe game.

## Build, Deployment & Integration Lab (5%)

Deliver two signed Android releases of this Flutter starter through GitHub Actions. Complete the six stages in order. No Google Play Console account or new Flutter dependency is required. This lab is worth **5% of the course grade**. Original project information follows the lab.

### Stage 1 — Run the app

This Flutter app is a two-player Tic-Tac-Toe game with a theme switch and a restart button.

1. Open the project folder and delete its `android` folder.
2. From the project root, regenerate the platform files and run the app:

   ```powershell
   flutter create .
   flutter pub get
   flutter run
   ```

3. Play a game and try the restart button and theme switch. Keep `version: 1.0.0+1` in `pubspec.yaml`.


### Stage 2 — Build and install a signed release APK

1. Generate a dedicated lab release key outside the repository. Use your JDK's keytool (full executable path if necessary):

   ```powershell
   keytool -genkeypair -v -keystore "$env:USERPROFILE\tic-tac-toe-lab-release.jks" -alias lab-release -keyalg RSA -keysize 2048 -validity 10000
   ```

   Enter passwords interactively. Keep a secure private backup of the key, alias and passwords. Use this same key locally, in Actions, and for both versions.
2. Create `android/key.properties` with the following content, replacing the placeholders with your own values:

   ```properties
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=lab-release
   storeFile=C:/Users/YOUR_USERNAME/tic-tac-toe-lab-release.jks
   ```

   Use the alias and keystore path from step 1:

   - If step 1 asked for only one password, enter that same password for both `storePassword` and `keyPassword`. If you chose separate passwords, use their respective values.
   - For `storeFile`, copy the keystore file path shown in the output of step 1 (the “Storing” message). Paste it after `storeFile=` without the surrounding brackets, and replace backslashes (`\`) with forward slashes (`/`).
   - Keep `keyAlias=lab-release` if you used the command in step 1 unchanged. 
3. Configure release signing in `android/app/build.gradle.kts`:

   **A.** Add these imports at the very top of the file, before `plugins`:

   ```kotlin
   import java.io.FileInputStream
   import java.util.Properties
   ```

   **B.** After the existing `plugins { ... }` block and before `android { ... }`, add:

   ```kotlin
   val keystorePropertiesFile = rootProject.file("key.properties")
   require(keystorePropertiesFile.isFile) {
       "Missing android/key.properties. Complete step 2 first."
   }
   val keystoreProperties = Properties().apply {
       FileInputStream(keystorePropertiesFile).use { load(it) }
   }
   fun signingProperty(name: String): String =
       requireNotNull(keystoreProperties.getProperty(name)) {
           "Missing signing property: $name"
       }.also {
           require(it.isNotBlank()) { "Empty signing property: $name" }
       }
   ```

   `rootProject.file("key.properties")` refers to the file inside `android`. This check stops the build if signing details are missing.

   **C.** Inside the existing `android { ... }` block, immediately before `buildTypes`, add:

   ```kotlin
   signingConfigs {
       create("release") {
           keyAlias = signingProperty("keyAlias")
           keyPassword = signingProperty("keyPassword")
           storeFile = file(signingProperty("storeFile"))
           storePassword = signingProperty("storePassword")
       }
   }
   ```

   **D.** In the existing `buildTypes` → `release` block, replace:

   ```kotlin
   signingConfig = signingConfigs.getByName("debug")
   ```

   with:

   ```kotlin
   signingConfig = signingConfigs.getByName("release")
   ```

   Remove the old comments saying the release uses debug keys. Keep the other settings and existing blocks; do not add a second `android` or `buildTypes` block. Save the file. Release builds now use your private signing key instead of the debug key. Because properties are loaded during configuration, this setup requires `android/key.properties` for debug builds too.
4. Before continuing, make sure your project has a Git repository connected to your own GitHub repository. If you have not created one yet, do so now. Confirm that `android/key.properties` and your keystore are excluded from version control. Never commit passwords or signing keys. The exclusions in `android/.gitignore` cover signing files inside `android`; protect any other locations too.

   Build the signed release APK:

   ```powershell
   flutter build apk --release
   ```

5. Find the generated APK at `build/app/outputs/flutter-apk/app-release.apk`. Save a copy named `tic-tac-toe-v1.0.0.apk`.


### Stage 3 — Automate signed APK builds with GitHub Actions


Use the code blocks below to build the same workflow file. Preserve YAML indentation. Place the workflow steps in this order: **2 → 4 → 3 → 5 → 6** after the header from step 1.

1. **Set the workflow trigger.** Name it `android-release.yml` in the project root, or extend your existing workflow. Do not add pull-request triggers to this signing job.

   ```yaml
   name: Build signed Android APK
   
   # 1. Trusted branch push or manual run
   on:
     push:
       branches: [main]
     workflow_dispatch:
   
   permissions:
     contents: read
   
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
   ```

2. **Set up the build tools.** The workflow checks out your code and installs Java and Flutter. Run `flutter --version` locally, then replace `YOUR_FLUTTER_VERSION` in the code below with that exact version number. Java 25 matches the working local setup used for this lab's Gradle 9.3.1 configuration; if your working toolchain differs, use its compatible Java version. Commit `pubspec.lock` for reproducible dependencies. Commit the Android build configuration, but not `android/local.properties` or signing files.

   ```yaml
         # 2. Get the source and install the build tools
         - name: Check out source
           uses: actions/checkout@v4
   
         - name: Set up Java
           uses: actions/setup-java@v4
           with:
             distribution: temurin
             java-version: '25'
   
         - name: Set up Flutter
           uses: subosito/flutter-action@v2
           with:
             flutter-version: 'YOUR_FLUTTER_VERSION'
             channel: stable
             cache: true
   
         - name: Record tool versions
           run: |
             flutter --version
             java -version
   ```

3. **Check the project.** The workflow installs dependencies and analyzes the project. Analysis uses `--no-fatal-infos` so informational findings in the starter code stay visible without stopping the build; warnings and errors still fail the step. Address failures before continuing. The starter has no tests, so this workflow omits `flutter test`; add a test step when meaningful tests are introduced in Stage 5.

   ```yaml
         # 3. Install dependencies and analyze the project
         - name: Install dependencies
           run: flutter pub get
   
         - name: Analyze
           run: flutter analyze --no-fatal-infos
   
   ```

4. **Provide signing secrets and reconstruct the private files.** On your repository page, open **Settings → Secrets and variables → Actions → New repository secret**. Add these four secrets:

   | Secret name | Value |
   | --- | --- |
   | `ANDROID_KEYSTORE_BASE64` | Base64-encoded contents of the keystore from Stage 2 |
   | `ANDROID_KEYSTORE_PASSWORD` | Your keystore password |
   | `ANDROID_KEY_PASSWORD` | Your key password; use the same password if Stage 2 asked for only one |
   | `ANDROID_KEY_ALIAS` | `lab-release`, if you used the Stage 2 command unchanged |

   To copy the encoded keystore directly to your clipboard, run this in PowerShell, replacing the path with the one from Stage 2:

   ```powershell
   $keystorePath = 'C:/Users/YOUR_USERNAME/tic-tac-toe-lab-release.jks'
   [Convert]::ToBase64String([IO.File]::ReadAllBytes($keystorePath)) | Set-Clipboard
   ```

   `ANDROID_KEYSTORE_BASE64` is not a file or a value to look up: the command above generates it from your keystore and copies it to your clipboard without displaying it. For the Windows account `adm1`, the keystore path is `C:/Users/adm1/tic-tac-toe-lab-release.jks`; use your own path from Stage 2.

   On GitHub, under **Settings → Secrets and variables → Actions**, click **New repository secret**:

   - **Name:** enter `ANDROID_KEYSTORE_BASE64`.
   - **Secret:** press **Ctrl+V** to paste the encoded keystore.
   - Click **Add secret**.

   After saving it, clear your clipboard in PowerShell:

   ```powershell
   Set-Clipboard -Value ''
   ```

   Add the other three secrets from the table one at a time using the same **New repository secret** button. Keep all secret values private; do not print, commit or share the encoded key.
 The workflow recreates the keystore and `android/key.properties` privately on GitHub's Linux runner. It uses a Linux path instead of your local Windows path and escapes passwords for the properties-file format. Signing files are created before analysis because Stage 2's Gradle configuration requires them during configuration.

   This shell version supports passwords and aliases made of printable ASCII characters (letters, numbers, spaces and symbols). It stops with a clear error for unsupported characters rather than creating incorrect signing files. Use the same existing passwords as Stage 2.

   ```yaml
         # 4. Restore signing files before any Gradle configuration
         - name: Prepare signing files
           shell: bash
           env:
             KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
             STORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
             KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
             KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
           run: |
             set -euo pipefail
             : "${KEYSTORE_BASE64:?Missing keystore secret}"
             : "${STORE_PASSWORD:?Missing keystore password}"
             : "${KEY_PASSWORD:?Missing key password}"
             : "${KEY_ALIAS:?Missing key alias}"
             umask 077
             printf '%s' "$KEYSTORE_BASE64" | base64 --decode > "$RUNNER_TEMP/lab-release.jks"

             # Escape backslashes and spaces for Java properties.
             write_property() {
               local value="$2"
               if printf '%s' "$value" | LC_ALL=C grep -q '[^ -~]'; then
                 echo 'Signing values must contain printable ASCII characters.' >&2
                 exit 1
               fi
               value="${value//\\/\\\\}"
               value="${value// /\\ }"
               printf '%s=%s\n' "$1" "$value"
             }

             {
               write_property storeFile "$RUNNER_TEMP/lab-release.jks"
               write_property storePassword "$STORE_PASSWORD"
               write_property keyPassword "$KEY_PASSWORD"
               write_property keyAlias "$KEY_ALIAS"
             } > android/key.properties
   ```

5. **Build the APK.** The workflow runs the same `flutter build apk --release` command used locally. It uses your release key through the configuration from Stage 2.

   ```yaml
         # 5. Build with the signing configuration from Stage 2
         - name: Build signed release APK
           run: flutter build apk --release
   ```

6. **Upload the APK and clean up.** The workflow uploads only the APK, keeps the download for 14 days, and deletes temporary signing files even after a failure. After pushing the workflow, open **Actions → Build signed Android APK → latest run**. When it succeeds, scroll to **Artifacts**, download the version-labelled ZIP and extract the APK. This is an Actions artifact; publishing a GitHub Release comes in Stage 4.

   ```yaml
         # 6. Upload only the APK, then remove private signing files
         - name: Read app version
           id: version
           shell: bash
           run: |
             version=$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | tr -d '\r')
             test -n "$version"
             echo "value=$version" >> "$GITHUB_OUTPUT"
   
         - name: Upload APK
           uses: actions/upload-artifact@v4
           with:
             name: tic-tac-toe-${{ steps.version.outputs.value }}
             path: build/app/outputs/flutter-apk/app-release.apk
             if-no-files-found: error
             retention-days: 14
   
         - name: Remove signing files
           if: always()
           shell: bash
           run: |
             rm -f -- android/key.properties "$RUNNER_TEMP/lab-release.jks"
   ```

The action version tags identify the example versions; for a maintained course workflow, pin reviewed action revisions to full commit SHAs. Never commit your local signing files. Download the completed APK and open it on your Android device to install and run it.


### Stage 4 — Automatically publish GitHub Release v1.0.0

Edit the same `.github/workflows/android-release.yml` from Stage 3. Keep its setup, signing, analysis, build, artifact upload and cleanup steps.

1. **Add the tag trigger.** Replace the existing `on` block with this. Keep your actual default branch name if it is not `main`:

   ```yaml
   on:
     push:
       branches: [main]
       tags: ['v*']
     workflow_dispatch:
   ```

   A branch push still builds an artifact. A pushed version tag also publishes a release. The existing checkout step builds the tagged commit automatically; do not override it to check out main.

2. **Allow release creation.** Keep the workflow's top-level `permissions: contents: read`. Add this permission inside the existing `build` job, at the same indentation as `runs-on`:

   ```yaml
   jobs:
     build:
       runs-on: ubuntu-latest
       permissions:
         contents: write
       steps:
         # Keep the existing steps here.
   ```

   This is a placement example, not a second job to paste beneath the first. The built-in token can now publish releases; no new secret or personal access token is needed. Keep this job restricted to your trusted branch/tag pushes and manual runs.

3. **Add the publishing step.** Place this after **Upload APK** and before **Remove signing files**, aligned with the other steps under `steps`. It runs only on tag pushes and only after preceding steps succeed. It checks the tag/version pair, copies the signed APK to a versioned filename, and creates the release with that APK attached:

   ```yaml
         - name: Publish GitHub Release
           if: github.event_name == 'push' && startsWith(github.ref, 'refs/tags/v')
           shell: bash
           env:
             GH_TOKEN: ${{ github.token }}
           run: |
             set -euo pipefail
             version=$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | tr -d '\r')
             case "$GITHUB_REF_NAME" in
               v1.0.0) expected='1.0.0+1' ;;
               v1.1.0) expected='1.1.0+2' ;;
               *) echo 'Unsupported release tag'; exit 1 ;;
             esac
             if [ "$version" != "$expected" ]; then
               echo "Tag $GITHUB_REF_NAME requires pubspec version $expected"
               exit 1
             fi
             apk="tic-tac-toe-${GITHUB_REF_NAME}.apk"
             cp build/app/outputs/flutter-apk/app-release.apk "$apk"
             gh release create "$GITHUB_REF_NAME" "$apk" \
               --verify-tag \
               --title "$GITHUB_REF_NAME" \
               --generate-notes
   ```

   This uses the APK already built in the same job, so no artifact-download step is needed. The version check also supports the Stage 6 update. Generated release notes can be edited afterward to describe the app changes. If a release already exists, the create command fails; do not move published tags or silently overwrite an existing release.

4. **Push the workflow, then create the release tag.** Make sure pubspec.yaml contains `version: 1.0.0+1`. Commit and push your workflow changes first. From the project root, tag the intended release commit and push the tag:

   ```powershell
   git tag -a v1.0.0 -m "Release 1.0.0"
   git push origin v1.0.0
   ```

5. **Check the release.** Open GitHub's **Actions** tab and wait for the v1.0.0 run to succeed. Then open **Releases → v1.0.0 → Assets** and download `tic-tac-toe-v1.0.0.apk`. The source-code ZIP is not the APK. Install this APK on your Android device and keep it installed for the later update.



### Stage 5 — Integrate version 1.1.0+2

After establishing v1.0.0, implement this observable feature update. Keep the application ID and signing key unchanged.

1. Set pubspec.yaml to `version: 1.1.0+2`.
2. Update both the visible AppBar title and MaterialApp title to `Tic-Tac-Toe - <Student ID> v1.1`. Keep the launcher identity recognizable.
3. Add a visible **Round: N** counter with this exact acceptance contract:
   - A fresh app session starts at **Round: 1**.
   - Each press of **Restart Game** clears the board and advances exactly once: 1 → 2 → 3.
   - Restarting an unfinished game also advances once. After a win, the counter waits for Restart Game; it must not also advance automatically.
   - Moves, winning, theme changes and widget rebuilds do not increment or reset the counter.
   - The counter stays visible in both themes and existing moves, wins, restart and theme switching continue to work.
   - Persistence across app termination or installation is not required. The final update demonstrates package/signing compatibility, not counter persistence.

   In `lib/main.dart`, make these three changes:

   **A.** Inside `_HomePageState`, alongside the other state variables, add:

   ```dart
   int round = 1;
   ```

   **B.** In the existing **Restart Game** button, update its `setState` block to:

   ```dart
   setState(() {
     round++;
     _initialize();
   });
   ```

   **C.** In the game board's `Column`, add this widget at the beginning of its `children` list, before the `SizedBox` containing the grid:

   ```dart
   Padding(
     padding: const EdgeInsets.only(bottom: 16),
     child: Text(
       'Round: $round',
       style: TextStyle(
         fontSize: 22,
         color: isDarkTheme ? Colors.white : Colors.black,
       ),
     ),
   ),
   ```

4. Keep `round` outside `_initialize()` so clearing the board does not reset the counter to 1.

5. Commit/push the feature and confirm the normal signed Actions build succeeds before tagging. Use another device for development so the final demonstration device retains installed v1.0.0.



### Stage 6 — Publish and install the update over v1.0.0

1. Reuse the automatic pipeline. Validate v1.1.0 against pubspec 1.1.0+2, name its asset `tic-tac-toe-v1.1.0.apk` and describe the counter/title changes in release notes. Generalize Stage 4's hard-coded filename and notes before tagging.
2. Confirm the feature commit is pushed and tested:

   ```powershell
   git tag -a v1.1.0 -m "Release 1.1.0"
   git push origin v1.1.0
   ```

3. Observe the successful tag run and automatic Release. Download its APK and verify versionName 1.1.0, versionCode 2, the same application ID and the same signer-certificate fingerprint as v1.0.0.


### Grading (5%)

For grading, show me :

- The signed release APK.
- A successful GitHub Actions workflow run that produced the APK.
- Releases 
- Artifacts
- The app running on your device, including the updated title and round counter.















