// Quest UI building blocks — refined v2
// Hierarchy: header → dominant progress → subtle inline chain → optional 2 detail rows

// ─────────────────────────────────────────────────────────────
// Category accent tokens — palette switches by Vibe tweak
// ─────────────────────────────────────────────────────────────

// Each vibe defines hex+rgb-triple for the 5 categories. The token shapes
// (soft/strong/fill/glow) are derived once at lookup time so adding a vibe
// only means listing 5 colors.
const VIBES = {
  mystic: {
    bg: { stripe: 'rgba(124, 92, 255, 0.18)', counter: 'rgba(34, 211, 178, 0.10)' },
    cards: {
      activity: { hex: '#22d3b2', rgb: '42, 250, 197',  fill2: '#6deaff' },
      victory:  { hex: '#a07aff', rgb: '160, 122, 255', fill2: '#c896ff' },
      nutrition:{ hex: '#3edca0', rgb: '62, 220, 160',  fill2: '#6df0c4' },
      steps:    { hex: '#5b8eff', rgb: '91, 142, 255',  fill2: '#8ab2ff' },
      streak:   { hex: '#ffae3d', rgb: '255, 174, 61',  fill2: '#ffd35a' },
    },
    expandedBg: 'linear-gradient(180deg, rgba(36, 28, 60, 0.92) 0%, rgba(22, 22, 40, 0.95) 100%)',
    expandedBorder: 'rgba(180, 140, 255, 0.45)',
    expandedShadowRgb: '160, 110, 255',
    sectionAccent: '#a07aff',
    titleAccent: '#7c5fe0',
    detailAccent: '#7c5fe0',
  },
  ember: {
    bg: { stripe: 'rgba(255, 120, 50, 0.20)', counter: 'rgba(220, 60, 80, 0.10)' },
    cards: {
      activity: { hex: '#ff7a3d', rgb: '255, 122, 61',  fill2: '#ffb070' },
      victory:  { hex: '#e6394d', rgb: '230, 57, 77',   fill2: '#ff7888' },
      nutrition:{ hex: '#ffc34d', rgb: '255, 195, 77',  fill2: '#ffe080' },
      steps:    { hex: '#c66a3a', rgb: '198, 106, 58',  fill2: '#e89866' },
      streak:   { hex: '#ff5050', rgb: '255, 80, 80',   fill2: '#ff8a8a' },
    },
    expandedBg: 'linear-gradient(180deg, rgba(60, 28, 22, 0.92) 0%, rgba(30, 18, 18, 0.95) 100%)',
    expandedBorder: 'rgba(255, 140, 80, 0.45)',
    expandedShadowRgb: '255, 110, 60',
    sectionAccent: '#ff8a4d',
    titleAccent: '#ff7a3d',
    detailAccent: '#e6394d',
  },
  aurora: {
    bg: { stripe: 'rgba(34, 211, 238, 0.18)', counter: 'rgba(160, 90, 255, 0.10)' },
    cards: {
      activity: { hex: '#22d3ee', rgb: '34, 211, 238',  fill2: '#6deaff' },
      victory:  { hex: '#5b7cff', rgb: '91, 124, 255',  fill2: '#8aa4ff' },
      nutrition:{ hex: '#83f0a8', rgb: '131, 240, 168', fill2: '#b0fac6' },
      steps:    { hex: '#7c5fe0', rgb: '124, 95, 224',  fill2: '#a487f0' },
      streak:   { hex: '#e066ff', rgb: '224, 102, 255', fill2: '#f098ff' },
    },
    expandedBg: 'linear-gradient(180deg, rgba(20, 36, 60, 0.92) 0%, rgba(16, 22, 40, 0.95) 100%)',
    expandedBorder: 'rgba(100, 200, 255, 0.50)',
    expandedShadowRgb: '90, 180, 255',
    sectionAccent: '#22d3ee',
    titleAccent: '#22d3ee',
    detailAccent: '#5b7cff',
  },
  crimson: {
    bg: { stripe: 'rgba(255, 60, 110, 0.20)', counter: 'rgba(180, 50, 90, 0.12)' },
    cards: {
      activity: { hex: '#ff4d8a', rgb: '255, 77, 138',  fill2: '#ff8ab0' },
      victory:  { hex: '#dc2848', rgb: '220, 40, 72',   fill2: '#ff5c7a' },
      nutrition:{ hex: '#ff8a3d', rgb: '255, 138, 61',  fill2: '#ffb070' },
      steps:    { hex: '#ff66c4', rgb: '255, 102, 196', fill2: '#ff98d6' },
      streak:   { hex: '#ffc850', rgb: '255, 200, 80',  fill2: '#ffe085' },
    },
    expandedBg: 'linear-gradient(180deg, rgba(60, 18, 32, 0.92) 0%, rgba(28, 14, 22, 0.95) 100%)',
    expandedBorder: 'rgba(255, 100, 140, 0.50)',
    expandedShadowRgb: '255, 80, 120',
    sectionAccent: '#ff4d8a',
    titleAccent: '#ff4d8a',
    detailAccent: '#dc2848',
  },
};

