// rpg-assets.jsx — Custom cartoon/RPG illustrated SVG assets

// Domain color lookup (minimal copy for icons)
const ASSET_DOM = {
  steps:    { color:'#34D399', dim:'rgba(52,211,153,0.16)'  },
  calories: { color:'#FBBF24', dim:'rgba(251,191,36,0.16)'  },
  sleep:    { color:'#A89BFF', dim:'rgba(168,155,255,0.16)' },
  weight:   { color:'#60A5FA', dim:'rgba(96,165,250,0.16)'  },
  activity: { color:'#2DD4BF', dim:'rgba(45,212,191,0.16)'  },
  xp:       { color:'#7C6FFF', dim:'rgba(124,111,255,0.16)' },
};

// ─── Chibi Knight Avatar ──────────────────────────────────────
function KnightAvatar({ size = 80 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      {/* Armor body / collar */}
      <path d="M18 95 C18 78 82 78 82 95 Z" fill="#3344aa"/>
      <ellipse cx="50" cy="83" rx="32" ry="12" fill="#4455bb"/>
      {/* Pauldron left */}
      <ellipse cx="19" cy="76" rx="13" ry="7" fill="#5566cc" transform="rotate(-20 19 76)"/>
      <ellipse cx="19" cy="75" rx="10" ry="5" fill="#6677dd" transform="rotate(-20 19 75)"/>
      {/* Pauldron right */}
      <ellipse cx="81" cy="76" rx="13" ry="7" fill="#5566cc" transform="rotate(20 81 76)"/>
      <ellipse cx="81" cy="75" rx="10" ry="5" fill="#6677dd" transform="rotate(20 81 75)"/>
      {/* Helmet dome */}
      <path d="M24 52 C24 20 76 20 76 52" fill="#5566cc"/>
      <path d="M24 52 C24 20 76 20 76 52" fill="url(#helmGrad)" opacity="0.4"/>
      {/* Helmet brim */}
      <rect x="22" y="48" width="56" height="10" rx="5" fill="#4455bb"/>
      <rect x="24" y="49" width="52" height="5" rx="2.5" fill="#7788ee" opacity="0.35"/>
      {/* Face */}
      <ellipse cx="50" cy="60" rx="25" ry="24" fill="#ffd4a0"/>
      {/* Face shading */}
      <ellipse cx="50" cy="68" rx="20" ry="14" fill="#f5c088" opacity="0.3"/>
      {/* Ears */}
      <ellipse cx="25" cy="58" rx="5" ry="7" fill="#ffd4a0"/>
      <ellipse cx="75" cy="58" rx="5" ry="7" fill="#ffd4a0"/>
      {/* Eyes — big anime style */}
      <ellipse cx="38" cy="58" rx="9" ry="10" fill="white"/>
      <ellipse cx="62" cy="58" rx="9" ry="10" fill="white"/>
      {/* Iris */}
      <ellipse cx="38" cy="59" rx="7" ry="8" fill="#334edd"/>
      <ellipse cx="62" cy="59" rx="7" ry="8" fill="#334edd"/>
      {/* Pupil */}
      <ellipse cx="38" cy="60" rx="4" ry="5" fill="#1a1a44"/>
      <ellipse cx="62" cy="60" rx="4" ry="5" fill="#1a1a44"/>
      {/* Eye shine — top right */}
      <circle cx="42" cy="55" r="2.5" fill="white"/>
      <circle cx="66" cy="55" r="2.5" fill="white"/>
      <circle cx="40" cy="58" r="1" fill="white" opacity="0.7"/>
      <circle cx="64" cy="58" r="1" fill="white" opacity="0.7"/>
      {/* Blush */}
      <ellipse cx="26" cy="66" rx="8" ry="5" fill="#ff9999" opacity="0.42"/>
      <ellipse cx="74" cy="66" rx="8" ry="5" fill="#ff9999" opacity="0.42"/>
      {/* Nose — tiny */}
      <circle cx="50" cy="66" r="1.5" fill="#cc9977" opacity="0.5"/>
      {/* Mouth — happy */}
      <path d="M43 72 Q50 79 57 72" stroke="#aa6644" strokeWidth="2.2" fill="none" strokeLinecap="round"/>
      {/* Helmet crest / ornament */}
      <path d="M46 22 L50 10 L54 22" fill="#fbbf24"/>
      <circle cx="50" cy="10" r="6" fill="#fbbf24"/>
      <circle cx="50" cy="10" r="3.5" fill="#fff8e1"/>
      {/* Armor chest line */}
      <path d="M30 83 L50 78 L70 83" stroke="#6677ee" strokeWidth="1.5" fill="none" opacity="0.6"/>
      <defs>
        <linearGradient id="helmGrad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="white"/>
          <stop offset="100%" stopColor="transparent"/>
        </linearGradient>
      </defs>
    </svg>
  );
}

