<p align="center">
  <picture >
    <source height="96" media="(prefers-color-scheme: dark)" srcset="./.github/resources/icon-white.png">
    <img height="96" alt="QuickPush" src="./.github/resources/icon-dark.png">
  </picture>
  <h1 align="center">QuickPush Tool</h1>
</p>

<p align="center">A lightweight macOS menu bar utility for quickly testing Expo push notifications, Live Activity updates, native APNs, and FCM (Android) pushes</p>

<p align="center">
  <a href="https://apps.apple.com/us/app/quickpush-tool/id6758917536">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="./.github/resources/Download_on_the_Mac_App_Store_Badge_US-UK_RGB_wht_092917.svg">
      <img alt="Download on the Mac App Store" src="./.github/resources/Download_on_the_Mac_App_Store_Badge_US-UK_RGB_blk_092917.svg" height="48">
    </picture>
  </a>
</p>

### Features

- Send test push notifications to your Expo apps directly from the menu bar
- **Send Live Activity pushes** (start, update, end) directly to APNs
- Simple and intuitive interface for quick testing
- Easy configuration of notification payload and options
- **Rich content (image) support** for Android notifications via `richContent`
- Advanced push notification features (priority, interruption level, TTL, and more)
- Platform-specific settings for iOS and Android
- Color pickers, progress sliders, and date pickers for Live Activity content
- JSON import/export for Live Activity payloads
- APNs JWT authentication with .p8 key files (no third-party dependencies)
- **Native APNs push** directly to raw device tokens — full payload control, image URL support
- **Native FCM push** directly to Firebase Cloud Messaging HTTP v1 API — service account auth, no SDKs required

## 🛠️ Installation

<a href="https://apps.apple.com/us/app/quickpush-tool/id6758917536">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="./.github/resources/Download_on_the_Mac_App_Store_Badge_US-UK_RGB_wht_092917.svg">
    <img alt="Download on the Mac App Store" src="./.github/resources/Download_on_the_Mac_App_Store_Badge_US-UK_RGB_blk_092917.svg" height="48">
  </picture>
</a>