// Live tweaks read by every render. App sets these via setQuestTweaks().
window.__QUEST_TWEAKS = window.__QUEST_TWEAKS || {
  vibe: 'mystic',
  density: 'cozy',   // compact | cozy | spacious
  glow: 100,         // 0..200 (%)
};

function getVibe() { return VIBES[window.__QUEST_TWEAKS.vibe] || VIBES.mystic; }
function getGlowMul() { return (window.__QUEST_TWEAKS.glow || 0) / 100; }
function getDensity() {
  const d = window.__QUEST_TWEAKS.density;
  if (d === 'compact') return {
    cardPad: '10px 12px', cardGap: 8, cardRadius: 14,
    headerGap: 10, sectionMargin: 16, betweenLabels: 7,
    progressMt: 9, progressLabelMb: 4, chainMt: 7, expandedDivider: 9,
    titleSize: 14.5, subtitleSize: 11.5, sectionGap: 8,
  };
  if (d === 'spacious') return {
    cardPad: '17px 18px', cardGap: 14, cardRadius: 18,
    headerGap: 14, sectionMargin: 28, betweenLabels: 12,
    progressMt: 16, progressLabelMb: 8, chainMt: 13, expandedDivider: 16,
    titleSize: 16.5, subtitleSize: 13, sectionGap: 12,
  };
  return { // cozy (default)
    cardPad: '13px 14px', cardGap: 10, cardRadius: 16,
    headerGap: 12, sectionMargin: 22, betweenLabels: 9,
    progressMt: 12, progressLabelMb: 6, chainMt: 10, expandedDivider: 12,
    titleSize: 15.5, subtitleSize: 12.5, sectionGap: 10,
  };
}

// Glow-modulated alpha — clamps so 0% glow goes flat, 200% punches through.
function gA(base) { return Math.max(0, Math.min(1, base * getGlowMul())); }

function cat(c) {
  const v = getVibe().cards;
  const e = v[c] || v.activity;
  const r = e.rgb;
  return {
    hex: e.hex,
    soft: `rgba(${r}, 0.20)`,
    strong: `rgba(${r}, 0.60)`,
    fill: `linear-gradient(90deg, ${e.hex} 0%, ${e.fill2} 100%)`,
    glow: r,
  };
}

