import { Routes, Route, Navigate } from 'react-router-dom';
import { useEffect } from 'react';
import { useAuthStore, useNasStore, useUserPrefsStore } from './stores';
import AppLayout from './layouts/AppLayout';
import AppLogin from './screens/AppLogin/AppLogin';
import Dashboard from './screens/Dashboard/Dashboard';
import FileStation from './screens/FileStation/FileStation';
import Media from './screens/Media/Media';
import Packages from './screens/Packages/Packages';
import Docker from './screens/Docker/Docker';
import ResourceMonitor from './screens/ResourceMonitor/ResourceMonitor';
import UsersGroups from './screens/UsersGroups/UsersGroups';
import PlaceholderScreen from './screens/PlaceholderScreen';

/**
 * App Router — Two-layer auth flow:
 * 1. Google Sign-in (Firebase) → tier check
 * 2. Main App (NAS Sidebar + Nav + Content)
 * 
 * NAS management is now integrated into the main layout's left sidebar.
 * No separate /nas route needed.
 */

/* Guard: Requires Google authentication + loads persisted data */
const RequireAuth = ({ children }: { children: React.ReactElement }) => {
  const { isAuthenticated, user } = useAuthStore();
  const { loadConnections } = useNasStore();
  const { loadPrefs } = useUserPrefsStore();

  useEffect(() => {
    if (user?.uid) {
      loadConnections(user.uid);
      loadPrefs(user.uid);
    }
  }, [user?.uid]);

  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return children;
};

/* Auto-redirect from login if already authenticated */
const LoginRedirect = () => {
  const { isAuthenticated } = useAuthStore();
  if (isAuthenticated) return <Navigate to="/app" replace />;
  return <AppLogin />;
};

function App() {
  return (
    <Routes>
      {/* 1. Google Auth */}
      <Route path="/login" element={<LoginRedirect />} />

      {/* 2. Main App — 3-column layout */}
      <Route
        path="/app"
        element={
          <RequireAuth>
            <AppLayout />
          </RequireAuth>
        }
      >
        <Route index element={<Dashboard />} />
        <Route path="dashboard" element={<Dashboard />} />
        <Route path="files" element={<FileStation />} />
        <Route path="photos" element={<PlaceholderScreen title="Photos" icon="Image" description="Browse and manage your Synology Photos" />} />
        <Route path="media" element={<Media />} />
        <Route path="monitor" element={<ResourceMonitor />} />
        <Route path="users" element={<UsersGroups />} />
        <Route path="packages" element={<Packages />} />
        <Route path="docker" element={<Docker />} />
        <Route path="settings" element={<PlaceholderScreen title="Settings" icon="Settings" />} />
      </Route>

      {/* Catch-all */}
      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}

export default App;