The easiest way to get QuickPush is from the [Mac App Store](https://apps.apple.com/us/app/quickpush-tool/id6758917536). One-time purchase, automatic updates, no setup required.

#### Build from source

QuickPush is open source. If you prefer, you can clone the repo and build it locally with Xcode:

```bash
git clone https://github.com/betomoedano/quick-push.git
open quick-push/QuickPush.xcodeproj
```

Requires Xcode 16+ and macOS 14.6+.

## 🔴 Live Activity Setup

To send Live Activity push notifications, QuickPush communicates directly with Apple's APNs (Apple Push Notification service) using JWT-based authentication. You'll need a few things from your Apple Developer account before you can start.

### 1. Get your Team ID

Your Team ID is a 10-character string that identifies your Apple Developer team.

1. Go to [Apple Developer Account](https://developer.apple.com/account)
2. Sign in with your Apple ID
3. Your **Team ID** is displayed under **Membership Details**

### 2. Create an APNs Authentication Key (.p8 file)

The .p8 key file is used to sign JWT tokens that authenticate your requests with APNs. You only need to create this once — it works for all your apps.

1. Go to [Certificates, Identifiers & Profiles > Keys](https://developer.apple.com/account/resources/authkeys/list)
2. Click the **+** button to create a new key
3. Give it a name (e.g. "QuickPush APNs Key")
4. Check **Apple Push Notifications service (APNs)**
5. Click **Continue**, then **Register**
6. **Download the .p8 file** — you can only download it once, so save it somewhere safe
7. Note the **Key ID** shown on this page (10-character string, e.g. `ABC123DEF4`)

> **Important:** Apple only lets you download the .p8 file once. If you lose it, you'll need to create a new key.

For more details, see Apple's documentation: [Establishing a Token-Based Connection to APNs](https://developer.apple.com/documentation/usernotifications/establishing-a-token-based-connection-to-apns)

### 3. Find your Bundle ID

The Bundle ID is the unique identifier for your app (e.g. `com.yourcompany.yourapp`).

1. Go to [Certificates, Identifiers & Profiles > Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Find your app in the list
3. The **Bundle ID** is shown next to each app

This must match the bundle identifier of the app that registered the Live Activity.

### 4. Configure QuickPush

1. Open QuickPush from your menu bar
2. Switch to the **Live Activity** tab
3. Expand the **APNs Configuration** section
4. Enter your **Team ID**, **Key ID**, and **Bundle ID**
5. Click **Browse...** to select your `.p8` key file
6. Choose **Sandbox** (for development/TestFlight builds) or **Production** (for App Store builds)

> Your configuration is saved automatically and persists between sessions.

### 5. Send a Live Activity Push

1. Choose an event type:
   - **Start** — creates a new Live Activity on the device (requires a push-to-start token)
   - **Update** — updates an existing Live Activity (requires an activity token)
   - **End** — ends an existing Live Activity (requires an activity token)
2. Paste the device token (hex string) from your app
3. Fill in the content state fields (title, subtitle, progress, etc.)
4. For **Start** events, configure the attributes (colors, layout options)
5. Click **Send**

### Sandbox vs Production

| Environment | When to use | APNs hostname |
|---|---|---|
| **Sandbox** | Development builds, TestFlight | `api.sandbox.push.apple.com` |
| **Production** | App Store releases | `api.push.apple.com` |

If you're testing on a device with a development or TestFlight build, use **Sandbox**. If your app is installed from the App Store, use **Production**.

### Getting Device Tokens

Your app needs to provide the device token for Live Activities. Depending on the event type:

- **Push-to-start token**: Obtained via `Activity.pushToStartToken` — use this for **Start** events
- **Activity token**: Obtained via `activity.pushToken` after a Live Activity has been started — use this for **Update** and **End** events

These are raw APNs hex tokens (not Expo push tokens). See the [Expo LiveActivity documentation](https://docs.expo.dev/versions/latest/sdk/live-activity/) for implementation details with `expo-live-activity`.

### JSON Import/Export

Click the **JSON** button in the Live Activity tab to:

- **Export** the current form as a JSON payload (useful for debugging or sharing)
- **Import** a JSON payload to populate the form fields (useful for quickly loading saved payloads)

## 📡 APNs Tab

The **APNs** tab lets you send native iOS push notifications directly to Apple's Push Notification service — no Expo push token required. It's useful for testing notifications on devices where you only have the raw APNs device token, or when you need full control over the APNs payload.

### Device Tokens

APNs device tokens are raw hex strings (64 hex characters), different from Expo push tokens (`ExponentPushToken[...]`). Your app receives this token from the system:

```swift
// Swift (iOS)
func application(_ application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    print("APNs token:", token)
}
```

Tokens can be saved across sessions using the save button next to the token field.

### Payload Fields

| Field | Description |
|---|---|
| **Title / Subtitle / Body** | Standard alert text |
| **Sound** | `default` or a custom sound file name bundled in the app |
| **Badge** | Number shown on the app icon |
| **Image URL** | URL of an image to attach to the notification (see below) |
| **Thread ID** | Groups related notifications together in the notification center |
| **Category** | Enables interactive notification actions registered in the app |
| **Interruption Level** | Controls delivery timing (Active, Passive, Time Sensitive, Critical) |
| **Mutable Content** | Allows a Notification Service Extension to modify the payload before display |
| **Content Available** | Wakes the app in the background to process the notification silently |
| **Priority** | `10` = immediate, `5` = normal/background |

### Image URL (via Notification Service Extension)

APNs does not have a built-in image field. To display an image in a notification, the iOS app must include a **Notification Service Extension** — a small app extension that intercepts the push before it's shown, downloads the image, and attaches it as a media attachment.

The Image URL field in QuickPush injects the URL into the payload under a custom key path:

```json
{
  "aps": { "alert": { "title": "Hello" }, "mutable-content": 1 },
  "body": { "_richContent": { "image": "https://example.com/photo.jpg" } }
}
```

Your Notification Service Extension would read it like this:

```swift
// In NotificationService.swift
let imageUrl = (request.content.userInfo["body"] as? [String: Any])
    .flatMap { $0["_richContent"] as? [String: Any] }
    .flatMap { $0["image"] as? String }
    .flatMap { URL(string: $0) }
```

> **Note:** The exact key path (`body._richContent.image`) is the convention QuickPush uses. The key name your app listens for depends entirely on what the Notification Service Extension in that app is coded to read. If you're testing against an app that uses a different key, use the **Custom Data** section to inject the key manually instead.

Filling in the Image URL field automatically enables **Mutable Content** in the payload, which is required for the Notification Service Extension to be invoked.

## 🤖 FCM Tab

The **FCM** tab lets you send native Android push notifications directly to Firebase Cloud Messaging's HTTP v1 API — no Expo push token required. It authenticates using a Firebase service account, signs OAuth 2.0 tokens locally with RS256 (no third-party SDKs), and supports both notification and data-only messages.

### 1. Create a Firebase Project

If you don't already have one:

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** and follow the setup wizard
3. Once created, add your Android app to the project (**Project settings → Your apps → Add app**)

### 2. Generate a Service Account Key

QuickPush authenticates with FCM using a **service account JSON** file. This is the same credential type used by Firebase Admin SDKs.

1. In the [Firebase Console](https://console.firebase.google.com/), open your project
2. Go to **Project settings** (gear icon) → **Service accounts** tab
3. Click **Generate new private key**
4. Confirm by clicking **Generate key** — a `.json` file will download

The JSON file contains your project ID, client email, and private key. QuickPush reads all three from the file automatically when you select it.

> **Keep this file secure.** Anyone with it can send push notifications to all users of your app. Don't commit it to version control.

### 3. Find your FCM Registration Token

The FCM registration token identifies a specific app install on a device. It's not the same as an Expo push token.

**React Native / Expo (using `@react-native-firebase/messaging`):**

```js
import messaging from '@react-native-firebase/messaging';

const token = await messaging().getToken();
console.log('FCM token:', token);
```

**React Native / Expo (using `expo-notifications`):**

```js
import * as Notifications from 'expo-notifications';

const { data: token } = await Notifications.getDevicePushTokenAsync();
// On Android this returns the raw FCM registration token
console.log('FCM token:', token);
```

FCM tokens are long base64url strings (~163+ characters). They can change when the user reinstalls the app or clears app data.

### 4. Configure QuickPush

1. Open QuickPush from your menu bar
2. Switch to the **FCM** tab (⌘4)
3. Expand the **FCM Configuration** section
4. Click **Browse...** and select your downloaded service account `.json` file
5. **Project ID** and **Client Email** are auto-filled from the file — verify they look correct

> Your configuration is saved automatically and persists between sessions. The service account JSON contents are stored in macOS user defaults (local to your machine, not synced).

### 5. Send a Push

1. Paste your FCM registration token into the token field (or use the save button to store it for future sessions)
2. Choose the **Message Type**:
   - **Notification** — displays a visible notification on the device
   - **Data** — delivers a silent data payload to the app; no notification UI is shown
3. Fill in the notification fields (Title, Body, Image URL, Channel ID, Sound, Color)
4. Optionally add **Custom Data** key-value pairs — these are delivered in the message's `data` block
5. Click **Send** (or ⌘↵)

### Message Types

| Type | Description | When to use |
|---|---|---|
| **Notification** | Shows a visible notification with title, body, and optional image | User-facing alerts |
| **Data** | Silent payload delivered to the app; no system UI | Background processing, in-app messages |

### Notification Fields

| Field | Description |
|---|---|
| **Title** | Title of the notification |
| **Body** | Main message content |
| **Image URL** | URL of an image displayed in the expanded notification |
| **Channel ID** | Android notification channel the app must have pre-created (defaults to `default`) |
| **Sound** | Sound to play — use `default` for the device default |
| **Color** | Accent color for the notification icon, in hex format (e.g. `FF5733`) |

### Priority

| Value | Description |
|---|---|
| **HIGH** | Wakes the device immediately — use for user-visible notifications |
| **NORMAL** | May be delayed for battery optimization — suitable for non-urgent data messages |

### FCM Error Codes

| Code | Meaning |
|---|---|
| `INVALID_ARGUMENT` | The request payload is malformed or the token format is wrong |
| `NOT_FOUND` / `UNREGISTERED` | The token is no longer valid; the app was uninstalled or the token expired |
| `SENDER_ID_MISMATCH` | The token was registered with a different Firebase project |
| `QUOTA_EXCEEDED` | Sending rate too high; retry with exponential backoff |
| `UNAVAILABLE` | FCM service temporarily unavailable; retry with exponential backoff |
| `INTERNAL` | Internal FCM server error; retry with exponential backoff |

### Getting a cURL Command

Click the **cURL** button to generate a ready-to-run curl command for the current configuration. Because the OAuth access token requires an async exchange with Google's servers, the cURL output uses an `<ACCESS_TOKEN>` placeholder. To fill it in:

```bash
# Using the Google Cloud CLI
gcloud auth print-access-token

# Or using the service account directly
gcloud auth activate-service-account --key-file=/path/to/service-account.json
gcloud auth print-access-token
```

Replace `<ACCESS_TOKEN>` in the copied curl command with the token output.

### Saved Tokens

Click the **save** icon (↓) next to any token to store it with a label. Saved tokens persist across app restarts and appear at the top of the token list with a toggle to include or exclude them from sends.

## 🖼️ Rich Content (Image Notifications)

QuickPush supports the `richContent` field, allowing you to attach an image to your push notifications.

1. Open the **Push Notification** tab
2. Expand **Advanced Settings**
3. In the **Common Settings** section, find the **Image (richContent)** field
4. Paste the URL of the image you want to display

### Platform behavior

| Platform | Support |
|---|---|
| **Android** | Works out of the box — the image will display in the notification |
| **iOS** | Requires a [Notification Service Extension](https://github.com/expo/expo/pull/36202) target in your app to process and display the image |

> **Tip:** The help tooltip for this field includes a clickable link to the Expo PR with an iOS implementation example.

## 📸 Screenshots

<img width="504" alt="QuickPush Push Notification" src="https://github.com/user-attachments/assets/d5900db9-1f88-4dd8-b33a-3f5873c4c3b7" />

<img width="495" alt="QuickPush Advanced Settings" src="https://github.com/user-attachments/assets/bda2d077-0b77-432e-aa8f-10db145b4751" />

## License

MIT

---

<p align="center">
  Made with ❤️ by <a href="https://codewithbeto.dev">codewithbeto.dev</a>
</p>