// ─── Illustrated Cartoon Domain Icons ─────────────────────────
function CartIcon({ domain, size = 30 }) {
  const d = ASSET_DOM[domain] || ASSET_DOM.xp;
  const c = d.color;
  const pad = size * 0.2;
  const iconSize = size - pad * 2;

  const icons = {
    steps: (
      // Boot with speed lines
      <svg width={iconSize} height={iconSize} viewBox="0 0 24 24" fill="none">
        <path d="M9 3 L9 14 Q9 17 13 17 L19 17 Q21 17 21 15.5 L21 14.5 Q18 14.5 16 12.5 L16 3 Z" fill={c} opacity="0.9"/>
        <rect x="8" y="16.5" width="13" height="3.5" rx="1.8" fill={c}/>
        <path d="M3 8.5 L8 8.5" stroke={c} strokeWidth="1.8" strokeLinecap="round" opacity="0.55"/>
        <path d="M2 11.5 L8 11.5" stroke={c} strokeWidth="1.8" strokeLinecap="round" opacity="0.38"/>
        <path d="M3.5 14.5 L8 14.5" stroke={c} strokeWidth="1.8" strokeLinecap="round" opacity="0.22"/>
        <rect x="9" y="10" width="7" height="1.5" rx="0.75" fill="white" opacity="0.25"/>
      </svg>
    ),
    calories: (
      // Kawaii flame with face
      <svg width={iconSize} height={iconSize} viewBox="0 0 24 24" fill="none">
        <path d="M12 2 C12 2 6.5 7.5 6.5 13.5 C6.5 17.3 8.9 20.5 12 20.5 C15.1 20.5 17.5 17.3 17.5 13.5 C17.5 10.5 15 8 14.5 5.5 C14.5 8.5 12.5 10 12 10 C12.8 7.5 12 2 12 2Z" fill={c} opacity="0.9"/>
        <path d="M12 8 C10 10.5 10 14 12 16 C14 14 14 10.5 12 8Z" fill="white" opacity="0.22"/>
        {/* eyes */}
        <circle cx="10.2" cy="13.5" r="1.1" fill="rgba(0,0,0,0.35)"/>
        <circle cx="13.8" cy="13.5" r="1.1" fill="rgba(0,0,0,0.35)"/>
        {/* shine dots */}
        <circle cx="10.7" cy="13" r="0.4" fill="white" opacity="0.7"/>
        <circle cx="14.3" cy="13" r="0.4" fill="white" opacity="0.7"/>
        {/* smile */}
        <path d="M10.2 16 Q12 17.5 13.8 16" stroke="rgba(0,0,0,0.3)" strokeWidth="0.9" fill="none" strokeLinecap="round"/>
      </svg>
    ),
    sleep: (
      // Moon + stars
      <svg width={iconSize} height={iconSize} viewBox="0 0 24 24" fill="none">
        <path d="M14 3.5 C8.5 4.5 5 9 6 14.5 C7 19 11.5 22 16.5 21 C20 20 22.5 16.5 22 13 C19 15 14.5 14 13 10.5 C11.5 7 12.5 5 14 3.5Z" fill={c} opacity="0.88"/>
        {/* glow halo */}
        <path d="M14 3.5 C8.5 4.5 5 9 6 14.5 C7 19 11.5 22 16.5 21 C20 20 22.5 16.5 22 13 C19 15 14.5 14 13 10.5 C11.5 7 12.5 5 14 3.5Z" fill={c} opacity="0.12" transform="scale(1.15) translate(-2,-2)"/>
        {/* stars */}
        <path d="M4 7 L4.5 8.5 L6 9 L4.5 9.5 L4 11 L3.5 9.5 L2 9 L3.5 8.5Z" fill={c} opacity="0.7"/>
        <circle cx="7.5" cy="4" r="1.2" fill={c} opacity="0.55"/>
        <circle cx="2.5" cy="15" r="0.9" fill={c} opacity="0.4"/>
        {/* zzz */}
        <path d="M5 17 L7 17 L5 19.5 L7.5 19.5" stroke={c} strokeWidth="1" strokeLinecap="round" strokeLinejoin="round" opacity="0.5"/>
      </svg>
    ),
    weight: (
      // Cartoon shield with star
      <svg width={iconSize} height={iconSize} viewBox="0 0 24 24" fill="none">
        <path d="M12 2 L3.5 5.5 L3.5 12.5 C3.5 17.5 7 21.5 12 23 C17 21.5 20.5 17.5 20.5 12.5 L20.5 5.5 Z" fill={c} opacity="0.85"/>
        <path d="M12 4.5 L5.5 7.5 L5.5 12.5 C5.5 16.5 8.2 20 12 21.2 C15.8 20 18.5 16.5 18.5 12.5 L18.5 7.5 Z" fill="white" opacity="0.12"/>
        {/* star */}
        <path d="M12 8.5 L13 11 L15.5 11 L13.5 12.7 L14.3 15.5 L12 14 L9.7 15.5 L10.5 12.7 L8.5 11 L11 11 Z" fill="white" opacity="0.92"/>
      </svg>
    ),
    activity: (
      // Cartoon lightning bolt
      <svg width={iconSize} height={iconSize} viewBox="0 0 24 24" fill="none">
        <path d="M15 2 L5 13.5 L10.5 13.5 L9 22 L19 10.5 L13.5 10.5 Z" fill={c} opacity="0.9"/>
        <path d="M15 2 L5 13.5 L10.5 13.5 L9 22 L19 10.5 L13.5 10.5 Z" fill="white" opacity="0.18"/>
        {/* spark lines */}
        <path d="M3 9 L5.5 10" stroke={c} strokeWidth="1.4" strokeLinecap="round" opacity="0.45"/>
        <path d="M2 13 L4.5 13" stroke={c} strokeWidth="1.4" strokeLinecap="round" opacity="0.3"/>
        <path d="M3.5 17 L6 16" stroke={c} strokeWidth="1.4" strokeLinecap="round" opacity="0.2"/>
      </svg>
    ),
    xp: (
      // 4-pointed magic star
      <svg width={iconSize} height={iconSize} viewBox="0 0 24 24" fill="none">
        <path d="M12 2 L13.8 10.2 L22 12 L13.8 13.8 L12 22 L10.2 13.8 L2 12 L10.2 10.2 Z" fill={c} opacity="0.9"/>
        <path d="M12 5 L13.2 10.8 L19 12 L13.2 13.2 L12 19 L10.8 13.2 L5 12 L10.8 10.8 Z" fill="white" opacity="0.25"/>
        <circle cx="12" cy="12" r="2.5" fill="white" opacity="0.55"/>
        {/* tiny sparkles */}
        <circle cx="7" cy="7" r="1" fill={c} opacity="0.45"/>
        <circle cx="17" cy="17" r="1" fill={c} opacity="0.45"/>
        <circle cx="17" cy="7" r="0.7" fill={c} opacity="0.3"/>
        <circle cx="7" cy="17" r="0.7" fill={c} opacity="0.3"/>
      </svg>
    ),
  };

  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.3,
      background: d.dim, border: `1px solid ${c}44`,
      display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
    }}>
      <div style={{ width: iconSize, height: iconSize, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        {icons[domain] || icons.xp}
      </div>
    </div>
  );
}

