'use client';

import { Button } from '@/components/ui/button';

type Row = Record<string, string | number>;

export function ExportButton({
  rows,
  filename,
  label = 'Ekspor CSV',
}: {
  rows: Row[];
  filename: string;
  label?: string;
}) {
  function exportCsv() {
    if (rows.length === 0) return;
    const headers = Object.keys(rows[0]);
    const csv = [
      headers.join(','),
      ...rows.map((r) =>
        headers
          .map((h) => {
            const v = String(r[h] ?? '');
            return v.includes(',') ? `"${v.replace(/"/g, '""')}"` : v;
          })
          .join(','),
      ),
    ].join('\n');

    const blob = new Blob([`\ufeff${csv}`], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <Button variant="outline" size="sm" onClick={exportCsv} disabled={rows.length === 0}>
      {label}
    </Button>
  );
}
