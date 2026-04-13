import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard, FolderOpen, Image, Film, Users, Package,
  Settings, Activity, Lock, Container
} from 'lucide-react';
import { useAuthStore, useNasStore } from '../../stores';
import './Sidebar.css';

interface NavItem {
  icon: React.ElementType;
  label: string;
  path: string;
  premiumOnly?: boolean;  // Requires VIP Google account
  adminOnly?: boolean;    // Requires NAS admin
  colorClass?: string;    // Icon color class
}

const mainNav: NavItem[] = [
  { icon: LayoutDashboard, label: 'Dashboard', path: '/app/dashboard', colorClass: 'icon--dashboard' },
  { icon: FolderOpen, label: 'File Station', path: '/app/files', colorClass: 'icon--files' },
  { icon: Film, label: 'Media', path: '/app/media', premiumOnly: true, colorClass: 'icon--media' },
  { icon: Image, label: 'Photos', path: '/app/photos', premiumOnly: true, colorClass: 'icon--photos' },
];

const adminNav: NavItem[] = [
  { icon: Activity, label: 'Resource Monitor', path: '/app/monitor', colorClass: 'icon--monitor' },
  { icon: Users, label: 'Users & Groups', path: '/app/users', colorClass: 'icon--users' },
  { icon: Package, label: 'Packages', path: '/app/packages', colorClass: 'icon--packages' },
  { icon: Container, label: 'Docker', path: '/app/docker', colorClass: 'icon--docker' },
];

const bottomNav: NavItem[] = [
  { icon: Settings, label: 'Settings', path: '/app/settings', colorClass: 'icon--settings' },
];

/**
 * NavSidebar — Feature navigation for the currently selected NAS.
 * 
 * Permission model:
 * - Photos & Media: VIP Google account required (free = locked)
 * - Resource Monitor, Users, Packages, Docker: NAS admin required
 * - Everything else: available to all
 */
const NavSidebar: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { activeNas } = useNasStore();
  const { user } = useAuthStore();

  if (!activeNas) return null;

  const isVip = user?.tier === 'vip';

  const handleNavClick = (item: NavItem) => {
    if (item.premiumOnly && !isVip) {
      // Show upgrade prompt for free users
      return;
    }
    navigate(item.path);
  };

  const renderNavItem = (item: NavItem) => {
    const Icon = item.icon;
    const isActive = location.pathname === item.path;
    const isLocked = item.premiumOnly && !isVip;

    return (
      <button
        key={item.path}
        className={`sidebar__item ${isActive ? 'active' : ''} ${isLocked ? 'sidebar__item--locked' : ''}`}
        onClick={() => handleNavClick(item)}
        title={isLocked ? `${item.label} — Upgrade to Premium` : item.label}
      >
        <Icon size={15} className={`sidebar__item-icon ${item.colorClass || ''}`} />
        <span className="sidebar__item-label">{item.label}</span>
        {isLocked && (
          <div className="sidebar__item-lock">
            <Lock size={10} />
          </div>
        )}
      </button>
    );
  };

  return (
    <nav className="nav-sidebar">
      {/* Active NAS label */}
      <div className="nav-sidebar__nas-label">
        <span className="nav-sidebar__nas-name">{activeNas.name}</span>
        <span className="nav-sidebar__nas-model">{activeNas.model}</span>
      </div>

      <div className="nav-sidebar__nav">
        {mainNav.map(renderNavItem)}

        {activeNas.is_admin && (
          <>
            <div className="sidebar__section-label">Admin</div>
            {adminNav.map(renderNavItem)}
          </>
        )}
      </div>

      <div className="nav-sidebar__bottom">
        {bottomNav.map(renderNavItem)}

        <div className="nav-sidebar__version">v0.1.0</div>
      </div>
    </nav>
  );
};

export default NavSidebar;
