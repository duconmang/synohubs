use serde::{Deserialize, Serialize};
use tokio::sync::Mutex;
use tauri::{State, Manager};

/// Synology API client — port of Flutter SynologyApi
/// Handles auth, DSM info, utilization, storage, packages, file station, etc.
mod synology {
    use reqwest::Client;
    use serde_json::Value;
    use std::collections::HashMap;

    pub struct SynologyApi {
        pub host: String,
        pub port: u16,
        pub use_https: bool,
        pub sid: Option<String>,
        client: Client,
    }

    impl SynologyApi {
        pub fn new(host: &str, port: u16, use_https: bool) -> Self {
            let client = Client::builder()
                .danger_accept_invalid_certs(true) // NAS self-signed certs
                .timeout(std::time::Duration::from_secs(15))
                .build()
                .unwrap_or_default();

            Self {
                host: host.to_string(),
                port,
                use_https,
                sid: None,
                client,
            }
        }

        fn base_url(&self) -> String {
            let scheme = if self.use_https { "https" } else { "http" };
            format!("{}://{}:{}/webapi", scheme, self.host, self.port)
        }

        async fn get(
            &self,
            endpoint: &str,
            mut params: HashMap<String, String>,
        ) -> Result<Value, String> {
            if let Some(ref sid) = self.sid {
                params.insert("_sid".to_string(), sid.clone());
            }

            let url = format!("{}/{}", self.base_url(), endpoint);
            let resp = self
                .client
                .get(&url)
                .query(&params)
                .send()
                .await
                .map_err(|e| format!("Network error: {}", e))?;

            let json: Value = resp
                .json()
                .await
                .map_err(|e| format!("JSON parse error: {}", e))?;

            Ok(json)
        }

        /// POST request for mutating operations (create, delete, set)
        async fn post(
            &self,
            endpoint: &str,
            mut params: HashMap<String, String>,
        ) -> Result<Value, String> {
            if let Some(ref sid) = self.sid {
                params.insert("_sid".to_string(), sid.clone());
            }

            let url = format!("{}/{}", self.base_url(), endpoint);
            let resp = self
                .client
                .post(&url)
                .form(&params)
                .send()
                .await
                .map_err(|e| format!("Network error: {}", e))?;

            let json: Value = resp
                .json()
                .await
                .map_err(|e| format!("JSON parse error: {}", e))?;

            Ok(json)
        }

        /// Login to Synology NAS
        /// Supports device token for 2FA bypass on trusted devices.
        /// Uses SYNO.API.Auth v7 which supports enable_device_token.
        pub async fn login(
            &mut self,
            account: &str,
            passwd: &str,
            otp_code: Option<&str>,
            device_id: Option<&str>,
        ) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.API.Auth".to_string());
            params.insert("version".to_string(), "7".to_string());
            params.insert("method".to_string(), "login".to_string());
            params.insert("account".to_string(), account.to_string());
            params.insert("passwd".to_string(), passwd.to_string());
            params.insert("session".to_string(), "FileStation".to_string());
            params.insert("format".to_string(), "sid".to_string());

            // If we have a trusted device_id, send it to skip 2FA
            // IMPORTANT: device_name must always be sent alongside device_id
            if let Some(did) = device_id {
                if !did.is_empty() {
                    params.insert("device_id".to_string(), did.to_string());
                    params.insert("device_name".to_string(), "SynoHubs Desktop".to_string());
                }
            }

            if let Some(otp) = otp_code {
                if !otp.is_empty() {
                    params.insert("otp_code".to_string(), otp.to_string());
                    // Request a device token so we can skip 2FA next time
                    params.insert("enable_device_token".to_string(), "yes".to_string());
                    params.insert("device_name".to_string(), "SynoHubs Desktop".to_string());
                }
            }

            let resp = self.get("auth.cgi", params).await?;

            // Log for debugging device token issues
            if resp["success"].as_bool() == Some(true) {
                self.sid = resp["data"]["sid"].as_str().map(String::from);
                // Synology may return the device token as "did" or "device_id"
                let did = resp["data"]["did"].as_str()
                    .or_else(|| resp["data"]["device_id"].as_str())
                    .unwrap_or("none");
                eprintln!("[SynoHubs] Login success, did={}", did);
            } else {
                let code = resp["error"]["code"].as_i64().unwrap_or(0);
                eprintln!("[SynoHubs] Login failed, code={}, error={}", code, resp["error"]);
            }

            Ok(resp)
        }

        /// Logout
        pub async fn logout(&mut self) -> Result<(), String> {
            if self.sid.is_none() {
                return Ok(());
            }
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.API.Auth".to_string());
            params.insert("version".to_string(), "6".to_string());
            params.insert("method".to_string(), "logout".to_string());
            params.insert("session".to_string(), "FileStation".to_string());
            let _ = self.get("auth.cgi", params).await;
            self.sid = None;
            Ok(())
        }

        /// Check if user is admin (try calling admin-only API)
        pub async fn check_admin(&self) -> bool {
            if self.sid.is_none() {
                return false;
            }
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.System.Utilization".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "get".to_string());
            match self.get("entry.cgi", params).await {
                Ok(resp) => resp["success"].as_bool() == Some(true),
                Err(_) => false,
            }
        }

