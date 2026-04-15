export type PaymentStatus = "active" | "trialing" | "past_due" | "canceled" | "pending";

export interface Subscription {
  id: string;
  status: PaymentStatus;
  currentPeriodEnd: Date;
  customerId: string;
  productId: string;
}

export interface Customer {
  id: string;
  email: string;
  balance: number;
}
