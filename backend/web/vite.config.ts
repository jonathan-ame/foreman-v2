import { defineConfig, transformWithEsbuild } from "vite";
import react from "@vitejs/plugin-react";

function ga4InjectPlugin() {
  return {
    name: "ga4-inject",
    transformIndexHtml(html: string) {
      const ga4Id = process.env.GA4_MEASUREMENT_ID;
      if (!ga4Id) {
        return html.replace("%GA4_SCRIPT%", "");
      }
      const script = `
    <script async src="https://www.googletagmanager.com/gtag/js?id=${ga4Id}"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', '${ga4Id}', { send_page_view: false });
      window.GA4_MEASUREMENT_ID = '${ga4Id}';
    </script>`;
      return html.replace("%GA4_SCRIPT%", script);
    },
  };
}

export default defineConfig({
  plugins: [react(), ga4InjectPlugin()],
  build: {
    outDir: "../dist-web",
    emptyOutDir: true
  },
  server: {
    proxy: {
      "/api": "http://localhost:8080"
    }
  }
});
