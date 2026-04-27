/* global React */
const { useState } = React;

function DetailSheetVariant() {
  const TYPES = window.JOURNEY_TYPES;
  // Pre-selected sample — title unlock event
  const ev = window.JOURNEY_EVENTS.find(e => e.id === 'e44');

  return (
    <div style={{
      position: 'relative', height: '100%',
      background:
        'radial-gradient(ellipse at top, rgba(139,92,246,0.10), transparent 60%),' +
        'var(--bg-app)',
      overflow: 'hidden',
    }}>
      {/* Dimmed background — implies modal context */}
      <window.ScreenHeader
        kicker="HERO JOURNEY"
        title="Detail události"
        subtitle="Bottom sheet po kliknutí na checkpoint."
      />
      <div style={{
        position: 'absolute', inset: 0,
        background: 'rgba(8, 10, 22, 0.65)',
        backdropFilter: 'blur(2px)',
        zIndex: 1,
      }} />

      {/* Sheet */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        background: 'linear-gradient(180deg, #1B1A36 0%, #14132A 100%)',
        borderTop: '1px solid rgba(167,139,250,0.45)',
        borderTopLeftRadius: 24, borderTopRightRadius: 24,
        padding: '12px 20px 110px',
        zIndex: 2,
        boxShadow: '0 -20px 60px rgba(0,0,0,0.6), 0 0 0 1px rgba(167,139,250,0.10)',
      }}>
        <div style={{
          width: 40, height: 4, borderRadius: 2,
          background: 'rgba(167,139,250,0.35)',
          margin: '4px auto 16px',
        }} />

        {/* Hero block — type-tinted */}
        <div style={{
          padding: 18,
          borderRadius: 18,
          background: 'linear-gradient(180deg, rgba(167,139,250,0.18), rgba(124,58,237,0.08))',
          border: '1px solid rgba(167,139,250,0.45)',
          textAlign: 'center',
          position: 'relative', overflow: 'hidden',
        }}>
          {/* glow */}
          <div style={{
            position: 'absolute', inset: '-50% -20%',
            background: 'radial-gradient(circle, rgba(167,139,250,0.30), transparent 60%)',
            pointerEvents: 'none',
          }} />
          <div style={{
            position: 'relative',
            width: 64, height: 64,
            margin: '0 auto 12px',
            borderRadius: '50%',
            background: 'linear-gradient(180deg, var(--purple-400), var(--purple-600))',
            display: 'grid', placeItems: 'center',
            color: '#fff',
            boxShadow: '0 0 24px var(--purple-glow)',
          }}>
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
              <path d="M3 8l4 4 5-7 5 7 4-4-2 11H5L3 8z" fill="currentColor"/>
            </svg>
          </div>
          <div style={{
            fontSize: 10, fontWeight: 800, letterSpacing: '0.16em',
            color: 'var(--purple-300)',
          }}>NOVÝ TITUL ODEMČEN</div>
          <div style={{
            fontSize: 24, fontWeight: 800, marginTop: 6,
            color: 'var(--text-primary)',
          }}>{ev.name}</div>
          <div style={{
            fontSize: 12, color: 'var(--text-muted)', marginTop: 4,
          }}>z titulu „{ev.from}"</div>
        </div>

        {/* Meta */}
        <div style={{
          marginTop: 14,
          display: 'grid', gridTemplateColumns: '1fr 1fr',
          gap: 8,
        }}>
          <MetaRow label="DATUM" value={new Date(ev.at).toLocaleDateString('cs-CZ', { day: 'numeric', month: 'long', year: 'numeric' })} />
          <MetaRow label="ČAS" value={new Date(ev.at).toLocaleTimeString('cs-CZ', { hour: '2-digit', minute: '2-digit' })} />
          <MetaRow label="LEVEL" value="45" />
          <MetaRow label="ODMĚNA" value="+500 XP" accent="gold" />
        </div>

        <p style={{
          margin: '14px 0 0',
          fontSize: 13, color: 'var(--text-secondary)',
          textWrap: 'pretty', lineHeight: 1.55,
        }}>
          {ev.desc} Pokračuj v denních questech, abys odemkl další titul.
        </p>

        <div style={{
          marginTop: 18, display: 'flex', gap: 10,
        }}>
          <button style={{
            flex: 1,
            padding: '12px 14px',
            borderRadius: 12,
            border: '1px solid var(--border-mid)',
            background: 'transparent',
            color: 'var(--text-secondary)',
            fontSize: 12, fontWeight: 700,
            cursor: 'pointer',
          }}>Sdílet</button>
          <button style={{
            flex: 2,
            padding: '12px 14px',
            borderRadius: 12,
            border: '1px solid rgba(167,139,250,0.55)',
            background: 'linear-gradient(180deg, rgba(139,92,246,0.30), rgba(124,58,237,0.45))',
            color: 'var(--text-primary)',
            fontSize: 12, fontWeight: 700,
            cursor: 'pointer',
          }}>Pokračovat v cestě</button>
        </div>
      </div>

      <window.TabBar />
    </div>
  );
}

function MetaRow({ label, value, accent }) {
  return (
    <div className="ft-card" style={{ padding: '10px 12px' }}>
      <div style={{
        fontSize: 9, fontWeight: 700, letterSpacing: '0.10em',
        color: 'var(--text-muted)',
      }}>{label}</div>
      <div style={{
        fontSize: 13, fontWeight: 700, marginTop: 3,
        color: accent === 'gold' ? 'var(--gold)' : 'var(--text-primary)',
      }}>{value}</div>
    </div>
  );
}

window.DetailSheetVariant = DetailSheetVariant;
