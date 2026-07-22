// Abstraksi payment provider. Tambah provider baru dengan mengimplementasikan
// interface PaymentProvider dan menukar instance di factory.

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
  getInvoiceStatus(invoiceId: string): Promise<WebhookResult>;
  simulateQrPayment(orderId: string, amount: number): Promise<WebhookResult>;
  isTestMode(): boolean;
  parseWebhook(
    payload: Record<string, unknown>,
    headers?: Headers,
  ): Promise<WebhookResult>;
}

export function isXenditTestKey(secretKey: string): boolean {
  return secretKey.startsWith('xnd_development_');
}

function mapXenditStatus(xenditStatus: string): WebhookResult['status'] {
  const status = xenditStatus.toUpperCase();
  if (status === 'PAID' || status === 'SETTLED') return 'paid';
  if (status === 'PENDING') return 'pending';
  if (status === 'EXPIRED') return 'expired';
  return 'failed';
}

// ---------------- Xendit (Invoice) ----------------
class XenditProvider implements PaymentProvider {
  constructor(
    private secretKey: string,
    private callbackToken: string,
  ) {}

  async createTransaction(
    input: CreateTransactionInput,
  ): Promise<CreateTransactionResult> {
    const auth = btoa(`${this.secretKey}:`);
    const res = await fetch('https://api.xendit.co/v2/invoices', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        Authorization: `Basic ${auth}`,
      },
      body: JSON.stringify({
        external_id: input.orderId,
        amount: Math.round(input.amount),
        payer_email: input.customerEmail,
        customer: { given_names: input.customerName },
        description: `Pembayaran ${input.orderId}`,
      }),
    });

    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Xendit error ${res.status}: ${text}`);
    }

    const data = await res.json();
    return { redirectUrl: data.invoice_url, token: data.id };
  }

  isTestMode(): boolean {
    return isXenditTestKey(this.secretKey);
  }

  async simulateQrPayment(orderId: string, amount: number): Promise<WebhookResult> {
    if (!this.isTestMode()) {
      throw new Error('Simulasi pembayaran hanya tersedia di mode test Xendit');
    }

    const auth = btoa(`${this.secretKey}:`);
    const res = await fetch(
      `https://api.xendit.co/qr_codes/${encodeURIComponent(orderId)}/payments/simulate`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Basic ${auth}`,
        },
        body: JSON.stringify({ amount: Math.round(amount) }),
      },
    );

    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Xendit simulate error ${res.status}: ${text}`);
    }

    // Setelah simulasi, ambil status invoice terbaru.
    const invoicesRes = await fetch(
      `https://api.xendit.co/v2/invoices?external_id=${encodeURIComponent(orderId)}`,
      {
        headers: {
          Accept: 'application/json',
          Authorization: `Basic ${auth}`,
        },
      },
    );

    if (!invoicesRes.ok) {
      const text = await invoicesRes.text();
      throw new Error(`Xendit invoice lookup error ${invoicesRes.status}: ${text}`);
    }

    const invoices = await invoicesRes.json();
    const invoice = Array.isArray(invoices) ? invoices[0] : invoices;
    if (!invoice?.id) {
      throw new Error('Invoice tidak ditemukan setelah simulasi');
    }

    return this.getInvoiceStatus(String(invoice.id));
  }

  async getInvoiceStatus(invoiceId: string): Promise<WebhookResult> {
    const auth = btoa(`${this.secretKey}:`);
    const res = await fetch(`https://api.xendit.co/v2/invoices/${invoiceId}`, {
      headers: {
        Accept: 'application/json',
        Authorization: `Basic ${auth}`,
      },
    });

    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Xendit error ${res.status}: ${text}`);
    }

    const data = await res.json();
    return {
      orderId: String(data.external_id ?? ''),
      status: mapXenditStatus(String(data.status ?? '')),
      raw: data,
    };
  }

  async parseWebhook(
    payload: Record<string, unknown>,
    headers?: Headers,
  ): Promise<WebhookResult> {
    // Xendit memverifikasi callback lewat header x-callback-token
    const token = headers?.get('x-callback-token') ?? '';
    if (!this.callbackToken || token !== this.callbackToken) {
      throw new Error('Callback token tidak valid');
    }

    const orderId = String(payload.external_id ?? '');
    const xenditStatus = String(payload.status ?? '');

    return { orderId, status: mapXenditStatus(xenditStatus), raw: payload };
  }
}

// ---------------- Factory ----------------
export function getPaymentProvider(): PaymentProvider {
  const secretKey = Deno.env.get('XENDIT_SECRET_KEY') ?? '';
  const callbackToken = Deno.env.get('XENDIT_CALLBACK_TOKEN') ?? '';
  if (!secretKey) throw new Error('XENDIT_SECRET_KEY belum diset');
  return new XenditProvider(secretKey, callbackToken);
}
