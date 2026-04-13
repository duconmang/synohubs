import React from 'react';
import { Activity } from 'lucide-react';

/** Placeholder screen for features not yet implemented */
const PlaceholderScreen: React.FC<{ title: string; icon?: string; description?: string }> = ({
  title,
  description,
}) => {
  return (
    <div
      style={{
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '16px',
        color: 'var(--color-text-dim)',
        padding: '48px',
      }}
    >
      <Activity size={48} strokeWidth={1} />
      <h2
        style={{
          fontFamily: 'var(--font-heading)',
          fontSize: '24px',
          color: 'var(--color-text)',
        }}
      >
        {title}
      </h2>
      <p
        style={{
          fontSize: '14px',
          textAlign: 'center',
          maxWidth: '400px',
          lineHeight: '1.6',
        }}
      >
        {description || `${title} feature is under development.`}
      </p>
      <span className="badge badge-info">Coming Soon</span>
    </div>
  );
};

export default PlaceholderScreen;