        /// Get DSM info
        pub async fn get_dsm_info(&self) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.DSM.Info".to_string());
            params.insert("version".to_string(), "2".to_string());
            params.insert("method".to_string(), "getinfo".to_string());
            self.get("entry.cgi", params).await
        }

        /// Get system utilization (CPU, RAM, network)
        pub async fn get_system_utilization(&self) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.System.Utilization".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "get".to_string());
            self.get("entry.cgi", params).await
        }

        /// Get storage info (volumes, disks)
        pub async fn get_storage_info(&self) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Storage.CGI.Storage".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "load_info".to_string());
            self.get("entry.cgi", params).await
        }

        /// Get packages list
        pub async fn get_packages(&self) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.Package".to_string());
            params.insert("version".to_string(), "2".to_string());
            params.insert("method".to_string(), "list".to_string());
            self.get("entry.cgi", params).await
        }

        /// Get available packages from Synology Package Server
        pub async fn package_list_server(&self) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.Package.Server".to_string());
            params.insert("version".to_string(), "2".to_string());
            params.insert("method".to_string(), "list".to_string());
            params.insert("blforcereload".to_string(), "false".to_string());
            self.get("entry.cgi", params).await
        }

        /// Install a package by name
        pub async fn package_install(&self, id: &str, volume: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.Package.Installation".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "install".to_string());
            params.insert("id".to_string(), id.to_string());
            params.insert("volume".to_string(), volume.to_string());
            self.get("entry.cgi", params).await
        }

        /// Uninstall a package by name
        pub async fn package_uninstall(&self, id: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.Package.Uninstallation".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "uninstall".to_string());
            params.insert("id".to_string(), id.to_string());
            self.get("entry.cgi", params).await
        }

        /// Start a package
        pub async fn package_start(&self, id: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.Package".to_string());
            params.insert("version".to_string(), "2".to_string());
            params.insert("method".to_string(), "start".to_string());
            params.insert("id".to_string(), id.to_string());
            self.get("entry.cgi", params).await
        }

        /// Stop a package
        pub async fn package_stop(&self, id: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.Package".to_string());
            params.insert("version".to_string(), "2".to_string());
            params.insert("method".to_string(), "stop".to_string());
            params.insert("id".to_string(), id.to_string());
            self.get("entry.cgi", params).await
        }

        // ── User & Group Management APIs ─────────────────────

        /// List all users
        pub async fn user_list(&self) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.User".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "list".to_string());
            params.insert("type".to_string(), "local".to_string());
            params.insert("offset".to_string(), "0".to_string());
            params.insert("limit".to_string(), "200".to_string());
            params.insert("additional".to_string(), "[\"email\",\"description\",\"expired\"]".to_string());
            self.get("entry.cgi", params).await
        }

        /// Get detailed info for a specific user (with all additional fields)
        pub async fn user_get(&self, name: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.User".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "get".to_string());
            params.insert("name".to_string(), name.to_string());
            params.insert("additional".to_string(), "[\"email\",\"description\",\"expired\",\"password_last_change\",\"groups\"]".to_string());
            self.get("entry.cgi", params).await
        }

        /// Get quota usage for a user
        pub async fn user_quota(&self, name: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.Quota".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "get".to_string());
            params.insert("user".to_string(), name.to_string());
            self.get("entry.cgi", params).await
        }

        /// Create a new user (requires POST)
        pub async fn user_create(&self, name: &str, password: &str, email: &str, description: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.User".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "create".to_string());
            params.insert("name".to_string(), name.to_string());
            params.insert("password".to_string(), password.to_string());
            if !email.is_empty() {
                params.insert("email".to_string(), email.to_string());
            }
            if !description.is_empty() {
                params.insert("description".to_string(), description.to_string());
            }
            self.post("entry.cgi", params).await
        }

        /// Edit/update an existing user
        pub async fn user_edit(&self, name: &str, email: Option<&str>, description: Option<&str>) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.User".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "set".to_string());
            params.insert("name".to_string(), name.to_string());
            if let Some(e) = email {
                params.insert("email".to_string(), e.to_string());
            }
            if let Some(d) = description {
                params.insert("description".to_string(), d.to_string());
            }
            self.post("entry.cgi", params).await
        }

        /// Delete a user (requires POST)
        pub async fn user_delete(&self, name: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.User".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "delete".to_string());
            params.insert("name".to_string(), name.to_string());
            self.post("entry.cgi", params).await
        }

        /// Enable or disable a user (requires POST)
        pub async fn user_set_enabled(&self, name: &str, enabled: bool) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.User".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "set".to_string());
            params.insert("name".to_string(), name.to_string());
            params.insert("expired".to_string(), if enabled { "false" } else { "true" }.to_string());
            self.post("entry.cgi", params).await
        }

        /// List all groups
        pub async fn group_list(&self) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.Group".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "list".to_string());
            params.insert("type".to_string(), "local".to_string());
            params.insert("offset".to_string(), "0".to_string());
            params.insert("limit".to_string(), "200".to_string());
            self.get("entry.cgi", params).await
        }

        /// Get group members — try multiple param names for compatibility
        pub async fn group_member_list(&self, group: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Core.Group.Member".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "list".to_string());
            params.insert("group".to_string(), group.to_string());
            params.insert("group_name".to_string(), group.to_string());
            params.insert("offset".to_string(), "0".to_string());
            params.insert("limit".to_string(), "200".to_string());
            self.get("entry.cgi", params).await
        }

        // ── File Station APIs ────────────────────────────────

        /// List shared folders (root level)
        pub async fn file_list_shares(&self) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.FileStation.List".to_string());
            params.insert("version".to_string(), "2".to_string());
            params.insert("method".to_string(), "list_share".to_string());
            params.insert("additional".to_string(), "[\"size\",\"time\",\"perm\",\"owner\"]".to_string());
            self.get("entry.cgi", params).await
        }

        /// List files/folders in a directory
        pub async fn file_list(&self, folder_path: &str, offset: u32, limit: u32, sort_by: &str, sort_direction: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.FileStation.List".to_string());
            params.insert("version".to_string(), "2".to_string());
            params.insert("method".to_string(), "list".to_string());
            params.insert("folder_path".to_string(), folder_path.to_string());
            params.insert("offset".to_string(), offset.to_string());
            params.insert("limit".to_string(), limit.to_string());
            params.insert("sort_by".to_string(), sort_by.to_string());
            params.insert("sort_direction".to_string(), sort_direction.to_string());
            params.insert("additional".to_string(), "[\"size\",\"time\",\"type\",\"perm\",\"owner\"]".to_string());
            self.get("entry.cgi", params).await
        }

        /// Create a new folder
        pub async fn file_create_folder(&self, folder_path: &str, name: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.FileStation.CreateFolder".to_string());
            params.insert("version".to_string(), "2".to_string());
            params.insert("method".to_string(), "create".to_string());
            params.insert("folder_path".to_string(), folder_path.to_string());
            params.insert("name".to_string(), name.to_string());
            self.get("entry.cgi", params).await
        }

        /// Rename a file or folder
        pub async fn file_rename(&self, path: &str, name: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.FileStation.Rename".to_string());
            params.insert("version".to_string(), "2".to_string());
            params.insert("method".to_string(), "rename".to_string());
            params.insert("path".to_string(), path.to_string());
            params.insert("name".to_string(), name.to_string());
            self.get("entry.cgi", params).await
        }

        /// Delete files/folders
        pub async fn file_delete(&self, paths: &[String]) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.FileStation.Delete".to_string());
            params.insert("version".to_string(), "2".to_string());
            params.insert("method".to_string(), "start".to_string());
            let paths_str = paths.iter().map(|p| format!("\"{}\"", p)).collect::<Vec<_>>().join(",");
            params.insert("path".to_string(), format!("[{}]", paths_str));
            self.get("entry.cgi", params).await
        }

        /// Get download URL for a file
        pub fn file_download_url(&self, path: &str) -> String {
            let scheme = if self.use_https { "https" } else { "http" };
            let sid = self.sid.as_deref().unwrap_or("");
            format!(
                "{}://{}:{}/webapi/entry.cgi?api=SYNO.FileStation.Download&version=2&method=download&path={}&_sid={}",
                scheme, self.host, self.port, path, sid
            )
        }

        /// Copy or Move files
        pub async fn file_copy_move(&self, paths: &[String], dest_folder: &str, overwrite: bool, remove_src: bool) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.FileStation.CopyMove".to_string());
            params.insert("version".to_string(), "3".to_string());
            params.insert("method".to_string(), "start".to_string());
            let paths_str = paths.iter().map(|p| format!("\"{}\"", p)).collect::<Vec<_>>().join(",");
            params.insert("path".to_string(), format!("[{}]", paths_str));
            params.insert("dest_folder_path".to_string(), dest_folder.to_string());
            params.insert("overwrite".to_string(), overwrite.to_string());
            params.insert("remove_src".to_string(), remove_src.to_string());
            self.get("entry.cgi", params).await
        }

        /// Create a file sharing link
        pub async fn file_create_sharing_link(&self, path: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.FileStation.Sharing".to_string());
            params.insert("version".to_string(), "3".to_string());
            params.insert("method".to_string(), "create".to_string());
            params.insert("path".to_string(), path.to_string());
            self.get("entry.cgi", params).await
        }

        /// Get file/folder info (properties)
        pub async fn file_get_info(&self, paths: &[String]) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.FileStation.List".to_string());
            params.insert("version".to_string(), "2".to_string());
            params.insert("method".to_string(), "getinfo".to_string());
            let paths_str = paths.iter().map(|p| format!("\"{}\"", p)).collect::<Vec<_>>().join(",");
            params.insert("path".to_string(), format!("[{}]", paths_str));
            params.insert("additional".to_string(), "[\"size\",\"time\",\"type\",\"perm\",\"owner\"]".to_string());
            self.get("entry.cgi", params).await
        }

        /// Compress files into archive
        pub async fn file_compress(&self, paths: &[String], dest_file_path: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.FileStation.Compress".to_string());
            params.insert("version".to_string(), "3".to_string());
            params.insert("method".to_string(), "start".to_string());
            let paths_str = paths.iter().map(|p| format!("\"{}\"", p)).collect::<Vec<_>>().join(",");
            params.insert("path".to_string(), format!("[{}]", paths_str));
            params.insert("dest_file_path".to_string(), dest_file_path.to_string());
            self.get("entry.cgi", params).await
        }

        // ── Media APIs ──────────────────────────────────────

        /// Get thumbnail URL for a file
        pub fn file_thumbnail_url(&self, path: &str, size: &str) -> String {
            let scheme = if self.use_https { "https" } else { "http" };
            let sid = self.sid.as_deref().unwrap_or("");
            format!(
                "{}://{}:{}/webapi/entry.cgi?api=SYNO.FileStation.Thumb&version=2&method=get&path={}&size={}&_sid={}",
                scheme, self.host, self.port, path, size, sid
            )
        }

        /// Get video stream URL (direct play)
        pub fn file_stream_url(&self, path: &str) -> String {
            let scheme = if self.use_https { "https" } else { "http" };
            let sid = self.sid.as_deref().unwrap_or("");
            format!(
                "{}://{}:{}/webapi/entry.cgi?api=SYNO.FileStation.Download&version=2&method=download&path={}&_sid={}",
                scheme, self.host, self.port, path, sid
            )
        }

        // ── Docker / Container Manager APIs ─────────────────

        /// List all Docker containers
        pub async fn docker_list(&self) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Docker.Container".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "list".to_string());
            params.insert("limit".to_string(), "-1".to_string());
            params.insert("offset".to_string(), "0".to_string());
            params.insert("type".to_string(), "all".to_string());
            self.get("entry.cgi", params).await
        }

        /// Get Docker container details
        pub async fn docker_get(&self, name: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Docker.Container".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "get".to_string());
            params.insert("name".to_string(), name.to_string());
            self.get("entry.cgi", params).await
        }

        /// Start a Docker container
        pub async fn docker_start(&self, name: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Docker.Container".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "start".to_string());
            params.insert("name".to_string(), name.to_string());
            self.get("entry.cgi", params).await
        }

        /// Stop a Docker container
        pub async fn docker_stop(&self, name: &str) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Docker.Container".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "stop".to_string());
            params.insert("name".to_string(), name.to_string());
            self.get("entry.cgi", params).await
        }

        /// Get Docker resource usage (CPU, RAM per container)
        pub async fn docker_get_resource(&self) -> Result<Value, String> {
            let mut params = HashMap::new();
            params.insert("api".to_string(), "SYNO.Docker.Container.Resource".to_string());
            params.insert("version".to_string(), "1".to_string());
            params.insert("method".to_string(), "get".to_string());
            self.get("entry.cgi", params).await
        }
    }
}

