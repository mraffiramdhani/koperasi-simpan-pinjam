'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const nav = [
  { href: '/', label: 'Dashboard', icon: '📊' },
  { href: '/anggota', label: 'Anggota', icon: '👥' },
  { href: '/pinjaman', label: 'Pinjaman', icon: '💳' },
  { href: '/teller', label: 'POS Teller', icon: '🧾' },
  { href: '/laporan', label: 'Laporan', icon: '📈' },
];

export function Sidebar({ role, nama }: { role: string; nama: string }) {
  const pathname = usePathname();

  return (
    <aside className="flex w-64 shrink-0 flex-col border-r border-slate-200 bg-white">
      <div className="border-b border-slate-200 px-6 py-5">
        <div className="flex items-center gap-2 text-lg font-bold">
          <span>🏦</span>
          <span>Koperasi SP</span>
        </div>
      </div>

      <nav className="flex-1 space-y-1 p-3">
        {nav.map((item) => {
          const active =
            item.href === '/' ? pathname === '/' : pathname.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition ${
                active
                  ? 'bg-teal-50 text-teal-700'
                  : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <span>{item.icon}</span>
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="border-t border-slate-200 p-4">
        <p className="text-sm font-medium">{nama}</p>
        <p className="text-xs capitalize text-slate-500">{role}</p>
      </div>
    </aside>
  );
}
