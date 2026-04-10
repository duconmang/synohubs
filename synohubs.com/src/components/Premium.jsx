import { Check, Crown, Sparkles, Mail } from 'lucide-react';
import { useI18n } from '../i18n/I18nProvider';

export default function Premium() {
  const { t } = useI18n();
  const { free, vip } = t.premium;
  const donate = t.premium.donate || {};

  return (
    <section id="premium" className="section">
      <div className="container">
        <div className="text-center">
          <span className="section-badge gold">{t.premium.badge}</span>
          <h2 className="section-title">{t.premium.title}</h2>
          <p className="section-subtitle">{t.premium.subtitle}</p>
        </div>

        <div className="pricing-grid">
          {/* Free Plan */}
          <div className="pricing-card">
            <div className="plan-name">{free.title}</div>
            <div className="plan-price">{free.price}</div>
            <div className="plan-period">{free.period}</div>
            <ul className="pricing-features">
              {free.features.map((f, i) => (
                <li key={i}>
                  <Check size={16} className="check-icon" />
                  {f}
                </li>
              ))}
            </ul>
            <a href="#download" className="btn btn-outline">{free.cta}</a>
          </div>

          {/* VIP Plan */}
          <div className="pricing-card featured">
            <span className="pricing-popular">
              <Crown size={12} /> {vip.popular}
            </span>
            <div className="plan-name" style={{ color: '#fbbf24' }}>
              <Sparkles size={16} style={{ display: 'inline', verticalAlign: 'middle' }} /> {vip.title}
            </div>
            <div className="plan-price" style={{ color: '#fbbf24' }}>{vip.price}</div>
            <div className="plan-period">{vip.period}</div>
            <ul className="pricing-features">
              {vip.features.map((f, i) => (
                <li key={i}>
                  <Check size={16} className="check-icon gold" />
                  {f}
                </li>
              ))}
            </ul>
            <a href="#download" className="btn btn-gold">{vip.cta}</a>
          </div>
        </div>

        {/* PayPal Donate / Upgrade Section */}
        <div className="donate-section">
          <div className="donate-qr-box">
            <img src="/assets/paypal-qr.jpg" alt="PayPal QR" className="donate-qr-img" />
            <p className="donate-qr-label">{donate.scanLabel || 'Scan to pay via PayPal'}</p>
          </div>
          <div className="donate-info">
            <h3 className="donate-title">{donate.title || 'How to Upgrade to VIP'}</h3>
            <div className="donate-steps">
              <div className="donate-step">
                <span className="donate-step-num">1</span>
                <p>{donate.step1 || 'Scan the QR code or send $4.99 via PayPal.'}</p>
              </div>
              <div className="donate-step">
                <span className="donate-step-num">2</span>
                <p>{donate.step2 || 'Send an email to confirm your payment.'}</p>
              </div>
              <div className="donate-step">
                <span className="donate-step-num">3</span>
                <p>{donate.step3 || 'We will activate your VIP within 24 hours.'}</p>
              </div>
            </div>
            <a
              href="mailto:duconmang43@gmail.com?subject=SynoHub VIP Activation&body=PayPal username: @"
              className="btn btn-gold donate-email-btn"
            >
              <Mail size={16} /> {donate.emailBtn || 'Send Confirmation Email'}
            </a>
            <p className="donate-email-hint">
              {donate.emailHint || 'Include your PayPal @username so we can verify your payment.'}
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