/// QuickConnect resolver — faithful port of Flutter QuickConnectResolver
/// Supports: regional redirect, SmartDNS, relay tunnel, concurrent probing
mod quickconnect {
    use reqwest::Client;
    use serde_json::{json, Value};
    use std::time::Duration;

    #[derive(Debug, Clone)]
    pub struct QuickConnectResult {
        pub host: String,
        pub port: u16,
        pub use_https: bool,
    }

    pub fn is_quickconnect(input: &str) -> bool {
        let cleaned = input.trim().to_lowercase();
        if cleaned.contains("quickconnect.to") {
            return true;
        }
        let re = regex_lite::Regex::new(r"^[a-zA-Z0-9][a-zA-Z0-9\-]{0,62}$").unwrap();
        re.is_match(&cleaned) && !cleaned.contains('.') && !cleaned.contains(':')
    }

    pub fn extract_id(input: &str) -> String {
        let mut raw = input.trim().to_string();
        if raw.starts_with("https://") {
            raw = raw[8..].to_string();
        }
        if raw.starts_with("http://") {
            raw = raw[7..].to_string();
        }
        if raw.starts_with("quickconnect.to/") {
            raw = raw[16..].to_string();
        }
        raw.trim_end_matches('/').to_string()
    }

    fn make_client(timeout_secs: u64) -> Client {
        Client::builder()
            .danger_accept_invalid_certs(true)
            .timeout(Duration::from_secs(timeout_secs))
            .build()
            .unwrap_or_default()
    }

    fn make_payload(qc_id: &str) -> Value {
        json!([
            {
                "version": 1,
                "command": "get_server_info",
                "stop_when_error": false,
                "stop_when_success": false,
                "id": "mainapp_https",
                "serverID": qc_id,
                "is_gofile": false,
                "path": ""
            },
            {
                "version": 1,
                "command": "get_server_info",
                "stop_when_error": false,
                "stop_when_success": false,
                "id": "mainapp_http",
                "serverID": qc_id,
                "is_gofile": false,
                "path": ""
            }
        ])
    }

    /// Main resolve function
    pub async fn resolve(qc_id: &str) -> Result<QuickConnectResult, String> {
        let server_info = get_server_info(qc_id, "global.quickconnect.to").await?;

        let service = &server_info["service"];
        let server = &server_info["server"];
        let smartdns = &server_info["smartdns"];

        let dsm_port = service["port"].as_u64().unwrap_or(5001) as u16;

        let mut candidates = Vec::new();

        // 1. LAN IPs
        if let Some(interfaces) = server["interface"].as_array() {
            for iface in interfaces {
                if let Some(ip) = iface["ip"].as_str() {
                    if !ip.is_empty() {
                        candidates.push(QuickConnectResult {
                            host: ip.to_string(), port: dsm_port, use_https: true,
                        });
                    }
                }
            }
        }

        // 2. WAN IP + ext_port
        if let Some(ext_ip) = server["external"]["ip"].as_str() {
            if !ext_ip.is_empty() {
                if let Some(ext_port) = service["ext_port"].as_u64() {
                    if ext_port > 0 {
                        candidates.push(QuickConnectResult {
                            host: ext_ip.to_string(), port: ext_port as u16, use_https: true,
                        });
                    }
                }
                candidates.push(QuickConnectResult {
                    host: ext_ip.to_string(), port: dsm_port, use_https: true,
                });
            }
        }

        // 3. SmartDNS external
        if let Some(smart_ext) = smartdns["external"].as_str() {
            if !smart_ext.is_empty() {
                candidates.push(QuickConnectResult {
                    host: smart_ext.to_string(), port: dsm_port, use_https: true,
                });
            }
        }

        // 4. SmartDNS host
        if let Some(smart_host) = smartdns["host"].as_str() {
            if !smart_host.is_empty() {
                candidates.push(QuickConnectResult {
                    host: smart_host.to_string(), port: dsm_port, use_https: true,
                });
            }
        }

        // 5. SmartDNS LAN hosts
        if let Some(smart_lan) = smartdns["lan"].as_array() {
            for h in smart_lan {
                if let Some(host) = h.as_str() {
                    if !host.is_empty() {
                        candidates.push(QuickConnectResult {
                            host: host.to_string(), port: dsm_port, use_https: true,
                        });
                    }
                }
            }
        }

        // 6. DDNS
        if let Some(ddns) = server["ddns"].as_str() {
            if !ddns.is_empty() && ddns != "NULL" {
                candidates.push(QuickConnectResult {
                    host: ddns.to_string(), port: dsm_port, use_https: true,
                });
            }
        }

        // 7. Relay IP + port (from initial response — may be empty)
        if let Some(relay_ip) = service["relay_ip"].as_str() {
            if let Some(relay_port) = service["relay_port"].as_u64() {
                if !relay_ip.is_empty() && relay_port > 0 {
                    candidates.push(QuickConnectResult {
                        host: relay_ip.to_string(), port: relay_port as u16, use_https: true,
                    });
                }
            }
        }

        // 8. Relay DN hostname
        if let Some(relay_dn) = service["relay_dn"].as_str() {
            if !relay_dn.is_empty() {
                candidates.push(QuickConnectResult {
                    host: relay_dn.to_string(), port: dsm_port, use_https: true,
                });
            }
        }

        // 9. If no relay_ip in response, request a tunnel from control_host
        let has_relay = service["relay_ip"].as_str().map(|s| !s.is_empty()).unwrap_or(false);
        if !has_relay {
            let control_host = server_info["env"]["control_host"]
                .as_str()
                .unwrap_or("usc.quickconnect.to");
            if let Ok(tunnel) = request_tunnel(qc_id, control_host).await {
                candidates.push(tunnel);
            }
        }

        // 10. https_ip + https_port (alternative relay endpoint)
        if let Some(https_ip) = service["https_ip"].as_str() {
            if let Some(https_port) = service["https_port"].as_u64() {
                if !https_ip.is_empty() && https_port > 0 {
                    candidates.push(QuickConnectResult {
                        host: https_ip.to_string(), port: https_port as u16, use_https: true,
                    });
                }
            }
        }

        // Probe all candidates concurrently
        probe_first(candidates).await
    }

    /// Get server info with regional redirect support
    async fn get_server_info(qc_id: &str, host: &str) -> Result<Value, String> {
        let client = make_client(10);
        let payload = make_payload(qc_id);
        let url = format!("https://{}/Serv.php", host);

        let resp = client
            .post(&url)
            .json(&payload)
            .send()
            .await
            .map_err(|e| format!("QuickConnect request failed: {}", e))?;

        let body: Value = resp
            .json()
            .await
            .map_err(|e| format!("QuickConnect parse error: {}", e))?;

        if let Some(arr) = body.as_array() {
            // Find first successful entry
            for item in arr {
                let errno = &item["errno"];
                if errno.is_null() || errno.as_i64() == Some(0) {
                    return Ok(item.clone());
                }
            }
            // Check for regional redirect
            for item in arr {
                if let Some(sites) = item["sites"].as_array() {
                    if !sites.is_empty() {
                        return get_server_info_from_region(qc_id, sites).await;
                    }
                }
            }
            let err = arr.first()
                .and_then(|v| v["errinfo"].as_str())
                .unwrap_or("unknown error");
            return Err(format!("QuickConnect error: {}", err));
        }

        // Single object
        let errno = &body["errno"];
        if !errno.is_null() && errno.as_i64() != Some(0) {
            if let Some(sites) = body["sites"].as_array() {
                if !sites.is_empty() {
                    return get_server_info_from_region(qc_id, sites).await;
                }
            }
            return Err(format!("QuickConnect error: {}", body["errinfo"].as_str().unwrap_or("unknown")));
        }
        Ok(body)
    }

