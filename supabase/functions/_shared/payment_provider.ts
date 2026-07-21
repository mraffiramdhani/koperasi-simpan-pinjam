// Abstraksi payment provider. Tambah provider baru (mis. Xendit) dengan
// mengimplementasikan interface PaymentProvider dan menukar instance di factory.

export interface CreateTransactionInput {
  orderId: string;
  amount: number;
  customerName: string;
  customerEmail?: string;
}

export interface CreateTransactionResult {
  redirectUrl: string;
  token?: string;
}

export interface WebhookResult {
  orderId: string;
  status: 'pending' | 'paid' | 'failed' | 'expired';
  raw: Record<string, unknown>;
}

export interface PaymentProvider {
  createTransaction(input: CreateTransactionInput): Promise<CreateTransactionResult>;
  parseWebhook(payload: Record<string, unknown>): Promise<WebhookResult>;
}

// ---------------- Midtrans (Snap) ----------------
class MidtransProvider implements PaymentProvider {
  constructor(
    private serverKey: string,
    private isProduction: boolean,
  ) {}

  private get snapBaseUrl(): string {
    return this.isProduction
      ? 'https://app.midtrans.com/snap/v1/transactions'
      : 'https://app.sandbox.midtrans.com/snap/v1/transactions';
  }

  async createTransaction(
    input: CreateTransactionInput,
  ): Promise<CreateTransactionResult> {
    const auth = btoa(`${this.serverKey}:`);
    const res = await fetch(this.snapBaseUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        Authorization: `Basic ${auth}`,
      },
      body: JSON.stringify({
        transaction_details: {
          order_id: input.orderId,
          gross_amount: Math.round(input.amount),
        },
        customer_details: {
          first_name: input.customerName,
          email: input.customerEmail,
        },
        credit_card: { secure: true },
      }),
    });

    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Midtrans error ${res.status}: ${text}`);
    }

    const data = await res.json();
    return { redirectUrl: data.redirect_url, token: data.token };
  }

  async parseWebhook(
    payload: Record<string, unknown>,
  ): Promise<WebhookResult> {
    const orderId = String(payload.order_id ?? '');
    const statusCode = String(payload.status_code ?? '');
    const grossAmount = String(payload.gross_amount ?? '');
    const signatureKey = String(payload.signature_key ?? '');

    // Verifikasi signature: sha512(order_id + status_code + gross_amount + server_key)
    const expected = await sha512(
      `${orderId}${statusCode}${grossAmount}${this.serverKey}`,
    );
    if (expected !== signatureKey) {
      throw new Error('Signature tidak valid');
    }

    const txStatus = String(payload.transaction_status ?? '');
    const fraud = String(payload.fraud_status ?? 'accept');

    let status: WebhookResult['status'] = 'pending';
    if (txStatus === 'capture') {
      status = fraud === 'accept' ? 'paid' : 'pending';
    } else if (txStatus === 'settlement') {
      status = 'paid';
    } else if (txStatus === 'pending') {
      status = 'pending';
    } else if (['deny', 'cancel', 'failure'].includes(txStatus)) {
      status = 'failed';
    } else if (txStatus === 'expire') {
      status = 'expired';
    }

    return { orderId, status, raw: payload };
  }
}

async function sha512(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const hash = await crypto.subtle.digest('SHA-512', data);
  return [...new Uint8Array(hash)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

// ---------------- Factory ----------------
export function getPaymentProvider(): PaymentProvider {
  const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY') ?? '';
  const isProduction = Deno.env.get('MIDTRANS_IS_PRODUCTION') === 'true';
  if (!serverKey) throw new Error('MIDTRANS_SERVER_KEY belum diset');
  return new MidtransProvider(serverKey, isProduction);
}
