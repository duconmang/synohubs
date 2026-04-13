import React, { useEffect, useState } from 'react';
import { getCurrentWindow } from '@tauri-apps/api/window';
import { openUrl } from '@tauri-apps/plugin-opener';
import { SynoHubsLogo, GoogleLogo } from '../../components/Logo';
import { useAuthStore } from '../../stores';
import './AppLogin.css';

/** Floating macOS-style traffic lights for login screen */
const LoginTrafficLights: React.FC = () => {
  const [hovering, setHovering] = useState(false);
  const [isMaximized, setIsMaximized] = useState(false);
  const appWindow = getCurrentWindow();

  return (
    <div
      className="login-traffic-lights"
      onMouseEnter={() => setHovering(true)}
      onMouseLeave={() => setHovering(false)}
    >
      <button
        className="titlebar__light titlebar__light--close"
        onClick={() => appWindow.close()}
      >
        {hovering && (
          <svg width="8" height="8" viewBox="0 0 8 8">
            <path d="M1 1L7 7M7 1L1 7" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" />
          </svg>
        )}
      </button>
      <button
        className="titlebar__light titlebar__light--minimize"
        onClick={() => appWindow.minimize()}
      >
        {hovering && (
          <svg width="8" height="8" viewBox="0 0 8 8">
            <path d="M1 4H7" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" />
          </svg>
        )}
      </button>
      <button
        className="titlebar__light titlebar__light--maximize"
        onClick={async () => {
          const max = await appWindow.isMaximized();
          if (max) { await appWindow.unmaximize(); setIsMaximized(false); }
          else { await appWindow.maximize(); setIsMaximized(true); }
        }}
      >
        {hovering && (
          isMaximized ? (
            <svg width="8" height="8" viewBox="0 0 8 8">
              <path d="M1 2.5L4 0.5L7 2.5M1 5.5L4 7.5L7 5.5" stroke="currentColor" strokeWidth="1.0" strokeLinecap="round" strokeLinejoin="round" fill="none" />
            </svg>
          ) : (
            <svg width="8" height="8" viewBox="0 0 8 8">
              <path d="M1 5.5L4 0.5L7 5.5" stroke="currentColor" strokeWidth="1.0" strokeLinecap="round" strokeLinejoin="round" fill="none" />
            </svg>
          )
        )}
      </button>
    </div>
  );
};

/**
 * App Login Screen — Tauri Desktop Google Auth
 * 
 * 1. On mount → checkAuth() (check Firebase persisted session)
 * 2. If no session → show "Sign in with Google" button
 * 3. Click → signIn() → Rust opens system browser → OAuth → Firebase credential
 * 4. On success → redirect to NAS management
 */
const AppLogin: React.FC = () => {
  const { signIn, checkAuth, isLoading, error } = useAuthStore();

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  const handleGoogleSignIn = async () => {
    await signIn();
  };

  return (
    <div className="app-login" data-tauri-drag-region>
      {/* Traffic lights on login screen */}
      <LoginTrafficLights />
      <div className="app-login__card">
        <div className="app-login__logo">
          <SynoHubsLogo size={56} />
          <h1 className="app-login__title">SynoHubs</h1>
        </div>

        <p className="app-login__subtitle">
          The all-in-one NAS manager<br />for modern engineers
        </p>

        <button
          className={`app-login__google-btn ${isLoading ? 'loading' : ''}`}
          onClick={handleGoogleSignIn}
          disabled={isLoading}
          id="btn-google-signin"
        >
          {isLoading ? <div className="spinner" /> : <GoogleLogo size={18} />}
          {isLoading ? 'Signing in...' : 'Sign in with Google'}
        </button>

        {error && (
          <div className="app-login__error">
            {error}
          </div>
        )}

        <div className="app-login__tier-info">
          <div className="app-login__tier-badge">
            <span>Free</span>
            <span>1 NAS</span>
          </div>
          <div className="app-login__tier-divider" />
          <div className="app-login__tier-badge">
            <span>Pro</span>
            <span>Unlimited</span>
          </div>
        </div>

        <p className="app-login__terms">
          By signing in, you agree to our{' '}
          <a href="#" onClick={(e) => { e.preventDefault(); openUrl('https://synohubs.com/terms'); }}>Terms of Service</a> and{' '}
          <a href="#" onClick={(e) => { e.preventDefault(); openUrl('https://synohubs.com/privacy'); }}>Privacy Policy</a>
        </p>
      </div>

      <span className="app-login__version">v0.1.0</span>
    </div>
  );
};

export default AppLogin;
