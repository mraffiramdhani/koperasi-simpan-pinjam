'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Users,
  CreditCard,
  Receipt,
  LineChart,
  Landmark,
  BookOpen,
} from 'lucide-react';
import { cn } from '@/lib/utils';

const nav = [
  { href: '/', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/anggota', label: 'Anggota', icon: Users },
  { href: '/pinjaman', label: 'Pinjaman', icon: CreditCard },
  { href: '/teller', label: 'POS Teller', icon: Receipt },
  { href: '/laporan', label: 'Laporan', icon: LineChart },
  { href: '/panduan', label: 'Panduan', icon: BookOpen },
];

export function Sidebar({ role, nama }: { role: string; nama: string }) {
  const pathname = usePathname();

  return (
    <aside className="bg-sidebar text-sidebar-foreground flex w-64 shrink-0 flex-col border-r">
      <div className="border-b px-6 py-5">
        <div className="flex items-center gap-2 text-lg font-bold">
          <Landmark className="text-primary size-5" />
          <span>Koperasi SP</span>
        </div>
      </div>

      <nav className="flex-1 space-y-1 p-3">
        {nav.map((item) => {
          const active =
            item.href === '/' ? pathname === '/' : pathname.startsWith(item.href);
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors',
                active
                  ? 'bg-sidebar-accent text-sidebar-accent-foreground'
                  : 'text-muted-foreground hover:bg-muted hover:text-foreground',
              )}
            >
              <Icon className="size-4 shrink-0" />
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="border-t p-4">
        <p className="text-sm font-medium">{nama}</p>
        <p className="text-muted-foreground text-xs capitalize">{role}</p>
      </div>
    </aside>
  );
}
