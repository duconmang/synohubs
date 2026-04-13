import React, { useState } from 'react';
import { getCurrentWindow } from '@tauri-apps/api/window';
import { ArrowUp, ArrowDown, Bell, Settings } from 'lucide-react';
import { useNasStore } from '../stores';

/**
 * Titlebar — Custom macOS-style traffic light buttons
 * Replaces native Windows title bar with premium circular buttons
 */
const Titlebar: React.FC = () => {
  const { activeNas } = useNasStore();
  const [isMaximized, setIsMaximized] = useState(false);
  const [hovering, setHovering] = useState(false);

  const appWindow = getCurrentWindow();

  const handleMinimize = () => appWindow.minimize();
  const handleMaximize = async () => {
    const maximized = await appWindow.isMaximized();
    if (maximized) {
      await appWindow.unmaximize();
      setIsMaximized(false);
    } else {
      await appWindow.maximize();
      setIsMaximized(true);
    }
  };
  const handleClose = () => appWindow.close();

  return (
    <div className="titlebar" data-tauri-drag-region>
      {/* macOS-style Traffic Light Buttons */}
      <div
        className="titlebar__traffic-lights"
        onMouseEnter={() => setHovering(true)}
        onMouseLeave={() => setHovering(false)}
      >
        <button
          className="titlebar__light titlebar__light--close"
          onClick={handleClose}
          title="Close"
        >
          {hovering && (
            <svg width="8" height="8" viewBox="0 0 8 8">
              <path d="M1 1L7 7M7 1L1 7" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" />
            </svg>
          )}
        </button>
        <button
          className="titlebar__light titlebar__light--minimize"
          onClick={handleMinimize}
          title="Minimize"
        >
          {hovering && (
            <svg width="8" height="8" viewBox="0 0 8 8">
              <path d="M1 4H7" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" />
            </svg>
          )}
        </button>
        <button
          className="titlebar__light titlebar__light--maximize"
          onClick={handleMaximize}
          title={isMaximized ? 'Restore' : 'Maximize'}
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

      <div className="titlebar__spacer" />

      {/* Network stats */}
      {activeNas && (
        <div className="titlebar__stats">
          <div className="titlebar__stat">
            <ArrowUp size={10} className="up" />
            <span>52 B/s</span>
          </div>
          <div className="titlebar__stat">
            <ArrowDown size={10} className="down" />
            <span>36 B/s</span>
          </div>
        </div>
      )}

      {/* Action buttons */}
      <div className="titlebar__actions">
        <button className="titlebar__action" title="Notifications">
          <Bell size={14} />
        </button>
        <button className="titlebar__action" title="Settings">
          <Settings size={14} />
        </button>
      </div>
    </div>
  );
};

export default Titlebar;
