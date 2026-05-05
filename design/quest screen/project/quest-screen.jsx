// Main quest screen — composes everything

const ACTIVE_QUESTS = [
  {
    id: 'q1',
    asset: <PngIcon src="assets/activity.png" accentRgb="42, 250, 197" />,
    category: 'activity',
    title: 'Týdenní tempo aktivity',
    subtitle: 'Podle: Týdenní aktivita',
    progress: 2, total: 4,
    reward: '1035 XP',
    rewardState: 'inProgress',
    chain: [
      { state: 'done' },
      { state: 'current', label: '4' },
      { state: 'locked', label: '12' },
    ],
    details: [
      { icon: 'target', label: 'Cíl', value: 'Buď aktivní 4 dny v týdnu.' },
      { icon: 'star', label: 'Další v řadě', value: 'Legenda týdenní aktivity' },
    ],
  },
  {
    id: 'q2',
    asset: <PngIcon src="assets/double_win.png" accentRgb="160, 122, 255" />,
    category: 'victory',
    title: 'Dvojité vítězství',
    subtitle: 'Pro combo v aktuálním období',
    progress: 0, total: 2,
    reward: '805 XP',
    rewardState: 'inProgress',
    chain: [
      { state: 'current', label: '2' },
      { state: 'locked', label: '3' },
      { state: 'locked', label: '4' },
    ],
  },
  {
    id: 'q3',
    asset: <PngIcon src="assets/nutri_combo.png" accentRgb="62, 220, 160" />,
    category: 'nutrition',
    title: 'Nutriční kombo',
    subtitle: 'Pro combo v aktuálním období',
    progress: 0, total: 2,
    reward: '575 XP',
    rewardState: 'inProgress',
    chain: [
      { state: 'current', label: '2' },
      { state: 'locked', label: '3' },
      { state: 'locked', label: '4' },
    ],
  },
  {
    id: 'q4',
    asset: <PngIcon src="assets/steps.png" accentRgb="160, 122, 255" />,
    category: 'steps',
    title: 'Ujdi 100 tisíc kroků',
    subtitle: 'Podle celkového součtu · Denní kroky',
    progress: 0, total: 100000,
    reward: '920 XP',
    rewardState: 'inProgress',
    chain: [
      { state: 'current', label: '100K' },
      { state: 'locked', label: '500K' },
      { state: 'locked', label: '1M' },
    ],
  },
  {
    id: 'q5',
    asset: <PngIcon src="assets/streak.png" accentRgb="255, 174, 61" />,
    category: 'streak',
    title: 'Série kroků',
    subtitle: 'Podle: Denní kroky',
    progress: 7, total: 14,
    reward: '600 XP',
    rewardState: 'inProgress',
    chain: [
      { state: 'current', label: '7' },
      { state: 'locked', label: '14' },
      { state: 'locked', label: '30' },
    ],
  },
];

const _UNUSED_LOCKED = [
  {
    id: 'l1',
    title: 'Trojité vítězství',
    prereq: 'Dokonči Dvojité vítězství',
    reward: '915 XP',
    lockedKind: 'swords',
    chain: [
      { state: 'locked', label: '2' },
      { state: 'locked', label: '3' },
      { state: 'locked', label: '4' },
    ],
  },
  {
    id: 'l2',
    title: 'Ujdi 500 tisíc kroků',
    prereq: 'Dokonči Ujdi 100 tisíc kroků',
    reward: '1050 XP',
    lockedKind: 'steps',
    chain: [
      { state: 'locked', label: '100K' },
      { state: 'locked', label: '500K' },
      { state: 'locked', label: '1M' },
    ],
  },
  {
    id: 'l3',
    title: 'Legenda týdenní aktivity',
    prereq: 'Dokonči Týdenní tempo aktivity',
    reward: '1180 XP',
    lockedKind: 'boot',
    chain: [
      { state: 'locked', label: '4' },
      { state: 'locked', label: '12' },
      { state: 'locked', label: '20' },
    ],
  },
];

const COMPLETED_QUESTS = [
  {
    id: 'c1',
    asset: <AssetChest size={48} />,
    title: 'Dosáhni 10 000 XP',
    subtitle: 'Dokončeno dnes',
    reward: '+500 XP',
    state: 'claimable',
  },
  {
    id: 'c2',
    asset: <AssetCrystal size={48} />,
    title: 'Dosáhni 5 000 XP',
    subtitle: 'Dokončeno 3. kvě · 20:03',
    reward: 'Vyzvednuto',
    state: 'claimed',
  },
];