// ─────────────────────────────────────────────────────────────
// XP / Reward Pill
// ─────────────────────────────────────────────────────────────
function XpPill({ label, state = 'inProgress' }) {
  const styles = {
    inProgress: {
      bg: 'rgba(30, 34, 50, 0.85)',
      border: '1px solid rgba(120, 130, 160, 0.14)',
      color: '#9097b0',
      iconColor: '#6e7595',
    },
    locked: {
      bg: 'rgba(22, 24, 36, 0.55)',
      border: '1px solid rgba(80, 86, 110, 0.18)',
      color: '#6a7090',
      iconColor: '#525878',
    },
    gold: {
      bg: 'linear-gradient(180deg, #ffd35a 0%, #f2a82e 100%)',
      border: '1px solid #ffe28a',
      color: '#3a2700',
      iconColor: '#3a2700',
      shadow: '0 0 12px -2px rgba(255, 200, 70, 0.5), inset 0 1px 0 rgba(255,255,255,0.4)',
    },
    claimed: {
      bg: 'rgba(38, 90, 64, 0.22)',
      border: '1px solid rgba(94, 200, 140, 0.25)',
      color: '#6cc89a',
      iconColor: '#5fc593',
    },
  }[state];

  const Icon = state === 'locked'
    ? <svg width="10" height="10" viewBox="0 0 12 12" fill="none"><rect x="2.5" y="5.5" width="7" height="5" rx="1" fill={styles.iconColor}/><path d="M4 5.5 V4 a2 2 0 0 1 4 0 V5.5" stroke={styles.iconColor} strokeWidth="1.3" fill="none"/></svg>
    : state === 'claimed'
    ? <svg width="11" height="11" viewBox="0 0 12 12" fill="none"><path d="M2.5 6.5 L5 9 L9.5 3.5" stroke={styles.iconColor} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none"/></svg>
    : state === 'gold'
    ? <svg width="11" height="11" viewBox="0 0 12 12" fill="none"><path d="M6 1 L7.4 4.5 L11 5 L8.5 7.5 L9.2 11 L6 9.2 L2.8 11 L3.5 7.5 L1 5 L4.6 4.5 Z" fill={styles.iconColor}/></svg>
    : null;

  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      padding: state === 'inProgress' ? '4px 10px' : '4px 9px',
      borderRadius: 999,
      background: styles.bg,
      border: styles.border,
      boxShadow: styles.shadow || 'none',
      fontSize: 11.5, fontWeight: 700, letterSpacing: 0.2,
      color: styles.color,
      whiteSpace: 'nowrap',
      flexShrink: 0,
      fontFamily: 'JetBrains Mono, monospace',
    }}>
      {Icon}
      <span>{label}</span>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Inline chain — small, subtle, secondary
// ─────────────────────────────────────────────────────────────
function InlineChain({ nodes, muted = false, accent }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      opacity: muted ? 0.7 : 1,
    }}>
      {nodes.map((n, i) => (
        <React.Fragment key={i}>
          <InlineChainNode {...n} accent={accent} />
          {i < nodes.length - 1 && (
            <span style={{
              width: 10, height: 1,
              borderTop: n.state === 'done'
                ? '1px solid rgba(34, 211, 178, 0.5)'
                : '1px dotted rgba(110, 118, 145, 0.35)',
            }} />
          )}
        </React.Fragment>
      ))}
    </div>
  );
}

function InlineChainNode({ state, label, accent }) {
  const a = cat(accent);
  const baseStyle = {
    height: 18,
    minWidth: 18,
    padding: label && label.length > 1 ? '0 6px' : 0,
    borderRadius: 999,
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 3,
    fontFamily: 'JetBrains Mono, monospace',
    fontSize: 9.5, fontWeight: 700,
    letterSpacing: 0.3,
    flexShrink: 0,
  };
  if (state === 'done') {
    return (
      <span style={{
        ...baseStyle,
        background: 'rgba(34, 211, 178, 0.18)',
        border: '1px solid rgba(34, 211, 178, 0.65)',
        boxShadow: '0 0 6px -1px rgba(34, 211, 178, 0.45)',
      }}>
        <svg width="8" height="8" viewBox="0 0 12 12" fill="none">
          <path d="M2.5 6.5 L5 9 L9.5 3.5" stroke="#22d3b2" strokeWidth="2.3" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
        </svg>
      </span>
    );
  }
  if (state === 'current') {
    return (
      <span style={{
        ...baseStyle,
        background: a.soft,
        border: `1px solid ${a.strong}`,
        color: '#fff',
        boxShadow: `0 0 8px -1px rgba(${a.glow}, 0.65), inset 0 0 4px rgba(255,255,255,0.18)`,
        textShadow: `0 0 6px rgba(${a.glow}, 0.7)`,
      }}>{label}</span>
    );
  }
  // locked
  return (
    <span style={{
      ...baseStyle,
      background: 'transparent',
      border: '1px dashed rgba(110, 118, 145, 0.30)',
      color: '#5a607a',
      gap: 2,
    }}>
      <svg width="7" height="7" viewBox="0 0 12 12" fill="none">
        <rect x="2.5" y="5.5" width="7" height="5" rx="1" fill="#5a607a"/>
        <path d="M4 5.5 V4 a2 2 0 0 1 4 0 V5.5" stroke="#5a607a" strokeWidth="1.3" fill="none"/>
      </svg>
      {label && <span>{label}</span>}
    </span>
  );
}

