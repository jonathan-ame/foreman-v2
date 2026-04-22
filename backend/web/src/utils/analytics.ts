type EventName =
  | "page_view"
  | "signup_started"
  | "pricing_viewed"
  | "how_it_works_viewed"
  | "blog_viewed"
  | "blog_post_viewed"
  | "contact_clicked"
  | "email_subscribed"
  | "feedback_submitted";

interface EventParams {
  [key: string]: string | number | boolean | undefined;
}

function getGA4Id(): string | undefined {
  return window.GA4_MEASUREMENT_ID;
}

function isGA4Available(): boolean {
  return typeof window.gtag === "function";
}

export function trackEvent(eventName: EventName, params?: EventParams) {
  const ga4Id = getGA4Id();

  if (isGA4Available() && ga4Id) {
    window.gtag("event", eventName, {
      send_to: ga4Id,
      page_location: window.location.href,
      page_title: document.title,
      ...params,
    });
  }

  if (import.meta.env.DEV) {
    console.log("[analytics]", eventName, params);
  }
}

export function trackPageView(path: string, title?: string) {
  trackEvent("page_view", {
    page_path: path,
    page_title: title ?? document.title,
  });
}

export function trackSignupStarted(source: string) {
  trackEvent("signup_started", { source });
}

export function trackEmailSubscribed(source: string) {
  trackEvent("email_subscribed", { source });
}

export function trackFeedbackSubmitted(category: string) {
  trackEvent("feedback_submitted", { category });
}

declare global {
  interface Window {
    dataLayer: Record<string, unknown>[];
    gtag: (...args: unknown[]) => void;
    GA4_MEASUREMENT_ID: string;
  }
}