// ─── Achievement Medal Badge ───────────────────────────────────
function MedalBadge({ domain, size = 40 }) {
  const d = ASSET_DOM[domain] || ASSET_DOM.xp;
  const c = d.color;
  const r = size / 2;
  return (
    <svg width={size} height={size} viewBox="0 0 100 100">
      {/* Outer star burst */}
      {Array.from({ length: 8 }, (_, i) => {
        const a = (i * 45 * Math.PI) / 180;
        const r1 = 48, r2 = 40;
        const x1 = 50 + r1 * Math.cos(a), y1 = 50 + r1 * Math.sin(a);
        const a2 = ((i + 0.5) * 45 * Math.PI) / 180;
        const x2 = 50 + r2 * Math.cos(a2), y2 = 50 + r2 * Math.sin(a2);
        return null; // computed in path below
      })}
      <polygon points={
        Array.from({ length: 16 }, (_, i) => {
          const isOuter = i % 2 === 0;
          const angle = (i * 22.5 - 90) * Math.PI / 180;
          const radius = isOuter ? 47 : 38;
          return `${50 + radius * Math.cos(angle)},${50 + radius * Math.sin(angle)}`;
        }).join(' ')
      } fill={c} opacity="0.85"/>
      {/* Inner circle */}
      <circle cx="50" cy="50" r="32" fill={c}/>
      <circle cx="50" cy="50" r="28" fill={c} opacity="0.7"/>
      {/* Shine */}
      <ellipse cx="41" cy="38" rx="12" ry="7" fill="white" opacity="0.2" transform="rotate(-30 41 38)"/>
      {/* Center star */}
      <path d="M50 26 L53.5 40.5 L68 44 L53.5 47.5 L50 62 L46.5 47.5 L32 44 L46.5 40.5 Z" fill="white" opacity="0.88"/>
      <circle cx="50" cy="44" r="5" fill="white" opacity="0.6"/>
    </svg>
  );
}

