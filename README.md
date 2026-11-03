# ROS OSJA (iOS game lobby preview)

A Flutter app that looks like a mobile game lobby. It is a preview only: there is no gameplay.

## What it does

1. **Login.** The app always opens on the login screen. The only account is:
   - Username: `PanhaShen`
   - Password: `Panhakoko99`
2. **Home.** After login you see the artwork, the ROS OSJA title and a **PLAY** button.
3. **Loading.** PLAY shows a loading screen with a progress bar and tips.
4. **Lobby.** After loading you reach the lobby:
   - left: a scrolling list of 30 players with avatars, levels and status (tap a player to invite them to your team)
   - middle: your avatar and team slots
   - right: SOLO / DUO / SQUAD and a **START** button (START only shows "Preview only")

The login is only a screen. The username and password are stored in `lib/login_page.dart`, so anyone who unpacks the app could read them. Do not reuse a real password.

## Change the picture

The background on every screen is `assets/images/home_bg.jpg`. Replace that file with your own picture (a landscape image, about 1920x1080, works best) and build again. The app icon is `assets/icon/icon.png` (1024x1024).

## Build the .ipa

1. Create a new GitHub repository and upload everything in this folder (keep the `.github/workflows/main.yml` path).
2. Open **Actions**, choose **iOS-ipa-build**, then **Run workflow**.
3. After about 10 minutes, download `ROS_OSJA.ipa` from **Releases**.
4. The file is unsigned. Sign and install it with Sideloadly, or sign it with your ShenSign app.

The workflow is the same method as amir14a/flutter-ipa-export: a free macOS runner builds without code signing and zips the app into an `.ipa`. It also creates the `ios/` folder, sets the name to ROS OSJA and locks the app to landscape.

## Files

- `lib/main.dart` starts the app in landscape.
- `lib/login_page.dart`, `home_page.dart`, `loading_page.dart`, `lobby_page.dart` are the four screens.
- `lib/common.dart` has the shared background, title, button and avatar.
