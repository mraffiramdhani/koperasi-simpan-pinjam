'use client';

import {
  Bar,
  BarChart,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { formatRupiah } from '@/lib/types';

const COLORS = ['#0d9488', '#0ea5e9', '#f59e0b', '#ef4444', '#8b5cf6'];

export function SimpananBarChart({
  data,
}: {
  data: { tipe: string; total: number }[];
}) {
  return (
    <ResponsiveContainer width="100%" height={260}>
      <BarChart data={data} margin={{ top: 8, right: 8, left: 8, bottom: 8 }}>
        <XAxis dataKey="tipe" tickLine={false} axisLine={false} className="text-xs" />
        <YAxis
          tickFormatter={(v) => `${v / 1000}k`}
          tickLine={false}
          axisLine={false}
          width={40}
          className="text-xs"
        />
        <Tooltip formatter={(value) => formatRupiah(Number(value))} />
        <Bar dataKey="total" radius={[6, 6, 0, 0]} fill="#0d9488" />
      </BarChart>
    </ResponsiveContainer>
  );
}

export function LoanStatusPie({
  data,
}: {
  data: { status: string; jumlah: number }[];
}) {
  return (
    <ResponsiveContainer width="100%" height={260}>
      <PieChart>
        <Pie
          data={data}
          dataKey="jumlah"
          nameKey="status"
          cx="50%"
          cy="50%"
          outerRadius={90}
          label={(e: { name?: string; value?: number }) => `${e.name} (${e.value})`}
        >
          {data.map((_, i) => (
            <Cell key={i} fill={COLORS[i % COLORS.length]} />
          ))}
        </Pie>
        <Tooltip />
      </PieChart>
    </ResponsiveContainer>
  );
}

export function CashflowChart({
  data,
}: {
  data: { bulan: string; masuk: number; keluar: number }[];
}) {
  return (
    <ResponsiveContainer width="100%" height={300}>
      <BarChart data={data} margin={{ top: 8, right: 8, left: 8, bottom: 8 }}>
        <XAxis dataKey="bulan" tickLine={false} axisLine={false} className="text-xs" />
        <YAxis
          tickFormatter={(v) => `${v / 1000}k`}
          tickLine={false}
          axisLine={false}
          width={40}
          className="text-xs"
        />
        <Tooltip formatter={(value) => formatRupiah(Number(value))} />
        <Bar dataKey="masuk" name="Masuk" radius={[6, 6, 0, 0]} fill="#0d9488" />
        <Bar dataKey="keluar" name="Keluar" radius={[6, 6, 0, 0]} fill="#ef4444" />
      </BarChart>
    </ResponsiveContainer>
  );
}