// ─── Quest Scroll Decoration ───────────────────────────────────
function ScrollDeco({ color, width = 200, side = 'top' }) {
  return (
    <svg width={width} height="10" viewBox={`0 0 ${width} 10`} style={{ display: 'block' }}>
      {/* Center diamond */}
      <polygon points={`${width/2} 2, ${width/2+4} 5, ${width/2} 8, ${width/2-4} 5`} fill={color} opacity="0.7"/>
      {/* Lines */}
      <line x1="0" y1="5" x2={width/2 - 8} y2="5" stroke={color} strokeWidth="1" opacity="0.3"/>
      <line x1={width/2 + 8} y1="5" x2={width} y2="5" stroke={color} strokeWidth="1" opacity="0.3"/>
      {/* End dots */}
      <circle cx="6" cy="5" r="2.5" fill={color} opacity="0.4"/>
      <circle cx={width - 6} cy="5" r="2.5" fill={color} opacity="0.4"/>
      {/* Inner dots near center */}
      <circle cx={width/2 - 14} cy="5" r="1.5" fill={color} opacity="0.35"/>
      <circle cx={width/2 + 14} cy="5" r="1.5" fill={color} opacity="0.35"/>
    </svg>
  );
}

// ─── XP Orb (small animated gem) ──────────────────────────────
function XPOrb({ color = '#7C6FFF', size = 14 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 20 20">
      <defs>
        <radialGradient id="orbGrad" cx="35%" cy="30%" r="60%">
          <stop offset="0%" stopColor="white" stopOpacity="0.8"/>
          <stop offset="100%" stopColor={color} stopOpacity="1"/>
        </radialGradient>
      </defs>
      <circle cx="10" cy="10" r="9" fill={color} opacity="0.25"/>
      <polygon points="10,2 17,7 14,16 6,16 3,7" fill="url(#orbGrad)"/>
      <ellipse cx="7.5" cy="6.5" rx="2.5" ry="1.5" fill="white" opacity="0.5" transform="rotate(-20 7.5 6.5)"/>
    </svg>
  );
}

