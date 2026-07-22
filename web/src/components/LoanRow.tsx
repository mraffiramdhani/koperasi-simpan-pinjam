'use client';

import { useState, useTransition } from 'react';
import { ChevronDown, ChevronRight } from 'lucide-react';
import { LoanActions } from '@/components/LoanActions';
import { bayarAngsuranTunai } from '@/lib/actions';
import {
  formatRupiah,
  formatTanggal,
  type DisbursementStatus,
  type InstallmentStatus,
  type LoanStatus,
} from '@/lib/types';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { cn } from '@/lib/utils';

const statusStyle: Record<LoanStatus, string> = {
  pengajuan: 'bg-amber-100 text-amber-700 hover:bg-amber-100',
  approved: 'bg-blue-100 text-blue-700 hover:bg-blue-100',
  active: 'bg-green-100 text-green-700 hover:bg-green-100',
  rejected: 'bg-destructive/10 text-destructive hover:bg-destructive/10',
  lunas: 'bg-primary/15 text-primary hover:bg-primary/15',
};

const statusLabel: Record<LoanStatus, string> = {
  pengajuan: 'Menunggu',
  approved: 'Menunggu Pencairan',
  active: 'Aktif',
  rejected: 'Ditolak',
  lunas: 'Lunas',
};

const installmentStyle: Record<InstallmentStatus, string> = {
  belum: 'bg-muted text-muted-foreground hover:bg-muted',
  lunas: 'bg-green-100 text-green-700 hover:bg-green-100',
  telat: 'bg-destructive/10 text-destructive hover:bg-destructive/10',
};

type InstallmentRow = {
  id: string;
  angsuran_ke: number;
  jatuh_tempo: string;
  nominal_pokok: number;
  nominal_jasa: number;
  total: number;
  status: InstallmentStatus;
  paid_at: string | null;
};

export type LoanRowData = {
  id: string;
  pokok: number;
  tenor: number;
  jasa_persen: number;
  tujuan: string | null;
  status: LoanStatus;
  tanggal_pengajuan: string;
  members: {
    nama: string;
    no_anggota: string | null;
    bank_code: string | null;
    account_number: string | null;
    account_holder_name: string | null;
  } | null;
  disbursements: { status: DisbursementStatus; created_at: string }[] | null;
  loan_installments: InstallmentRow[] | null;
};

export function LoanRow({
  loan,
  canManage = false,
}: {
  loan: LoanRowData;
  canManage?: boolean;
}) {
  const [expanded, setExpanded] = useState(false);
  const [pending, start] = useTransition();
  const [error, setError] = useState<string | null>(null);

  const hasBankAccount = Boolean(
    loan.members?.bank_code &&
      loan.members?.account_number &&
      loan.members?.account_holder_name,
  );
  const latestDisbursement = (loan.disbursements ?? [])
    .slice()
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())[0];
  const installments = (loan.loan_installments ?? []).slice().sort(
    (a, b) => a.angsuran_ke - b.angsuran_ke,
  );
  const hasInstallments = installments.length > 0;

  function payCash(installmentId: string) {
    setError(null);
    start(async () => {
      const res = await bayarAngsuranTunai(installmentId);
      if (res?.error) setError(res.error);
    });
  }

  return (
    <>
      <tr className="hover:bg-muted/50 border-b transition-colors">
        <td className="px-4 py-3">
          <div className="flex items-center gap-2">
            {hasInstallments && (
              <Button
                type="button"
                variant="ghost"
                size="icon-xs"
                onClick={() => setExpanded((v) => !v)}
                aria-label={expanded ? 'Tutup jadwal' : 'Lihat jadwal'}
              >
                {expanded ? <ChevronDown /> : <ChevronRight />}
              </Button>
            )}
            <div>
              <div className="font-medium">{loan.members?.nama ?? '-'}</div>
              <div className="text-muted-foreground font-mono text-xs">
                {loan.members?.no_anggota ?? '-'}
              </div>
            </div>
          </div>
        </td>
        <td className="px-4 py-3 font-medium">{formatRupiah(loan.pokok)}</td>
        <td className="px-4 py-3">{loan.tenor} bln</td>
        <td className="px-4 py-3">{loan.jasa_persen}%/bln</td>
        <td className="px-4 py-3">{loan.tujuan ?? '-'}</td>
        <td className="px-4 py-3">{formatTanggal(loan.tanggal_pengajuan)}</td>
        <td className="px-4 py-3">
          <Badge variant="secondary" className={cn(statusStyle[loan.status])}>
            {statusLabel[loan.status]}
          </Badge>
        </td>
        <td className="px-4 py-3">
          {loan.status === 'pengajuan' || loan.status === 'approved' ? (
            <LoanActions
              loanId={loan.id}
              status={loan.status}
              hasBankAccount={hasBankAccount}
              disbursementStatus={latestDisbursement?.status ?? null}
              canManage={canManage}
            />
          ) : (
            <span className="text-muted-foreground text-xs">-</span>
          )}
        </td>
      </tr>
      {expanded && hasInstallments && (
        <tr className="bg-muted/40 border-b">
          <td colSpan={8} className="px-4 py-3">
            {error && (
              <Alert variant="destructive" className="mb-2">
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}
            <p className="text-muted-foreground mb-2 text-xs font-medium">Jadwal Angsuran</p>
            <table className="w-full text-xs">
              <thead>
                <tr className="text-muted-foreground text-left">
                  <th className="pb-2 pr-4">Ke</th>
                  <th className="pb-2 pr-4">Jatuh Tempo</th>
                  <th className="pb-2 pr-4">Pokok</th>
                  <th className="pb-2 pr-4">Jasa</th>
                  <th className="pb-2 pr-4">Total</th>
                  <th className="pb-2 pr-4">Status</th>
                  <th className="pb-2">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-border divide-y">
                {installments.map((inst) => (
                  <tr key={inst.id}>
                    <td className="py-2 pr-4">{inst.angsuran_ke}</td>
                    <td className="py-2 pr-4">{formatTanggal(inst.jatuh_tempo)}</td>
                    <td className="py-2 pr-4">{formatRupiah(inst.nominal_pokok)}</td>
                    <td className="py-2 pr-4">{formatRupiah(inst.nominal_jasa)}</td>
                    <td className="py-2 pr-4 font-medium">{formatRupiah(inst.total)}</td>
                    <td className="py-2 pr-4">
                      <Badge
                        variant="secondary"
                        className={cn('capitalize', installmentStyle[inst.status])}
                      >
                        {inst.status}
                      </Badge>
                    </td>
                    <td className="py-2">
                      {inst.status !== 'lunas' && loan.status === 'active' ? (
                        <Button
                          type="button"
                          size="xs"
                          disabled={pending}
                          onClick={() => payCash(inst.id)}
                        >
                          Bayar Tunai
                        </Button>
                      ) : (
                        <span className="text-muted-foreground">-</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </td>
        </tr>
      )}
    </>
  );
}
