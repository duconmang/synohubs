import React from 'react';
import './NasLoadingScreen.css';

interface Props {
  nasName?: string;
}

const NasLoadingScreen: React.FC<Props> = ({ nasName }) => {
  return (
    <div className="nas-loading">
      <div className="nas-loading__card">
        {/* Spinner ring */}
        <div className="nas-loading__spinner">
          <div className="nas-loading__ring" />
          <div className="nas-loading__ring nas-loading__ring--inner" />
          <div className="nas-loading__pulse" />
        </div>

        {/* NAS name */}
        {nasName && (
          <div className="nas-loading__name">{nasName}</div>
        )}

        {/* Connecting text */}
        <div className="nas-loading__text">
          Connecting<span className="nas-loading__dots" />
        </div>
      </div>

      {/* Background particles */}
      <div className="nas-loading__particles">
        {Array.from({ length: 20 }).map((_, i) => (
          <div
            key={i}
            className="nas-loading__particle"
            style={{
              left: `${Math.random() * 100}%`,
              top: `${Math.random() * 100}%`,
              animationDelay: `${Math.random() * 5}s`,
              animationDuration: `${3 + Math.random() * 4}s`,
            }}
          />
        ))}
      </div>
    </div>
  );
};

export default NasLoadingScreen;
