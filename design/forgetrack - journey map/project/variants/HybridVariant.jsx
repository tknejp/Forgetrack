/* global React */
const { useState } = React;

function HybridVariant() {
  const events = window.JOURNEY_EVENTS;
  const TYPES = window.JOURNEY_TYPES;

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
        title="Tvoje cesta hrdiny"
        subtitle="Mapa tvé cesty a přehled událostí."
      />

      <div className="ft-scroll" style={{
        flex: 1, overflowY: 'auto', padding: '4px 16px 110px',
      }}>
        {/* Mini map */}
        <div style={{
          position: 'relative',
          height: 180,
          borderRadius: 20,
          overflow: 'hidden',
          background:
            'radial-gradient(ellipse 60% 50% at 30% 30%, rgba(139,92,246,0.30), transparent 70%),' +
            'radial-gradient(ellipse 60% 50% at 80% 80%, rgba(63,184,175,0.20), transparent 70%),' +
            'linear-gradient(180deg, #1A1838 0%, #0F1226 100%)',
          border: '1px solid var(--border-mid)',
          padding: 12,
        }}>
          {/* Header in map */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', position: 'relative', zIndex: 2 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: 'linear-gradient(135deg, var(--purple-500), var(--purple-600))',
                display: 'grid', placeItems: 'center',
                fontWeight: 800, fontSize: 14, color: '#fff',
                boxShadow: '0 4px 12px -2px var(--purple-glow)',
              }}>48</div>
              <div>
                <div style={{ fontSize: 12, fontWeight: 800, color: 'var(--gold)' }}>DRAGON RIDER</div>
                <div style={{ fontSize: 10, color: 'var(--text-muted)', marginTop: 1 }}>81 265 / 90 000 XP</div>
              </div>
            </div>
            <div style={{
              fontSize: 10, fontWeight: 700,
              color: 'var(--purple-300)',
              padding: '5px 10px',
              borderRadius: 999,
              background: 'rgba(139,92,246,0.15)',
              border: '1px solid rgba(167,139,250,0.35)',
            }}>Otevřít mapu →</div>
          </div>

          {/* Mini path */}
          <svg width="100%" height="100" viewBox="0 0 320 100" preserveAspectRatio="none"
               style={{ position: 'absolute', left: 0, right: 0, bottom: 8 }}>
            <defs>
              <linearGradient id="hpath" x1="0" y1="0" x2="1" y2="0">
                <stop offset="0%" stopColor="#7C3AED" stopOpacity="0.9"/>
                <stop offset="100%" stopColor="#A78BFA" stopOpacity="0.9"/>
              </linearGradient>
            </defs>
            <path d="M 20 70 Q 70 30, 110 60 T 200 50 Q 240 30, 290 60"
                  stroke="url(#hpath)" strokeWidth="2.5" fill="none"
                  strokeLinecap="round"
                  filter="drop-shadow(0 0 4px rgba(167,139,250,0.6))" />
            <path d="M 290 60 Q 305 50, 310 35"
                  stroke="rgba(167,139,250,0.4)" strokeWidth="2" fill="none"
                  strokeDasharray="3 5" strokeLinecap="round" />
          </svg>

          {/* Mini checkpoints */}
          {[
            { x: 20, y: 70, type: 'quest' },
            { x: 75, y: 42, type: 'achievement' },
            { x: 130, y: 60, type: 'level', n: '40' },
            { x: 175, y: 50, type: 'quest' },
            { x: 220, y: 56, type: 'title' },
            { x: 290, y: 60, type: 'level', n: '48', current: true },
          ].map((p, i) => (
            <MiniNode key={i} {...p} />
          ))}
        </div>

        {/* Stat cluster */}
        <div style={{
          marginTop: 12,
          display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)',
          gap: 8,
        }}>
          <StatTile icon={<window.Icons.LvlIcon />} value="+15" label="LEVELY" color="gold" />
          <StatTile icon={<window.Icons.CrownIcon />} value="+3" label="TITULY" color="purple" />
          <StatTile icon={<window.Icons.ShieldIcon />} value="28" label="ACHIEVEMENTY" color="teal" small />
          <StatTile icon={<window.Icons.FlagIcon />} value="42" label="QUESTY" color="green" />
        </div>

        {/* Recent feed */}
        <div className="ft-section-label" style={{ marginTop: 18, marginBottom: 10 }}>
          POSLEDNÍ UDÁLOSTI
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {events.slice(0, 4).map(ev => <CompactRow key={ev.id} ev={ev} />)}
        </div>

        <button style={{
          marginTop: 14,
          width: '100%',
          padding: '14px 16px',
          borderRadius: 14,
          border: '1px solid rgba(167,139,250,0.55)',
          background: 'linear-gradient(180deg, rgba(139,92,246,0.30), rgba(124,58,237,0.45))',
          color: 'var(--text-primary)',
          fontSize: 13, fontWeight: 700,
          cursor: 'pointer',
          boxShadow: '0 8px 24px -8px var(--purple-glow)',
        }}>
          Zobrazit celou cestu
        </button>
      </div>

      <window.TabBar />
    </div>
  );
}

