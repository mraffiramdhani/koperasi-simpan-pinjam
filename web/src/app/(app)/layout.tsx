import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { Sidebar } from '@/components/Sidebar';
import { LogoutButton } from '@/components/LogoutButton';

export default async function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect('/login');

  const { data: staff } = await supabase
    .from('staff_roles')
    .select('role, nama')
    .eq('user_id', user.id)
    .maybeSingle();

  if (!staff) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 p-6 text-center">
        <p className="text-lg font-semibold">Akses ditolak</p>
        <p className="max-w-md text-slate-500">
          Akun ini bukan pengurus/teller. Dashboard hanya untuk staff koperasi.
          Anggota silakan gunakan aplikasi mobile.
        </p>
        <LogoutButton />
      </div>
    );
  }

  return (
    <div className="flex min-h-screen">
      <Sidebar role={staff.role} nama={staff.nama} />
      <div className="flex flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-slate-200 bg-white px-6 py-3">
          <div className="text-sm text-slate-500">Selamat datang, {staff.nama}</div>
          <LogoutButton />
        </header>
        <main className="flex-1 overflow-auto p-6">{children}</main>
      </div>
    </div>
  );
}