    /// Retry with regional servers
    async fn get_server_info_from_region(qc_id: &str, sites: &[Value]) -> Result<Value, String> {
        for site in sites {
            let host = site.as_str()
                .map(String::from)
                .or_else(|| site["host"].as_str().map(String::from))
                .unwrap_or_default();
            if host.is_empty() { continue; }

            let client = make_client(10);
            let payload = make_payload(qc_id);
            let url = format!("https://{}/Serv.php", host);

            if let Ok(resp) = client.post(&url).json(&payload).send().await {
                if let Ok(body) = resp.json::<Value>().await {
                    if let Some(arr) = body.as_array() {
                        for item in arr {
                            let errno = &item["errno"];
                            if errno.is_null() || errno.as_i64() == Some(0) {
                                return Ok(item.clone());
                            }
                        }
                    } else {
                        let errno = &body["errno"];
                        if errno.is_null() || errno.as_i64() == Some(0) {
                            return Ok(body);
                        }
                    }
                }
            }
        }
        Err("QuickConnect: all regional servers failed".to_string())
    }

    /// Request a relay tunnel from Synology's control host.
    /// This is needed when the NAS is behind NAT and not directly reachable.
    async fn request_tunnel(qc_id: &str, control_host: &str) -> Result<QuickConnectResult, String> {
        let client = make_client(15);
        let payload = json!([{
            "version": 1,
            "command": "request_tunnel",
            "stop_when_error": false,
            "stop_when_success": true,
            "id": "mainapp_https",
            "serverID": qc_id,
            "is_gofile": false,
            "path": ""
        }]);

        let url = format!("https://{}/Serv.php", control_host);
        let resp = client
            .post(&url)
            .json(&payload)
            .send()
            .await
            .map_err(|e| format!("Tunnel request failed: {}", e))?;

        let body: Value = resp
            .json()
            .await
            .map_err(|e| format!("Tunnel parse error: {}", e))?;

        // Response may be array or single object
        let json = if let Some(arr) = body.as_array() {
            arr.first().cloned().unwrap_or(body.clone())
        } else {
            body
        };

        let service = &json["service"];

        // Prefer relay_ip + relay_port
        if let (Some(relay_ip), Some(relay_port)) = (
            service["relay_ip"].as_str(),
            service["relay_port"].as_u64(),
        ) {
            if !relay_ip.is_empty() && relay_port > 0 {
                return Ok(QuickConnectResult {
                    host: relay_ip.to_string(),
                    port: relay_port as u16,
                    use_https: true,
                });
            }
        }

        // Fallback to https_ip + https_port
        if let (Some(https_ip), Some(https_port)) = (
            service["https_ip"].as_str(),
            service["https_port"].as_u64(),
        ) {
            if !https_ip.is_empty() && https_port > 0 {
                return Ok(QuickConnectResult {
                    host: https_ip.to_string(),
                    port: https_port as u16,
                    use_https: true,
                });
            }
        }

        Err("No relay tunnel available".to_string())
    }

    /// Probe candidates concurrently — HTTPS + HTTP for each
    async fn probe_first(candidates: Vec<QuickConnectResult>) -> Result<QuickConnectResult, String> {
        if candidates.is_empty() {
            return Err("QuickConnect: no endpoints found".to_string());
        }

        // Deduplicate
        let mut seen = std::collections::HashSet::new();
        let unique: Vec<_> = candidates
            .into_iter()
            .filter(|c| seen.insert(format!("{}:{}:{}", c.host, c.port, c.use_https)))
            .collect();

        // Spawn probe tasks for all candidates
        let mut handles = Vec::new();
        for candidate in &unique {
            // HTTPS probe
            let c = candidate.clone();
            handles.push(tokio::spawn(async move {
                probe_single(&c).await.map(|_| c)
            }));
            // HTTP probe (skip for port 5001 which is HTTPS-only)
            if candidate.port != 5001 {
                let c_http = QuickConnectResult {
                    host: candidate.host.clone(),
                    port: candidate.port,
                    use_https: false,
                };
                handles.push(tokio::spawn(async move {
                    probe_single(&c_http).await.map(|_| c_http)
                }));
            }
        }

        // Wait for first success or all to complete
        let (tx, mut rx) = tokio::sync::mpsc::channel::<QuickConnectResult>(1);
        for handle in handles {
            let tx = tx.clone();
            tokio::spawn(async move {
                if let Ok(Ok(result)) = handle.await {
                    let _ = tx.send(result).await;
                }
            });
        }
        drop(tx);

        // Race with timeout
        match tokio::time::timeout(Duration::from_secs(8), rx.recv()).await {
            Ok(Some(result)) => Ok(result),
            _ => {
                // Fallback to hostname-based candidate (not raw IP)
                unique.iter()
                    .find(|c| !c.host.chars().next().map(|ch| ch.is_ascii_digit()).unwrap_or(false))
                    .cloned()
                    .ok_or_else(|| "QuickConnect: none of the resolved endpoints are reachable".to_string())
            }
        }
    }

    /// Probe a single endpoint
    async fn probe_single(candidate: &QuickConnectResult) -> Result<(), String> {
        let scheme = if candidate.use_https { "https" } else { "http" };
        let url = format!(
            "{}://{}:{}/webapi/entry.cgi?api=SYNO.API.Info&version=1&method=query&query=SYNO.API.Auth",
            scheme, candidate.host, candidate.port
        );
        let client = make_client(4);
        let resp = client.get(&url).send().await.map_err(|e| e.to_string())?;
        let text = resp.text().await.map_err(|e| e.to_string())?;
        if text.contains("\"success\"") && text.contains("SYNO.API.Auth") {
            Ok(())
        } else {
            Err("Not DSM".to_string())
        }
    }
}

// ── Tauri state ─────────────────────────────────────────────

use std::sync::Arc;

#[derive(Clone)]
struct AppState {
    api: Arc<Mutex<Option<synology::SynologyApi>>>,
    proxy_port: Arc<Mutex<u16>>,
    proxy_state: media_proxy::SharedProxyState,
}

// ── Tauri commands ──────────────────────────────────────────

#[derive(Serialize, Deserialize)]
struct LoginRequest {
    address: String,
    username: String,
    password: String,
    otp_code: Option<String>,
    device_id: Option<String>,
}

#[derive(Serialize)]
struct LoginResponse {
    success: bool,
    error: Option<String>,
    error_code: Option<i64>,
    host: Option<String>,
    port: Option<u16>,
    use_https: Option<bool>,
    model: Option<String>,
    dsm_version: Option<String>,
    serial: Option<String>,
    hostname: Option<String>,
    is_admin: Option<bool>,
    did: Option<String>,
}

/// Parse user input to extract host, port, protocol
fn parse_address(input: &str) -> (String, u16, bool) {
    let trimmed = input.trim();

    // Check for protocol
    let (scheme, rest) = if trimmed.starts_with("https://") {
        (true, &trimmed[8..])
    } else if trimmed.starts_with("http://") {
        (false, &trimmed[7..])
    } else {
        (true, trimmed) // default HTTPS
    };

    // Split host:port
    let parts: Vec<&str> = rest.split(':').collect();
    let host = parts[0].to_string();
    let port = if parts.len() > 1 {
        parts[1].parse::<u16>().unwrap_or(if scheme { 5001 } else { 5000 })
    } else {
        if scheme { 5001 } else { 5000 }
    };

    (host, port, scheme)
}

