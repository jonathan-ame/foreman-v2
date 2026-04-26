import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { trackEvent, trackPageView, trackSignupStarted, trackEmailSubscribed, trackFeedbackSubmitted } from '../analytics';

// Mock the global window object
declare global {
  interface Window {
    gtag: (...args: unknown[]) => void;
    dataLayer: Record