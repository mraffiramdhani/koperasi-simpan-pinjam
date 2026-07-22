'use client';

import { useState, useTransition } from 'react';
import { approveLoan, rejectLoan, cairkanPinjaman } from '@/lib/actions';
import type { DisbursementStatus, LoanStatus } from '@/lib/types';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

export function LoanActions({
  loanId,
  status,
  hasBankAccount,
  disbursementStatus,
  canManage = false,
}: {
  loanId: string;
  status: LoanStatus;
  hasBankAccount: boolean;
  disbursementStatus?: DisbursementStatus | null;
  /** Hanya pengurus yang boleh setujui/tolak/cairkan */
  canManage?: boolean;
}) {
  const [pending, start] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [showReject, setShowReject] = useState(false);
  const [alasan, setAlasan] = useState('Tidak memenuhi syarat');

  if (!canManage) {
    return <span className="text-muted-foreground text-xs">-</span>;
  }

  if (status === 'pengajuan') {
    if (showReject) {
      return (
        <div className="flex min-w-[200px] flex-col gap-1.5">
          <Label htmlFor={`alasan-${loanId}`} className="text-xs">
            Alasan penolakan
          </Label>
          <Input
            id={`alasan-${loanId}`}
            value={alasan}
            onChange={(e) => setAlasan(e.target.value)}
            className="h-7 text-xs"
            placeholder="Alasan..."
          />
          <div className="flex gap-1">
            <Button
              size="xs"
              variant="destructive"
              disabled={pending || !alasan.trim()}
              onClick={() =>
                start(async () => {
                  await rejectLoan(loanId, alasan.trim());
                  setShowReject(false);
                })
              }
            >
              Konfirmasi Tolak
            </Button>
            <Button
              size="xs"
              variant="ghost"
              disabled={pending}
              onClick={() => setShowReject(false)}
            >
              Batal
            </Button>
          </div>
        </div>
      );
    }

    return (
      <div className="flex gap-2">
        <Button
          size="xs"
          disabled={pending}
          onClick={() => start(() => approveLoan(loanId).then(() => {}))}
        >
          Setujui
        </Button>
        <Button
          size="xs"
          variant="destructive"
          disabled={pending}
          onClick={() => setShowReject(true)}
        >
          Tolak
        </Button>
      </div>
    );
  }

  if (status === 'approved') {
    const disabled = pending || !hasBankAccount || disbursementStatus === 'processing';

    return (
      <div className="flex flex-col items-start gap-1">
        <Button
          size="xs"
          disabled={disabled}
          onClick={() =>
            start(async () => {
              setError(null);
              const res = await cairkanPinjaman(loanId);
              if (res?.error) setError(res.error);
            })
          }
        >
          {disbursementStatus === 'processing'
            ? 'Sedang Dicairkan...'
            : disbursementStatus === 'failed'
              ? 'Coba Cairkan Lagi'
              : 'Cairkan via Xendit'}
        </Button>
        {!hasBankAccount && (
          <span className="text-destructive text-xs">Rekening anggota belum diisi</span>
        )}
        {disbursementStatus === 'failed' && (
          <span className="text-destructive text-xs">Pencairan sebelumnya gagal</span>
        )}
        {error && <span className="text-destructive text-xs">{error}</span>}
      </div>
    );
  }

  return <span className="text-muted-foreground text-xs">-</span>;
}