#[tauri::command]
async fn nas_login(
    state: State<'_, AppState>,
    request: LoginRequest,
) -> Result<LoginResponse, String> {
    let address = request.address.trim().to_string();

    // Check if QuickConnect
    let (host, port, use_https) = if quickconnect::is_quickconnect(&address) {
        let qc_id = quickconnect::extract_id(&address);
        match quickconnect::resolve(&qc_id).await {
            Ok(result) => (result.host, result.port, result.use_https),
            Err(e) => {
                return Ok(LoginResponse {
                    success: false,
                    error: Some(format!("QuickConnect resolution failed: {}", e)),
                    error_code: None,
                    host: None,
                    port: None,
                    use_https: None,
                    model: None,
                    dsm_version: None,
                    serial: None,
                    hostname: None,
                    is_admin: None,
                    did: None,
                });
            }
        }
    } else {
        parse_address(&address)
    };

    // Create API and login — try HTTPS first, fallback to HTTP
    // This handles cases where custom ports use HTTP instead of HTTPS
    let user_specified_protocol = address.starts_with("https://") || address.starts_with("http://");

    let mut api = synology::SynologyApi::new(&host, port, use_https);
    let mut login_result = api
        .login(
            &request.username,
            &request.password,
            request.otp_code.as_deref(),
            request.device_id.as_deref(),
        )
        .await;

    // If HTTPS failed with network error and user didn't specify protocol, retry with HTTP
    if login_result.is_err() && use_https && !user_specified_protocol {
        api = synology::SynologyApi::new(&host, port, false);
        login_result = api
            .login(
                &request.username,
                &request.password,
                request.otp_code.as_deref(),
                request.device_id.as_deref(),
            )
            .await;
    }

    match login_result {
        Ok(resp) => {
            if resp["success"].as_bool() == Some(true) {
                // Check admin
                let is_admin = api.check_admin().await;

                // Get DSM info
                let mut model = None;
                let mut dsm_version = None;
                let mut serial = None;
                let mut hostname = None;

                if let Ok(dsm) = api.get_dsm_info().await {
                    if dsm["success"].as_bool() == Some(true) {
                        let data = &dsm["data"];
                        model = data["model"].as_str().map(String::from);
                        dsm_version = data["version_string"]
                            .as_str()
                            .map(String::from)
                            .or_else(|| {
                                data["version"].as_str().map(|v| format!("DSM {}", v))
                            });
                        serial = data["serial"].as_str().map(String::from);
                        hostname = data["hostname"].as_str().map(String::from);
                    }
                }

                // Store API in state
                *state.api.lock().await = Some(api);

                // Update proxy server with NAS connection info
                update_proxy_state(&state).await;

                // Extract device ID from response (for 2FA trust)
                // Synology uses "did" in some versions, "device_id" in others
                let did = resp["data"]["did"].as_str()
                    .or_else(|| resp["data"]["device_id"].as_str())
                    .map(String::from);

                Ok(LoginResponse {
                    success: true,
                    error: None,
                    error_code: None,
                    host: Some(host),
                    port: Some(port),
                    use_https: Some(use_https),
                    model,
                    dsm_version,
                    serial,
                    hostname,
                    is_admin: Some(is_admin),
                    did,
                })
            } else {
                let code = resp["error"]["code"].as_i64();
                let error_msg = match code {
                    Some(400) => "No such account or incorrect password",
                    Some(401) => "Account is disabled",
                    Some(402) => "Permission denied",
                    Some(403) | Some(406) => "2FA_REQUIRED",
                    Some(404) => "2-step verification failed",
                    Some(407) => "Max login attempts reached — try later",
                    Some(408) => "IP blocked — too many failed attempts",
                    _ => "Login failed",
                };
                Ok(LoginResponse {
                    success: false,
                    error: Some(error_msg.to_string()),
                    error_code: code,
                    host: None,
                    port: None,
                    use_https: None,
                    model: None,
                    dsm_version: None,
                    serial: None,
                    hostname: None,
                    is_admin: None,
                    did: None,
                })
            }
        }
        Err(e) => Ok(LoginResponse {
            success: false,
            error: Some(e),
            error_code: None,
            host: None,
            port: None,
            use_https: None,
            model: None,
            dsm_version: None,
            serial: None,
            hostname: None,
            is_admin: None,
            did: None,
        }),
    }
}

#[tauri::command]
async fn nas_logout(state: State<'_, AppState>) -> Result<(), String> {
    let mut guard = state.api.lock().await;
    if let Some(ref mut api) = *guard {
        let _ = api.logout().await;
    }
    *guard = None;
    Ok(())
}

#[tauri::command]
async fn nas_get_system_info(state: State<'_, AppState>) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;

    // Fetch DSM info + utilization + storage + packages in sequence
    let dsm = api.get_dsm_info().await.unwrap_or_default();
    let util = api.get_system_utilization().await.unwrap_or_default();
    let storage = api.get_storage_info().await.unwrap_or_default();
    let packages = api.get_packages().await.unwrap_or_default();

    Ok(serde_json::json!({
        "dsm": dsm.get("data"),
        "utilization": util.get("data"),
        "storage": storage.get("data"),
        "packages": packages.get("data"),
    }))
}
// ── User & Group Management Commands ───────────────────────

#[tauri::command]
async fn user_list(state: State<'_, AppState>) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.user_list().await
}

#[tauri::command]
async fn user_get(state: State<'_, AppState>, name: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.user_get(&name).await
}

#[tauri::command]
async fn user_quota(state: State<'_, AppState>, name: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.user_quota(&name).await
}

#[tauri::command]
async fn user_create(state: State<'_, AppState>, name: String, password: String, email: String, description: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.user_create(&name, &password, &email, &description).await
}

#[tauri::command]
async fn user_edit(state: State<'_, AppState>, name: String, email: Option<String>, description: Option<String>) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.user_edit(&name, email.as_deref(), description.as_deref()).await
}

#[tauri::command]
async fn user_delete(state: State<'_, AppState>, name: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.user_delete(&name).await
}

#[tauri::command]
async fn user_set_enabled(state: State<'_, AppState>, name: String, enabled: bool) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.user_set_enabled(&name, enabled).await
}

#[tauri::command]
async fn group_list(state: State<'_, AppState>) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.group_list().await
}

#[tauri::command]
async fn group_member_list(state: State<'_, AppState>, group: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.group_member_list(&group).await
}

// ── Package Management Commands ────────────────────────────

/// List all available packages from Synology's package server
#[tauri::command]
async fn package_list_server(state: State<'_, AppState>) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.package_list_server().await
}

/// Install a package
#[tauri::command]
async fn package_install(state: State<'_, AppState>, id: String, volume: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.package_install(&id, &volume).await
}

/// Uninstall a package
#[tauri::command]
async fn package_uninstall(state: State<'_, AppState>, id: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.package_uninstall(&id).await
}

/// Start a package
#[tauri::command]
async fn package_start(state: State<'_, AppState>, id: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.package_start(&id).await
}

/// Stop a package
#[tauri::command]
async fn package_stop(state: State<'_, AppState>, id: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.package_stop(&id).await
}

// ── File Station Commands ───────────────────────────────────

#[tauri::command]
async fn file_list_shares(state: State<'_, AppState>) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    let resp = api.file_list_shares().await?;
    Ok(resp)
}

#[derive(Deserialize)]
struct FileListRequest {
    folder_path: String,
    offset: Option<u32>,
    limit: Option<u32>,
    sort_by: Option<String>,
    sort_direction: Option<String>,
}

#[tauri::command]
async fn file_list(state: State<'_, AppState>, request: FileListRequest) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    let resp = api.file_list(
        &request.folder_path,
        request.offset.unwrap_or(0),
        request.limit.unwrap_or(200),
        &request.sort_by.unwrap_or_else(|| "name".to_string()),
        &request.sort_direction.unwrap_or_else(|| "asc".to_string()),
    ).await?;
    Ok(resp)
}

#[derive(Deserialize)]
struct FileCreateFolderRequest {
    folder_path: String,
    name: String,
}

#[tauri::command]
async fn file_create_folder(state: State<'_, AppState>, request: FileCreateFolderRequest) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.file_create_folder(&request.folder_path, &request.name).await
}

#[derive(Deserialize)]
struct FileRenameRequest {
    path: String,
    name: String,
}

#[tauri::command]
async fn file_rename(state: State<'_, AppState>, request: FileRenameRequest) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.file_rename(&request.path, &request.name).await
}

#[derive(Deserialize)]
struct FileDeleteRequest {
    paths: Vec<String>,
}

#[tauri::command]
async fn file_delete(state: State<'_, AppState>, request: FileDeleteRequest) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.file_delete(&request.paths).await
}

#[tauri::command]
async fn file_download_url(state: State<'_, AppState>, path: String) -> Result<String, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    Ok(api.file_download_url(&path))
}

#[derive(Deserialize)]
struct FileCopyMoveRequest {
    paths: Vec<String>,
    dest_folder: String,
    overwrite: Option<bool>,
    remove_src: bool,
}

#[tauri::command]
async fn file_copy_move(state: State<'_, AppState>, request: FileCopyMoveRequest) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.file_copy_move(&request.paths, &request.dest_folder, request.overwrite.unwrap_or(false), request.remove_src).await
}

#[tauri::command]
async fn file_share_link(state: State<'_, AppState>, path: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.file_create_sharing_link(&path).await
}

#[tauri::command]
async fn file_get_info(state: State<'_, AppState>, paths: Vec<String>) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.file_get_info(&paths).await
}

#[derive(Deserialize)]
struct FileCompressRequest {
    paths: Vec<String>,
    dest_file_path: String,
}

#[tauri::command]
async fn file_compress(state: State<'_, AppState>, request: FileCompressRequest) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.file_compress(&request.paths, &request.dest_file_path).await
}

// ── Docker / Container Manager Commands ─────────────────────

/// List all Docker containers
#[tauri::command]
async fn docker_list(state: State<'_, AppState>) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.docker_list().await
}

/// Get Docker container details
#[tauri::command]
async fn docker_get_container(state: State<'_, AppState>, name: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.docker_get(&name).await
}

/// Start a Docker container
#[tauri::command]
async fn docker_start(state: State<'_, AppState>, name: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.docker_start(&name).await
}

/// Stop a Docker container
#[tauri::command]
async fn docker_stop(state: State<'_, AppState>, name: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.docker_stop(&name).await
}

