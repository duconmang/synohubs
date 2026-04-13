import React from 'react';

interface SynoHubsLogoProps {
  size?: number;
  className?: string;
}

/**
 * SynoHubs Logo — Hexagonal hub with connection nodes
 */
export const SynoHubsLogo: React.FC<SynoHubsLogoProps> = ({ size = 48, className = '' }) => {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 64 64"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      aria-label="SynoHubs Logo"
    >
      {/* Glow filter */}
      <defs>
        <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur stdDeviation="2" result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
        <linearGradient id="hexGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#22C55E" />
          <stop offset="100%" stopColor="#16A34A" />
        </linearGradient>
      </defs>

      {/* Outer hexagon */}
      <path
        d="M32 4L56 18V46L32 60L8 46V18L32 4Z"
        stroke="url(#hexGrad)"
        strokeWidth="2"
        fill="none"
        opacity="0.3"
        filter="url(#glow)"
      />

      {/* Inner hexagon */}
      <path
        d="M32 12L48 22V42L32 52L16 42V22L32 12Z"
        stroke="url(#hexGrad)"
        strokeWidth="2"
        fill="rgba(34, 197, 94, 0.08)"
      />

      {/* Center hub circle */}
      <circle cx="32" cy="32" r="6" fill="url(#hexGrad)" filter="url(#glow)" />

      {/* Connection lines to nodes */}
      <line x1="32" y1="26" x2="32" y2="14" stroke="#22C55E" strokeWidth="1.5" opacity="0.6" />
      <line x1="37" y1="29" x2="46" y2="22" stroke="#22C55E" strokeWidth="1.5" opacity="0.6" />
      <line x1="37" y1="35" x2="46" y2="42" stroke="#22C55E" strokeWidth="1.5" opacity="0.6" />
      <line x1="32" y1="38" x2="32" y2="50" stroke="#22C55E" strokeWidth="1.5" opacity="0.6" />
      <line x1="27" y1="35" x2="18" y2="42" stroke="#22C55E" strokeWidth="1.5" opacity="0.6" />
      <line x1="27" y1="29" x2="18" y2="22" stroke="#22C55E" strokeWidth="1.5" opacity="0.6" />

      {/* Node dots */}
      <circle cx="32" cy="14" r="3" fill="#22C55E" opacity="0.8" />
      <circle cx="46" cy="22" r="3" fill="#22C55E" opacity="0.8" />
      <circle cx="46" cy="42" r="3" fill="#22C55E" opacity="0.8" />
      <circle cx="32" cy="50" r="3" fill="#22C55E" opacity="0.8" />
      <circle cx="18" cy="42" r="3" fill="#22C55E" opacity="0.8" />
      <circle cx="18" cy="22" r="3" fill="#22C55E" opacity="0.8" />
    </svg>
  );
};

/**
 * Google "G" Logo for Sign-in button
 */
export const GoogleLogo: React.FC<{ size?: number }> = ({ size = 20 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
    <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4" />
    <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
    <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05" />
    <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" />
  </svg>
);
