'use client';

import { useState, useTransition } from 'react';
import { updateRekening } from '@/lib/actions';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { NativeSelect } from '@/components/ui/native-select';

const BANK_OPTIONS = ['BCA', 'BNI', 'BRI', 'MANDIRI', 'CIMB', 'PERMATA'];

export function BankAccountForm({
  memberId,
  bankCode,
  accountNumber,
  accountHolderName,
}: {
  memberId: string;
  bankCode: string | null;
  accountNumber: string | null;
  accountHolderName: string | null;
}) {
  const [editing, setEditing] = useState(false);
  const [pending, start] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState({
    bankCode: bankCode ?? '',
    accountNumber: accountNumber ?? '',
    accountHolderName: accountHolderName ?? '',
  });

  if (!editing) {
    return (
      <div className="flex items-center gap-2">
        {bankCode && accountNumber ? (
          <span className="text-muted-foreground text-xs">
            {bankCode} · {accountNumber}
          </span>
        ) : (
          <span className="text-xs text-amber-600">Belum diisi</span>
        )}
        <Button variant="link" size="xs" className="h-auto p-0" onClick={() => setEditing(true)}>
          Edit
        </Button>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-1.5">
      <div className="flex gap-1">
        <NativeSelect
          value={form.bankCode}
          onChange={(e) => setForm((f) => ({ ...f, bankCode: e.target.value }))}
          className="h-7 w-24 text-xs"
        >
          <option value="">Bank</option>
          {BANK_OPTIONS.map((b) => (
            <option key={b} value={b}>
              {b}
            </option>
          ))}
        </NativeSelect>
        <Input
          value={form.accountNumber}
          onChange={(e) => setForm((f) => ({ ...f, accountNumber: e.target.value }))}
          placeholder="No. rekening"
          className="h-7 w-32 text-xs"
        />
      </div>
      <Input
        value={form.accountHolderName}
        onChange={(e) => setForm((f) => ({ ...f, accountHolderName: e.target.value }))}
        placeholder="Nama pemilik rekening"
        className="h-7 text-xs"
      />
      {error && <span className="text-destructive text-xs">{error}</span>}
      <div className="flex gap-2">
        <Button
          size="xs"
          disabled={pending}
          onClick={() =>
            start(async () => {
              setError(null);
              const res = await updateRekening(
                memberId,
                form.bankCode,
                form.accountNumber,
                form.accountHolderName,
              );
              if (res?.error) setError(res.error);
              else setEditing(false);
            })
          }
        >
          Simpan
        </Button>
        <Button
          variant="ghost"
          size="xs"
          onClick={() => setEditing(false)}
        >
          Batal
        </Button>
      </div>
    </div>
  );
}
