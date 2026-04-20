export function Contact() {
  return (
    <>
      <section className="page-hero">
        <div className="content-inner text-center">
          <h1>Contact us</h1>
          <p>We'd love to hear from you.</p>
        </div>
      </section>

      <section className="prose-section">
        <div className="content-inner content-narrow">
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
        </div>
      </section>
    </>
  );
}