/// Restart a Docker container (stop then start)
#[tauri::command]
async fn docker_restart(state: State<'_, AppState>, name: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    // Stop first
    let stop_result = api.docker_stop(&name).await?;
    if stop_result["success"].as_bool() != Some(true) {
        return Err(format!("Failed to stop container: {}", stop_result));
    }
    // Then start
    api.docker_start(&name).await
}

/// Get Docker container resource usage (CPU/Memory)
#[tauri::command]
async fn docker_get_resource(state: State<'_, AppState>) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    api.docker_get_resource().await
}

// ── Media Commands ──────────────────────────────────────────

const VIDEO_EXTENSIONS: &[&str] = &[
    "mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "m4v", "ts", "mpg", "mpeg", "3gp", "ogv",
];

/// Recursively scan a folder for video files
#[tauri::command]
async fn media_scan_folder(state: State<'_, AppState>, folder_path: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;

    let mut all_videos = Vec::new();
    let mut folders_to_scan = vec![folder_path];

    while let Some(current) = folders_to_scan.pop() {
        let resp = api.file_list(&current, 0, 2000, "name", "asc").await?;
        if resp["success"].as_bool() == Some(true) {
            if let Some(files) = resp["data"]["files"].as_array() {
                for file in files {
                    let is_dir = file["isdir"].as_bool().unwrap_or(false);
                    let path = file["path"].as_str().unwrap_or("").to_string();
                    let name = file["name"].as_str().unwrap_or("").to_string();

                    if is_dir {
                        folders_to_scan.push(path);
                    } else {
                        // Check if video extension
                        let ext = name.rsplit('.').next().unwrap_or("").to_lowercase();
                        if VIDEO_EXTENSIONS.contains(&ext.as_str()) {
                            all_videos.push(serde_json::json!({
                                "path": file["path"],
                                "name": file["name"],
                                "size": file["additional"]["size"],
                                "mtime": file["additional"]["time"]["mtime"],
                                "folder": current,
                            }));
                        }
                    }
                }
            }
        }
    }

    Ok(serde_json::json!({
        "success": true,
        "total": all_videos.len(),
        "videos": all_videos,
    }))
}

const AUDIO_EXTENSIONS: &[&str] = &[
    "mp3", "flac", "aac", "ogg", "m4a", "wav", "wma", "opus", "alac", "aiff", "ape", "dsf",
];

/// Recursively scan a folder for audio files
#[tauri::command]
async fn audio_scan_folder(state: State<'_, AppState>, folder_path: String) -> Result<serde_json::Value, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;

    let mut all_audio = Vec::new();
    let mut folders_to_scan = vec![folder_path];

    while let Some(current) = folders_to_scan.pop() {
        let resp = api.file_list(&current, 0, 2000, "name", "asc").await?;
        if resp["success"].as_bool() == Some(true) {
            if let Some(files) = resp["data"]["files"].as_array() {
                for file in files {
                    let is_dir = file["isdir"].as_bool().unwrap_or(false);
                    let path = file["path"].as_str().unwrap_or("").to_string();
                    let name = file["name"].as_str().unwrap_or("").to_string();

                    if is_dir {
                        folders_to_scan.push(path);
                    } else {
                        let ext = name.rsplit('.').next().unwrap_or("").to_lowercase();
                        if AUDIO_EXTENSIONS.contains(&ext.as_str()) {
                            all_audio.push(serde_json::json!({
                                "path": file["path"],
                                "name": file["name"],
                                "size": file["additional"]["size"],
                                "mtime": file["additional"]["time"]["mtime"],
                                "folder": current,
                                "ext": ext,
                            }));
                        }
                    }
                }
            }
        }
    }

    Ok(serde_json::json!({
        "success": true,
        "total": all_audio.len(),
        "files": all_audio,
    }))
}

/// Get thumbnail as base64 data URI (proxied through Rust to handle self-signed SSL)
#[tauri::command]
async fn media_get_thumbnail_url(state: State<'_, AppState>, path: String) -> Result<String, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    let url = api.file_thumbnail_url(&path, "medium");

    // Download the thumbnail binary through our SSL-tolerant client
    let client = reqwest::Client::builder()
        .danger_accept_invalid_certs(true)
        .timeout(std::time::Duration::from_secs(5))
        .build()
        .map_err(|e| e.to_string())?;

    match client.get(&url).send().await {
        Ok(resp) => {
            if resp.status().is_success() {
                let content_type = resp.headers()
                    .get("content-type")
                    .and_then(|v| v.to_str().ok())
                    .unwrap_or("image/jpeg")
                    .to_string();
                let bytes = resp.bytes().await.map_err(|e| e.to_string())?;
                let b64 = base64::Engine::encode(&base64::engine::general_purpose::STANDARD, &bytes);
                Ok(format!("data:{};base64,{}", content_type, b64))
            } else {
                Err(format!("Thumbnail fetch failed: {}", resp.status()))
            }
        }
        Err(e) => Err(e.to_string()),
    }
}

/// Get stream URL for a video file
/// Returns the direct URL — video playback uses external player for non-MP4 formats
#[tauri::command]
async fn media_get_stream_url(state: State<'_, AppState>, path: String) -> Result<String, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    Ok(api.file_stream_url(&path))
}

/// Proxy-download a video file chunk for in-app playback (handles self-signed SSL)
/// Returns base64 encoded data — only use for small files or when needed
#[tauri::command]
async fn media_proxy_stream(state: State<'_, AppState>, path: String) -> Result<String, String> {
    let guard = state.api.lock().await;
    let api = guard.as_ref().ok_or("Not connected")?;
    let url = api.file_stream_url(&path);
    drop(guard); // Release lock before download

    let client = reqwest::Client::builder()
        .danger_accept_invalid_certs(true)
        .timeout(std::time::Duration::from_secs(120))
        .build()
        .map_err(|e| e.to_string())?;

    let resp = client.get(&url).send().await.map_err(|e| e.to_string())?;
    if !resp.status().is_success() {
        return Err(format!("Download failed: {}", resp.status()));
    }

    let content_type = resp.headers()
        .get("content-type")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("video/mp4")
        .to_string();
    let bytes = resp.bytes().await.map_err(|e| e.to_string())?;
    let b64 = base64::Engine::encode(&base64::engine::general_purpose::STANDARD, &bytes);
    Ok(format!("data:{};base64,{}", content_type, b64))
}

/// Search TMDB for movie/TV metadata (poster, backdrop, overview)
/// Tries movie search first, falls back to TV search for series
#[tauri::command]
async fn tmdb_search(query: String, year: Option<String>) -> Result<serde_json::Value, String> {
    const TMDB_KEY: &str = "b31e1adb42056a9dc0b3d42239af559b";

    let client = reqwest::Client::builder()
        .danger_accept_invalid_certs(true)
        .timeout(std::time::Duration::from_secs(8))
        .build()
        .map_err(|e| e.to_string())?;

    // 1. Try multi-search first (searches movies, TV, people)
    let multi_url = format!(
        "https://api.themoviedb.org/3/search/multi?api_key={}&query={}&language=en-US&page=1",
        TMDB_KEY,
        urlencoding::encode(&query)
    );

    let resp = client.get(&multi_url).send().await.map_err(|e| e.to_string())?;
    let json: serde_json::Value = resp.json().await.map_err(|e| e.to_string())?;

    // Filter to only movie + tv results with a poster
    if let Some(results) = json["results"].as_array() {
        let filtered: Vec<&serde_json::Value> = results.iter()
            .filter(|r| {
                let mt = r["media_type"].as_str().unwrap_or("");
                (mt == "movie" || mt == "tv") && r["poster_path"].as_str().is_some()
            })
            .collect();

        if !filtered.is_empty() {
            let best = filtered[0];
            let media_type = best["media_type"].as_str().unwrap_or("movie");
            
            // Normalize TV results to match movie schema for frontend
            if media_type == "tv" {
                return Ok(serde_json::json!({
                    "results": [{
                        "title": best["name"],
                        "poster_path": best["poster_path"],
                        "backdrop_path": best["backdrop_path"],
                        "overview": best["overview"],
                        "vote_average": best["vote_average"],
                        "release_date": best["first_air_date"],
                        "media_type": "tv",
                    }]
                }));
            }
            
            return Ok(serde_json::json!({ "results": [best] }));
        }
    }

    // 2. Fallback: try movie-only search with year
    let mut movie_url = format!(
        "https://api.themoviedb.org/3/search/movie?api_key={}&query={}&language=en-US&page=1",
        TMDB_KEY,
        urlencoding::encode(&query)
    );
    if let Some(y) = &year {
        movie_url.push_str(&format!("&year={}", y));
    }

    let resp2 = client.get(&movie_url).send().await.map_err(|e| e.to_string())?;
    let json2: serde_json::Value = resp2.json().await.map_err(|e| e.to_string())?;
    Ok(json2)
}

