<p align="center">
  <picture >
    <source height="96" media="(prefers-color-scheme: dark)" srcset="./.github/resources/icon-white.png">
    <img height="96" alt="QuickPush" src="./.github/resources/icon-dark.png">
  </picture>
  <h1 align="center">QuickPush Tool</h1>
</p>

<p align="center">A lightweight macOS menu bar utility for quickly testing Expo push notifications and Live Activity updates</p>

### Features highlights

- Send test push notifications to your Expo apps directly from the menu bar
- **Send Live Activity pushes** (start, update, end) directly to APNs
- Simple and intuitive interface for quick testing
- Easy configuration of notification payload and options
- Advanced push notification features available
- Platform specific settings available
- Color pickers, progress sliders, and date pickers for Live Activity content
- JSON import/export for Live Activity payloads
- APNs JWT authentication with .p8 key files (no third-party dependencies)

Try out QuickPush now, explore its capabilities, and share your feedback. Your input will shape the future of this tool and guide us on where to take it next.

## 🛠️ Installation

You can download the latest version of QuickPush for macOS from [quickpush/releases](https://github.com/betomoedano/quick-push/releases) page.

1. Download the QuickPush.zip file
2. Extract the zip file by double-clicking it
3. Drag and drop the QuickPush app to your Applications folder
4. Open QuickPush from your Applications folder
5. The QuickPush icon will appear in your menu bar

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

## 📸 Screenshots

<img width="504" alt="Screenshot 2025-02-22 at 7 08 40 PM" src="https://github.com/user-attachments/assets/d5900db9-1f88-4dd8-b33a-3f5873c4c3b7" />

<img width="495" alt="Screenshot 2025-02-22 at 7 08 33 PM" src="https://github.com/user-attachments/assets/bda2d077-0b77-432e-aa8f-10db145b4751" />