// ─────────────────────────────────────────────────────────────
// Progress bar — taller, more prominent
// ─────────────────────────────────────────────────────────────
function ProgressBar({ pct, full = false, height = 8, accent }) {
  const a = cat(accent);
  return (
    <div style={{
      height, width: '100%',
      borderRadius: 999,
      background: 'rgba(8, 10, 20, 0.95)',
      overflow: 'hidden',
      boxShadow: 'inset 0 1px 2px rgba(0,0,0,0.6), inset 0 0 0 1px rgba(255,255,255,0.02)',
      position: 'relative',
    }}>
      <div style={{
        height: '100%',
        width: `${Math.max(pct, 0)}%`,
        background: full
          ? 'linear-gradient(90deg, #ffd35a, #f2a82e)'
          : a.fill,
        borderRadius: 999,
        boxShadow: full
          ? '0 0 12px rgba(255, 200, 70, 0.7), 0 0 4px rgba(255, 220, 120, 0.6)'
          : `0 0 12px rgba(${a.glow}, 0.65), 0 0 3px rgba(${a.glow}, 0.55)`,
        transition: 'width 0.3s ease',
        position: 'relative',
      }}>
        <span style={{
          position: 'absolute', inset: 0, borderRadius: 999,
          background: 'linear-gradient(180deg, rgba(255,255,255,0.35) 0%, transparent 50%)',
        }}/>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Active quest card — refined hierarchy
// ─────────────────────────────────────────────────────────────
function ActiveQuestCard({ quest, expanded = false, onToggle }) {
  const pct = (quest.progress / quest.total) * 100;
  const a = cat(quest.category);
  return (
    <div onClick={onToggle} style={{
      background: expanded
        ? 'linear-gradient(180deg, rgba(36, 28, 60, 0.92) 0%, rgba(22, 22, 40, 0.95) 100%)'
        : `linear-gradient(180deg, rgba(20, 22, 36, 0.85) 0%, rgba(14, 16, 26, 0.85) 100%)`,
      borderRadius: 16,
      border: expanded
        ? '1px solid rgba(180, 140, 255, 0.45)'
        : `1px solid rgba(${a.glow}, 0.14)`,
      boxShadow: expanded
        ? '0 0 0 1px rgba(160, 110, 255, 0.18), 0 0 28px -6px rgba(160, 110, 255, 0.35), 0 12px 28px -10px rgba(124, 92, 255, 0.40)'
        : `0 0 16px -10px rgba(${a.glow}, 0.45), 0 4px 14px -8px rgba(0,0,0,0.5)`,
      padding: '13px 14px',
      cursor: 'pointer',
      transition: 'all 0.2s ease',
      position: 'relative',
      overflow: 'hidden',
    }}>
      {/* category accent stripe (left edge) */}
      {!expanded && (
        <span style={{
          position: 'absolute', left: 0, top: 14, bottom: 14, width: 2,
          borderRadius: 999,
          background: `linear-gradient(180deg, ${a.hex}, transparent)`,
          boxShadow: `0 0 8px rgba(${a.glow}, 0.5)`,
          opacity: 0.7,
        }}/>
      )}
      {/* corner aura */}
      {!expanded && (
        <span style={{
          position: 'absolute', top: -20, left: -20, width: 100, height: 100,
          background: `radial-gradient(circle, rgba(${a.glow}, 0.10), transparent 65%)`,
          pointerEvents: 'none',
        }}/>
      )}
      {expanded && (
        <div style={{
          position: 'absolute', inset: 0, borderRadius: 16, pointerEvents: 'none',
          background: 'radial-gradient(ellipse 80% 50% at 0% 0%, rgba(160, 110, 255, 0.10), transparent 60%)',
        }}/>
      )}
      {/* HEADER: asset · title/subtitle · pill · chevron */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, position: 'relative' }}>
        {React.cloneElement(quest.asset, {
          glowStrength: expanded ? 'strong' : 'mild',
          accentRgb: a.glow,
        })}
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            fontSize: 15.5, fontWeight: 700, color: '#f4f5fa',
            lineHeight: 1.2, letterSpacing: -0.1,
            marginBottom: 3,
            overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
          }}>{quest.title}</div>
          <div style={{
            fontSize: 12.5, color: '#a8afc8', fontWeight: 500,
            lineHeight: 1.25,
            overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
          }}>{quest.subtitle}</div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6 }}>
          <XpPill label={quest.reward} state={quest.rewardState} />
          <svg width="14" height="14" viewBox="0 0 16 16" fill="none" style={{
            color: '#5a607a',
            transform: expanded ? 'rotate(180deg)' : 'rotate(0)',
            transition: 'transform 0.2s',
          }}>
            <path d="M4 6 L8 10 L12 6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
      </div>

      {/* PROGRESS — dominant, with inline numerics on the line above */}
      <div style={{ marginTop: 12 }}>
        <div style={{
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
          marginBottom: 6,
        }}>
          <span style={{
            fontSize: 11, fontWeight: 700, color: '#7c83a0',
            letterSpacing: 1.2, textTransform: 'uppercase',
          }}>Postup</span>
          <span style={{
            fontFamily: 'JetBrains Mono, monospace',
            fontSize: 13, fontWeight: 700,
            color: '#e6e8f2',
          }}>
            {formatProgress(quest.progress)}
            <span style={{ color: '#5a607a', fontWeight: 600 }}> / {formatProgress(quest.total)}</span>
          </span>
        </div>
        <ProgressBar pct={pct} accent={quest.category} />
      </div>

      {/* CHAIN — small, secondary, below the progress */}
      <div style={{ marginTop: 10, display: 'flex', alignItems: 'center', gap: 8 }}>
        <span style={{
          fontSize: 9.5, fontWeight: 700, color: '#5a607a',
          letterSpacing: 1, textTransform: 'uppercase',
        }}>Řada</span>
        <InlineChain nodes={quest.chain} accent={quest.category} />
      </div>

      {/* EXPANDED — divider + 2 plain inline rows */}
      {expanded && quest.details && (
        <div style={{
          marginTop: 12, paddingTop: 12,
          borderTop: '1px solid rgba(255,255,255,0.05)',
          display: 'flex', flexDirection: 'column', gap: 7,
        }}>
          {quest.details.map((d, i) => (
            <DetailRow key={i} label={d.label} value={d.value} />
          ))}
        </div>
      )}
    </div>
  );
}

