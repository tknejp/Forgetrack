/* global React */
const { useState, useMemo } = React;

function TimelineVariant() {
  const events = window.JOURNEY_EVENTS;
  const TYPES = window.JOURNEY_TYPES;
  const [filter, setFilter] = useState('all');

  const filters = [
    { id: 'all', label: 'Vše' },
    { id: 'level', label: 'Levely' },
    { id: 'title', label: 'Tituly' },
    { id: 'achievement', label: 'Achievementy' },
    { id: 'quest', label: 'Questy' },
    { id: 'streak', label: 'Série' },
  ];

  const filtered = filter === 'all' ? events : events.filter(e => e.type === filter);

  // group by month
  const groups = useMemo(() => {
    const m = new Map();
    filtered.forEach(e => {
      const key = window.czMonth(e.at);
      if (!m.has(key)) m.set(key, []);
      m.get(key).push(e);
    });
    return Array.from(m.entries());
  }, [filtered]);

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
        title="Tvoje cesta v čase"
        subtitle="Přehled všech tvých dobrodružství."
      />

      {/* Filter pills */}
      <div className="ft-scroll" style={{
        display: 'flex', gap: 8, padding: '8px 20px 14px',
        overflowX: 'auto', scrollbarWidth: 'none',
      }}>
        {filters.map(f => (
          <button key={f.id} onClick={() => setFilter(f.id)} style={{
            flexShrink: 0,
            padding: '8px 14px',
            borderRadius: 999,
            fontSize: 12, fontWeight: 700,
            border: '1px solid',
            borderColor: filter === f.id ? 'rgba(167,139,250,0.55)' : 'var(--border-soft)',
            background: filter === f.id ? 'rgba(139,92,246,0.20)' : 'rgba(255,255,255,0.02)',
            color: filter === f.id ? 'var(--purple-300)' : 'var(--text-secondary)',
            cursor: 'pointer',
          }}>{f.label}</button>
        ))}
      </div>

      {/* Scrollable feed */}
      <div className="ft-scroll" style={{
        flex: 1, overflowY: 'auto', padding: '0 20px 110px',
      }}>
        {groups.map(([monthLabel, items], gi) => (
          <div key={monthLabel} style={{ display: 'flex', gap: 14, marginTop: gi === 0 ? 0 : 18 }}>
            {/* Left rail with date + dots */}
            <div style={{
              position: 'relative', width: 56, flexShrink: 0,
              paddingTop: 4,
            }}>
              <div style={{
                fontSize: 10, fontWeight: 700, letterSpacing: '0.10em',
                color: 'var(--text-muted)', textTransform: 'uppercase',
                marginBottom: 4,
              }}>
                {monthLabel.split(' ')[0]}
              </div>
              <div style={{
                fontSize: 9, color: 'var(--text-dim)',
              }}>{monthLabel.split(' ')[1]}</div>
              {/* Vertical line */}
              <div style={{
                position: 'absolute',
                left: 50, top: 6, bottom: 0,
                width: 2,
                background: 'linear-gradient(180deg, rgba(167,139,250,0.45), rgba(167,139,250,0.05))',
              }} />
            </div>
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>
              {items.map(ev => <FeedCard key={ev.id} ev={ev} />)}
            </div>
          </div>
        ))}
      </div>

      <window.TabBar />
    </div>
  );
}

function FeedCard({ ev }) {
  const TYPES = window.JOURNEY_TYPES;
  const meta = TYPES[ev.type];
  const accentMap = {
    level: 'rgba(244,193,82,0.35)',
    title: 'rgba(167,139,250,0.45)',
    achievement: 'rgba(63,184,175,0.40)',
    streak: 'rgba(251,146,60,0.40)',
    quest: 'rgba(52,211,153,0.35)',
  };

  const titleByType = {
    level: `Level up — Level ${ev.level}`,
    title: `Získán nový titul`,
    achievement: `Odemčen achievement`,
    streak: `Milestone série`,
    quest: `Dokončen quest`,
  };

  const subByType = {
    level: ev.title ? `Titul: ${ev.title}` : null,
    title: ev.name + (ev.from ? ` (z ${ev.from})` : ''),
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
      padding: 12,
      borderColor: accentMap[ev.type],
      display: 'flex', alignItems: 'center', gap: 12,
      position: 'relative',
    }}>
      <window.TypeBadge type={ev.type} size={36} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
          gap: 8,
        }}>
          <div style={{
            fontSize: 13, fontWeight: 700, color: 'var(--text-primary)',
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{titleByType[ev.type]}</div>
          <div style={{
            fontSize: 10, fontWeight: 700, letterSpacing: '0.04em',
            color: 'var(--gold)',
            flexShrink: 0,
          }}>{xpMap[ev.type]}</div>
        </div>
        {subByType[ev.type] && (
          <div style={{
            fontSize: 11, color: 'var(--text-muted)', marginTop: 2,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{subByType[ev.type]}</div>
        )}
        <div style={{
          fontSize: 10, color: 'var(--text-dim)', marginTop: 4,
        }}>{window.czRelative(ev.at)} · {new Date(ev.at).toLocaleDateString('cs-CZ')}</div>
      </div>
    </div>
  );
}

window.TimelineVariant = TimelineVariant;
window.FeedCard = FeedCard;