// ── Google OAuth via Tauri child window ─────────────────────

/// Start Google OAuth by creating a new Tauri WebView window.
/// Uses on_navigation hook on the builder to intercept the redirect.
#[tauri::command]
async fn google_auth_start(app: tauri::AppHandle) -> Result<String, String> {
    use tauri::{WebviewWindowBuilder, WebviewUrl, Emitter, Listener};
    use std::sync::Arc;
    use tokio::sync::oneshot;

    let client_id = "650864805831-g40f6so2oo1eriv35t5isv0huqfk3uoo.apps.googleusercontent.com";
    let redirect_uri = "https://synohubs.firebaseapp.com/__/auth/handler";

    let nonce = {
        use std::time::{SystemTime, UNIX_EPOCH};
        let ts = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis();
        format!("synohubs_{}", ts)
    };

    let auth_url = format!(
        "https://accounts.google.com/o/oauth2/v2/auth?\
        client_id={}&\
        redirect_uri={}&\
        response_type=id_token+token&\
        scope=email%20profile%20openid&\
        nonce={}&\
        prompt=select_account",
        client_id, redirect_uri, nonce,
    );

    // Channel to receive the token from the navigation hook
    let (tx, rx) = oneshot::channel::<String>();
    let tx = Arc::new(std::sync::Mutex::new(Some(tx)));

    let tx_nav = tx.clone();
    let app_handle = app.clone();

    // Build the window with on_navigation hook to intercept the redirect
    let auth_window = WebviewWindowBuilder::new(
        &app,
        "google-auth",
        WebviewUrl::External(auth_url.parse().map_err(|e| format!("URL parse error: {:?}", e))?),
    )
    .title("SynoHubs — Sign in with Google")
    .inner_size(500.0, 700.0)
    .center()
    .resizable(true)
    .on_navigation(move |url| {
        let url_str = url.to_string();

        // Check if Firebase auth handler is being called with token
        if url_str.contains("synohubs.firebaseapp.com/__/auth/handler") {
            // The token comes in the URL fragment (#id_token=xxx)
            // Fragments are not sent to server but ARE visible in the URL
            if let Some(token) = extract_token_from_url(&url_str) {
                if let Ok(mut guard) = tx_nav.lock() {
                    if let Some(sender) = guard.take() {
                        let _ = sender.send(token);
                    }
                }
                // Emit event to close window from main thread
                let _ = app_handle.emit("google-auth-done", ());
            }
        }

        // Allow navigation
        true
    })
    .build()
    .map_err(|e| format!("Failed to create auth window: {}", e))?;

    // Handle window close (user cancelled)
    let tx_cancel = tx.clone();
    auth_window.on_window_event(move |event| {
        if let tauri::WindowEvent::Destroyed = event {
            if let Ok(mut guard) = tx_cancel.lock() {
                if let Some(sender) = guard.take() {
                    let _ = sender.send(String::new());
                }
            }
        }
    });

    // Listen for auth-done event to close window
    let auth_window_clone = auth_window.clone();
    app.listen("google-auth-done", move |_| {
        let _ = auth_window_clone.close();
    });

    // Wait for token (with timeout)
    match tokio::time::timeout(std::time::Duration::from_secs(120), rx).await {
        Ok(Ok(token)) if !token.is_empty() => Ok(token),
        Ok(Ok(_)) => Err("Sign-in cancelled".to_string()),
        Ok(Err(_)) => Err("Auth channel closed".to_string()),
        Err(_) => {
            let _ = auth_window.close();
            Err("Sign-in timed out".to_string())
        }
    }
}

/// Extract id_token from a URL (from fragment # or query ?)
fn extract_token_from_url(url: &str) -> Option<String> {
    // Check fragment first (#id_token=xxx)
    if let Some(fragment) = url.split('#').nth(1) {
        for param in fragment.split('&') {
            if let Some(token) = param.strip_prefix("id_token=") {
                return Some(token.to_string());
            }
        }
    }
    // Check query (?id_token=xxx)
    if let Some(query) = url.split('?').nth(1) {
        for param in query.split('&') {
            if let Some(token) = param.strip_prefix("id_token=") {
                // Remove any fragment part
                let token = token.split('#').next().unwrap_or(token);
                return Some(token.to_string());
            }
        }
    }
    None
}

// ── Encrypted Store ─────────────────────────────────────────
/// AES-256-GCM encrypted key-value store.
/// Master key is auto-generated on first use and stored in app data dir.
/// Each value is encrypted with a random nonce.
mod encrypted_store {
    use aes_gcm::{
        aead::{Aead, KeyInit},
        Aes256Gcm, Nonce,
    };
    use base64::{engine::general_purpose::STANDARD as B64, Engine};
    use rand::RngCore;
    use sha2::{Digest, Sha256};
    use std::collections::HashMap;
    use std::fs;
    use std::path::PathBuf;

    /// Get app data directory
    fn data_dir() -> PathBuf {
        let dir = dirs::data_local_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("com.synohubs.app");
        fs::create_dir_all(&dir).ok();
        dir
    }

    /// Get or create master key (32 bytes)
    fn master_key() -> [u8; 32] {
        let key_path = data_dir().join(".master.key");
        if let Ok(bytes) = fs::read(&key_path) {
            if bytes.len() == 32 {
                let mut key = [0u8; 32];
                key.copy_from_slice(&bytes);
                return key;
            }
        }
        // Generate new random key
        let mut key = [0u8; 32];
        rand::thread_rng().fill_bytes(&mut key);
        fs::write(&key_path, &key).ok();
        key
    }

    /// Derive a per-user encryption key from master key + user UID
    fn derive_key(user_uid: &str) -> [u8; 32] {
        let mk = master_key();
        let mut hasher = Sha256::new();
        hasher.update(&mk);
        hasher.update(user_uid.as_bytes());
        hasher.update(b"synohubs_v1");
        let result = hasher.finalize();
        let mut key = [0u8; 32];
        key.copy_from_slice(&result);
        key
    }

    /// Encrypt data → base64(nonce[12] + ciphertext)
    fn encrypt(data: &str, key: &[u8; 32]) -> Result<String, String> {
        let cipher = Aes256Gcm::new_from_slice(key)
            .map_err(|e| format!("Cipher init error: {}", e))?;
        
        let mut nonce_bytes = [0u8; 12];
        rand::thread_rng().fill_bytes(&mut nonce_bytes);
        let nonce = Nonce::from_slice(&nonce_bytes);

        let ciphertext = cipher
            .encrypt(nonce, data.as_bytes())
            .map_err(|e| format!("Encryption error: {}", e))?;

        // Combine: nonce (12) + ciphertext
        let mut combined = Vec::with_capacity(12 + ciphertext.len());
        combined.extend_from_slice(&nonce_bytes);
        combined.extend_from_slice(&ciphertext);
        
        Ok(B64.encode(&combined))
    }

    /// Decrypt base64(nonce[12] + ciphertext) → plaintext
    fn decrypt(encoded: &str, key: &[u8; 32]) -> Result<String, String> {
        let combined = B64
            .decode(encoded)
            .map_err(|e| format!("Base64 decode error: {}", e))?;
        
        if combined.len() < 13 {
            return Err("Data too short".to_string());
        }

        let (nonce_bytes, ciphertext) = combined.split_at(12);
        let nonce = Nonce::from_slice(nonce_bytes);

        let cipher = Aes256Gcm::new_from_slice(key)
            .map_err(|e| format!("Cipher init error: {}", e))?;

        let plaintext = cipher
            .decrypt(nonce, ciphertext)
            .map_err(|_| "Decryption failed (wrong key or corrupted data)".to_string())?;

        String::from_utf8(plaintext)
            .map_err(|e| format!("UTF-8 error: {}", e))
    }

    /// Store file path for a user
    fn store_path(user_uid: &str) -> PathBuf {
        let safe_uid: String = user_uid.chars().filter(|c| c.is_alphanumeric()).collect();
        data_dir().join(format!("{}.enc", safe_uid))
    }

    /// Load the encrypted store HashMap for a user
    fn load_store(user_uid: &str) -> HashMap<String, String> {
        let path = store_path(user_uid);
        if let Ok(content) = fs::read_to_string(&path) {
            if let Ok(map) = serde_json::from_str(&content) {
                return map;
            }
        }
        HashMap::new()
    }

    /// Save the encrypted store HashMap for a user
    fn save_store(user_uid: &str, store: &HashMap<String, String>) {
        let path = store_path(user_uid);
        if let Ok(json) = serde_json::to_string(store) {
            fs::write(&path, json).ok();
        }
    }

