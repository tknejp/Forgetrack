/* global React */
const { useState } = React;

function StatesVariant() {
  const [state, setState] = useState('empty');

  return (
    <div style={{
      position: 'relative', height: '100%',
      background:
        'radial-gradient(ellipse at top, rgba(139,92,246,0.10), transparent 60%),' +
        'var(--bg-app)',
      overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
    }}>
      <window.ScreenHeader
        kicker="HERO JOURNEY"
        title="Stavy obrazovky"
        subtitle="Empty, loading, error — pro ranou fázi appky."
      />

      {/* State switcher */}
      <div style={{
        display: 'flex', gap: 6, padding: '8px 20px 14px',
      }}>
        {[
          { id: 'empty', label: 'Prázdný' },
          { id: 'loading', label: 'Načítání' },
          { id: 'error', label: 'Chyba' },
        ].map(s => (
          <button key={s.id} onClick={() => setState(s.id)} style={{
            flex: 1,
            padding: '8px 10px',
            borderRadius: 999,
            fontSize: 11, fontWeight: 700,
            border: '1px solid',
            borderColor: state === s.id ? 'rgba(167,139,250,0.55)' : 'var(--border-soft)',
            background: state === s.id ? 'rgba(139,92,246,0.20)' : 'transparent',
            color: state === s.id ? 'var(--purple-300)' : 'var(--text-secondary)',
            cursor: 'pointer',
          }}>{s.label}</button>
        ))}
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '0 20px 110px' }}>
        {state === 'empty' && <EmptyState />}
        {state === 'loading' && <LoadingState />}
        {state === 'error' && <ErrorState />}
      </div>

      <window.TabBar />
    </div>
  );
}

function EmptyState() {
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      textAlign: 'center', paddingTop: 32,
    }}>
      {/* Decorative starting node */}
      <div style={{
        position: 'relative',
        width: 140, height: 140,
        marginBottom: 24,
      }}>
        <div style={{
          position: 'absolute', inset: 0,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(139,92,246,0.30), transparent 70%)',
        }} />
        <div style={{
          position: 'absolute', inset: '20%',
          borderRadius: '50%',
          background: 'linear-gradient(180deg, var(--purple-400), var(--purple-600))',
          display: 'grid', placeItems: 'center',
          fontSize: 32, color: '#fff', fontWeight: 800,
          boxShadow: '0 0 32px var(--purple-glow)',
        }}>1</div>
        {/* dashed path going up to nowhere */}
        <svg width="140" height="80" viewBox="0 0 140 80"
             style={{ position: 'absolute', left: 0, top: -60 }}>
          <path d="M 70 80 Q 50 50, 80 30 T 70 0"
                stroke="rgba(167,139,250,0.4)" strokeWidth="2" fill="none"
                strokeDasharray="4 6" strokeLinecap="round" />
        </svg>
      </div>

      <h2 style={{
        margin: 0, fontSize: 20, fontWeight: 800,
        color: 'var(--text-primary)', textWrap: 'balance',
      }}>Tvá hrdinská cesta začíná</h2>
      <p style={{
        margin: '10px 24px 0', fontSize: 13, color: 'var(--text-muted)',
        textWrap: 'pretty', lineHeight: 1.5,
      }}>
        Splň první quest a odemkni začátek své cesty. Každý úspěch tě posune o krok dál.
      </p>

      <button style={{
        marginTop: 24,
        padding: '14px 22px',
        borderRadius: 14,
        border: '1px solid rgba(167,139,250,0.55)',
        background: 'linear-gradient(180deg, rgba(139,92,246,0.30), rgba(124,58,237,0.45))',
        color: 'var(--text-primary)',
        fontSize: 13, fontWeight: 700,
        cursor: 'pointer',
        boxShadow: '0 8px 24px -8px var(--purple-glow)',
      }}>Začni první quest</button>

      {/* Tease — preview of upcoming milestones */}
      <div className="ft-section-label" style={{
        marginTop: 32, alignSelf: 'flex-start',
      }}>CO TĚ ČEKÁ</div>
      <div style={{
        marginTop: 10, width: '100%',
        display: 'flex', flexDirection: 'column', gap: 8,
      }}>
        {[
          { type: 'level', label: 'Level 5', sub: 'První meta' },
          { type: 'achievement', label: 'První 1 000 kroků', sub: 'Achievement' },
          { type: 'streak', label: '7denní série', sub: 'Konzistence' },
        ].map((p, i) => (
          <div key={i} className="ft-card" style={{
            padding: 12, display: 'flex', alignItems: 'center', gap: 12,
            opacity: 0.6,
          }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              border: '1.5px dashed rgba(167,139,250,0.35)',
              display: 'grid', placeItems: 'center',
              color: 'var(--text-dim)',
            }}><window.Icons.LockIcon /></div>
            <div style={{ flex: 1, textAlign: 'left' }}>
              <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-secondary)' }}>{p.label}</div>
              <div style={{ fontSize: 10, color: 'var(--text-dim)', marginTop: 2 }}>{p.sub}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function LoadingState() {
  return (
    <div style={{ paddingTop: 8 }}>
      {/* Skeleton hero card */}
      <Skeleton h={88} radius={16} />
      <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
        <Skeleton h={28} radius={999} w="22%" />
        <Skeleton h={28} radius={999} w="22%" />
        <Skeleton h={28} radius={999} w="22%" />
      </div>
      <Skeleton h={12} radius={4} w="40%" mt={20} />
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 12 }}>
        {[1,2,3,4].map(i => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <Skeleton h={36} w={36} radius={10} />
            <div style={{ flex: 1 }}>
              <Skeleton h={12} radius={4} w="70%" />
              <Skeleton h={10} radius={4} w="40%" mt={6} />
            </div>
          </div>
        ))}
      </div>

      {/* Subtle status text */}
      <div style={{
        marginTop: 28, textAlign: 'center',
        fontSize: 11, color: 'var(--text-muted)', letterSpacing: '0.06em',
      }}>
        <span style={{
          display: 'inline-block', verticalAlign: 'middle', marginRight: 8,
        }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="9" stroke="rgba(167,139,250,0.25)" strokeWidth="2"/>
            <path d="M12 3a9 9 0 019 9" stroke="var(--purple-300)" strokeWidth="2" strokeLinecap="round">
              <animateTransform attributeName="transform" type="rotate" from="0 12 12" to="360 12 12" dur="1s" repeatCount="indefinite"/>
            </path>
          </svg>
        </span>
        Načítáme tvou cestu…
      </div>
    </div>
  );
}