function formatProgress(n) {
  if (n >= 1000000) return (n / 1000000) + 'M';
  if (n >= 1000) return (n / 1000).toLocaleString('cs') + 'K';
  return String(n);
}

function DetailRow({ label, value }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, fontSize: 12.5, lineHeight: 1.4 }}>
      <span style={{
        fontSize: 10.5, fontWeight: 800, color: '#7c5fe0',
        letterSpacing: 1, textTransform: 'uppercase',
        minWidth: 84,
        flexShrink: 0,
      }}>{label}</span>
      <span style={{ color: '#d4d8e6', fontWeight: 500, flex: 1 }}>{value}</span>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Locked quest row — compact, low contrast, no progress bar
// ─────────────────────────────────────────────────────────────
function LockedQuestRow({ quest }) {
  return (
    <div style={{
      background: 'rgba(12, 14, 24, 0.5)',
      borderRadius: 12,
      border: '1px solid rgba(255,255,255,0.025)',
      padding: '9px 12px',
      display: 'flex', alignItems: 'center', gap: 11,
    }}>
      <AssetLocked kind={quest.lockedKind} size={36} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          marginBottom: 3,
        }}>
          <span style={{
            fontSize: 13.5, fontWeight: 700, color: '#8a90aa',
            letterSpacing: -0.1,
            overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
            flex: 1, minWidth: 0,
          }}>{quest.title}</span>
        </div>
        <div style={{
          fontSize: 11.5, color: '#5a607a',
          display: 'flex', alignItems: 'center', gap: 5,
          marginBottom: 6,
        }}>
          <svg width="9" height="9" viewBox="0 0 12 12" fill="none">
            <rect x="2.5" y="5.5" width="7" height="5" rx="1" fill="#5a607a"/>
            <path d="M4 5.5 V4 a2 2 0 0 1 4 0 V5.5" stroke="#5a607a" strokeWidth="1.3" fill="none"/>
          </svg>
          <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {quest.prereq}
          </span>
        </div>
        <InlineChain nodes={quest.chain} muted />
      </div>
      <XpPill label={quest.reward} state="locked" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Completed row
