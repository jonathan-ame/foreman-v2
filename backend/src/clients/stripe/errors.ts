export class StripeApiError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "StripeApiError";
  }
}