// ─── Decorative Tab Bar Icon Overrides ────────────────────────
function TabIcon({ name, color, size = 18 }) {
  const s = { width: size, height: size };
  const icons = {
    home: (
      <svg style={s} viewBox="0 0 24 24" fill="none">
        <path d="M3 10.5 L12 3 L21 10.5 L21 21 L15 21 L15 15 L9 15 L9 21 L3 21 Z" fill={color} opacity="0.85"/>
        <path d="M9 21 L9 15 L15 15 L15 21" stroke="white" strokeWidth="1.2" fill="none" opacity="0.3"/>
        <rect x="9.5" y="3.5" width="5" height="5" rx="1" fill="white" opacity="0.15"/>
      </svg>
    ),
    quests: (
      <svg style={s} viewBox="0 0 24 24" fill="none">
        <rect x="4" y="2" width="16" height="20" rx="3" fill={color} opacity="0.85"/>
        <rect x="4" y="2" width="16" height="20" rx="3" fill="white" opacity="0.06"/>
        <path d="M8 7 L16 7" stroke="white" strokeWidth="1.5" strokeLinecap="round" opacity="0.7"/>
        <path d="M8 11 L16 11" stroke="white" strokeWidth="1.5" strokeLinecap="round" opacity="0.5"/>
        <path d="M8 15 L13 15" stroke="white" strokeWidth="1.5" strokeLinecap="round" opacity="0.35"/>
        <circle cx="17" cy="17" r="4" fill={color}/>
        <path d="M15.5 17 L16.5 18 L18.5 15.5" stroke="white" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    ),
    hero: (
      <svg style={s} viewBox="0 0 24 24" fill="none">
        <path d="M12 2 C9.5 2 8 4 8 7.5 C8 11 9.5 13 12 13 C14.5 13 16 11 16 7.5 C16 4 14.5 2 12 2Z" fill={color} opacity="0.9"/>
        <path d="M3 22 C3 17 7 14 12 14 C17 14 21 17 21 22" stroke={color} strokeWidth="2.5" strokeLinecap="round" fill="none" opacity="0.85"/>
        <path d="M9 6 C9.5 8.5 10.5 9.5 12 9.5 C13.5 9.5 14.5 8.5 15 6" stroke="white" strokeWidth="1" fill="none" opacity="0.3"/>
      </svg>
    ),
    glory: (
      <svg style={s} viewBox="0 0 24 24" fill="none">
        <path d="M6 4 L18 4 L18 4 C18 10 15 14 12 15.5 C9 14 6 10 6 4Z" fill={color} opacity="0.85"/>
        <path d="M6 4 L18 4 C18 10 15 14 12 15.5 C9 14 6 10 6 4Z" fill="white" opacity="0.1"/>
        <path d="M4 4 L6 4" stroke={color} strokeWidth="2.5" strokeLinecap="round" opacity="0.7"/>
        <path d="M18 4 L20 4" stroke={color} strokeWidth="2.5" strokeLinecap="round" opacity="0.7"/>
        <path d="M4 4 C4 7 5 9 6 10" stroke={color} strokeWidth="1.5" strokeLinecap="round" opacity="0.5"/>
        <path d="M20 4 C20 7 19 9 18 10" stroke={color} strokeWidth="1.5" strokeLinecap="round" opacity="0.5"/>
        <path d="M10 15.5 L10 19" stroke={color} strokeWidth="2" strokeLinecap="round" opacity="0.7"/>
        <path d="M14 15.5 L14 19" stroke={color} strokeWidth="2" strokeLinecap="round" opacity="0.7"/>
        <rect x="7.5" y="19" width="9" height="2" rx="1" fill={color} opacity="0.7"/>
        {/* star on trophy */}
        <path d="M12 7 L12.8 9.2 L15 9.2 L13.4 10.5 L14 12.7 L12 11.5 L10 12.7 L10.6 10.5 L9 9.2 L11.2 9.2 Z" fill="white" opacity="0.8"/>
      </svg>
    ),
  };
  return icons[name] || null;
}

Object.assign(window, { KnightAvatar, CartIcon, MedalBadge, ScrollDeco, XPOrb, TabIcon });