function MiniNode({ x, y, type, n, current }) {
  const colorMap = {
    level:       { bg: 'linear-gradient(180deg, #FFD980, #E5A833)', ring: 'rgba(244,193,82,0.6)', fg: '#0B0F1E' },
    title:       { bg: 'linear-gradient(180deg, #A78BFA, #7C3AED)', ring: 'rgba(167,139,250,0.6)', fg: '#fff' },
    achievement: { bg: 'linear-gradient(180deg, #6FE3D8, #2A9D94)', ring: 'rgba(63,184,175,0.6)', fg: '#0B0F1E' },
    quest:       { bg: 'linear-gradient(180deg, #6BEEB6, #25A171)', ring: 'rgba(52,211,153,0.6)', fg: '#0B0F1E' },
  };
  const c = colorMap[type];
  const size = current ? 28 : 22;
  return (
    <div style={{
      position: 'absolute',
      left: `${(x / 320) * 100}%`,
      top: y + 60,
      transform: 'translate(-50%, -50%)',
      width: size, height: size, borderRadius: '50%',
      background: c.bg,
      border: `1.5px solid ${c.ring}`,
      boxShadow: `0 0 ${current ? 14 : 8}px ${c.ring}`,
      display: 'grid', placeItems: 'center',
      color: c.fg, fontSize: 10, fontWeight: 800,
    }}>
      {n ? n : (
        type === 'title' ? <window.Icons.CrownIcon /> :
        type === 'achievement' ? <window.Icons.ShieldIcon /> :
        type === 'quest' ? <window.Icons.FlagIcon /> : null
      )}
    </div>
  );
}

function StatTile({ icon, value, label, color, small }) {
  const palette = {
    gold:   { bg: 'rgba(244,193,82,0.10)',  border: 'rgba(244,193,82,0.30)',  fg: 'var(--gold)' },
    purple: { bg: 'rgba(167,139,250,0.12)', border: 'rgba(167,139,250,0.30)', fg: 'var(--purple-300)' },
    teal:   { bg: 'rgba(63,184,175,0.10)',  border: 'rgba(63,184,175,0.30)',  fg: 'var(--teal)' },
    green:  { bg: 'rgba(52,211,153,0.10)',  border: 'rgba(52,211,153,0.30)',  fg: 'var(--green)' },
  };
  const c = palette[color];
  return (
    <div style={{
      padding: '10px 8px',
      borderRadius: 14,
      background: c.bg,
      border: `1px solid ${c.border}`,
      textAlign: 'left',
      minWidth: 0,
    }}>
      <div style={{ color: c.fg, marginBottom: 6 }}>{icon}</div>
      <div style={{
        fontSize: 9, fontWeight: 800, letterSpacing: '0.08em',
        color: c.fg, opacity: 0.9,
        whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
      }}>{label}</div>
      <div style={{
        fontSize: 18, fontWeight: 800, color: 'var(--text-primary)',
        marginTop: 2,
      }}>{value}</div>
    </div>
  );
}

function CompactRow({ ev }) {
  const titleByType = {
    level: `Level up!`,
    title: `Získán nový titul`,
    achievement: `Odemčen achievement`,
    streak: `Milestone série`,
    quest: `Dokončen quest`,
  };
  const subByType = {
    level: `Dosáhl jsi levelu ${ev.level}`,
    title: `${ev.name}${ev.from ? ` · z ${ev.from}` : ''}`,
    achievement: ev.name,
    streak: `${ev.value} dní · ${ev.domain}`,
    quest: ev.name,
  };
  const xpMap = {
    level: '+250 XP', achievement: '+300 XP', title: '+500 XP',
    quest: '+150 XP', streak: '+120 XP',
  };
  return (
    <div className="ft-card" style={{
      padding: '10px 12px',
      display: 'flex', alignItems: 'center', gap: 12,
    }}>
      <window.TypeBadge type={ev.type} size={32} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 6,
        }}>
          <div style={{
            fontSize: 12, fontWeight: 700,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{titleByType[ev.type]}</div>
          <div style={{
            fontSize: 10, fontWeight: 700, color: 'var(--gold)', flexShrink: 0,
          }}>{xpMap[ev.type]}</div>
        </div>
        <div style={{
          fontSize: 11, color: 'var(--text-muted)', marginTop: 1,
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{subByType[ev.type]}</div>
      </div>
      <div style={{
        fontSize: 9, color: 'var(--text-dim)', flexShrink: 0,
        textAlign: 'right',
      }}>{window.czRelative(ev.at)}</div>
    </div>
  );
}

window.HybridVariant = HybridVariant;