// ─────────────────────────────────────────────────────────────
function CompletedQuestRow({ quest }) {
  const claimable = quest.state === 'claimable';
  return (
    <div style={{
      background: claimable
        ? 'linear-gradient(180deg, rgba(58, 42, 14, 0.40) 0%, rgba(18, 16, 24, 0.78) 100%)'
        : 'rgba(14, 20, 22, 0.55)',
      borderRadius: 12,
      border: claimable
        ? '1px solid rgba(255, 200, 70, 0.22)'
        : '1px solid rgba(94, 200, 140, 0.10)',
      padding: '9px 12px',
      display: 'flex', alignItems: 'center', gap: 11,
    }}>
      {quest.asset}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 14, fontWeight: 700, color: '#d4d8e6',
          marginBottom: 2, letterSpacing: -0.1,
          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
        }}>{quest.title}</div>
        <div style={{
          fontSize: 11.5, color: '#7c83a0', fontWeight: 500,
          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
        }}>
          {quest.subtitle}
        </div>
      </div>
      {claimable ? (
        <button onClick={(e) => e.stopPropagation()} style={{
          background: 'linear-gradient(180deg, #ffd35a 0%, #f2a82e 100%)',
          color: '#3a2700',
          border: '1px solid #ffe28a',
          borderRadius: 999,
          padding: '6px 12px',
          fontSize: 11, fontWeight: 800,
          letterSpacing: 0.4,
          cursor: 'pointer',
          boxShadow: '0 0 12px -2px rgba(255,200,70,0.45), inset 0 1px 0 rgba(255,255,255,0.4)',
          fontFamily: 'inherit',
          display: 'flex', alignItems: 'center', gap: 5,
          flexShrink: 0,
        }}>
          <svg width="10" height="10" viewBox="0 0 12 12" fill="none"><path d="M6 1 L7.4 4.5 L11 5 L8.5 7.5 L9.2 11 L6 9.2 L2.8 11 L3.5 7.5 L1 5 L4.6 4.5 Z" fill="#3a2700"/></svg>
          {quest.reward} · VYZVEDNOUT
        </button>
      ) : (
        <XpPill label={quest.reward} state="claimed" />
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────
function SectionHeader({ icon, title, count, accent = '#a07aff', vivid = false }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 4px', marginBottom: 10 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
        <span style={{
          color: accent, display: 'flex', alignItems: 'center', justifyContent: 'center',
          width: 22, height: 22, borderRadius: 7,
          background: vivid ? `${accent}1f` : 'transparent',
          boxShadow: vivid ? `0 0 10px -2px ${accent}80, inset 0 0 0 1px ${accent}40` : 'none',
        }}>{icon}</span>
        <span style={{
          fontSize: 11.5, fontWeight: 800, letterSpacing: 1.2,
          color: accent, textTransform: 'uppercase',
          textShadow: vivid ? `0 0 12px ${accent}50` : 'none',
        }}>{title}</span>
        {vivid && (
          <span style={{
            width: 28, height: 1,
            background: `linear-gradient(90deg, ${accent}80, transparent)`,
            marginLeft: 2,
          }}/>
        )}
      </div>
      {count !== undefined && (
        <span style={{ fontSize: 11, color: '#5a607a', fontWeight: 600, letterSpacing: 0.2 }}>{count}</span>
      )}
    </div>
  );
}

Object.assign(window, {
  XpPill, InlineChain, ProgressBar, ActiveQuestCard, LockedQuestRow, CompletedQuestRow, SectionHeader, DetailRow,
  // back-compat name
  ChainPreview: InlineChain,
});
