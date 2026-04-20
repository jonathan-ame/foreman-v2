import { LegalLayout } from "../../components/LegalLayout";

export function Cookies() {
  return (
    <LegalLayout title="Cookie Policy" lastUpdated="April 20, 2026">
      <h2>1. What are cookies?</h2>
      <p>
        Cookies are small text files stored on your device when you visit a website. We use cookies
        and similar technologies (local storage, session storage) to operate the Service and
        understand how it is used.
      </p>

      <h2>2. Cookies we use</h2>

      <h3>Essential cookies</h3>
      <p>
        These are necessary to provide the Service. They include session authentication tokens and
        security cookies. You cannot opt out of essential cookies without also opting out of the
        Service.
      </p>
      <table className="legal-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Purpose</th>
            <th>Duration</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>foreman_session</td>
            <td>Authenticates your session</td>
            <td>Session</td>
          </tr>
          <tr>
            <td>foreman_csrf</td>
            <td>CSRF protection</td>
            <td>Session</td>
          </tr>
        </tbody>
      </table>

      <h3>Analytics cookies</h3>
      <p>
        We may use analytics cookies to understand usage patterns and improve the Service. These
        cookies collect aggregate, anonymized data. You may opt out via your browser settings or our
        consent manager.
      </p>

      <h2>3. Managing cookies</h2>
      <p>
        Most browsers allow you to refuse or delete cookies through settings. Note that disabling
        essential cookies will prevent you from using the Service. Refer to your browser's help
        documentation for instructions.
      </p>

      <h2>4. Updates</h2>
      <p>
        We may update this Cookie Policy as we add or change features. Check back periodically for
        updates.
      </p>
    </LegalLayout>
  );
}
