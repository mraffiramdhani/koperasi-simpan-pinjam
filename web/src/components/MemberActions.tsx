'use client';

import { useTransition } from 'react';
import { activateMember, rejectMember } from '@/lib/actions';
import { Button } from '@/components/ui/button';

export function MemberActions({
  memberId,
  canManage = false,
}: {
  memberId: string;
  /** Hanya pengurus yang boleh aktifkan/tolak */
  canManage?: boolean;
}) {
  const [pending, start] = useTransition();

  if (!canManage) {
    return <span className="text-muted-foreground text-xs">-</span>;
  }

  return (
    <div className="flex gap-2">
      <Button
        size="xs"
        disabled={pending}
        onClick={() => start(() => activateMember(memberId).then(() => {}))}
      >
        Aktifkan
      </Button>
      <Button
        size="xs"
        variant="destructive"
        disabled={pending}
        onClick={() => start(() => rejectMember(memberId).then(() => {}))}
      >
        Tolak
      </Button>
    </div>
  );
}
