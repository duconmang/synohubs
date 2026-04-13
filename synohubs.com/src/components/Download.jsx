import { Download as DownloadIcon, Smartphone } from 'lucide-react';
import { useI18n } from '../i18n/I18nProvider';
import { useState, useEffect } from 'react';

const VERSION_JSON_URL = '/releases/version.json';

export default function Download() {
  const { t } = useI18n();
  const dl = t.download;
  const [apkUrl, setApkUrl] = useState('#');
  const [version, setVersion] = useState('');

  useEffect(() => {
    fetch(VERSION_JSON_URL)
      .then(r => r.json())
      .then(data => {
        setApkUrl(data.apkUrl || '#');
        setVersion(data.version || '');
      })
      .catch(() => {});
  }, []);

  return (
    <section id="download" className="section download-section">
      <div className="container">
        <div className="text-center">
          <span className="section-badge">{dl.badge}</span>
          <h2 className="section-title">{dl.title}</h2>
          <p className="section-subtitle">{dl.subtitle}</p>
        </div>

        <div className="download-box">
          <Smartphone size={48} style={{ color: '#22d3ee', marginBottom: 24 }} />

          {/* Primary download */}
          <a href={apkUrl} className="btn btn-primary" style={{ marginBottom: 12 }} rel="noopener noreferrer">
            <DownloadIcon size={18} /> {dl.androidBtn}
          </a>

          {/* Windows downloads */}
          <div className="download-box">
            <a href="/downloads/SynoHubs_0.1.0_x64-setup.exe" className="btn btn-secondary" rel="noopener noreferrer">
              <DownloadIcon size={18} /> {dl.windowsExeBtn}
            </a>
            <a href="/downloads/SynoHubs_0.1.0_x64_en-US.msi" className="btn btn-secondary" rel="noopener noreferrer">
              <DownloadIcon size={18} /> {dl.windowsMsiBtn}
            </a>
          </div>

          <div className="version-info">
            <span>{dl.requirement}</span>
            <span>•</span>
            <span>{version ? `v${version}` : dl.version}</span>
          </div>

          {/* QR Code */}
          <div className="download-qr-section">
            <p className="qr-label">{dl.qrLabel}</p>
            <div className="qr-code-box">
              <img
                src={'https://api.qrserver.com/v1/create-qr-code/?size=140x140&data=https%3A%2F%2Fsynohubs.com%2F%23download&bgcolor=ffffff&color=0a0e1a&format=svg'}
                alt="QR Code - synohubs.com"
                width="140"
                height="140"
                style={{ borderRadius: 8 }}
              />
            </div>
            <p style={{ fontSize: '.8rem', color: 'var(--text-dim)', marginTop: 8 }}>synohubs.com</p>
          </div>
        </div>
      </div>
    </section>
  );
}
