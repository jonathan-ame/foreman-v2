import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { trackEvent, trackPageView, trackSignupStarted, trackEmailSubscribed, trackFeedbackSubmitted } from '../analytics';

declare global {
  interface Window {
    gtag: (...args: unknown[]) => void;
    dataLayer: Record<string, unknown>[];
    GA4_MEASUREMENT_ID: string;
  }
}

describe('analytics', () => {
  let gtagSpy: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    gtagSpy = vi.fn();
    window.gtag = gtagSpy;
    window.dataLayer = [];
    window.GA4_MEASUREMENT_ID = 'G-TEST';
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('trackEvent', () => {
    it('calls gtag with event name and params', () => {
      trackEvent('page_view', { page_path: '/test' });
      expect(gtagSpy).toHaveBeenCalledWith('event', 'page_view', expect.objectContaining({
        send_to: 'G-TEST',
        page_path: '/test'
      }));
    });

    it('does not call gtag when not available', () => {
      window.gtag = undefined as never;
      trackEvent('page_view');
      expect(gtagSpy).not.toHaveBeenCalled();
    });
  });

  describe('trackPageView', () => {
    it('tracks a page view with path and title', () => {
      trackPageView('/pricing', 'Pricing');
      expect(gtagSpy).toHaveBeenCalledWith('event', 'page_view', expect.objectContaining({
        page_path: '/pricing',
        page_title: 'Pricing'
      }));
    });
  });

  describe('trackSignupStarted', () => {
    it('tracks signup started with source', () => {
      trackSignupStarted('hero_cta');
      expect(gtagSpy).toHaveBeenCalledWith('event', 'signup_started', expect.objectContaining({
        source: 'hero_cta'
      }));
    });
  });

  describe('trackEmailSubscribed', () => {
    it('tracks email subscription with source', () => {
      trackEmailSubscribed('footer');
      expect(gtagSpy).toHaveBeenCalledWith('event', 'email_subscribed', expect.objectContaining({
        source: 'footer'
      }));
    });
  });

  describe('trackFeedbackSubmitted', () => {
    it('tracks feedback with category', () => {
      trackFeedbackSubmitted('bug');
      expect(gtagSpy).toHaveBeenCalledWith('event', 'feedback_submitted', expect.objectContaining({
        category: 'bug'
      }));
    });
  });
});
