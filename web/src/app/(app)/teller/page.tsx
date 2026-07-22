'use client';

import { useEffect, useMemo, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { setorTunai, tarikTunai } from '@/lib/actions';
import { formatRupiah, type SavingsType } from '@/lib/types';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { NativeSelect } from '@/components/ui/native-select';
import {
  Card,
  CardContent,
  CardTitle,
} from '@/components/ui/card';
import { cn } from '@/lib/utils';

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

  const isError = message?.startsWith('Gagal') || message === 'Nominal tidak valid';

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold">POS Teller</h1>
        <p className="text-muted-foreground text-sm">Catat setoran & penarikan tunai anggota</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-[1fr_1.2fr]">
        <Card>
          <CardContent className="pt-(--card-spacing)">
            <Input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Cari nama / no. anggota..."
              className="mb-3"
            />
            <div className="max-h-96 space-y-1 overflow-auto">
              {filtered.map((m) => (
                <button
                  key={m.id}
                  type="button"
                  onClick={() => pick(m)}
                  className={cn(
                    'flex w-full items-center justify-between rounded-lg px-3 py-2 text-left text-sm transition-colors',
                    selected?.id === m.id
                      ? 'bg-accent text-accent-foreground'
                      : 'hover:bg-muted',
                  )}
                >
                  <span className="font-medium">{m.nama}</span>
                  <span className="text-muted-foreground font-mono text-xs">{m.no_anggota}</span>
                </button>
              ))}
              {filtered.length === 0 && (
                <p className="text-muted-foreground py-6 text-center text-sm">
                  Tidak ada anggota
                </p>
              )}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-(--card-spacing)">
            {!selected ? (
              <p className="text-muted-foreground py-16 text-center">
                Pilih anggota untuk memulai transaksi
              </p>
            ) : (
              <div className="space-y-5">
                <div>
                  <CardTitle className="text-lg">{selected.nama}</CardTitle>
                  <p className="text-muted-foreground font-mono text-xs">
                    {selected.no_anggota}
                  </p>
                </div>

                <div className="grid grid-cols-3 gap-3">
                  {accounts.map((a) => (
                    <div
                      key={a.id}
                      className="rounded-lg border p-3 text-center"
                    >
                      <p className="text-muted-foreground text-xs capitalize">{a.tipe}</p>
                      <p className="text-sm font-bold">{formatRupiah(a.saldo)}</p>
                    </div>
                  ))}
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-2">
                    <Label htmlFor="tipe">Jenis Simpanan</Label>
                    <NativeSelect
                      id="tipe"
                      value={tipe}
                      onChange={(e) => setTipe(e.target.value as SavingsType)}
                      className="capitalize"
                    >
                      <option value="pokok">Pokok</option>
                      <option value="wajib">Wajib</option>
                      <option value="sukarela">Sukarela</option>
                    </NativeSelect>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="nominal">Nominal</Label>
                    <Input
                      id="nominal"
                      type="number"
                      value={nominal}
                      onChange={(e) => setNominal(e.target.value)}
                      placeholder="0"
                    />
                  </div>
                </div>

                {message && (
                  <Alert
                    variant={isError ? 'destructive' : 'default'}
                    className={isError ? undefined : 'border-green-200 bg-green-50'}
                  >
                    <AlertDescription className={isError ? undefined : 'text-green-700'}>
                      {message}
                    </AlertDescription>
                  </Alert>
                )}

                <div className="flex gap-3">
                  <Button className="flex-1" disabled={busy} onClick={() => submit('setor')}>
                    Setor
                  </Button>
                  <Button
                    variant="outline"
                    className="flex-1"
                    disabled={busy}
                    onClick={() => submit('tarik')}
                  >
                    Tarik
                  </Button>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