// ─────────────────────────────────────────────────────────────
// Header — level / profile / streak / achievements
// (kept similar to current app, slightly refined visuals)
// ─────────────────────────────────────────────────────────────
function HeaderCard() {
  return (
    <div style={{
      background: 'linear-gradient(180deg, rgba(22, 26, 44, 0.95) 0%, rgba(16, 18, 30, 0.95) 100%)',
      borderRadius: 18,
      border: '1px solid rgba(255,255,255,0.05)',
      padding: 14,
      boxShadow: '0 8px 24px -12px rgba(0,0,0,0.6)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        {/* Level badge */}
        <div style={{
          width: 54, height: 54,
          borderRadius: 14,
          background: 'linear-gradient(180deg, #2dc8a3 0%, #1e9d80 100%)',
          border: '1.5px solid #43e0bb',
          boxShadow: '0 0 14px -4px rgba(34, 211, 178, 0.5), inset 0 1px 0 rgba(255,255,255,0.25)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
          fontSize: 22, fontWeight: 800, color: '#fff',
          fontFamily: 'JetBrains Mono, monospace',
          letterSpacing: -0.5,
        }}>13</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            fontSize: 11, fontWeight: 800, letterSpacing: 1.3,
            color: '#22d3b2', textTransform: 'uppercase', marginBottom: 4,
          }}>Level 13 · Hraničář hvozdu</div>
          <div style={{
            height: 6, borderRadius: 999, background: 'rgba(20, 22, 36, 0.8)', overflow: 'hidden', marginBottom: 5,
          }}>
            <div style={{
              height: '100%', width: '12.5%',
              background: 'linear-gradient(90deg, #ffb547, #ff8a3d)',
              boxShadow: '0 0 8px rgba(255, 150, 70, 0.5)',
            }}/>
          </div>
          <div style={{ fontSize: 11.5, color: '#7c83a0', fontFamily: 'JetBrains Mono, monospace' }}>
            <span style={{ color: '#d4d8e6', fontWeight: 600 }}>530</span>
            <span style={{ color: '#5a607a' }}> / 4275 XP</span>
          </div>
        </div>
        <button style={{
          width: 36, height: 36, borderRadius: 10,
          background: 'rgba(28, 32, 50, 0.8)',
          border: '1px solid rgba(255,255,255,0.06)',
          color: '#7c83a0',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer', flexShrink: 0,
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <path d="M3 5 L7 9 L11 5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </button>
      </div>

      {/* Stat chips */}
      <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
        <StatChip
          icon={
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <path d="M8 2 Q11 5 11 8 Q11 11 8 14 Q5 11 5 8 Q5 5 8 2 Z" fill="#22d3b2" stroke="#0e3d28" strokeWidth="1"/>
              <path d="M8 5 Q9.5 7 9.5 9 Q9.5 11 8 12" stroke="#fff" strokeWidth="1" fill="none" opacity="0.5"/>
            </svg>
          }
          value="0"
          label="Odstartuj svou první výzvu"
          tint="rgba(34, 211, 178, 0.10)"
          border="rgba(34, 211, 178, 0.20)"
        />
        <StatChip
          icon={
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <path d="M8 2 L13 5 V9 Q13 12 8 14 Q3 12 3 9 V5 Z" fill="#8b5fe0" stroke="#2d1759" strokeWidth="1"/>
              <path d="M6 8 L7.5 9.5 L10 7" stroke="#fff" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
            </svg>
          }
          value="16"
          label="Úspěchy"
          tint="rgba(139, 95, 224, 0.12)"
          border="rgba(139, 95, 224, 0.25)"
        />
      </div>
    </div>
  );
}

function StatChip({ icon, value, label, tint, border }) {
  return (
    <div style={{
      flex: 1,
      background: tint,
      borderRadius: 12,
      border: `1px solid ${border}`,
      padding: '8px 10px',
      display: 'flex', alignItems: 'center', gap: 8,
      minWidth: 0,
    }}>
      <div style={{ flexShrink: 0 }}>{icon}</div>
      <div style={{ minWidth: 0 }}>
        <div style={{
          fontSize: 16, fontWeight: 800, color: '#f0f2fa',
          fontFamily: 'JetBrains Mono, monospace', lineHeight: 1,
        }}>{value}</div>
        <div style={{
          fontSize: 10.5, color: '#7c83a0', fontWeight: 600,
          marginTop: 2,
          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
        }}>{label}</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Bottom nav
// ─────────────────────────────────────────────────────────────
function BottomNav() {
  const items = [
    {
      id: 'overview',
      label: 'Přehled',
      icon: (active) => (
        <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
          <rect x="3" y="3" width="7" height="7" rx="1.5" stroke={active ? '#fff' : '#5a607a'} strokeWidth="1.6"/>
          <rect x="12" y="3" width="7" height="7" rx="1.5" stroke={active ? '#fff' : '#5a607a'} strokeWidth="1.6"/>
          <rect x="3" y="12" width="7" height="7" rx="1.5" stroke={active ? '#fff' : '#5a607a'} strokeWidth="1.6"/>
          <rect x="12" y="12" width="7" height="7" rx="1.5" stroke={active ? '#fff' : '#5a607a'} strokeWidth="1.6"/>
        </svg>
      ),
    },
    {
      id: 'quests',
      label: 'Questy',
      active: true,
      icon: (active) => (
        <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
          <path d="M5 3 V19 M5 4 L17 4 L14 8 L17 12 L5 12" stroke={active ? '#fff' : '#5a607a'} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" fill={active ? 'rgba(255,255,255,0.15)' : 'none'}/>
        </svg>
      ),
    },
    {
      id: 'hero',
      label: 'Hero',
      icon: (active) => (
        <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
          <circle cx="11" cy="7" r="3.5" stroke={active ? '#fff' : '#5a607a'} strokeWidth="1.6"/>
          <path d="M4 19 Q4 13 11 13 Q18 13 18 19" stroke={active ? '#fff' : '#5a607a'} strokeWidth="1.6" strokeLinecap="round" fill="none"/>
        </svg>
      ),
    },
    {
      id: 'social',
      label: 'Social',
      icon: (active) => (
        <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
          <circle cx="8" cy="8" r="3" stroke={active ? '#fff' : '#5a607a'} strokeWidth="1.6"/>
          <circle cx="16" cy="9" r="2.5" stroke={active ? '#fff' : '#5a607a'} strokeWidth="1.6"/>
          <path d="M2 18 Q2 13 8 13 Q14 13 14 18" stroke={active ? '#fff' : '#5a607a'} strokeWidth="1.6" strokeLinecap="round" fill="none"/>
          <path d="M14 16 Q14 12 18 12 Q21 12 21 16" stroke={active ? '#fff' : '#5a607a'} strokeWidth="1.5" strokeLinecap="round" fill="none"/>
        </svg>
      ),
    },
  ];
  return (
    <div style={{
      borderTop: '1px solid rgba(255,255,255,0.05)',
      background: 'rgba(8, 9, 18, 0.95)',
      backdropFilter: 'blur(12px)',
      padding: '8px 8px 4px',
      display: 'flex', justifyContent: 'space-around',
    }}>
      {items.map(it => (
        <button key={it.id} style={{
          flex: 1, background: 'transparent', border: 'none', cursor: 'pointer',
          padding: '6px 4px', borderRadius: 12,
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
          fontFamily: 'inherit',
        }}>
          {it.active ? (
            <div style={{
              padding: '5px 16px', borderRadius: 999,
              background: 'linear-gradient(180deg, #8b5fe0 0%, #6a3fc7 100%)',
              boxShadow: '0 0 14px -4px rgba(139, 95, 224, 0.7), inset 0 1px 0 rgba(255,255,255,0.25)',
            }}>{it.icon(true)}</div>
          ) : it.icon(false)}
          <span style={{
            fontSize: 10.5, fontWeight: 700, letterSpacing: 0.2,
            color: it.active ? '#c9b6ff' : '#5a607a',
          }}>{it.label}</span>
        </button>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Status bar (custom, dark)
// ─────────────────────────────────────────────────────────────
function StatusBar() {
  return (
    <div style={{
      height: 36, padding: '0 18px',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      position: 'relative',
      fontFamily: 'system-ui, sans-serif',
      color: '#fff',
      fontSize: 14, fontWeight: 600,
    }}>
      <span>15:12</span>
      <div style={{
        position: 'absolute', left: '50%', top: 8, transform: 'translateX(-50%)',
        width: 22, height: 22, borderRadius: '50%', background: '#000',
      }} />
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <svg width="14" height="14" viewBox="0 0 14 14" fill="#fff"><path d="M7 1 L7 9 M3 5 L7 1 L11 5 M2 11 L12 11 L11 13 L3 13 Z" stroke="#fff" strokeWidth="1.4" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
        <svg width="14" height="14" viewBox="0 0 14 14" fill="#fff"><path d="M7 11 L7 11.01 M3.5 8 Q7 5 10.5 8 M1 5 Q7 0 13 5" stroke="#fff" strokeWidth="1.3" fill="none" strokeLinecap="round"/></svg>
        <svg width="16" height="14" viewBox="0 0 16 14" fill="#fff"><rect x="1" y="6" width="2" height="6" rx="0.5"/><rect x="4.5" y="4" width="2" height="8" rx="0.5"/><rect x="8" y="2" width="2" height="10" rx="0.5"/><rect x="11.5" y="0" width="2" height="12" rx="0.5"/></svg>
        <div style={{
          width: 26, height: 13, borderRadius: 4,
          background: '#fff', display: 'flex', alignItems: 'center',
          padding: '0 2px', position: 'relative',
        }}>
          <svg width="6" height="6" viewBox="0 0 6 6" style={{ position: 'absolute', left: 3 }}><path d="M3 1 L1 3 L3 3 L2 5 L4 3 L3 3 Z" fill="#000"/></svg>
          <span style={{ marginLeft: 9, fontSize: 9, fontWeight: 800, color: '#000' }}>63</span>
          <div style={{
            position: 'absolute', right: -2, top: 3, width: 2, height: 7,
            background: '#fff', borderRadius: 1,
          }}/>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Main app
// ─────────────────────────────────────────────────────────────
function QuestApp() {
  const [expandedId, setExpandedId] = React.useState('q1');

  return (
    <div style={{
      width: 412, height: 892,
      borderRadius: 36,
      overflow: 'hidden',
      background: '#05070f',
      border: '8px solid #1a1c28',
      boxShadow: '0 40px 80px -20px rgba(0,0,0,0.7), 0 0 0 1px rgba(255,255,255,0.05)',
      display: 'flex', flexDirection: 'column',
      position: 'relative',
    }}>
      {/* Background glows */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: `
          radial-gradient(ellipse 70% 40% at 30% 0%, rgba(124, 92, 255, 0.18), transparent 70%),
          radial-gradient(ellipse 60% 35% at 80% 100%, rgba(34, 211, 178, 0.10), transparent 70%)
        `,
      }} />

      <StatusBar />

      <div style={{ flex: 1, overflow: 'auto', position: 'relative', zIndex: 1 }}>
        <div style={{ padding: '6px 16px 16px' }}>
          {/* Title */}
          <div style={{
            fontSize: 11, fontWeight: 800, letterSpacing: 1.4,
            color: '#7c5fe0', textTransform: 'uppercase', marginBottom: 4,
          }}>Questy</div>
          <div style={{
            fontSize: 24, fontWeight: 800, color: '#f4f5fa',
            letterSpacing: -0.5, marginBottom: 16,
          }}>Tvoje questy a odměny</div>

          {/* Header card */}
          <HeaderCard />

          {/* Active section */}
          <div style={{ marginTop: 22 }}>
            <SectionHeader
              accent="#a07aff"
              vivid
              icon={<svg width="12" height="12" viewBox="0 0 14 14" fill="none"><path d="M7 1 L8.6 4.5 L12.5 5 L9.7 7.7 L10.4 11.5 L7 9.7 L3.6 11.5 L4.3 7.7 L1.5 5 L5.4 4.5 Z" fill="currentColor"/></svg>}
              title="Aktivní questy"
              count="5 aktivních"
            />
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {ACTIVE_QUESTS.map(q => (
                <ActiveQuestCard
                  key={q.id}
                  quest={q}
                  expanded={expandedId === q.id}
                  onToggle={() => setExpandedId(expandedId === q.id ? null : q.id)}
                />
              ))}
            </div>
          </div>

          {/* Locked section removed — future quests are hinted via active card chain previews only */}

          {/* Completed section */}
          <div style={{ marginTop: 22 }}>
            <SectionHeader
              accent="#4ec494"
              icon={<svg width="14" height="14" viewBox="0 0 14 14" fill="none"><circle cx="7" cy="7" r="5.5" stroke="currentColor" strokeWidth="1.4" fill="none"/><path d="M4.5 7 L6.5 9 L9.5 5.5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" fill="none"/></svg>}
              title="Dokončené"
              count="2 dokončené"
            />
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {COMPLETED_QUESTS.map(q => <CompletedQuestRow key={q.id} quest={q} />)}
            </div>
          </div>

          <div style={{ height: 12 }} />
        </div>
      </div>

      <BottomNav />
    </div>
  );
}

Object.assign(window, { QuestApp });
