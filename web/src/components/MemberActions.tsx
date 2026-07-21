'use client';

import { useTransition } from 'react';
import { activateMember, rejectMember } from '@/lib/actions';

export function MemberActions({ memberId }: { memberId: string }) {
  const [pending, start] = useTransition();

  return (
    <div className="flex gap-2">
      <button
        disabled={pending}
        onClick={() => start(() => activateMember(memberId).then(() => {}))}
        className="rounded-md bg-teal-600 px-3 py-1 text-xs font-medium text-white hover:bg-teal-700 disabled:opacity-50"
      >
        Aktifkan
      </button>
      <button
        disabled={pending}
        onClick={() => start(() => rejectMember(memberId).then(() => {}))}
        className="rounded-md border border-red-300 px-3 py-1 text-xs font-medium text-red-600 hover:bg-red-50 disabled:opacity-50"
      >
        Tolak
      </button>
    </div>
  );
}
