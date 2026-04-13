# SynoHub

<p align="center">
  <img src="synohubs.com/public/favicon.svg" alt="SynoHub Logo" width="120" />
</p>

<p align="center">
  <strong>The Ultimate Client for your Synology NAS</strong>
</p>

<p align="center">
  <a href="https://synohubs.com">Website</a> •
  <a href="https://synohubs.com/#download">Download</a> •
  <a href="https://github.com/duconmang/synohubs/blob/main/LICENSE">License</a>
</p>

## Overview

SynoHub is a powerful, secure, and intuitive mobile client for managing your Synology NAS. Built with Flutter, it provides a seamless experience for files, photos, media streaming, and system monitoring directly from your phone.

We prioritize your privacy:
- **Zero Cloud Intermediaries:** SynoHub connects directly to your NAS. Your data never touches our servers.
- **No Subscriptions:** Buy once, use forever. No hidden fees.

## Features

- **Multi-NAS Support:** Manage multiple Synology devices from a single app.
- **Google Drive Backup:** Securely backup your connection profiles to Google Drive with AES-256-CBC encryption.
- **6 Languages:** Available in English, Vietnamese, Chinese, Japanese, French, and Portuguese.
- **Self-Signed Certificates:** Easily connect using self-signed or unverified SSL certificates.
- **Unified Dashboard:** Real-time monitoring of CPU, RAM, network speeds, and storage capacity.
- **File Explorer:** Browse, upload, download, and manage your NAS file system.
- **Media Hub:** Stream your movies and shows with a beautiful cinematic interface.
- **SynoHub Photos:** View and manage your photo library with timeline and album views.

## Technologies Used

- **Framework:** Flutter (SDK 3.10+)
- **State Management:** Provider / Riverpod 
- **Encryption:** AES-256 for secure profile backups
- **Authentication:** Firebase (for VIP verification only)
- **Website:** React + Vite, deployed on Cloudflare Pages (`synohubs.com/`)

## Getting Started

### Prerequisites

- Flutter SDK 3.10 or higher
- Android Studio / VS Code
- A Firebase project (for VIP authentication)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/duconmang/synohubs.git
   cd synohubs
   ```

2. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Copy `android/app/google-services.json.example` to `android/app/google-services.json` and fill in your Firebase details.
   - Copy `lib/firebase_options.dart.example` to `lib/firebase_options.dart` and update with your Firebase project keys.

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

- `/lib`: Main Flutter Dart source code.
- `/android` & `/ios`: Platform-specific native code.
- `/synohubs.com`: Source code for the marketing website (React + Vite).
- `/html`: HTML prototypes and design references.

## Security & Privacy 

SynoHub does not store your NAS credentials or data on our servers. The app requires Firebase primarily to verify VIP or Premium user status. Connection profiles backed up to Google Drive are encrypted using AES-256-CBC, with the recovery key stored securely. Sensitive files such as Firebase configurations and Keystores are purposely excluded from this repository.

## License

This project is licensed under the [GNU Affero General Public License v3.0 (AGPL-3.0)](LICENSE) - see the LICENSE file for details. 

*Note: You are free to use, modify, and distribute this software, but any modified versions of the software accessed over a network must also have their source code made publicly available.*