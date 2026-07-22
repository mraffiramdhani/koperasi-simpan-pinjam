// Abstraksi disbursement (pencairan dana) provider. Tambah provider baru
// dengan mengimplementasikan interface DisbursementProvider dan menukar
// instance di factory.

export interface CreateDisbursementInput {
  externalId: string;
  amount: number;
  bankCode: string;
  accountNumber: string;
  accountHolderName: string;
  description?: string;
}

export interface CreateDisbursementResult {
  providerRef: string;
  status: 'pending' | 'completed' | 'failed';
}

export interface DisbursementWebhookResult {
  externalId: string;
  status: 'pending' | 'completed' | 'failed';
  raw: Record<string, unknown>;
}

export interface DisbursementProvider {
  createDisbursement(
    input: CreateDisbursementInput,
  ): Promise<CreateDisbursementResult>;
  parseWebhook(
    payload: Record<string, unknown>,
    headers?: Headers,
  ): Promise<DisbursementWebhookResult>;
}

// ---------------- Xendit (Disbursement) ----------------
class XenditDisbursementProvider implements DisbursementProvider {
  constructor(
    private secretKey: string,
    private callbackToken: string,
  ) {}

  async createDisbursement(
    input: CreateDisbursementInput,
  ): Promise<CreateDisbursementResult> {
    const auth = btoa(`${this.secretKey}:`);
    const res = await fetch('https://api.xendit.co/disbursements', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        Authorization: `Basic ${auth}`,
      },
      body: JSON.stringify({
        external_id: input.externalId,
        amount: Math.round(input.amount),
        bank_code: input.bankCode,
        account_holder_name: input.accountHolderName,
        account_number: input.accountNumber,
        description: input.description ?? `Pencairan pinjaman ${input.externalId}`,
      }),
    });

    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Xendit disbursement error ${res.status}: ${text}`);
    }

    const data = await res.json();
    const xenditStatus = String(data.status ?? '').toUpperCase();
    return {
      providerRef: String(data.id ?? ''),
      status: xenditStatus === 'COMPLETED' ? 'completed' : 'pending',
    };
  }

  async parseWebhook(
    payload: Record<string, unknown>,
    headers?: Headers,
  ): Promise<DisbursementWebhookResult> {
    // Xendit memverifikasi callback lewat header x-callback-token
    const token = headers?.get('x-callback-token') ?? '';
    if (!this.callbackToken || token !== this.callbackToken) {
      throw new Error('Callback token tidak valid');
    }

    const externalId = String(payload.external_id ?? '');
    const xenditStatus = String(payload.status ?? '').toUpperCase();

    let status: DisbursementWebhookResult['status'] = 'pending';
    if (xenditStatus === 'COMPLETED') {
      status = 'completed';
    } else if (xenditStatus === 'FAILED') {
      status = 'failed';
    } else {
      status = 'pending';
    }

    return { externalId, status, raw: payload };
  }
}

// ---------------- Factory ----------------
export function getDisbursementProvider(): DisbursementProvider {
  const secretKey = Deno.env.get('XENDIT_SECRET_KEY') ?? '';
  const callbackToken = Deno.env.get('XENDIT_CALLBACK_TOKEN') ?? '';
  if (!secretKey) throw new Error('XENDIT_SECRET_KEY belum diset');
  return new XenditDisbursementProvider(secretKey, callbackToken);
}