    /// Public: save a key-value pair (encrypted)
    pub fn save(user_uid: &str, key: &str, data: &str) -> Result<(), String> {
        let enc_key = derive_key(user_uid);
        let encrypted = encrypt(data, &enc_key)?;
        let mut store = load_store(user_uid);
        store.insert(key.to_string(), encrypted);
        save_store(user_uid, &store);
        Ok(())
    }

    /// Public: load a value (decrypted)
    pub fn load(user_uid: &str, key: &str) -> Result<Option<String>, String> {
        let enc_key = derive_key(user_uid);
        let store = load_store(user_uid);
        match store.get(key) {
            Some(encrypted) => {
                let decrypted = decrypt(encrypted, &enc_key)?;
                Ok(Some(decrypted))
            }
            None => Ok(None),
        }
    }

    /// Public: delete a key
    pub fn delete(user_uid: &str, key: &str) -> Result<(), String> {
        let mut store = load_store(user_uid);
        store.remove(key);
        save_store(user_uid, &store);
        Ok(())
    }
}

// ── Tauri Commands: Encrypted Store ─────────────────────────

#[tauri::command]
fn secure_save(user_uid: String, key: String, data: String) -> Result<(), String> {
    encrypted_store::save(&user_uid, &key, &data)
}

#[tauri::command]
fn secure_load(user_uid: String, key: String) -> Result<Option<String>, String> {
    encrypted_store::load(&user_uid, &key)
}

#[tauri::command]
fn secure_delete(user_uid: String, key: String) -> Result<(), String> {
    encrypted_store::delete(&user_uid, &key)
}

// ── App entry ───────────────────────────────────────────────

#[cfg_attr(mobile, tauri::mobile_entry_point)]
// ── Local Media Proxy Server ────────────────────────────────
// Streams NAS media through localhost to bypass WebView SSL restrictions.
// WebView2 = Chromium = same codec support as Chrome.
// Only blocker was self-signed SSL certs → solved by this proxy.

mod media_proxy {
    use axum::{
        Router,
        routing::get,
        extract::{Query, State},
        response::IntoResponse,
    };
    use std::collections::HashMap;
    use std::sync::Arc;
    use tokio::sync::Mutex;
    /// Shared proxy state that gets updated when NAS connects
    pub type SharedProxyState = Arc<Mutex<Option<(String, u16, bool, String)>>>;

    pub fn create_shared_state() -> SharedProxyState {
        Arc::new(Mutex::new(None))
    }

    async fn stream_handler(
        Query(params): Query<HashMap<String, String>>,
        State(state): State<SharedProxyState>,
    ) -> impl IntoResponse {
        let path = params.get("path").cloned().unwrap_or_default();

        let guard = state.lock().await;
        let conn = match guard.as_ref() {
            Some(c) => c.clone(),
            None => return axum::http::Response::builder()
                .status(503)
                .body(axum::body::Body::from("Not connected"))
                .unwrap(),
        };
        drop(guard);

        let (host, port, use_https, sid) = conn;
        let scheme = if use_https { "https" } else { "http" };
        let url = format!(
            "{}://{}:{}/webapi/entry.cgi?api=SYNO.FileStation.Download&version=2&method=download&path={}&_sid={}",
            scheme, host, port, urlencoding::encode(&path), sid
        );

        let client = reqwest::Client::builder()
            .danger_accept_invalid_certs(true)
            .build()
            .unwrap();

        match client.get(&url).send().await {
            Ok(resp) => {
                let content_type = resp.headers()
                    .get("content-type")
                    .and_then(|v| v.to_str().ok())
                    .unwrap_or("application/octet-stream")
                    .to_string();

                let content_length = resp.content_length();
                let stream = resp.bytes_stream();
                let body = axum::body::Body::from_stream(stream);

                let mut builder = axum::http::Response::builder()
                    .header("Content-Type", &content_type)
                    .header("Access-Control-Allow-Origin", "*")
                    .header("Accept-Ranges", "none");

                if let Some(len) = content_length {
                    builder = builder.header("Content-Length", len.to_string());
                }

                builder.body(body).unwrap()
            }
            Err(e) => {
                axum::http::Response::builder()
                    .status(502)
                    .body(axum::body::Body::from(format!("Proxy error: {}", e)))
                    .unwrap()
            }
        }
    }

    async fn thumb_handler(
        Query(params): Query<HashMap<String, String>>,
        State(state): State<SharedProxyState>,
    ) -> impl IntoResponse {
        let path = params.get("path").cloned().unwrap_or_default();
        let size = params.get("size").cloned().unwrap_or("medium".to_string());

        let guard = state.lock().await;
        let conn = match guard.as_ref() {
            Some(c) => c.clone(),
            None => return axum::http::Response::builder()
                .status(503)
                .body(axum::body::Body::from("Not connected"))
                .unwrap(),
        };
        drop(guard);

        let (host, port, use_https, sid) = conn;
        let scheme = if use_https { "https" } else { "http" };
        let url = format!(
            "{}://{}:{}/webapi/entry.cgi?api=SYNO.FileStation.Thumb&version=2&method=get&path={}&size={}&_sid={}",
            scheme, host, port, urlencoding::encode(&path), size, sid
        );

        let client = reqwest::Client::builder()
            .danger_accept_invalid_certs(true)
            .timeout(std::time::Duration::from_secs(5))
            .build()
            .unwrap();

        match client.get(&url).send().await {
            Ok(resp) if resp.status().is_success() => {
                let content_type = resp.headers()
                    .get("content-type")
                    .and_then(|v| v.to_str().ok())
                    .unwrap_or("image/jpeg")
                    .to_string();

                let bytes = resp.bytes().await.unwrap_or_default();
                axum::http::Response::builder()
                    .header("Content-Type", content_type)
                    .header("Access-Control-Allow-Origin", "*")
                    .header("Cache-Control", "max-age=3600")
                    .body(axum::body::Body::from(bytes))
                    .unwrap()
            }
            _ => {
                axum::http::Response::builder()
                    .status(404)
                    .body(axum::body::Body::from("No thumbnail"))
                    .unwrap()
            }
        }
    }

    /// Start the local proxy server, returns the port
    pub async fn start(state: SharedProxyState) -> u16 {
        let app = Router::new()
            .route("/stream", get(stream_handler))
            .route("/thumb", get(thumb_handler))
            .with_state(state);

        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let port = listener.local_addr().unwrap().port();
        println!("[SynoHubs] Media proxy started on http://localhost:{}", port);

        tokio::spawn(async move {
            axum::serve(listener, app).await.unwrap();
        });

        port
    }
}

/// Get the local proxy server port
#[tauri::command]
async fn get_proxy_port(state: State<'_, AppState>) -> Result<u16, String> {
    let port = state.proxy_port.lock().await;
    Ok(*port)
}

/// Update proxy state when NAS connects (called internally after login)
async fn update_proxy_state(state: &AppState) {
    let guard = state.api.lock().await;
    if let Some(api) = guard.as_ref() {
        let conn = (
            api.host.clone(),
            api.port,
            api.use_https,
            api.sid.clone().unwrap_or_default(),
        );
        let mut proxy = state.proxy_state.lock().await;
        *proxy = Some(conn);
    }
}

pub fn run() {
    // Create shared proxy state
    let proxy_state = media_proxy::create_shared_state();
    let proxy_state_for_server = proxy_state.clone();

    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .manage(AppState {
            api: Arc::new(Mutex::new(None)),
            proxy_port: Arc::new(Mutex::new(0)),
            proxy_state: proxy_state.clone(),
        })
        .setup(move |app| {
            // Start local media proxy server
            let state = app.state::<AppState>().inner().clone();
            let proxy_state = proxy_state_for_server.clone();
            tauri::async_runtime::spawn(async move {
                let port = media_proxy::start(proxy_state).await;
                let mut p = state.proxy_port.lock().await;
                *p = port;
            });
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            nas_login,
            nas_logout,
            nas_get_system_info,
            google_auth_start,
            file_list_shares,
            file_list,
            file_create_folder,
            file_rename,
            file_delete,
            file_download_url,
            file_copy_move,
            file_share_link,
            file_get_info,
            file_compress,
            docker_list,
            docker_get_container,
            docker_start,
            docker_stop,
            docker_restart,
            docker_get_resource,
            package_list_server,
            package_install,
            package_uninstall,
            package_start,
            package_stop,
            user_list,
            user_get,
            user_quota,
            user_create,
            user_edit,
            user_delete,
            user_set_enabled,
            group_list,
            group_member_list,
            media_scan_folder,
            audio_scan_folder,
            media_get_thumbnail_url,
            media_get_stream_url,
            media_proxy_stream,
            tmdb_search,
            get_proxy_port,
            secure_save,
            secure_load,
            secure_delete,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
