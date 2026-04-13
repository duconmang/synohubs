# SynoHub Project: Core Authentication, Synology API Usage, and Architecture

## 1. Core Login Logic

### Input Parsing & Address Handling
- **User Input**: Users can enter an IP, domain, or Synology QuickConnect ID.
- **Parsing**: The app parses the input to extract host, port, and protocol (http/https). It supports:
  - IP addresses (IPv4/IPv6)
  - Hostnames (with/without port)
  - URLs (with/without protocol)
  - QuickConnect IDs (e.g., `quickconnect.to/teknasarc` or just `teknasarc`)

### QuickConnect Resolution
- **Detection**: The app detects QuickConnect IDs using `QuickConnectResolver.isQuickConnect`.
- **Resolution Flow**:
  1. POST to `https://global.quickconnect.to/Serv.php` with the QC ID.
  2. Parse the JSON response for available endpoints (LAN, WAN, DDNS, relay).
  3. Try endpoints in priority order: LAN → WAN → DDNS → relay.
  4. Return the first reachable endpoint as a `QuickConnectResult`.
  5. Handles region redirects and relay tunnels if needed.
- **Error Handling**: If resolution fails, a user-friendly error is shown.

### Authentication
- **Login Process**:
  1. The app uses the resolved host/port/protocol to create a `SynologyApi` instance.
  2. Calls `SynologyApi.login` with username, password, and optional OTP (for 2FA).
  3. If login fails with 2FA required, prompts for OTP and retries.
  4. On success, stores the session ID (`sid`) for future API calls.
- **Session Management**: Managed by `SessionManager` singleton, which:
  - Stores connection parameters and session state.
  - Notifies listeners on login/logout/refresh.
  - Handles secure credential storage (with option to remember credentials).
- **Error Handling**:
  - All error codes are mapped to user-friendly messages.
  - Handles network errors, invalid credentials, 2FA, and server-side errors.

### Certificate Handling
- **Self-signed Certificates**: The app accepts self-signed certificates only for trusted NAS hosts (managed by `NasCertOverrides`).
- **Other HTTPS**: Full certificate validation is enforced for all other connections (Google, TMDB, etc.).

---

## 2. Official Synology APIs Used

Below is a list of all official Synology APIs used, their endpoints, purposes, and where they are called:

| API Name / Endpoint                | Purpose                                      | Where Called / Used In                |
|------------------------------------|----------------------------------------------|---------------------------------------|
| `SYNO.API.Auth` (`auth.cgi`)       | Login/logout, session management             | `SynologyApi.login`, `logout`         |
| `SYNO.DSM.Info` (`entry.cgi`)      | Get DSM/NAS info (model, version, serial)    | `getDsmInfo`, dashboard, session init |
| `SYNO.Core.System.Utilization`     | CPU, RAM, network usage                      | `getSystemUtilization`, resource monitor, admin check |
| `SYNO.Storage.CGI.Storage`         | Volumes, disks, RAID info                    | `getStorageInfo`, dashboard           |
| `SYNO.Core.System`                 | Network info, reboot, shutdown, identify     | `getNetworkInfo`, `reboot`, `shutdown`, `findMe` |
| `SYNO.Core.Package`                | List installed/running packages              | `getPackages`, dashboard              |
| `SYNO.Core.User`                   | List, get, create, edit, delete users        | User management screens, admin tools   |
| `SYNO.Core.Group`                  | List, create, edit, delete groups            | Group management (admin)              |
| `SYNO.Core.Group.Member`           | Add/remove group members                     | Group management                      |
| `SYNO.Core.CurrentConnection`      | List current user sessions                   | Resource monitor                      |
| `SYNO.Core.Service`                | List running services                        | Resource monitor                      |
| `SYNO.Core.Quota`                  | List/set user quotas                         | Admin tools                           |
| `SYNO.Core.Share.Permission`       | List/set shared folder permissions           | Admin tools                           |
| `SYNO.Core.User.Home`              | User home directory status                   | Admin tools                           |
| `SYNO.FileStation.List`            | List shared folders, files, get info         | File manager, media hub, photos       |
| `SYNO.FileStation.CreateFolder`    | Create folders                               | File manager                          |
| `SYNO.FileStation.Rename`          | Rename files/folders                         | File manager                          |
| `SYNO.FileStation.Delete`          | Delete files/folders                         | File manager                          |
| `SYNO.FileStation.CopyMove`        | Copy/move files/folders                      | File manager                          |
| `SYNO.FileStation.Search`          | Search files/folders                         | File manager                          |
| `SYNO.FileStation.Sharing`         | Create file sharing links                    | File manager                          |
| `SYNO.FileStation.Upload`          | Upload files                                 | File manager, photo upload            |
| `SYNO.Foto.*` / `SYNO.FotoTeam.*`  | Synology Photos: list, albums, sharing, etc. | Photos screen, albums, sharing        |

---

## 3. Error Handling

- **Network/Parsing Errors**: All network and JSON parsing errors are caught and surfaced to the user.
- **API Errors**: API error codes are mapped to localized, user-friendly messages.
- **2FA/OTP**: Special handling for 2FA-required errors, with OTP dialog and retry.
- **Session Expiry**: If the session expires, the user is prompted to log in again.
- **Self-signed Certs**: Only allowed for user-approved NAS hosts.

---

## 4. Project Architecture & Critical Information

### Architecture Overview
- **Flutter App**: Main codebase in `lib/`, with screens, services, models, and widgets.
- **Session Management**: Centralized in `SessionManager`, which holds the current NAS connection, user info, and notifies the UI.
- **API Layer**: All Synology API calls are encapsulated in `SynologyApi`, which handles authentication, requests, and error handling.
- **QuickConnect**: Handled by `QuickConnectResolver`, which abstracts the complexity of Synology's QuickConnect protocol.
- **Secure Storage**: Credentials are stored securely using `flutter_secure_storage` with encrypted shared preferences.
- **UI**: Modern, responsive UI with support for dark mode, localization, and animated backgrounds.
- **Website**: Separate web frontend in `synohubs.com/` (not covered in this summary).

### Main Goals
- **Unified NAS Management**: Provide a single app for managing Synology NAS devices, regardless of how they are accessed (IP, domain, QuickConnect).
- **Security**: Secure credential handling, support for 2FA, and careful certificate validation.
- **User Experience**: Fast, modern UI with clear error messages and robust handling of all connection scenarios.
- **Extensibility**: Modular codebase, easy to add new Synology API endpoints or features.

---

## 5. Onboarding Notes

- **Start with `main.dart`**: Entry point, sets up certificate overrides and localization.
- **Authentication Flow**: See `login_screen.dart`, `SessionManager`, and `SynologyApi`.
- **API Reference**: All Synology API interactions are in `synology_api.dart`.
- **QuickConnect**: See `quickconnect_resolver.dart` for details on how QuickConnect is resolved.
- **Error Handling**: Consistently handled in all screens and services, with localization.
- **Adding Features**: To add new Synology API calls, extend `SynologyApi` and update relevant screens.

---

*This document provides a comprehensive overview of SynoHub's authentication, API usage, and architecture as of April 10, 2026. For further details, refer to the code comments and service classes in the `lib/services/` directory.*