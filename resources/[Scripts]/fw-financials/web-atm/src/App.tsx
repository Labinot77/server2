import { useEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react';

// ─────────────────────────────────────────────────────────────────────────────
// Fleeca ATM screen (DUI). Pure renderer: Lua owns all state and sends
//   INIT   { layout, bankName, quickAmounts, dailyLimit, model, sheet }
//          sheet = the screen is a corner of a shared texture sheet (stock Fleeca ATM): squeeze the UI into it.
//                  The rest of the sheet (the lit sign panels) is drawn from html/atm/prop_fleece_emis.png when it exists
//                  (the original texture exported from the game), otherwise those parts stay dark.
//   STATE  { screen, accounts, accIndex, amount, history, result, toast, processing, ... }
//   CURSOR { x, y, hover, visible }   (percent of screen)
//   PRESS  { id }                     (click flash)
// Button rects come from client/layout.lua, so what's drawn is exactly what's clickable.
// ─────────────────────────────────────────────────────────────────────────────

type Rect = [number, number, number, number];
type Layout = Record<string, { id: string; rect: Rect }[]>;

interface Account { id: string; label: string; type?: string; balance: number | string; canHistory?: boolean }
interface HistoryRow { type: string; amount: number; negative: boolean; date: string; note?: string }
interface State {
  screen: 'idle' | 'loading' | 'accounts' | 'menu' | 'withdraw' | 'history' | 'result' | 'goodbye';
  accounts?: Account[];
  accIndex?: number;
  amount?: string;
  dailyLeft?: number;
  history?: HistoryRow[] | null;
  historyLoading?: boolean;
  result?: { amount: number; balance: number | string; message: string };
  toast?: { msg: string; id: number } | null;
  processing?: boolean;
}

// A string is shown as-is: someone watching another player's ATM gets '**' instead of the balance.
const money = (n: number | string | undefined) => typeof n === 'string' ? n : '$' + Math.round(Number(n || 0)).toLocaleString('en-US');
const cn = (...c: (string | false | null | undefined)[]) => c.filter(Boolean).join(' ');

export default function App() {
  const [layout, setLayout] = useState<Layout>({});
  const [quick, setQuick] = useState<number[]>([100, 500, 1000, 5000]);
  const [bankName, setBankName] = useState('FLEECA');
  const [dailyLimit, setDailyLimit] = useState(50000);
  const [state, setState] = useState<State>({ screen: 'idle' });
  const [cursor, setCursor] = useState<{ x: number; y: number; hover?: string | null; visible: boolean }>({ x: 50, y: 72, hover: null, visible: false });
  const [pressed, setPressed] = useState<string | null>(null);
  const [sheet, setSheet] = useState(false);
  const [sheetArt, setSheetArt] = useState(true); // false = prop_fleece_emis.png missing
  const pressTimer = useRef<number>();

  useEffect(() => {
    const onMessage = (e: MessageEvent) => {
      const { action, data } = e.data || {};
      switch (action) {
        case 'INIT':
          if (data?.layout) setLayout(data.layout);
          if (data?.quickAmounts) setQuick(data.quickAmounts);
          if (data?.bankName) setBankName(data.bankName);
          if (data?.dailyLimit) setDailyLimit(data.dailyLimit);
          setSheet(data?.sheet === true);
          break;
        case 'STATE': setState(data || { screen: 'idle' }); break;
        case 'CURSOR': setCursor(c => ({ ...c, ...data, visible: data?.visible !== false })); break;
        case 'PRESS':
          setPressed(data?.id || null);
          window.clearTimeout(pressTimer.current);
          pressTimer.current = window.setTimeout(() => setPressed(null), 140);
          break;
      }
    };
    window.addEventListener('message', onMessage);
    return () => window.removeEventListener('message', onMessage);
  }, []);

  const acc = state.accounts?.[(state.accIndex || 1) - 1];
  const rectOf = (id: string): CSSProperties => {
    const r = layout[state.screen]?.find(e => e.id === id)?.rect;
    if (!r) return { display: 'none' };
    return { position: 'absolute', left: `${r[0]}%`, top: `${r[1]}%`, width: `${r[2]}%`, height: `${r[3]}%` };
  };
  const hov = (id: string) => cursor.visible && cursor.hover === id;
  const prs = (id: string) => pressed === id;

  const panelScreen = state.screen === 'withdraw' || state.screen === 'history';

  return (
    <div className="w-full h-full relative overflow-hidden bg-transparent">
      {sheet && sheetArt && (
        <img src="./prop_fleece_emis.png" alt="" onError={() => setSheetArt(false)}
          className="absolute inset-0 w-full h-full pointer-events-none" style={{ objectFit: 'fill' }} />
      )}
      <div
        className="w-full h-full relative overflow-hidden bg-fleeca-paper text-fleeca-ink select-none"
        style={sheet ? { transformOrigin: 'top left', transform: 'translate(0.39vw, 50.78vh) scale(0.4921, 0.4648)' } : undefined}
      >
        {/* Background diagonal shape */}
        <div
          className={cn('absolute inset-0 transition-colors duration-300', panelScreen ? 'bg-fleeca-soft' : 'bg-fleeca-shape')}
          style={{ clipPath: 'polygon(100% 0, 34.5% 51%, 54% 100%, 100% 100%)' }}
        />

        {(state.screen === 'loading' || state.screen === 'goodbye') && (
          <div className="absolute left-[28%] top-[27%] w-[44%] h-[46%] bg-white rounded-[1vh] shadow-[0_1vh_3vh_rgba(0,0,0,0.18)]" />
        )}
        {state.screen !== 'idle' && <Logo name={bankName} big={state.screen === 'loading' || state.screen === 'goodbye'} />}

        {/* Account summary (top right) */}
        {acc && ['menu', 'withdraw', 'history'].includes(state.screen) && (
          <div className="absolute right-[3.6%] top-[5.2%] text-right">
            <p className="cond font-semibold text-[1.7vh] text-black/55 tracking-wide">{acc.label} - #{acc.id}</p>
            <p className="cond font-extrabold text-[3.9vh] leading-none tabular">{money(acc.balance)}</p>
          </div>
        )}

        {/* ── ACCOUNTS ── */}
        {state.screen === 'accounts' && (
          <>
            <p className="cond absolute left-[25.5%] top-[33.5%] font-bold text-[2.7vh]">Select Account</p>
            <div className="absolute left-[25.5%] top-[39%] w-[49%] h-[11%] bg-fleeca-ink rounded-[0.6vh] shadow-[0_0.6vh_1.4vh_rgba(0,0,0,0.25)]" />
            <div className="absolute left-[32.3%] top-[39.6%] w-[35.4%] h-[9.8%] bg-white flex flex-col items-center justify-center">
              <p className="cond font-extrabold text-[3.7vh] leading-none">{acc?.label}</p>
              <p className="font-sans font-medium text-[1.8vh] text-black/70 mt-[0.6vh] tabular">#{acc?.id} · {money(acc?.balance)}</p>
            </div>
            {(['acc_prev', 'acc_next'] as const).map(id => (
              <div key={id} style={rectOf(id)} className={cn('flex items-center justify-center text-white font-sans text-[4vh] leading-none transition-colors',
                (state.accounts?.length || 0) < 2 && 'opacity-30', hov(id) && 'bg-white/15', prs(id) && 'bg-white/30')}>
                {id === 'acc_prev' ? '‹' : '›'}
              </div>
            ))}
            <Btn style={rectOf('acc_confirm')} hover={hov('acc_confirm')} press={prs('acc_confirm')}
              className="bg-fleeca-green text-white text-[3.1vh]">Confirm</Btn>
          </>
        )}

        {/* ── MENU ── */}
        {state.screen === 'menu' && (
          <>
            {[['menu_history', 'History'], ['menu_withdraw', 'Withdraw'], ['menu_finish', 'Finish']].map(([id, label]) => (
              <div key={id} style={rectOf(id)} className={cn('flex rounded-[0.6vh] overflow-hidden shadow-[0_0.5vh_1.2vh_rgba(0,0,0,0.22)] transition-transform duration-100',
                hov(id) && 'scale-[1.02]', prs(id) && 'scale-[0.98]')}>
                <div className={cn('w-[15.5%] flex items-center justify-center text-white text-[3vh] font-sans transition-colors', hov(id) ? 'bg-fleeca-green' : 'bg-fleeca-ink')}>›</div>
                <div className={cn('flex-1 flex items-center justify-center cond font-extrabold text-[3.3vh] transition-colors', hov(id) ? 'bg-[#eef7f0]' : 'bg-white')}>{label}</div>
              </div>
            ))}
          </>
        )}

        {/* ── WITHDRAW / HISTORY shared: tabs + panel ── */}
        {panelScreen && (
          <>
            {[['tab_history', 'History', 'history'], ['tab_withdraw', 'Withdraw', 'withdraw']].map(([id, label, scr]) => (
              <Btn key={id} style={rectOf(id)} hover={hov(id)} press={prs(id)}
                className={cn('text-white text-[2.1vh] font-bold', state.screen === scr ? 'bg-fleeca-green' : 'bg-fleeca-ink')}>{label}</Btn>
            ))}
            <div className="absolute left-[13%] top-[15%] w-[74%] h-[73.5%] bg-white rounded-[1vh] shadow-[0_1vh_3vh_rgba(0,0,0,0.18)]" />
            <div className="absolute left-[14.7%] top-[17%] w-[70.3%] h-[7%] bg-fleeca-ink rounded-[0.4vh] flex items-center justify-between px-[1.6%]">
              <p className="cond font-extrabold text-white text-[2.8vh]">{state.screen === 'withdraw' ? 'Withdraw Money' : 'Transaction History'}</p>
              <p className="cond font-bold text-white text-[1.9vh]">
                Account Balance <span className="text-[#5fe07d] text-[2.6vh] ml-[0.4vw] tabular">{money(acc?.balance)}</span>
              </p>
            </div>
          </>
        )}

        {/* ── WITHDRAW ── */}
        {state.screen === 'withdraw' && (
          <>
            <div className="absolute left-[14.7%] top-[25.8%] w-[70.3%] h-[9.2%] border-[0.25vh] border-fleeca-green rounded-[0.5vh] flex items-center justify-between px-[1.6%]">
              <p className="cond font-bold text-[1.6vh] text-black/60">Amount</p>
              <p className="font-sans font-medium text-[3.4vh] tabular flex items-center">
                {money(Number(state.amount || 0))}
                <span className="caret inline-block w-[0.18vh] h-[3.6vh] bg-fleeca-ink ml-[0.4vh]" />
              </p>
            </div>

            {quick.slice(0, 4).map((v, i) => {
              const id = `quick_${i + 1}`;
              const active = Number(state.amount) === v || hov(id);
              return (
                <Btn key={id} style={rectOf(id)} hover={false} press={prs(id)}
                  className={cn('rounded-full text-white text-[2.3vh] font-bold', active ? 'bg-fleeca-green' : 'bg-fleeca-ink')}>
                  {money(v)}
                </Btn>
              );
            })}

            {['1', '2', '3', '4', '5', '6', '7', '8', '9', 'clear', '0', 'del'].map(k => {
              const id = `key_${k}`;
              return (
                <div key={id} style={rectOf(id)} className={cn(
                  'flex items-center justify-center rounded-[0.5vh] transition-all duration-75',
                  'shadow-[0_0.45vh_0_#b9b9b9]',
                  hov(id) ? 'bg-[#d6ecdb]' : 'bg-fleeca-key',
                  prs(id) && 'translate-y-[0.35vh] shadow-[0_0.1vh_0_#b9b9b9]',
                )}>
                  {k === 'clear' ? <span className="cond font-bold text-[2vh]">Clear</span>
                    : k === 'del' ? <span className="font-sans text-[2.6vh] text-black/70">⌫</span>
                      : <span className="font-sans font-medium text-[3.1vh]">{k}</span>}
                </div>
              );
            })}

            <Btn style={rectOf('submit')} hover={hov('submit')} press={prs('submit')}
              className="bg-fleeca-green text-white text-[3.6vh] rounded-[0.5vh]">Withdraw</Btn>
            <p className="absolute left-[54.8%] top-[66.8%] font-sans font-medium text-[1.9vh] text-black/60">
              Daily limit {money(dailyLimit)}
            </p>
            {state.dailyLeft !== undefined && state.dailyLeft < dailyLimit && (
              <p className="absolute left-[54.8%] top-[70.4%] font-sans text-[1.7vh] text-black/45">Remaining today {money(state.dailyLeft)}</p>
            )}
          </>
        )}

        {/* ── HISTORY ── */}
        {state.screen === 'history' && (
          <div className="absolute left-[14.7%] top-[26.5%] w-[70.3%] h-[58%] flex flex-col">
            <div className="grid grid-cols-[18%_22%_1fr_20%] cond font-bold text-[1.6vh] text-black/50 px-[1.2%] pb-[0.8vh] border-b border-black/10">
              <span>Date</span><span>Type</span><span>Note</span><span className="text-right">Amount</span>
            </div>
            {state.historyLoading && <p className="cond font-bold text-[2.4vh] text-black/40 m-auto">Loading…</p>}
            {!state.historyLoading && (state.history?.length || 0) === 0 && (
              <p className="cond font-bold text-[2.4vh] text-black/40 m-auto">No transactions yet</p>
            )}
            {!state.historyLoading && state.history?.map((t, i) => (
              <div key={i} className={cn('grid grid-cols-[18%_22%_1fr_20%] items-center px-[1.2%] h-[13.5%] font-sans text-[1.9vh]', i % 2 === 0 && 'bg-black/[0.035] rounded-[0.4vh]')}>
                <span className="text-black/60 tabular">{t.date}</span>
                <span className="cond font-bold text-[2.1vh]">{t.type}</span>
                <span className="text-black/55 truncate pr-[1vw]">{t.note}</span>
                <span className={cn('text-right font-medium tabular', t.negative ? 'text-[#c0392b]' : 'text-fleeca-green')}>
                  {t.negative ? '-' : '+'}{money(t.amount)}
                </span>
              </div>
            ))}
          </div>
        )}

        {/* ── RESULT ── */}
        {state.screen === 'result' && state.result && (
          <>
            <div className="absolute left-[28%] top-[20%] w-[44%] h-[60%] bg-white rounded-[1vh] shadow-[0_1vh_3vh_rgba(0,0,0,0.18)] flex flex-col items-center pt-[4.5vh]">
              <div className="w-[9vh] h-[9vh] rounded-full bg-fleeca-green flex items-center justify-center">
                <svg viewBox="0 0 24 24" className="w-[5vh] h-[5vh]" fill="none" stroke="white" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5" /></svg>
              </div>
              <p className="cond font-bold text-[2.2vh] text-black/50 mt-[2.5vh]">Withdrawn</p>
              <p className="cond font-extrabold text-[6.5vh] leading-none tabular">{money(state.result.amount)}</p>
              <p className="font-sans font-medium text-[2.1vh] text-black/60 mt-[1.6vh]">{state.result.message}</p>
              <p className="cond font-bold text-[1.9vh] text-black/50 mt-[2.4vh]">
                New balance <span className="text-fleeca-green text-[2.4vh] tabular">{money(state.result.balance)}</span>
              </p>
            </div>
            <Btn style={rectOf('result_done')} hover={hov('result_done')} press={prs('result_done')}
              className="bg-fleeca-ink text-white text-[2.8vh]">Done</Btn>
          </>
        )}

        {/* ── LOADING / GOODBYE ── */}
        {(state.screen === 'loading' || state.screen === 'goodbye') && (
          <div className="absolute left-0 right-0 top-[55%] flex flex-col items-center">
            {state.screen === 'loading'
              ? <div className="spin w-[6vh] h-[6vh] rounded-full border-[0.6vh] border-black/10 border-t-fleeca-green" />
              : <p className="cond font-extrabold text-[3.2vh]">Thank you for banking with us</p>}
          </div>
        )}

        {/* Back button */}
        {['menu', 'withdraw', 'history'].includes(state.screen) && (
          <Btn style={rectOf('back')} hover={hov('back')} press={prs('back')} className="bg-fleeca-ink text-white text-[2.3vh]">‹ Back</Btn>
        )}

        {/* Processing overlay */}
        {state.processing && (
          <div className="absolute inset-0 bg-white/80 flex flex-col items-center justify-center z-40">
            <div className="spin w-[7vh] h-[7vh] rounded-full border-[0.7vh] border-black/10 border-t-fleeca-green" />
            <p className="cond font-extrabold text-[3.2vh] mt-[2.5vh]">Processing</p>
          </div>
        )}

        {/* Toast */}
        {state.toast && (
          <div className="absolute left-0 right-0 bottom-[4%] flex justify-center z-50">
            <div className="flex items-center gap-[0.8vw] bg-fleeca-ink text-white px-[2.2vw] py-[1.3vh] rounded-[0.6vh] shadow-[0_0.8vh_2vh_rgba(0,0,0,0.3)]">
              <span className="w-[1.3vh] h-[1.3vh] rounded-full bg-[#ff5a4e]" />
              <span className="cond font-bold text-[2.3vh]">{state.toast.msg}</span>
            </div>
          </div>
        )}

        {/* Cursor */}
        {cursor.visible && state.screen !== 'idle' && (
          <svg viewBox="0 0 24 24" className="absolute z-[60] pointer-events-none w-[3.4vh] h-[3.4vh] drop-shadow-[0_0.2vh_0.3vh_rgba(0,0,0,0.35)]"
            style={{ left: `${cursor.x}%`, top: `${cursor.y}%` }}>
            <path d="M3 2l15 11.2-6.6.9 3.9 7.6-2.6 1.3-3.9-7.7L3 20z" fill="white" stroke="#141414" strokeWidth="1.4" strokeLinejoin="round" />
          </svg>
        )}

      </div>
    </div>
  );
}

function Logo({ name, big }: { name: string; big?: boolean }) {
  // "FLEECA" -> FL + EE (green) + CA; other names render plain
  const n = name.toUpperCase();
  const parts: [string, boolean][] = n === 'FLEECA' ? [['FL', false], ['EE', true], ['CA', false]] : [[n, false]];
  return (
    <p className={cn('cond font-extrabold leading-none absolute tracking-tight',
      big ? 'left-0 right-0 top-[35%] text-center text-[11vh]' : 'left-[3.8%] top-[5.2%] text-[5.6vh]')}>
      {parts.map(([t, g], i) => <span key={i} className={g ? 'text-fleeca-bright' : 'text-fleeca-ink'}>{t}</span>)}
    </p>
  );
}

function Btn({ style, hover, press, className, children }: { style: CSSProperties; hover: boolean; press: boolean; className?: string; children: ReactNode }) {
  return (
    <div style={style} className={cn(
      'cond font-extrabold flex items-center justify-center rounded-[0.6vh] transition-all duration-100',
      'shadow-[0_0.4vh_1vh_rgba(0,0,0,0.18)]',
      hover && 'brightness-110 scale-[1.02]',
      press && 'scale-[0.97] brightness-95',
      className,
    )}>{children}</div>
  );
}
