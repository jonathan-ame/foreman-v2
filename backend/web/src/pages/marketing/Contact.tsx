import { useState } from "react";

export function Contact() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    company: '',
    useCase: '',
    message: ''
  });
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setErrorMsg('');

    const useCaseMap: Record<string, string> = {
      'solopreneur': 'solopreneur',
      'small-team': 'small_team',
      'enterprise': 'enterprise',
      'technical': 'technical',
      'other': 'other',
    };

    try {
      const params = new URLSearchParams(window.location.search);
      const response = await fetch('/api/marketing/subscribe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: formData.email,
          name: formData.name || undefined,
          company: formData.company || undefined,
          useCase: useCaseMap[formData.useCase] || undefined,
          message: formData.message || undefined,
          source: 'contact',
          utmSource: params.get('utm_source') || undefined,
          utmMedium: params.get('utm_medium') || undefined,
          utmCampaign: params.get('utm_campaign') || undefined,
        }),
      });

      if (response.ok) {
        setSubmitted(true);
        setFormData({ name: '', email: '', company: '', useCase: '', message: '' });
      } else {
        const data = await response.json().catch(() => ({}));
        setErrorMsg(data.error ?? 'Something went wrong. Please try again.');
      }
    } catch {
      setErrorMsg('Network error. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <section className="page-hero">
        <div className="content-inner text-center">
          <h1>Contact us</h1>
          <p>We'd love to hear from you.</p>
        </div>
      </section>

      <section className="prose-section">
        <div className="content-inner">
          <div className="two-column-layout">
            <div className="column">
              <h2>Join our waitlist</h2>
              <p className="subtitle">Be among the first to experience Foreman's AI workforce platform.</p>
              
              {submitted ? (
                <div className="success-message">
                  <h3>Thank you for your interest!</h3>
                  <p>We'll be in touch soon with more information about Foreman.</p>
                  <p>In the meantime, check out our <a href="/">homepage</a> for more details.</p>
                  <button 
                    className="btn btn-secondary" 
                    onClick={() => setSubmitted(false)}
                  >
                    Submit another response
                  </button>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="contact-form">
                  <div className="form-group">
                    <label htmlFor="name">Full Name *</label>
                    <input
                      type="text"
                      id="name"
                      name="name"
                      value={formData.name}
                      onChange={handleChange}
                      required
                      placeholder="Your name"
                    />
                  </div>
                  
                  <div className="form-group">
                    <label htmlFor="email">Email Address *</label>
                    <input
                      type="email"
                      id="email"
                      name="email"
                      value={formData.email}
                      onChange={handleChange}
                      required
                      placeholder="you@company.com"
                    />
                  </div>
                  
                  <div className="form-group">
                    <label htmlFor="company">Company / Organization</label>
                    <input
                      type="text"
                      id="company"
                      name="company"
                      value={formData.company}
                      onChange={handleChange}
                      placeholder="Where you work"
                    />
                  </div>
                  
                  <div className="form-group">
                    <label htmlFor="useCase">Primary Use Case *</label>
                    <select
                      id="useCase"
                      name="useCase"
                      value={formData.useCase}
                      onChange={handleChange}
                      required
                    >
                      <option value="">Select an option</option>
                      <option value="solopreneur">Solopreneur needing AI assistant</option>
                      <option value="small-team">Small team expanding capacity</option>
                      <option value="enterprise">Enterprise evaluating AI orchestration</option>
                      <option value="technical">Technical integration partner</option>
                      <option value="other">Other</option>
                    </select>
                  </div>
                  
                  <div className="form-group">
                    <label htmlFor="message">Message / Questions</label>
                    <textarea
                      id="message"
                      name="message"
                      value={formData.message}
                      onChange={handleChange}
                      rows={4}
                      placeholder="Tell us what you're hoping to achieve with Foreman..."
                    />
                  </div>
                  
                  <div className="form-footer">
                    <p className="form-note">
                      By submitting, you agree to receive emails about Foreman. Unsubscribe anytime.
                    </p>
                    <button 
                      type="submit" 
                      className="button-primary"
                      disabled={loading}
                    >
                      {loading ? 'Submitting...' : 'Join Waitlist'}
                    </button>
                  </div>
                  {errorMsg && <p className="contact-form-error">{errorMsg}</p>}
                </form>
              )}
              
              <div className="form-instructions">
                <h4>Next Steps:</h4>
                <ul>
                  <li>You'll receive a confirmation email with our "Getting Started with AI Agents" guide</li>
                  <li>Our team will review your use case and follow up within 48 hours</li>
                  <li>Early access invitations will be sent on a rolling basis</li>
                </ul>
              </div>
            </div>
            
            <div className="column">
              <h2>Direct contacts</h2>
              <p className="subtitle">Prefer to email us directly?</p>
              
              <div className="contact-options">
                <div className="contact-option">
                  <h3>General inquiries</h3>
                  <p>
                    <a href="mailto:hello@foreman.company">hello@foreman.company</a>
                  </p>
                </div>
                <div className="contact-option">
                  <h3>Support</h3>
                  <p>
                    <a href="mailto:support@foreman.company">support@foreman.company</a>
                  </p>
                </div>
                <div className="contact-option">
                  <h3>Legal &amp; privacy</h3>
                  <p>
                    <a href="mailto:legal@foreman.company">legal@foreman.company</a>
                  </p>
                </div>
                <div className="contact-option">
                  <h3>Press</h3>
                  <p>
                    <a href="mailto:press@foreman.company">press@foreman.company</a>
                  </p>
                </div>
              </div>
              
              <div className="contact-note">
                <h4>Response Time:</h4>
                <p>We aim to respond to all inquiries within 24-48 hours during business days.</p>
              </div>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