function Skeleton({ h, w = '100%', radius = 8, mt = 0 }) {
  return (
    <div style={{
      width: w, height: h, marginTop: mt,
      borderRadius: radius,
      background:
        'linear-gradient(90deg, rgba(255,255,255,0.04) 0%, rgba(167,139,250,0.10) 50%, rgba(255,255,255,0.04) 100%)',
      backgroundSize: '200% 100%',
      animation: 'shimmer 1.4s linear infinite',
    }} />
  );
}

function ErrorState() {
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      textAlign: 'center', paddingTop: 40,
    }}>
      <div style={{
        width: 88, height: 88, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(244,114,182,0.25), transparent 70%)',
        display: 'grid', placeItems: 'center',
        marginBottom: 18,
      }}>
        <div style={{
          width: 56, height: 56, borderRadius: '50%',
          background: 'rgba(244,114,182,0.15)',
          border: '1px solid rgba(244,114,182,0.45)',
          display: 'grid', placeItems: 'center',
          color: 'var(--rose)',
        }}>
          <svg width="26" height="26" viewBox="0 0 24 24" fill="none">
            <path d="M12 8v5M12 17v.01" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round"/>
            <path d="M10.3 3.86l-8.18 14.16A2 2 0 003.86 21h16.28a2 2 0 001.74-2.98L13.7 3.86a2 2 0 00-3.4 0z" stroke="currentColor" strokeWidth="1.8"/>
          </svg>
        </div>
      </div>

      <h2 style={{
        margin: 0, fontSize: 18, fontWeight: 800, color: 'var(--text-primary)',
      }}>Cesta se nepodařila načíst</h2>
      <p style={{
        margin: '8px 18px 0', fontSize: 12, color: 'var(--text-muted)',
        textWrap: 'pretty', lineHeight: 1.5,
      }}>
        Připojení selhalo. Zkontroluj internet a zkus to znovu — tvůj postup je v bezpečí.
      </p>

      <div style={{ display: 'flex', gap: 10, marginTop: 22 }}>
        <button style={{
          padding: '12px 18px',
          borderRadius: 12,
          border: '1px solid rgba(167,139,250,0.55)',
          background: 'rgba(139,92,246,0.18)',
          color: 'var(--purple-300)',
          fontSize: 12, fontWeight: 700,
          cursor: 'pointer',
        }}>Zkusit znovu</button>
        <button style={{
          padding: '12px 18px',
          borderRadius: 12,
          border: '1px solid var(--border-mid)',
          background: 'transparent',
          color: 'var(--text-secondary)',
          fontSize: 12, fontWeight: 600,
          cursor: 'pointer',
        }}>Hlášení chyby</button>
      </div>

      <div style={{
        marginTop: 24,
        padding: '8px 12px',
        borderRadius: 8,
        background: 'rgba(255,255,255,0.03)',
        fontSize: 10, fontFamily: 'ui-monospace, SFMono-Regular, monospace',
        color: 'var(--text-dim)',
        letterSpacing: '0.04em',
      }}>err: journey/fetch · code 503</div>
    </div>
  );
}

window.StatesVariant = StatesVariant;
