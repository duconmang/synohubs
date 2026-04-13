import React from 'react';
import { Outlet } from 'react-router-dom';
import NasSidebar from '../components/NasSidebar/NasSidebar';
import NavSidebar from '../components/Sidebar/Sidebar';
import NasLoadingScreen from '../components/NasLoadingScreen/NasLoadingScreen';
import Titlebar from '../components/Titlebar';
import MiniPlayer from '../components/MiniPlayer/MiniPlayer';
import { useNasStore } from '../stores';
import { useAudioStore } from '../stores/audioStore';
import './AppLayout.css';

/**
 * AppLayout — 3-column layout:
 * [NAS Sidebar] | [Nav Menu] | [Content Area]
 * 
 * - NAS Sidebar: always visible, collapsible, shows NAS device cards
 * - Nav Menu: feature navigation, only visible when NAS is selected
 * - Content Area: displays the active feature screen
 */
const AppLayout: React.FC = () => {
  const { activeNas, isConnecting } = useNasStore();

  // Determine which NAS name to show on loading
  const connectingNas = useNasStore(s =>
    s.connections.find(c => c.status === 'connecting')
  );

  const { currentTrack } = useAudioStore();
  const hasPlayer = !!currentTrack;

  return (
    <div className={`app-layout ${hasPlayer ? 'app-layout--has-player' : ''}`}>
      <Titlebar />
      <div className="app-layout__body">
        <NasSidebar />
        <NavSidebar />
        <div className="app-layout__content">
          {isConnecting ? (
            <NasLoadingScreen nasName={connectingNas?.name || connectingNas?.model} />
          ) : activeNas ? (
            <Outlet />
          ) : (
            <div className="app-layout__empty">
              <div className="app-layout__empty-icon">📡</div>
              <h2>Select a NAS Device</h2>
              <p>Choose a NAS from the sidebar or add a new one to get started.</p>
            </div>
          )}
        </div>
      </div>
      <MiniPlayer />
    </div>
  );
};

export default AppLayout;
