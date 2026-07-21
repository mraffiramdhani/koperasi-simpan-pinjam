'use client';

import { useEffect, useMemo, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { setorTunai, tarikTunai } from '@/lib/actions';
import { formatRupiah, type SavingsType } from '@/lib/types';

type MemberLite = { id: string; no_anggota: string | null; nama: string };
type Account = { id: string; tipe: SavingsType; saldo: number };

export default function TellerPage() {
  const supabase = useMemo(() => createClient(), []);
  const [members, setMembers] = useState<MemberLite[]>([]);
  const [query, setQuery] = useState('');
  const [selected, setSelected] = useState<MemberLite | null>(null);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [tipe, setTipe] = useState<SavingsType>('sukarela');
  const [nominal, setNominal] = useState('');
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    supabase
      .from('members')
      .select('id, no_anggota, nama')
      .eq('status', 'active')
      .order('nama')
      .then(({ data }) => setMembers(data ?? []));
  }, [supabase]);

  async function loadAccounts(memberId: string) {
    const { data } = await supabase
      .from('savings_accounts')
      .select('id, tipe, saldo')
      .eq('member_id', memberId)
      .order('tipe');
    setAccounts((data as Account[]) ?? []);
  }

  function pick(m: MemberLite) {
    setSelected(m);
    setMessage(null);
    loadAccounts(m.id);
  }

  async function submit(kind: 'setor' | 'tarik') {
    if (!selected) return;
    const value = Number(nominal);
    if (!value || value <= 0) {
      setMessage('Nominal tidak valid');
      return;
    }
    setBusy(true);
    setMessage(null);
    const fn = kind === 'setor' ? setorTunai : tarikTunai;
    const res = await fn(selected.id, tipe, value);
    setBusy(false);
    if (res?.error) {
      setMessage(`Gagal: ${res.error}`);
      return;
    }
    setMessage(
      `${kind === 'setor' ? 'Setoran' : 'Penarikan'} ${formatRupiah(value)} berhasil`,
    );
    setNominal('');
    loadAccounts(selected.id);
  }

  const filtered = members.filter(
    (m) =>
      m.nama.toLowerCase().includes(query.toLowerCase()) ||
      (m.no_anggota ?? '').toLowerCase().includes(query.toLowerCase()),
  );

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold">POS Teller</h1>
        <p className="text-sm text-slate-500">Catat setoran & penarikan tunai anggota</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-[1fr_1.2fr]">
        {/* Pencarian anggota */}
        <div className="rounded-xl border border-slate-200 bg-white p-4">
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Cari nama / no. anggota..."
            className="mb-3 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-teal-500"
          />
          <div className="max-h-96 space-y-1 overflow-auto">
            {filtered.map((m) => (
              <button
                key={m.id}
                onClick={() => pick(m)}
                className={`flex w-full items-center justify-between rounded-lg px-3 py-2 text-left text-sm ${
                  selected?.id === m.id ? 'bg-teal-50 text-teal-700' : 'hover:bg-slate-50'
                }`}
              >
                <span className="font-medium">{m.nama}</span>
                <span className="font-mono text-xs text-slate-400">{m.no_anggota}</span>
              </button>
            ))}
            {filtered.length === 0 && (
              <p className="py-6 text-center text-sm text-slate-400">
                Tidak ada anggota
              </p>
            )}
          </div>
        </div>

        {/* Panel transaksi */}
        <div className="rounded-xl border border-slate-200 bg-white p-6">
          {!selected ? (
            <p className="py-16 text-center text-slate-400">
              Pilih anggota untuk memulai transaksi
            </p>
          ) : (
            <div className="space-y-5">
              <div>
                <h2 className="text-lg font-semibold">{selected.nama}</h2>
                <p className="font-mono text-xs text-slate-400">
                  {selected.no_anggota}
                </p>
              </div>

              <div className="grid grid-cols-3 gap-3">
                {accounts.map((a) => (
                  <div
                    key={a.id}
                    className="rounded-lg border border-slate-200 p-3 text-center"
                  >
                    <p className="text-xs capitalize text-slate-500">{a.tipe}</p>
                    <p className="text-sm font-bold">{formatRupiah(a.saldo)}</p>
                  </div>
                ))}
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="mb-1 block text-sm font-medium">Jenis Simpanan</label>
                  <select
                    value={tipe}
                    onChange={(e) => setTipe(e.target.value as SavingsType)}
                    className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm capitalize outline-none focus:border-teal-500"
                  >
                    <option value="pokok">Pokok</option>
                    <option value="wajib">Wajib</option>
                    <option value="sukarela">Sukarela</option>
                  </select>
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium">Nominal</label>
                  <input
                    type="number"
                    value={nominal}
                    onChange={(e) => setNominal(e.target.value)}
                    placeholder="0"
                    className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-teal-500"
                  />
                </div>
              </div>

              {message && (
                <p
                  className={`rounded-lg px-3 py-2 text-sm ${
                    message.startsWith('Gagal')
                      ? 'bg-red-50 text-red-600'
                      : 'bg-green-50 text-green-700'
                  }`}
                >
                  {message}
                </p>
              )}

              <div className="flex gap-3">
                <button
                  disabled={busy}
                  onClick={() => submit('setor')}
                  className="flex-1 rounded-lg bg-teal-600 py-2.5 font-medium text-white hover:bg-teal-700 disabled:opacity-50"
                >
                  Setor
                </button>
                <button
                  disabled={busy}
                  onClick={() => submit('tarik')}
                  className="flex-1 rounded-lg border border-slate-300 py-2.5 font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50"
                >
                  Tarik
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
