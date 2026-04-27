/* global React */
const { useState, useRef, useEffect, useMemo } = React;

/* ──────────────────────────────────────────────────────────
   MapVariant — scrollable from start to current position.
   Each milestone is a tappable node; tap reveals info card
   inline (same content/style as Timeline feed cards).
   ────────────────────────────────────────────────────────── */

const TYPES = window.JOURNEY_TYPES;

function LvlIcon()    { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M12 4l8 8h-5v8H9v-8H4l8-8z" fill="currentColor"/></svg>; }
function CrownIcon()  { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M3 8l4 4 5-7 5 7 4-4-2 11H5L3 8z" fill="currentColor"/></svg>; }
function ShieldIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M12 3l8 3v6c0 4.5-3.5 8-8 9-4.5-1-8-4.5-8-9V6l8-3z" fill="currentColor"/></svg>; }
function FlameIcon()  { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M12 3s4 4 4 8a4 4 0 11-8 0c0-1.5.5-2 1-2.5C7 11 6 13 6 15a6 6 0 1012 0c0-5-6-12-6-12z" fill="currentColor"/></svg>; }
function FlagIcon()   { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M5 3v18M5 4h12l-2 4 2 4H5" stroke="currentColor" strokeWidth="2" fill="none" strokeLinejoin="round"/></svg>; }
function ChevronLeft(){ return <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M15 6l-6 6 6 6" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/></svg>; }
function InfoIcon()   { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.6"/><path d="M12 8v.01M12 11v5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"/></svg>; }
function LockIcon()   { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><rect x="5" y="11" width="14" height="9" rx="2" stroke="currentColor" strokeWidth="1.8"/><path d="M8 11V8a4 4 0 118 0v3" stroke="currentColor" strokeWidth="1.8"/></svg>; }
function ChevronDown(){ return <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M6 9l6 6 6-6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>; }

const COLOR_MAP = {
  level:       { fg: '#0B0F1E', bg: 'linear-gradient(180deg, #FFD980, #E5A833)', ring: 'rgba(244,193,82,0.55)', accent: '#F4C152' },
  title:       { fg: '#FFFFFF', bg: 'linear-gradient(180deg, #A78BFA, #7C3AED)', ring: 'rgba(167,139,250,0.55)', accent: '#A78BFA' },
  achievement: { fg: '#0B0F1E', bg: 'linear-gradient(180deg, #6FE3D8, #2A9D94)', ring: 'rgba(63,184,175,0.55)', accent: '#3FB8AF' },
  streak:      { fg: '#FFFFFF', bg: 'linear-gradient(180deg, #FBA976, #E26E2A)', ring: 'rgba(251,146,60,0.55)', accent: '#FB923C' },
  quest:       { fg: '#0B0F1E', bg: 'linear-gradient(180deg, #6BEEB6, #25A171)', ring: 'rgba(52,211,153,0.55)', accent: '#34D399' },
};

/* ──────────────────────────────────────────────────────────
   Map layout — vertical zigzag.
   Each event becomes a row of fixed height; the path SVG
   is one continuous curve drawn over them. Easy to port to
   Flutter as a single Path() in CustomPainter or static SVG.
   ────────────────────────────────────────────────────────── */

const ROW_H = 100;          // px per milestone row
const MAP_W = 320;          // SVG width (proportional)
const SIDE_AMP = 0.30;      // how far left/right nodes swing (0..0.5)

function nodePos(i, total) {
  // alternate left/right; gentle ease at the very ends
  const t = i / Math.max(1, total - 1);
  // 0.5 + amplitude * sin(...) gives smooth zigzag
  const x = 0.5 + SIDE_AMP * Math.sin((i + 0.5) * Math.PI);
  return { x: x * MAP_W, y: i * ROW_H + 60 };
}

function buildPathD(points) {
  if (!points.length) return '';
  let d = `M ${points[0].x} ${points[0].y}`;
  for (let i = 1; i < points.length; i++) {
    const p0 = points[i - 1];
    const p1 = points[i];
    // Smooth curve via cubic bezier — control points biased vertically
    const c1x = p0.x;
    const c1y = p0.y + (p1.y - p0.y) * 0.55;
    const c2x = p1.x;
    const c2y = p1.y - (p1.y - p0.y) * 0.55;
    d += ` C ${c1x} ${c1y}, ${c2x} ${c2y}, ${p1.x} ${p1.y}`;
  }
  return d;
}

/* Info card rendered inline under (or beside) a tapped node */
function MilestoneInfoCard({ ev, onClose }) {
  const c = COLOR_MAP[ev.type];
  const titleByType = {
    level: `Level up — Level ${ev.level}`,
    title: `Získán nový titul`,
    achievement: `Odemčen achievement`,
    streak: `Milestone série`,
    quest: `Dokončen quest`,
  };
  const subByType = {
    level: ev.title ? `Titul: ${ev.title}` : null,
    title: ev.name + (ev.from ? ` · z titulu „${ev.from}"` : ''),
    achievement: ev.name + (ev.rarity ? ` · ${ev.rarity}` : ''),
    streak: `${ev.value} dní · ${ev.domain}${ev.best ? ' · NOVÝ REKORD' : ''}`,
    quest: ev.name + (ev.questType ? ` · ${ev.questType}` : ''),
  };
  const xpMap = { level: '+250 XP', achievement: '+300 XP', title: '+500 XP', quest: '+150 XP', streak: '+120 XP' };
  return (
    <div
      onClick={(e) => e.stopPropagation()}
      style={{
        background: 'linear-gradient(180deg, rgba(40,38,76,0.85), rgba(22,22,46,0.92))',
        border: `1px solid ${c.ring}`,
        borderRadius: 14,
        padding: 12,
        boxShadow: `0 8px 24px -8px ${c.ring}, 0 0 0 1px ${c.ring}`,
        animation: 'cardIn 220ms ease-out',
      }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8 }}>
        <div style={{
          fontSize: 9, fontWeight: 800, letterSpacing: '0.14em',
          color: c.accent, textTransform: 'uppercase',
        }}>{TYPES[ev.type].label}</div>
        <div style={{ fontSize: 10, fontWeight: 700, color: 'var(--gold)' }}>{xpMap[ev.type]}</div>
      </div>
      <div style={{ fontSize: 14, fontWeight: 800, marginTop: 4, color: 'var(--text-primary)' }}>
        {titleByType[ev.type]}
      </div>
      {subByType[ev.type] && (
        <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 3, lineHeight: 1.4 }}>
          {subByType[ev.type]}
        </div>
      )}
      {ev.desc && (
        <div style={{
          fontSize: 11, color: 'var(--text-muted)', marginTop: 6,
          lineHeight: 1.5, textWrap: 'pretty',
        }}>{ev.desc}</div>
      )}
      <div style={{
        fontSize: 10, color: 'var(--text-dim)', marginTop: 6,
        display: 'flex', justifyContent: 'space-between',
      }}>
        <span>{new Date(ev.at).toLocaleDateString('cs-CZ', { day: 'numeric', month: 'long', year: 'numeric' })}</span>
        <span>{window.czRelative(ev.at)}</span>
      </div>
    </div>
  );
}

function MapNode({ ev, x, y, isCurrent, isLocked, isExpanded, onTap }) {
  const c = COLOR_MAP[ev.type];
  const size = isCurrent ? 46 : (ev.type === 'level' ? 40 : 34);
  const showsNumber = ev.type === 'level' && ev.level;

  const iconMap = {
    level: showsNumber ? <span style={{ fontSize: 13, fontWeight: 800 }}>{ev.level}</span> : <LvlIcon />,
    title: <CrownIcon />,
    achievement: <ShieldIcon />,
    streak: <FlameIcon />,
    quest: <FlagIcon />,
  };

  return (
    <button
      onClick={(e) => { e.stopPropagation(); onTap(ev.id); }}
      style={{
        position: 'absolute',
        left: `${(x / MAP_W) * 100}%`,
        top: y,
        transform: 'translate(-50%, -50%)',
        width: size, height: size, borderRadius: '50%',
        border: 'none', padding: 0, cursor: 'pointer',
        background: 'transparent',
        zIndex: isExpanded ? 5 : 3,
      }}>
      {isCurrent && (
        <div style={{
          position: 'absolute', inset: -8,
          borderRadius: '50%',
          border: `2px solid ${c.ring}`,
          animation: 'pulse 2.2s ease-out infinite',
        }} />
      )}
      <div style={{
        width: '100%', height: '100%', borderRadius: '50%',
        background: isLocked ? 'rgba(50,48,80,0.85)' : c.bg,
        border: isLocked ? '1.5px dashed rgba(167,139,250,0.35)' : `2px solid ${c.ring}`,
        boxShadow: isLocked ? 'none'
          : (isExpanded ? `0 0 0 4px rgba(255,255,255,0.06), 0 0 24px ${c.ring}` : `0 0 14px ${c.ring}`),
        display: 'grid', placeItems: 'center',
        color: isLocked ? 'rgba(167,139,250,0.55)' : c.fg,
        transition: 'box-shadow 200ms ease',
      }}>
        {isLocked ? <LockIcon /> : iconMap[ev.type]}
      </div>
    </button>
  );
}

function MilestoneRow({ ev, i, total, isCurrent, isLocked, isExpanded, onTap }) {
  const c = COLOR_MAP[ev.type];
  const { x, y } = nodePos(i, total);
  const isLeftSide = x < MAP_W / 2;

  // Floating compact label (visible when not expanded)
  const labelByType = {
    level: ev.level ? `Level ${ev.level}` : 'Level',
    title: ev.name || 'Titul',
    achievement: ev.name || 'Achievement',
    streak: `${ev.value} dní`,
    quest: ev.name || 'Quest',
  };
  const dateLabel = new Date(ev.at).toLocaleDateString('cs-CZ', { day: 'numeric', month: 'short' });

  return (
    <>
      {/* Compact label opposite the node */}
      {!isExpanded && !isLocked && (
        <div style={{
          position: 'absolute',
          top: y, left: 0, right: 0,
          transform: 'translateY(-50%)',
          padding: '0 16px',
          pointerEvents: 'none',
        }}>
          <div style={{
            position: 'absolute',
            [isLeftSide ? 'left' : 'right']: `${((isLeftSide ? x + 26 : MAP_W - x + 26) / MAP_W) * 100}%`,
            top: '50%', transform: 'translateY(-50%)',
            textAlign: isLeftSide ? 'left' : 'right',
            whiteSpace: 'nowrap',
            maxWidth: 160,
          }}>
            <div style={{
              fontSize: 12, fontWeight: 700,
              color: 'var(--text-primary)',
              lineHeight: 1.1,
              overflow: 'hidden', textOverflow: 'ellipsis',
            }}>{labelByType[ev.type]}</div>
            <div style={{
              fontSize: 9, fontWeight: 600,
              color: c.accent, opacity: 0.85,
              marginTop: 3, letterSpacing: '0.04em',
            }}>{dateLabel}{isCurrent ? ' · TADY' : ''}</div>
          </div>
        </div>
      )}

      {/* Node (sits on top of path) */}
      <MapNode
        ev={ev} x={x} y={y}
        isCurrent={isCurrent} isLocked={isLocked}
        isExpanded={isExpanded} onTap={onTap}
      />

      {/* Inline info card under the node */}
      {isExpanded && (
        <div style={{
          position: 'absolute',
          top: y + 30,
          left: 16, right: 16,
          zIndex: 4,
          pointerEvents: 'auto',
        }}>
          <MilestoneInfoCard ev={ev} />
        </div>
      )}
    </>
  );
}

function MapVariant() {
  // Order events oldest → newest so the path "starts" at the bottom of history
  // and ends at the current/locked top. We render top-to-bottom = oldest at top
  // (chronological reading order while you scroll DOWN to the future).
  // To match the brief's "start to current level" via scroll, we put oldest
  // at the top and current near the bottom; future nodes (locked) come last.
  const events = useMemo(() => {
    const completed = [...window.JOURNEY_EVENTS]
      .filter(e => new Date(e.at) <= new Date('2026-04-27T12:00:00Z'))
      .sort((a, b) => new Date(a.at) - new Date(b.at));
    // Append a couple of locked future milestones for visual continuation
    const locked = [
      { id: 'fLock1', type: 'achievement', at: '2099-01-01', name: 'Crown', _locked: true, desc: 'Odemkne se po dosažení 90 % úspěchů.' },
      { id: 'fLock2', type: 'title',       at: '2099-01-01', name: 'Mythic Champion', _locked: true, desc: 'Cíl: dosáhnout Level 50.' },
    ];
    return [...completed, ...locked];
  }, []);

  // currentId = the most recent non-locked event
  const currentId = useMemo(() => {
    const done = events.filter(e => !e._locked);
    return done[done.length - 1]?.id;
  }, [events]);

  const [expanded, setExpanded] = useState(currentId);
  const scrollRef = useRef(null);
  const total = events.length;

  // Scroll to current on mount
  useEffect(() => {
    if (!scrollRef.current) return;
    const idx = events.findIndex(e => e.id === currentId);
    if (idx < 0) return;
    const { y } = nodePos(idx, total);
    // header (~ 184px) keeps current node near vertical center
    const targetTop = Math.max(0, y - 240);
    scrollRef.current.scrollTo({ top: targetTop, behavior: 'instant' });
  }, [currentId, total]);

  // Build path points for the SVG curve
  const points = useMemo(
    () => events.map((_, i) => nodePos(i, total)),
    [events, total]
  );
  const completedCount = events.filter(e => !e._locked).length;
  const completedPoints = points.slice(0, completedCount);
  const lockedPoints    = points.slice(completedCount - 1); // include join

  const totalH = total * ROW_H + 120;

  function toggle(id) {
    setExpanded(prev => prev === id ? null : id);
  }

  return (
    <div style={{
      position: 'relative', height: '100%',
      background:
        'radial-gradient(ellipse at top, rgba(139,92,246,0.10), transparent 60%),' +
        'radial-gradient(ellipse at bottom, rgba(63,184,175,0.06), transparent 60%),' +
        'var(--bg-app)',
      overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
    }}>
      <window.ScreenHeader
        kicker="HERO JOURNEY"
        title="Tvoje cesta světem síly"
        subtitle="Posuň se zpět k začátku, klepni na milník pro detail."
      />

      {/* Status pills */}
      <div style={{ display: 'flex', gap: 10, padding: '4px 20px 12px' }}>
        <div className="ft-card" style={{
          flex: '1 1 0', display: 'flex', alignItems: 'center', gap: 10,
          padding: '10px 12px',
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10,
            background: 'linear-gradient(135deg, var(--purple-500), var(--purple-600))',
            display: 'grid', placeItems: 'center',
            fontWeight: 800, fontSize: 14, color: '#fff',
            boxShadow: '0 4px 12px -2px var(--purple-glow)',
          }}>48</div>
          <div style={{ minWidth: 0 }}>
            <div style={{ fontSize: 9, fontWeight: 700, letterSpacing: '0.12em', color: 'var(--text-muted)' }}>
              AKTUÁLNÍ LEVEL
            </div>
            <div style={{ fontSize: 13, fontWeight: 700, marginTop: 2 }}>Dragon Rider</div>
          </div>
        </div>
        <button
          onClick={() => {
            // jump to current position
            const idx = events.findIndex(e => e.id === currentId);
            const { y } = nodePos(idx, total);
            scrollRef.current?.scrollTo({ top: Math.max(0, y - 240), behavior: 'smooth' });
            setExpanded(currentId);
          }}
          style={{
            flexShrink: 0,
            padding: '0 14px',
            borderRadius: 14,
            border: '1px solid rgba(167,139,250,0.45)',
            background: 'rgba(139,92,246,0.18)',
            color: 'var(--purple-300)',
            fontSize: 11, fontWeight: 700, letterSpacing: '0.04em',
            cursor: 'pointer',
            display: 'flex', alignItems: 'center', gap: 6,
          }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="3" fill="currentColor"/>
            <circle cx="12" cy="12" r="8" stroke="currentColor" strokeWidth="1.6"/>
          </svg>
          TADY
        </button>
      </div>

      {/* Scrollable map */}
      <div
        ref={scrollRef}
        className="ft-scroll"
        onClick={() => setExpanded(null)}
        style={{
          flex: 1, overflowY: 'auto',
          padding: '0 12px 110px',
          position: 'relative',
        }}>
        <div style={{
          position: 'relative',
          height: totalH,
          borderRadius: 22,
          overflow: 'hidden',
          background:
            'radial-gradient(ellipse 70% 30% at 30% 12%, rgba(139,92,246,0.25), transparent 70%),' +
            'radial-gradient(ellipse 60% 25% at 80% 50%, rgba(63,184,175,0.15), transparent 70%),' +
            'radial-gradient(ellipse 60% 25% at 30% 88%, rgba(244,193,82,0.12), transparent 70%),' +
            'linear-gradient(180deg, #1A1838 0%, #0F1226 60%, #14122B 100%)',
          border: '1px solid var(--border-mid)',
        }}>
          {/* Mountain decor — repeating layered polygons */}
          <svg width="100%" height={totalH} viewBox={`0 0 ${MAP_W} ${totalH}`}
               preserveAspectRatio="none"
               style={{ position: 'absolute', inset: 0, opacity: 0.30, pointerEvents: 'none' }}>
            <defs>
              <linearGradient id="mtnV" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#6F5AC8" stopOpacity="0.5"/>
                <stop offset="100%" stopColor="#1A1838" stopOpacity="0"/>
              </linearGradient>
            </defs>
            {/* Decorative diagonal "ridges" along the map */}
            {Array.from({ length: Math.ceil(totalH / 320) + 1 }).map((_, i) => {
              const yo = i * 320;
              return (
                <g key={i}>
                  <polygon
                    points={`0,${yo + 200} 60,${yo + 100} 130,${yo + 170} 200,${yo + 80} 280,${yo + 160} ${MAP_W},${yo + 130} ${MAP_W},${yo + 320} 0,${yo + 320}`}
                    fill="url(#mtnV)" />
                </g>
              );
            })}
          </svg>

          {/* The path (one continuous curve) */}
          <svg width="100%" height={totalH} viewBox={`0 0 ${MAP_W} ${totalH}`}
               preserveAspectRatio="none"
               style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
            <defs>
              <linearGradient id="pathDone" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#A78BFA" stopOpacity="0.9"/>
                <stop offset="100%" stopColor="#7C3AED" stopOpacity="0.95"/>
              </linearGradient>
            </defs>
            <path
              d={buildPathD(completedPoints)}
              stroke="url(#pathDone)" strokeWidth="3" fill="none"
              strokeLinecap="round"
              filter="drop-shadow(0 0 6px rgba(167,139,250,0.5))"
            />
            <path
              d={buildPathD(lockedPoints)}
              stroke="rgba(167,139,250,0.45)" strokeWidth="2.5" fill="none"
              strokeLinecap="round" strokeDasharray="4 6"
            />
          </svg>

          {/* Milestone rows */}
          {events.map((ev, i) => (
            <MilestoneRow
              key={ev.id}
              ev={ev}
              i={i}
              total={total}
              isCurrent={ev.id === currentId}
              isLocked={!!ev._locked}
              isExpanded={expanded === ev.id}
              onTap={toggle}
            />
          ))}

          {/* "START" marker at very top */}
          <div style={{
            position: 'absolute',
            top: 14, left: 0, right: 0,
            display: 'flex', justifyContent: 'center',
            pointerEvents: 'none',
          }}>
            <div style={{
              fontSize: 9, fontWeight: 800, letterSpacing: '0.16em',
              color: 'var(--text-muted)',
              padding: '4px 10px',
              borderRadius: 999,
              background: 'rgba(20,18,42,0.7)',
              border: '1px solid var(--border-soft)',
            }}>
              ZAČÁTEK CESTY · 25. 11. 2025
            </div>
          </div>
        </div>

        {/* Legend below map */}
        <div style={{
          marginTop: 12,
          display: 'flex', gap: 6, flexWrap: 'wrap', justifyContent: 'center',
        }}>
          {Object.entries(TYPES).map(([k, v]) => {
            const c = COLOR_MAP[k];
            return (
              <div key={k} style={{
                display: 'flex', alignItems: 'center', gap: 6,
                padding: '5px 10px',
                background: 'rgba(255,255,255,0.03)',
                border: '1px solid var(--border-soft)',
                borderRadius: 999,
                fontSize: 10, fontWeight: 600,
                color: 'var(--text-secondary)',
              }}>
                <div style={{
                  width: 10, height: 10, borderRadius: '50%',
                  background: c.bg, boxShadow: `0 0 6px ${c.ring}`,
                }} />
                {v.label.split(' ')[0]}
              </div>
            );
          })}
        </div>
      </div>

      <window.TabBar />
    </div>
  );
}

/* ──────────────────────────────────────────────────────────
   Shared atoms (also used by other variants)
   ────────────────────────────────────────────────────────── */
function ScreenHeader({ kicker, title, subtitle }) {
  return (
    <div style={{ padding: '12px 20px 8px' }}>
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        color: 'var(--text-secondary)', marginBottom: 14,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <ChevronLeft />
          <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.16em' }}>{kicker}</span>
        </div>
        <div style={{ color: 'var(--text-muted)' }}><InfoIcon /></div>
      </div>
      <h1 style={{
        margin: 0, fontSize: 26, fontWeight: 800, letterSpacing: '-0.01em',
        color: 'var(--text-primary)',
      }}>{title}</h1>
      {subtitle && (
        <p style={{ margin: '6px 0 0', fontSize: 13, color: 'var(--text-muted)', textWrap: 'pretty' }}>
          {subtitle}
        </p>
      )}
    </div>
  );
}

function TabBar({ active = 'hero' }) {
  const tabs = [
    { id: 'overview', label: 'Přehled', icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><rect x="3" y="3" width="8" height="8" rx="2" stroke="currentColor" strokeWidth="1.6"/><rect x="13" y="3" width="8" height="8" rx="2" stroke="currentColor" strokeWidth="1.6"/><rect x="3" y="13" width="8" height="8" rx="2" stroke="currentColor" strokeWidth="1.6"/><rect x="13" y="13" width="8" height="8" rx="2" stroke="currentColor" strokeWidth="1.6"/></svg> },
    { id: 'quests',   label: 'Questy',  icon: <FlagIcon /> },
    { id: 'hero',     label: 'Hero',    icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke="currentColor" strokeWidth="1.6"/><path d="M4 21c0-4 4-7 8-7s8 3 8 7" stroke="currentColor" strokeWidth="1.6"/></svg> },
    { id: 'social',   label: 'Social',  icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><circle cx="9" cy="9" r="3" stroke="currentColor" strokeWidth="1.6"/><circle cx="17" cy="11" r="2.5" stroke="currentColor" strokeWidth="1.6"/><path d="M3 19c0-2.5 3-4 6-4s6 1.5 6 4M14 19c0-2 2-3 4-3s4 1 4 3" stroke="currentColor" strokeWidth="1.6"/></svg> },
  ];
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0,
      background: 'rgba(13, 16, 33, 0.92)',
      borderTop: '1px solid var(--border-soft)',
      backdropFilter: 'blur(12px)',
      padding: '10px 8px 28px',
      display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)',
      zIndex: 5,
    }}>
      {tabs.map(t => {
        const isActive = t.id === active;
        return (
          <div key={t.id} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
            padding: '6px 0',
            color: isActive ? 'var(--purple-300)' : 'var(--text-muted)',
          }}>
            <div style={{
              width: 38, height: 30, borderRadius: 10,
              display: 'grid', placeItems: 'center',
              background: isActive ? 'rgba(139,92,246,0.18)' : 'transparent',
            }}>{t.icon}</div>
            <span style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.04em' }}>{t.label}</span>
          </div>
        );
      })}
    </div>
  );
}

