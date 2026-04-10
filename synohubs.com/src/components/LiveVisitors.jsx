import { useState, useEffect } from 'react';
import { useI18n } from '../i18n/I18nProvider';

export default function LiveVisitors() {
  const { t } = useI18n();
  // Random initial viewers between 5 and 20
  const [activeVisitors, setActiveVisitors] = useState(() => Math.floor(Math.random() * 15) + 5);
  // Total visitors starting at a realistic static number and increasing
  const [totalVisitors, setTotalVisitors] = useState(() => 14258 + Math.floor(Math.random() * 100));

  useEffect(() => {
    // Randomly change the count every 4 seconds
    const interval = setInterval(() => {
      setActiveVisitors(prev => {
        const change = Math.floor(Math.random() * 5) - 2; // -2, -1, 0, 1, 2
        let next = prev + change;
        if (next < 2) next = 2; // Keep at least 2 people
        if (next > 45) next = 45; // Cap at 45 so it looks realistic
        return next;
      });
      
      // Occasionally increment total visitors
      if (Math.random() > 0.4) {
        setTotalVisitors(prev => prev + Math.floor(Math.random() * 3) + 1);
      }
    }, 4000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="live-stats-floating fade-in-up">
      <div className="stat-item">
        <span className="pulse-dot"></span>
        <span className="stat-text">
          <strong>{activeVisitors}</strong> {t.liveVisitors?.active || 'online'}
        </span>
      </div>
      <div className="stat-divider"></div>
      <div className="stat-item">
        <span className="static-dot"></span>
        <span className="stat-text">
          <strong>{totalVisitors.toLocaleString()}</strong> {t.liveVisitors?.total || 'total visits'}
        </span>
      </div>
    </div>
  );
}