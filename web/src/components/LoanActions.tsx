'use client';

import { useTransition } from 'react';
import { approveLoan, rejectLoan } from '@/lib/actions';

export function LoanActions({ loanId }: { loanId: string }) {
  const [pending, start] = useTransition();

  return (
    <div className="flex gap-2">
      <button
        disabled={pending}
        onClick={() => start(() => approveLoan(loanId).then(() => {}))}
        className="rounded-md bg-teal-600 px-3 py-1 text-xs font-medium text-white hover:bg-teal-700 disabled:opacity-50"
      >
        Setujui
      </button>
      <button
        disabled={pending}
        onClick={() =>
          start(() =>
            rejectLoan(loanId, 'Tidak memenuhi syarat').then(() => {}),
          )
        }
        className="rounded-md border border-red-300 px-3 py-1 text-xs font-medium text-red-600 hover:bg-red-50 disabled:opacity-50"
      >
        Tolak
      </button>
    </div>
  );
}