function TypeBadge({ type, size = 32 }) {
  const colorMap = {
    level:       { bg: 'rgba(244,193,82,0.18)',  ring: 'rgba(244,193,82,0.55)',  fg: 'var(--gold)' },
    title:       { bg: 'rgba(167,139,250,0.20)', ring: 'rgba(167,139,250,0.55)', fg: 'var(--purple-300)' },
    achievement: { bg: 'rgba(63,184,175,0.20)',  ring: 'rgba(63,184,175,0.55)',  fg: 'var(--teal)' },
    streak:      { bg: 'rgba(251,146,60,0.20)',  ring: 'rgba(251,146,60,0.55)',  fg: 'var(--orange)' },
    quest:       { bg: 'rgba(52,211,153,0.18)',  ring: 'rgba(52,211,153,0.50)',  fg: 'var(--green)' },
  };
  const c = colorMap[type];
  const iconMap = {
    level: <LvlIcon />, title: <CrownIcon />, achievement: <ShieldIcon />,
    streak: <FlameIcon />, quest: <FlagIcon />,
  };
  return (
    <div style={{
      width: size, height: size, borderRadius: 10,
      background: c.bg, border: `1px solid ${c.ring}`,
      display: 'grid', placeItems: 'center', color: c.fg,
      flexShrink: 0,
    }}>
      {iconMap[type]}
    </div>
  );
}

window.MapVariant = MapVariant;
window.ScreenHeader = ScreenHeader;
window.TabBar = TabBar;
window.TypeBadge = TypeBadge;
window.Icons = { ChevronLeft, InfoIcon, LockIcon, FlagIcon, CrownIcon, ShieldIcon, FlameIcon, LvlIcon };
