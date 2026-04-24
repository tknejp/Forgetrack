// rpg-ui.jsx — Forgetrack v3 · Unified UI

// ─── Design tokens ────────────────────────────────────────────
const DARK_T = {
  bg:        '#0D0F1C',
  bgDeep:    '#080A14',
  surface:   'rgba(255,255,255,0.04)',
  surfaceMid:'rgba(255,255,255,0.07)',
  border:    'rgba(255,255,255,0.08)',
  borderBright:'rgba(255,255,255,0.14)',
  accent:    '#7C6FFF',
  accentDim: 'rgba(124,111,255,0.18)',
  accentGlow:'rgba(124,111,255,0.4)',
  gold:      '#FBBF24',
  goldDim:   'rgba(251,191,36,0.18)',
  goldGlow:  'rgba(251,191,36,0.28)',
  orange:    '#F97316',
  red:       '#EF4444',
  emerald:   '#10B981',
  t1: 'rgba(255,255,255,0.95)',
  t2: 'rgba(255,255,255,0.65)',
  t3: 'rgba(255,255,255,0.38)',
  t4: 'rgba(255,255,255,0.2)',
};

const LIGHT_T = {
  bg:        '#F4EFE6',
  bgDeep:    '#EAE3D6',
  surface:   'rgba(0,0,0,0.04)',
  surfaceMid:'rgba(0,0,0,0.07)',
  border:    'rgba(0,0,0,0.1)',
  borderBright:'rgba(0,0,0,0.18)',
  accent:    '#6B5CE7',
  accentDim: 'rgba(107,92,231,0.14)',
  accentGlow:'rgba(107,92,231,0.28)',
  gold:      '#F59E0B',
  goldDim:   'rgba(245,158,11,0.16)',
  goldGlow:  'rgba(245,158,11,0.3)',
  orange:    '#C2560A',
  red:       '#DC2626',
  emerald:   '#059669',
  t1: 'rgba(14,10,36,0.92)',
  t2: 'rgba(14,10,36,0.62)',
  t3: 'rgba(14,10,36,0.4)',
  t4: 'rgba(14,10,36,0.22)',
};

const DOMAIN_EMOJI = {
  steps:'👟', calories:'🔥', sleep:'🌙', weight:'⚖️', activity:'⚡', xp:'✨', protein:'🥩',
};

const DARK_DOM = {
  steps:    { color:'#34D399', dim:'rgba(52,211,153,0.14)',  rich:'rgba(52,211,153,0.26)',  glow:'rgba(52,211,153,0.3)',  label:'Kroky',    bg:'linear-gradient(135deg,#0d2e22,#0a1a15)' },
  calories: { color:'#FBBF24', dim:'rgba(251,191,36,0.14)',  rich:'rgba(251,191,36,0.26)',  glow:'rgba(251,191,36,0.3)',  label:'Kalorie',  bg:'linear-gradient(135deg,#2e2100,#1a1400)' },
  sleep:    { color:'#A89BFF', dim:'rgba(168,155,255,0.14)', rich:'rgba(168,155,255,0.26)', glow:'rgba(168,155,255,0.3)', label:'Spánek',   bg:'linear-gradient(135deg,#1a1830,#0e0d1f)' },
  weight:   { color:'#60A5FA', dim:'rgba(96,165,250,0.14)',  rich:'rgba(96,165,250,0.26)',  glow:'rgba(96,165,250,0.3)',  label:'Váha',     bg:'linear-gradient(135deg,#0d1e2e,#080f1a)' },
  activity: { color:'#2DD4BF', dim:'rgba(45,212,191,0.14)',  rich:'rgba(45,212,191,0.26)',  glow:'rgba(45,212,191,0.3)',  label:'Aktivita', bg:'linear-gradient(135deg,#0d2b28,#081a18)' },
  xp:       { color:'#7C6FFF', dim:'rgba(124,111,255,0.14)', rich:'rgba(124,111,255,0.26)', glow:'rgba(124,111,255,0.3)', label:'XP',       bg:'linear-gradient(135deg,#18143a,#0e0b22)' },
  protein:  { color:'#F472B6', dim:'rgba(244,114,182,0.14)', rich:'rgba(244,114,182,0.26)', glow:'rgba(244,114,182,0.3)', label:'Protein',  bg:'linear-gradient(135deg,#2e1020,#1a0812)' },
};

const LIGHT_DOM = {
  steps:    { color:'#059669', dim:'rgba(5,150,105,0.12)',   rich:'rgba(5,150,105,0.2)',    glow:'rgba(5,150,105,0.22)',   label:'Kroky',    bg:'linear-gradient(135deg,#d1fae5,#ecfdf5)' },
  calories: { color:'#B45309', dim:'rgba(180,83,9,0.12)',    rich:'rgba(180,83,9,0.2)',     glow:'rgba(180,83,9,0.22)',    label:'Kalorie',  bg:'linear-gradient(135deg,#fef3c7,#fffbeb)' },
  sleep:    { color:'#6D28D9', dim:'rgba(109,40,217,0.12)',  rich:'rgba(109,40,217,0.2)',   glow:'rgba(109,40,217,0.22)',  label:'Spánek',   bg:'linear-gradient(135deg,#ede9fe,#f5f3ff)' },
  weight:   { color:'#1D4ED8', dim:'rgba(29,78,216,0.12)',   rich:'rgba(29,78,216,0.2)',    glow:'rgba(29,78,216,0.22)',   label:'Váha',     bg:'linear-gradient(135deg,#dbeafe,#eff6ff)' },
  activity: { color:'#0F766E', dim:'rgba(15,118,110,0.12)',  rich:'rgba(15,118,110,0.2)',   glow:'rgba(15,118,110,0.22)',  label:'Aktivita', bg:'linear-gradient(135deg,#ccfbf1,#f0fdfa)' },
  xp:       { color:'#6B5CE7', dim:'rgba(107,92,231,0.12)',  rich:'rgba(107,92,231,0.2)',   glow:'rgba(107,92,231,0.22)',  label:'XP',       bg:'linear-gradient(135deg,#ede9fe,#f5f3ff)' },
  protein:  { color:'#BE185D', dim:'rgba(190,24,93,0.12)',   rich:'rgba(190,24,93,0.2)',    glow:'rgba(190,24,93,0.22)',   label:'Protein',  bg:'linear-gradient(135deg,#fce7f3,#fdf2f8)' },
};

// Mutable theme globals — updated by RPGApp before each render
let T = DARK_T;
let DOM = DARK_DOM;
let _isDark = true;
let _toggleTheme = () => {};

// ─── Primitives ───────────────────────────────────────────────
function PBar({ value, color, glow, h = 5 }) {
  const pct = Math.min(1, Math.max(0, value)) * 100;
  return (
    <div style={{ height: h, borderRadius: 99, background: T.border, overflow: 'hidden' }}>
      <div style={{
        height: '100%', width: `${pct}%`, borderRadius: 99,
        background: `linear-gradient(90deg, ${color}bb, ${color})`,
        boxShadow: `0 0 8px ${glow}`,
        transition: 'width .6s cubic-bezier(.4,0,.2,1)',
      }}/>
    </div>
  );
}

function Sparkle({ x, y, scale = 0.65, delay = 0, color }) {
  return (
    <div style={{ position:'absolute', left:`${x}%`, top:`${y}%`, pointerEvents:'none', animation:`rpg-spark 2.4s ease-in-out ${delay}s infinite` }}>
      <svg width={9*scale} height={9*scale} viewBox="0 0 10 10">
        <path d="M5 0L5.8 4.2 10 5 5.8 5.8 5 10 4.2 5.8 0 5 4.2 4.2 5 0z" fill={color||T.accent}/>
      </svg>
    </div>
  );
}

function SectionHead({ label, sub, color }) {
  const c = color || T.accent;
  return (
    <div style={{ display:'flex', alignItems:'center', gap:7, marginBottom:10 }}>
      <svg width="9" height="9" viewBox="0 0 10 10">
        <path d="M5 0L5.8 4.2 10 5 5.8 5.8 5 10 4.2 5.8 0 5 4.2 4.2 5 0z" fill={c}/>
      </svg>
      <div>
        <div style={{ fontFamily:'"Press Start 2P", monospace', fontSize:8, color:c, letterSpacing:'.05em', lineHeight:1 }}>{label}</div>
        {sub && <div style={{ fontSize:10, color:T.t3, fontWeight:500, marginTop:2 }}>{sub}</div>}
      </div>
    </div>
  );
}

function Badge({ label, color, small }) {
  return (
    <div style={{
      display:'inline-flex', alignItems:'center',
      background:`${color}22`, border:`1px solid ${color}44`,
      borderRadius:99, padding: small ? '1px 7px' : '2px 9px',
      fontSize: small ? 9 : 10, fontWeight:700, color, letterSpacing:'.04em', whiteSpace:'nowrap',
    }}>{label}</div>
  );
}

function LevelBadge({ level, size = 44, pulse = false }) {
  return (
    <div style={{
      width:size, height:size, borderRadius:size*0.28, flexShrink:0,
      background:`linear-gradient(135deg, ${T.accent}, #5a4fd8)`,
      border:`2px solid ${T.accent}88`,
      display:'flex', alignItems:'center', justifyContent:'center',
      fontFamily:'"Press Start 2P", monospace',
      fontSize:size*0.3, color:'#fff',
      boxShadow:`0 0 18px ${T.accentGlow}`,
      animation: pulse ? 'rpg-glow 3s ease-in-out infinite' : 'none',
      position:'relative', overflow:'hidden',
    }}>
      <div style={{ position:'absolute', top:2, left:4, right:4, height:8, background:'rgba(255,255,255,0.2)', borderRadius:3 }}/>
      {level}
    </div>
  );
}

function IconBox({ domain, size = 40 }) {
  const d = DOM[domain] || DOM.xp;
  const emoji = DOMAIN_EMOJI[domain] || '⚡';
  return (
    <div style={{
      width:size, height:size, borderRadius:Math.round(size*0.28), flexShrink:0,
      background: d.bg, border:`1.5px solid ${d.color}44`,
      boxShadow:`0 2px 10px ${d.glow}44, inset 0 1px 0 rgba(255,255,255,0.08)`,
      display:'flex', alignItems:'center', justifyContent:'center',
      fontSize: Math.round(size * 0.52), lineHeight:1,
    }}>{emoji}</div>
  );
}

// ─── Unified Header ───────────────────────────────────────────
function UnifiedHeader({ supra, title, right, noBorder }) {
  return (
    <div style={{
      padding:'12px 16px 10px',
      borderBottom: noBorder ? 'none' : `1px solid ${T.border}`,
      display:'flex', alignItems:'flex-end', justifyContent:'space-between',
    }}>
      <div>
        <div style={{ fontSize:11, fontWeight:700, color:T.accent, textTransform:'uppercase', letterSpacing:'.1em', marginBottom:3, lineHeight:1 }}>{supra}</div>
        <div style={{ fontSize:16, fontWeight:800, color:T.t1, letterSpacing:'-0.02em', lineHeight:1.1, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{title}</div>
      </div>
      <div style={{ display:'flex', alignItems:'center', gap:8, flexShrink:0 }}>
        {right}
        <button onClick={_toggleTheme} style={{
          width:32, height:32, borderRadius:10, border:`1px solid ${T.border}`,
          background:T.surface, cursor:'pointer',
          display:'flex', alignItems:'center', justifyContent:'center', fontSize:15,
        }}>{_isDark ? '☀️' : '🌙'}</button>
      </div>
    </div>
  );
}

// Icon button for header right
function HeaderIconBtn({ onClick, children, badge }) {
  return (
    <button onClick={onClick} style={{
      width:36, height:36, borderRadius:11, display:'flex', alignItems:'center', justifyContent:'center',
      background:T.accentDim, border:`1px solid ${T.accent}44`,
      boxShadow:`0 0 12px ${T.accentGlow}`,
      cursor:'pointer', position:'relative', flexShrink:0,
    }}>
      {children}
      {badge > 0 && <div style={{
        position:'absolute', top:-4, right:-4,
        width:16, height:16, borderRadius:99, background:T.red,
        fontSize:9, fontWeight:800, color:'#fff', display:'flex', alignItems:'center', justifyContent:'center',
        border:`2px solid ${T.bg}`,
      }}>{badge > 9 ? '9+' : badge}</div>}
    </button>
  );
}

// ─── Level XP Strip ───────────────────────────────────────────
// Shown just below header on all screens
function LevelStrip({ level, title, cur, max, compact }) {
  const pct = cur / max;
  return (
    <div style={{
      margin: compact ? '0 16px 8px' : '0 16px 12px',
      background: _isDark ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.06)',
      borderRadius:12, padding:'8px 12px',
      border:`1px solid rgba(124,111,255,0.22)`,
      boxShadow:`0 2px 12px rgba(124,111,255,0.1)`,
    }}>
      <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:5 }}>
        <div style={{ display:'flex', alignItems:'center', gap:7 }}>
          <LevelBadge level={level} size={28} pulse/>
          <div>
            <div style={{ fontFamily:'"Press Start 2P", monospace', fontSize:7, color:T.gold, letterSpacing:'.04em', lineHeight:1 }}>LV{level} · {title}</div>
          </div>
        </div>
        <span style={{ fontSize:10, color:T.t3, fontWeight:600 }}>{cur.toLocaleString()} / {max.toLocaleString()} XP</span>
      </div>
      <PBar value={pct} color={T.gold} glow={T.goldGlow} h={5}/>
    </div>
  );
}

// ─── Expandable Hero Card (Overview sticky) ───────────────────
function ExpandableHeroCard({ expanded, onToggle }) {
  return (
    <div style={{
      margin:'0 12px 0', borderRadius:18,
      background: _isDark
        ? `linear-gradient(145deg,rgba(124,111,255,0.16),rgba(124,111,255,0.04))`
        : `linear-gradient(145deg,rgba(107,92,231,0.1),rgba(107,92,231,0.03))`,
      border:`1px solid ${T.accent}28`,
      boxShadow:`0 4px 24px ${T.accentGlow}`,
      overflow:'hidden', position:'relative',
    }}>
      <Sparkle x={90} y={10} scale={.65} delay={0.3}/>
      <Sparkle x={4}  y={80} scale={.5}  delay={1.1}/>

      {/* Collapsed row: always visible */}
      <div style={{ display:'flex', alignItems:'center', gap:10, padding:'10px 12px', cursor:'pointer' }} onClick={onToggle}>
        <LevelBadge level={20} size={36} pulse/>
        <div style={{ flex:1 }}>
          <div style={{ fontSize:10, fontWeight:700, color:T.gold, textTransform:'uppercase', letterSpacing:'.08em', lineHeight:1 }}>Level 20 · Iron Warden</div>
          <div style={{ marginTop:5 }}>
            <PBar value={5675/9125} color={T.gold} glow={T.goldGlow} h={5}/>
          </div>
          <div style={{ fontSize:9, color:T.t3, marginTop:3 }}>5 675 / 9 125 XP</div>
          {/* Stat pills */}
          <div style={{ display:'flex', gap:6, marginTop:8 }}>
            <div style={{
              flex:1, borderRadius:9, padding:'5px 8px',
              background: _isDark ? 'rgba(45,212,191,0.15)' : 'rgba(15,118,110,0.1)',
              border:`1px solid ${DOM.activity.color}33`,
              display:'flex', alignItems:'center', gap:5, fontSize:11, fontWeight:700, color:DOM.activity.color,
            }}>⚡ 26 <span style={{fontWeight:500,color:T.t3}}>Aktivita</span></div>
            <div style={{
              flex:1, borderRadius:9, padding:'5px 8px',
              background: _isDark ? 'rgba(124,111,255,0.15)' : 'rgba(107,92,231,0.1)',
              border:`1px solid ${T.accent}33`,
              display:'flex', alignItems:'center', gap:5, fontSize:11, fontWeight:700, color:T.accent,
            }}>🛡 25 <span style={{fontWeight:500,color:T.t3}}>Úspěchy</span></div>
          </div>
        </div>
        <div style={{
          width:26, height:26, borderRadius:8, display:'flex', alignItems:'center', justifyContent:'center',
          background:'rgba(255,255,255,0.08)', flexShrink:0,
          transform: expanded ? 'rotate(180deg)' : 'none', transition:'transform .25s',
        }}>
          <svg width="10" height="6" viewBox="0 0 10 6"><path d="M1 1l4 4 4-4" stroke={T.t3} strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </div>
      </div>

      {/* Expanded content */}
      {expanded && (
        <div style={{ padding:'0 12px 12px', borderTop:`1px solid rgba(255,255,255,0.07)` }}>
          {/* Quick stats row */}
          <div style={{ display:'grid', gridTemplateColumns:'repeat(4,1fr)', gap:6, marginTop:10 }}>
            {[
              { label:'Celkem XP', val:'69,7k', color:T.accent, domain:'xp' },
              { label:'Do dalšího', val:'3 450', color:DOM.steps.color, domain:'steps' },
              { label:'Úspěchy',   val:'25',    color:'#A89BFF', domain:'sleep' },
              { label:'Questy',    val:'17',    color:DOM.activity.color, domain:'activity' },
            ].map((s, i) => (
              <div key={i} style={{
                borderRadius:10, padding:'7px 6px', textAlign:'center',
                background:T.surface, border:`1px solid ${T.border}`,
              }}>
                <div style={{ fontSize:14, fontWeight:800, color:s.color, letterSpacing:'-0.02em' }}>{s.val}</div>
                <div style={{ fontSize:8, color:T.t4, fontWeight:600, textTransform:'uppercase', letterSpacing:'.05em', marginTop:2, lineHeight:1.2 }}>{s.label}</div>
              </div>
            ))}
          </div>

          {/* Series cards */}
          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:7, marginTop:8 }}>
            <div style={{ borderRadius:12, padding:'10px 11px', background:`linear-gradient(135deg, ${DOM.activity.rich}, rgba(0,0,0,0))`, border:`1px solid ${DOM.activity.color}33` }}>
              <div style={{ fontSize:9, fontWeight:700, color:DOM.activity.color, textTransform:'uppercase', letterSpacing:'.08em', marginBottom:2 }}>Aktuální série</div>
              <div style={{ fontSize:22, fontWeight:900, color:DOM.activity.color, letterSpacing:'-0.04em', lineHeight:1 }}>26 <span style={{ fontSize:11, fontWeight:500, opacity:.7 }}>dní</span></div>
              <div style={{ fontSize:9, color:T.t4, fontWeight:600, textTransform:'uppercase', letterSpacing:'.06em', marginTop:3 }}>Aktivita</div>
            </div>
            <div style={{ borderRadius:12, padding:'10px 11px', background:`linear-gradient(135deg, ${T.goldDim}, rgba(0,0,0,0))`, border:`1px solid ${T.gold}33` }}>
              <div style={{ fontSize:9, fontWeight:700, color:T.gold, textTransform:'uppercase', letterSpacing:'.08em', marginBottom:2 }}>Nejlepší série</div>
              <div style={{ fontSize:22, fontWeight:900, color:T.gold, letterSpacing:'-0.04em', lineHeight:1 }}>65 <span style={{ fontSize:11, fontWeight:500, opacity:.7 }}>dní</span></div>
              <div style={{ fontSize:9, color:T.t4, fontWeight:600, textTransform:'uppercase', letterSpacing:'.06em', marginTop:3 }}>Body</div>
            </div>
          </div>

          {/* Active quests */}
          <div style={{ marginTop:8 }}>
            <div style={{ fontSize:10, fontWeight:700, color:T.t4, textTransform:'uppercase', letterSpacing:'.08em', marginBottom:6 }}>Aktivní questy</div>
            {[
              { name:'Dvojité vítězství', pct: 0 },
              { name:'Nutriční kombo',    pct: 0 },
            ].map((q, i) => (
              <div key={i} style={{
                display:'flex', alignItems:'center', gap:9,
                padding:'6px 9px', borderRadius:9,
                background:T.surface, border:`1px solid ${T.border}`,
                marginBottom:5,
              }}>
                <IconBox domain="activity" size={28}/>
                <div style={{ flex:1 }}>
                  <div style={{ fontSize:11, fontWeight:700, color:T.t2, marginBottom:3 }}>{q.name}</div>
                  <PBar value={q.pct} color={DOM.activity.color} glow={DOM.activity.glow} h={3}/>
                </div>
                <span style={{ fontSize:10, fontWeight:700, color:T.t3, minWidth:26, textAlign:'right' }}>{Math.round(q.pct*100)}%</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Range + Date row ─────────────────────────────────────────
function RangeDateRow({ range, onRange, dateLabel }) {
  return (
    <div style={{ padding:'8px 12px 4px' }}>
      {/* Range tabs */}
      <div style={{
        display:'flex', borderRadius:12, background:T.surface,
        border:`1px solid ${T.border}`, padding:3, marginBottom:8,
      }}>
        {['Den','Týden','Měsíc'].map(r => (
          <button key={r} onClick={() => onRange(r)} style={{
            flex:1, borderRadius:9, padding:'7px 0',
            background: range===r ? T.accent : 'transparent',
            border:'none', cursor:'pointer',
            fontSize:12, fontWeight:700, color: range===r ? '#fff' : T.t3,
            transition:'all .18s',
          }}>{r}</button>
        ))}
      </div>
      {/* Date nav */}
      <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between' }}>
        <button style={{ background:'none', border:`1px solid ${T.border}`, borderRadius:8, width:28, height:28, display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer', color:T.t3, fontSize:14 }}>‹</button>
        <div style={{ textAlign:'center' }}>
          <div style={{ fontSize:13, fontWeight:700, color:T.t1, display:'flex', alignItems:'center', gap:5 }}>
            {dateLabel}
            <svg width="8" height="5" viewBox="0 0 8 5"><path d="M1 1l3 3 3-3" stroke={T.t3} strokeWidth="1.5" fill="none" strokeLinecap="round"/></svg>
          </div>
          <div style={{ fontSize:10, color:T.t4, marginTop:1 }}>Synced 23:20</div>
        </div>
        <button style={{ background:'none', border:`1px solid ${T.border}`, borderRadius:8, width:28, height:28, display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer', color:T.t3, fontSize:14 }}>›</button>
      </div>
    </div>
  );
}

// ─── Metric card (Overview list) ─────────────────────────────
function MetricCard({ domain, name, value, unit, xp, pct, badge }) {
  const d = DOM[domain];
  return (
    <div style={{
      borderRadius:16, padding:'13px 14px 10px',
      background: d.bg,
      border:`1px solid ${d.color}33`,
      boxShadow:`0 2px 14px ${d.glow}22`,
      animation:'rpg-card-in .3s ease both',
      position:'relative', overflow:'hidden',
    }}>
      <div style={{ position:'absolute', top:0, left:0, right:0, height:2, background:`linear-gradient(90deg,transparent,${d.color}60,transparent)` }}/>
      <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:10 }}>
        <IconBox domain={domain} size={38}/>
        <div style={{ flex:1 }}>
          <div style={{ fontSize:14, fontWeight:700, color:T.t1, letterSpacing:'-0.01em' }}>{name}</div>
        </div>
        <div style={{ display:'flex', alignItems:'center', gap:6 }}>
          {badge && <Badge label={badge} color={T.gold} small/>}
          <div style={{
            display:'flex', alignItems:'center', gap:4,
            background:`${d.color}18`, border:`1px solid ${d.color}33`, borderRadius:8, padding:'2px 8px',
            fontSize:11, fontWeight:700, color:T.t3,
          }}>{Math.round(pct*100)}%</div>
          <div style={{
            background:T.accentDim, border:`1px solid ${T.accent}33`, borderRadius:8, padding:'2px 8px',
            fontSize:11, fontWeight:700, color:T.t3,
          }}>🔒 {xp} XP</div>
        </div>
        <svg width="7" height="11" viewBox="0 0 7 11"><path d="M1 1l5 4.5L1 10" stroke={T.t4} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
      </div>
      <div style={{ fontSize:36, fontWeight:900, color:d.color, letterSpacing:'-0.04em', lineHeight:1, marginBottom:14 }}>
        {value}<span style={{ fontSize:13, fontWeight:500, color:`${d.color}77`, marginLeft:4 }}>{unit}</span>
      </div>
      <PBar value={pct} color={d.color} glow={d.glow} h={4}/>
      <div style={{ fontSize:10, color:T.t4, fontWeight:600, textTransform:'uppercase', letterSpacing:'.08em', marginTop:5, textAlign:'right' }}>{d.label}</div>
    </div>
  );
}

// ─── DASHBOARD ────────────────────────────────────────────────
function DashboardScreen() {
  const [expanded, setExpanded] = React.useState(false);
  const [range, setRange] = React.useState('Den');

  const metrics = [
    { domain:'steps',    name:'Kroky',        value:'0',    unit:'',     xp:620,  pct:0, badge:null,  bottomLabel:'KROKY'    },
    { domain:'calories', name:'Kalorie dnes', value:'0',    unit:'kcal', xp:775,  pct:0, badge:null,  bottomLabel:'PŘIJATO'  },
    { domain:'weight',   name:'Váha',         value:'––',   unit:'kg',   xp:1315, pct:0, badge:'🏆', bottomLabel:'AKTUÁLNÍ' },
    { domain:'sleep',    name:'Spánek',        value:'––',   unit:'',     xp:395,  pct:0, badge:null,  bottomLabel:'POSLEDNÍ'  },
  ];

  return (
    <div>
      {/* Sticky block */}
      <div style={{ position:'sticky', top:0, zIndex:20, background:T.bg, paddingBottom:8 }}>
        <UnifiedHeader
          supra="Dnes, Tomáš"
          title="Přehled"
          right={
            <HeaderIconBtn>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M12 2L3 7v5c0 5.25 3.75 10.15 9 11.25C17.25 22.15 21 17.25 21 12V7L12 2z" stroke={T.accent} strokeWidth="2" fill={T.accentDim}/></svg>
            </HeaderIconBtn>
          }
          noBorder
        />
        <ExpandableHeroCard expanded={expanded} onToggle={() => setExpanded(e => !e)}/>
        <RangeDateRow range={range} onRange={setRange} dateLabel="Pá 24. dubna"/>
      </div>

      {/* Cards flow normally */}
      <div style={{ padding:'4px 12px 16px', display:'flex', flexDirection:'column', gap:10 }}>
        {metrics.map((m, i) => <MetricCard key={i} {...m}/>)}
      </div>
    </div>
  );
}

// ─── Hero profile card (Questy / Hero shared) ─────────────────
function HeroInfoCard({ detailed, onSettings, onPhoto }) {
  return (
    <div style={{
      margin:'0 12px 12px',
      borderRadius:18, padding:'14px',
      background:`linear-gradient(145deg, ${T.accentDim}, rgba(124,111,255,0.04))`,
      border:`1px solid rgba(124,111,255,0.26)`,
      boxShadow:`0 4px 28px rgba(124,111,255,0.14)`,
      position:'relative', overflow:'hidden',
      animation:'rpg-card-in .3s ease both',
    }}>
      <Sparkle x={89} y={7}  delay={0.3}/>
      <Sparkle x={4}  y={80} scale={.5}  delay={0.9}/>

      <div style={{ display:'flex', alignItems:'flex-start', gap:12, marginBottom:12 }}>
        {/* Avatar */}
        <div style={{ position:'relative', flexShrink:0 }}>
          <div style={{
            width: detailed ? 70 : 52, height: detailed ? 70 : 52,
            borderRadius: detailed ? 18 : 14,
            background:`linear-gradient(135deg, rgba(124,111,255,0.3), rgba(124,111,255,0.08))`,
            border:`2px solid ${T.accent}60`,
            boxShadow:`0 0 18px ${T.accentGlow}`,
            display:'flex', alignItems:'center', justifyContent:'center',
            overflow:'hidden', cursor: detailed ? 'pointer' : 'default',
          }} onClick={detailed ? onPhoto : undefined}>
            <KnightAvatar size={detailed ? 70 : 52}/>
          </div>
          {detailed && (
            <div onClick={onPhoto} style={{
              position:'absolute', bottom:-4, right:-4,
              width:22, height:22, borderRadius:7,
              background:T.accent, border:`2px solid ${T.bg}`,
              display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer',
              boxShadow:`0 2px 8px ${T.accentGlow}`,
            }}>
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none"><path d="M12 20h9M16.5 3.5a2.121 2.121 0 013 3L7 19l-4 1 1-4L16.5 3.5z" stroke="#fff" strokeWidth="2.2" strokeLinecap="round"/></svg>
            </div>
          )}
        </div>

        <div style={{ flex:1, minWidth:0 }}>
          <div style={{ fontSize: detailed ? 18 : 16, fontWeight:800, color:T.t1, letterSpacing:'-0.02em', lineHeight:1.15 }}>Tomáš Knejp</div>
          {detailed && <div style={{ fontSize:10, color:T.t4, marginTop:2 }}>@tom_knejp</div>}
          <div style={{ fontFamily:'"Press Start 2P", monospace', fontSize:6, color:T.gold, marginTop:4, letterSpacing:1 }}>IRON WARDEN</div>
        </div>

        <div style={{ textAlign:'right', flexShrink:0, display:'flex', flexDirection:'column', alignItems:'flex-end', gap:4 }}>
          {detailed && (
            <button onClick={onSettings} style={{
              background:T.surface, border:`1px solid ${T.border}`, borderRadius:9,
              width:30, height:30, display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer', marginBottom:2,
            }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="3" stroke={T.t3} strokeWidth="1.8"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41" stroke={T.t3} strokeWidth="1.8" strokeLinecap="round"/></svg>
            </button>
          )}
          <div style={{ fontSize:9, fontWeight:700, color:T.t4, textTransform:'uppercase', letterSpacing:'.08em' }}>Celkem XP</div>
          <div style={{ fontSize:18, fontWeight:900, color:T.t1, letterSpacing:'-0.04em' }}>69,7k</div>
        </div>
      </div>

      {/* XP bar */}
      <div style={{ background: _isDark ? 'rgba(0,0,0,0.22)' : 'rgba(0,0,0,0.06)', borderRadius:12, padding:'8px 11px', border:`1px solid ${T.border}` }}>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:5 }}>
          <span style={{ fontFamily:'"Press Start 2P", monospace', fontSize:7, color:T.gold, letterSpacing:'.04em' }}>LV20 · IRON WARDEN</span>
          <span style={{ fontSize:10, color:T.t3 }}>5 675 / 9 125 XP</span>
        </div>
        <PBar value={5675/9125} color={T.gold} glow={T.goldGlow} h={5}/>
      </div>

    </div>
  );
}

// ─── QUESTS ───────────────────────────────────────────────────
function QuestsScreen() {
  const active = [
    { name:'Dvojité vítězství', sub:'Pro combo v aktuálním období', desc:'Splň v aktuálním dni libovolně 2 denní cíle.', xp:1195, cur:0, max:2 },
    { name:'Nutriční kombo',    sub:'Pro combo v aktuálním období', desc:'Splň v aktuálním dni kalorický i proteinový cíl.', xp:855, cur:0, max:2 },
  ];
  const locked = [
    { name:'Čtyři pilíře',     desc:'Splň v aktuálním dni všechny 4 denní cíle.',        xp:1965 },
    { name:'Trojité vítězství',desc:'Splň v aktuálním dni libovolně 3 denní cíle.',      xp:1620 },
    { name:'Týdenní výzva',    desc:'Splň alespoň 5 ze 7 denních cílů v jednom týdnu.',  xp:2400 },
  ];

  return (
    <div style={{ display:'flex', flexDirection:'column' }}>
      <div style={{ position:'sticky', top:0, zIndex:20, background:T.bg, paddingBottom:4 }}>
        <UnifiedHeader supra="Questy" title="Questy a odměny" noBorder/>
        <HeroInfoCard/>
      </div>

      <div style={{ padding:'0 12px 16px', display:'flex', flexDirection:'column', gap:14 }}>
        {/* Active quests */}
        <div>
          <SectionHead label="Aktivní questy" sub="Aktivní a zamčené questy nahoře, dokončené níže."/>
          <div style={{ display:'flex', flexDirection:'column', gap:8 }}>
            {active.map((q, i) => (
              <div key={i} style={{
                borderRadius:14, padding:'12px 13px',
                background:`linear-gradient(135deg, ${DOM.activity.rich}, rgba(0,0,0,0))`,
                border:`1px solid ${DOM.activity.color}44`,
                boxShadow:`0 2px 12px ${DOM.activity.glow}22`,
                position:'relative', overflow:'hidden',
                animation:`rpg-card-in .3s ease ${i*0.06}s both`,
              }}>
                <div style={{ position:'absolute', top:0, left:0, right:0, height:2, background:`linear-gradient(90deg,transparent,${DOM.activity.color}80,transparent)` }}/>
                <div style={{ display:'flex', alignItems:'flex-start', gap:10, marginBottom:10 }}>
                  <IconBox domain="activity" size={36}/>
                  <div style={{ flex:1 }}>
                    <div style={{ fontSize:13, fontWeight:800, color:T.t1 }}>{q.name}</div>
                    <div style={{ fontSize:10, color:DOM.activity.color, fontWeight:600, marginTop:2 }}>{q.sub}</div>
                    <div style={{ fontSize:11, color:T.t3, marginTop:4, lineHeight:1.4 }}>{q.desc}</div>
                  </div>
                  <div style={{
                    background:T.accentDim, border:`1px solid ${T.accent}33`, borderRadius:8, padding:'3px 8px',
                    fontSize:11, fontWeight:700, color:T.t3, whiteSpace:'nowrap',
                  }}>🔒 {q.xp} XP</div>
                </div>
                <PBar value={q.cur/q.max} color={DOM.activity.color} glow={DOM.activity.glow} h={5}/>
                <div style={{ display:'flex', justifyContent:'space-between', marginTop:5 }}>
                  <span style={{ fontSize:10, color:T.t4 }}>{q.cur} / {q.max}</span>
                  <span style={{ fontSize:10, color:T.t4 }}>{Math.round(q.cur/q.max*100)} %</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Locked quests */}
        <div>
          <SectionHead label="Zamčené questy"/>
          <div style={{ display:'flex', flexDirection:'column', gap:6 }}>
            {locked.map((q, i) => (
              <div key={i} style={{
                borderRadius:14, padding:'11px 13px',
                background:T.surface, border:`1px solid ${T.border}`,
                display:'flex', alignItems:'center', gap:10,
                animation:`rpg-card-in .3s ease ${i*0.05}s both`,
                opacity:0.75,
              }}>
                <div style={{
                  width:36, height:36, borderRadius:11, background:T.surface, border:`1px solid ${T.border}`,
                  display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0,
                }}>
                  <svg width="14" height="17" viewBox="0 0 14 17" fill="none"><rect x="1" y="7" width="12" height="10" rx="2.5" stroke={T.t4} strokeWidth="1.6"/><path d="M4 7V5a3 3 0 016 0v2" stroke={T.t4} strokeWidth="1.6" strokeLinecap="round"/></svg>
                </div>
                <div style={{ flex:1 }}>
                  <div style={{ fontSize:13, fontWeight:700, color:T.t3 }}>{q.name}</div>
                  <div style={{ fontSize:11, color:T.t4, marginTop:2, lineHeight:1.3 }}>{q.desc}</div>
                </div>
                <div style={{ fontSize:11, fontWeight:700, color:T.t4, whiteSpace:'nowrap' }}>🔒 {q.xp} XP</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── HERO SCREEN ──────────────────────────────────────────────
function HeroScreen() {
  const [photoPrompt, setPhotoPrompt] = React.useState(false);

  const series = [
    { label:'Aktuální série', val:'26', unit:'dní', sub:'Aktivita', color:DOM.activity.color, dim:DOM.activity.rich, domain:'activity' },
    { label:'Nejlepší série', val:'65', unit:'dní', sub:'Body',     color:T.gold,             dim:T.goldDim,         domain:'calories' },
  ];

  const stats2x2 = [
    { label:'Aktuální série', val:'26', sub:'Aktivita', color:DOM.activity.color, domain:'activity' },
    { label:'Nejlepší série', val:'65', sub:'Body',     color:T.gold,             domain:'calories' },
    { label:'Dok. questy',    val:'17', sub:'Splněno',  color:DOM.steps.color,    domain:'steps'    },
    { label:'Úspěchy',        val:'25', sub:'Odemknuto',color:T.accent,           domain:'xp'       },
  ];

  const achievements = [
    { name:'Balanced Rhythm', desc:'Výživa 3 dny v řadě',   color:'#FBBF24', domain:'calories', unlocked:true },
    { name:'Chain of Steps',  desc:'Kroky 3 dny v řadě',    color:'#34D399', domain:'steps',    unlocked:true },
    { name:'Weekly Warrior',  desc:'Týdenní aktivitní cíl',  color:'#2DD4BF', domain:'activity', unlocked:true },
    { name:'Trailblazer',     desc:'Dosáhni level 10',       color:'#7C6FFF', domain:'xp',       unlocked:false },
    { name:'Iron Will',       desc:'30 dní aktivity v řadě', color:'#60A5FA', domain:'weight',   unlocked:false },
  ];

  return (
    <div style={{ display:'flex', flexDirection:'column' }}>
      {/* Sticky header */}
      <div style={{ position:'sticky', top:0, zIndex:20, background:T.bg, paddingBottom:4 }}>
        <UnifiedHeader supra="Hero profil" title="Tvoje hero cesta" noBorder/>
        <HeroInfoCard detailed onSettings={() => {}} onPhoto={() => setPhotoPrompt(true)}/>
      </div>

      {/* Photo prompt */}
      {photoPrompt && (
        <div style={{
          position:'fixed', inset:0, zIndex:99,
          background:'rgba(0,0,0,0.75)', display:'flex', alignItems:'flex-end', justifyContent:'center',
        }} onClick={() => setPhotoPrompt(false)}>
          <div style={{
            width:'100%', maxWidth:393,
            background:T.bg, borderRadius:'20px 20px 0 0', padding:'20px 16px 40px',
            border:`1px solid ${T.border}`,
          }} onClick={e => e.stopPropagation()}>
            <div style={{ width:40, height:4, borderRadius:99, background:T.border, margin:'0 auto 18px' }}/>
            <div style={{ fontSize:15, fontWeight:800, color:T.t1, marginBottom:16 }}>Nahrát profilový obrázek</div>
            {[
              { icon:'📷', label:'Fotoaparát' },
              { icon:'🖼️', label:'Vybrat z galerie' },
              { icon:'🗑️', label:'Odebrat fotografii', red:true },
            ].map((a, i) => (
              <button key={i} onClick={() => setPhotoPrompt(false)} style={{
                width:'100%', padding:'14px 16px', borderRadius:12, marginBottom:6,
                background:T.surface, border:`1px solid ${T.border}`,
                display:'flex', alignItems:'center', gap:12, cursor:'pointer',
                fontSize:14, fontWeight:600, color: a.red ? T.red : T.t2,
              }}><span style={{ fontSize:18 }}>{a.icon}</span>{a.label}</button>
            ))}
          </div>
        </div>
      )}

      <div style={{ padding:'0 12px 16px', display:'flex', flexDirection:'column', gap:14 }}>
        {/* Přehled postupu */}
        <div>
          <SectionHead label="Přehled postupu"/>
          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:8 }}>
            {stats2x2.map((s, i) => (
              <div key={i} style={{
                borderRadius:14, padding:'14px 12px',
                background: DOM[s.domain].bg,
                border:`1px solid ${s.color}33`,
                boxShadow:`0 2px 12px ${DOM[s.domain].glow}22`,
                animation:`rpg-card-in .3s ease ${i*0.06}s both`,
              }}>
                <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:8 }}>
                  <IconBox domain={s.domain} size={28}/>
                  <div style={{ fontSize:9, fontWeight:700, color:s.color, textTransform:'uppercase', letterSpacing:'.08em', lineHeight:1.3 }}>{s.label}</div>
                </div>
                <div style={{ fontSize:28, fontWeight:900, color:s.color, letterSpacing:'-0.04em', lineHeight:1 }}>{s.val}</div>
                <div style={{ fontSize:9, color:T.t4, fontWeight:700, textTransform:'uppercase', letterSpacing:'.07em', marginTop:4 }}>{s.sub}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Série */}
        <div>
          <SectionHead label="Série" sub="Aktuální a nejlepší série napříč doménami."/>
          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:8 }}>
            {series.map((s, i) => (
              <div key={i} style={{
                borderRadius:14, padding:'14px 13px',
                background:`linear-gradient(135deg, ${s.dim}, rgba(0,0,0,0))`,
                border:`1px solid ${s.color}40`,
                animation:`rpg-card-in .3s ease ${i*0.08}s both`,
              }}>
                <div style={{ display:'flex', alignItems:'center', gap:7, marginBottom:8 }}>
                  <IconBox domain={s.domain} size={28}/>
                  <span style={{ fontSize:9, fontWeight:700, color:s.color, textTransform:'uppercase', letterSpacing:'.08em' }}>{s.label}</span>
                </div>
                <div style={{ fontSize:26, fontWeight:900, color:s.color, letterSpacing:'-0.04em', lineHeight:1 }}>
                  {s.val}<span style={{ fontSize:11, fontWeight:600, opacity:.7, marginLeft:3 }}>{s.unit}</span>
                </div>
                <div style={{ fontSize:9, color:T.t4, fontWeight:700, textTransform:'uppercase', letterSpacing:'.06em', marginTop:5 }}>{s.sub}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Úspěchy */}
        <div>
          <SectionHead label="Úspěchy" sub="Odemčené odznaky a aktuální postup."/>
          <div style={{ display:'flex', flexDirection:'column', gap:7 }}>
            {achievements.map((a, i) => {
              const d = DOM[a.domain];
              return (
                <div key={i} style={{
                  borderRadius:14, padding:'11px 12px',
                  background: a.unlocked ? `linear-gradient(135deg, ${d.rich}, rgba(0,0,0,0))` : T.surface,
                  border:`1px solid ${a.unlocked ? a.color+'44' : T.border}`,
                  opacity: a.unlocked ? 1 : 0.5,
                  animation:`rpg-card-in .3s ease ${i*0.05}s both`,
                }}>
                  <div style={{ display:'flex', alignItems:'center', gap:11 }}>
                    <div style={{
                      width:42, height:42, borderRadius:13, flexShrink:0,
                      background: a.unlocked ? `linear-gradient(135deg, ${a.color}40, ${a.color}18)` : T.surface,
                      border:`1.5px solid ${a.unlocked ? a.color+'55' : T.border}`,
                      display:'flex', alignItems:'center', justifyContent:'center',
                    }}>
                      <MedalBadge domain={a.domain} size={34}/>
                    </div>
                    <div style={{ flex:1 }}>
                      <div style={{ fontSize:13, fontWeight:800, color: a.unlocked ? T.t1 : T.t3 }}>{a.name}</div>
                      <div style={{ fontSize:11, color:T.t3, marginTop:2 }}>{a.desc}</div>
                    </div>
                    {a.unlocked
                      ? <Badge label="✓ Splněno" color={a.color} small/>
                      : <div style={{ width:20, height:20, display:'flex', alignItems:'center', justifyContent:'center' }}><svg width="12" height="15" viewBox="0 0 12 15" fill="none"><rect x="0.8" y="6" width="10.4" height="9" rx="2" stroke={T.t4} strokeWidth="1.5"/><path d="M3 6V4a3 3 0 016 0v2" stroke={T.t4} strokeWidth="1.5" strokeLinecap="round"/></svg></div>
                    }
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── SOCIAL SCREEN ────────────────────────────────────────────
function SocialScreen() {
  const [tab, setTab] = React.useState('feed');
  const [requestsOpen, setRequestsOpen] = React.useState(true);

  const PENDING_REQUESTS = 1;

  const friends = [
    { name:'Petra Horáková',   handle:'@petra_h',   level:22, title:'Steel Vanguard', streak:34, xp:'102k', online:true,  domain:'steps'    },
    { name:'Karolína Nová',    handle:'@karo_nova',  level:18, title:'Iron Blade',     streak:12, xp:'71k',  online:true,  domain:'activity' },
    { name:'Martin Procházka', handle:'@m_prochazka',level:15, title:'Bronze Shield',  streak:5,  xp:'54k',  online:false, domain:'weight'   },
    { name:'Ondřej Blažek',    handle:'@ondrej_b',   level:12, title:'Copper Scout',   streak:2,  xp:'28k',  online:false, domain:'sleep'    },
  ];

  const leaderboard = [
    { rank:1, name:'Tomáš Knejp',    level:20, xp:2450, you:true  },
    { rank:2, name:'Petra Horáková', level:22, xp:2100, you:false },
    { rank:3, name:'Karolína Nová',  level:18, xp:1890, you:false },
    { rank:4, name:'Martin P.',      level:15, xp:1240, you:false },
    { rank:5, name:'Ondřej B.',      level:12, xp:890,  you:false },
  ];

  const feed = [
    { name:'Petra Horáková',   action:'dokončila quest', detail:'Měsíční válečník',  xp:2400, time:'před 22 min', domain:'activity', type:'quest'   },
    { name:'Karolína Nová',    action:'odemkla úspěch',  detail:'Unbroken Momentum', xp:180,  time:'před 1 hod',  domain:'steps',    type:'achievement' },
    { name:'Martin Procházka', action:'dosáhl levelu',   detail:'Level 15',          xp:0,    time:'před 3 hod',  domain:'xp',       type:'level'   },
    { name:'Petra Horáková',   action:'splnila streak',  detail:'30 dní aktivity',   xp:500,  time:'před 5 hod',  domain:'activity', type:'streak'  },
    { name:'Ondřej Blažek',    action:'dokončil quest',  detail:'Dvojité vítězství', xp:1195, time:'včera',       domain:'calories', type:'quest'   },
  ];

  const rankColors = ['#FBBF24','#CBD5E1','#CD7F32'];

  const tabs = [
    { id:'feed',        label:'Feed',      badge:0 },
    { id:'friends',     label:'Přátelé',   badge: PENDING_REQUESTS },
    { id:'leaderboard', label:'Žebříček',  badge:0 },
  ];

  function AvatarPlaceholder({ name, size = 36, color }) {
    const initials = name.split(' ').map(w=>w[0]).join('').slice(0,2);
    return (
      <div style={{
        width:size, height:size, borderRadius:size*0.3, flexShrink:0,
        background: color ? `${color}28` : T.accentDim,
        border: `1.5px solid ${color || T.accent}44`,
        display:'flex', alignItems:'center', justifyContent:'center',
        fontSize:size*0.34, fontWeight:800, color: color || T.accent,
        letterSpacing:'-0.02em',
      }}>{initials}</div>
    );
  }

  return (
    <div style={{ display:'flex', flexDirection:'column', height:'100%' }}>
      {/* Sticky header */}
      <div style={{ position:'sticky', top:0, zIndex:20, background:T.bg }}>
        <UnifiedHeader
          supra="Social"
          title="Přátelé & výzvy"
          right={
            <HeaderIconBtn badge={PENDING_REQUESTS}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2v10z" stroke={T.accent} strokeWidth="2" fill={T.accentDim}/></svg>
            </HeaderIconBtn>
          }
          noBorder
        />

        {/* Tabs */}
        <div style={{ display:'flex', gap:0, padding:'0 12px 10px', borderBottom:`1px solid ${T.border}` }}>
          {tabs.map(t => {
            const active = tab === t.id;
            return (
              <button key={t.id} onClick={() => setTab(t.id)} style={{
                flex:1, padding:'8px 0', border:'none', background:'none', cursor:'pointer',
                fontSize:12, fontWeight:700, color: active ? T.accent : T.t3,
                borderBottom: `2px solid ${active ? T.accent : 'transparent'}`,
                transition:'all .18s', position:'relative', display:'flex', alignItems:'center', justifyContent:'center', gap:5,
              }}>
                {t.label}
                {t.badge > 0 && (
                  <div style={{
                    width:16, height:16, borderRadius:99, background:T.red,
                    fontSize:9, fontWeight:800, color:'#fff', display:'flex', alignItems:'center', justifyContent:'center',
                  }}>{t.badge}</div>
                )}
              </button>
            );
          })}
        </div>
      </div>

      <div style={{ flex:1, overflowY:'auto', padding:'10px 12px 16px', display:'flex', flexDirection:'column', gap:10 }}>

        {/* ── FRIENDS TAB ── */}
        {tab === 'friends' && (
          <>
            {/* Friend requests */}
            <div style={{
              borderRadius:14, overflow:'hidden',
              background:`linear-gradient(135deg, rgba(239,68,68,0.1), rgba(0,0,0,0))`,
              border:`1px solid rgba(239,68,68,0.3)`,
            }}>
              <div style={{
                display:'flex', alignItems:'center', justifyContent:'space-between', padding:'10px 13px',
                cursor:'pointer',
              }} onClick={() => setRequestsOpen(o => !o)}>
                <div style={{ display:'flex', alignItems:'center', gap:8 }}>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M16 21v-2a4 4 0 00-4-4H6a4 4 0 00-4 4v2" stroke={T.red} strokeWidth="2" strokeLinecap="round"/><circle cx="9" cy="7" r="4" stroke={T.red} strokeWidth="2"/><line x1="19" y1="8" x2="19" y2="14" stroke={T.red} strokeWidth="2" strokeLinecap="round"/><line x1="22" y1="11" x2="16" y2="11" stroke={T.red} strokeWidth="2" strokeLinecap="round"/></svg>
                  <span style={{ fontSize:12, fontWeight:700, color:T.red }}>Žádosti o přátelství</span>
                  <div style={{ width:18, height:18, borderRadius:99, background:T.red, fontSize:10, fontWeight:800, color:'#fff', display:'flex', alignItems:'center', justifyContent:'center' }}>{PENDING_REQUESTS}</div>
                </div>
                <svg width="10" height="6" viewBox="0 0 10 6" style={{ transform: requestsOpen ? 'rotate(180deg)' : 'none', transition:'transform .2s' }}><path d="M1 1l4 4 4-4" stroke={T.t3} strokeWidth="1.8" fill="none" strokeLinecap="round"/></svg>
              </div>
              {requestsOpen && (
                <div style={{ borderTop:`1px solid rgba(239,68,68,0.2)`, padding:'10px 13px' }}>
                  <div style={{ display:'flex', alignItems:'center', gap:10 }}>
                    <AvatarPlaceholder name="JV" size={40} color={T.orange}/>
                    <div style={{ flex:1 }}>
                      <div style={{ fontSize:13, fontWeight:700, color:T.t1 }}>jan_vondrak</div>
                      <div style={{ fontSize:11, color:T.t4 }}>Chce se stát tvým přítelem</div>
                    </div>
                    <div style={{ display:'flex', gap:6 }}>
                      <button style={{ background:T.emerald+'22', border:`1px solid ${T.emerald}44`, borderRadius:9, padding:'6px 12px', fontSize:12, fontWeight:700, color:T.emerald, cursor:'pointer' }}>Přijmout</button>
                      <button style={{ background:'rgba(239,68,68,0.12)', border:'1px solid rgba(239,68,68,0.3)', borderRadius:9, padding:'6px 12px', fontSize:12, fontWeight:700, color:T.red, cursor:'pointer' }}>Odmítnout</button>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Search */}
            <div style={{
              display:'flex', gap:8, alignItems:'center',
              background:T.surface, border:`1px solid ${T.border}`, borderRadius:12, padding:'8px 12px',
            }}>
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none"><circle cx="11" cy="11" r="8" stroke={T.t3} strokeWidth="2"/><path d="M21 21l-4.35-4.35" stroke={T.t3} strokeWidth="2" strokeLinecap="round"/></svg>
              <span style={{ fontSize:13, color:T.t4, flex:1 }}>Hledat podle přezdívky…</span>
              <button style={{ background:T.accent, border:'none', borderRadius:8, padding:'5px 12px', fontSize:12, fontWeight:700, color:'#fff', cursor:'pointer' }}>Najít</button>
            </div>

            {/* Online now */}
            <div>
              <SectionHead label="Online" color={T.emerald}/>
              <div style={{ display:'flex', flexDirection:'column', gap:6 }}>
                {friends.filter(f=>f.online).map((f, i) => {
                  const d = DOM[f.domain];
                  return (
                    <div key={i} style={{
                      borderRadius:14, padding:'11px 13px',
                      background:`linear-gradient(135deg, ${d.dim}, ${T.surface})`,
                      border:`1px solid ${d.color}33`,
                      display:'flex', alignItems:'center', gap:11,
                      animation:`rpg-card-in .3s ease ${i*0.05}s both`,
                    }}>
                      <div style={{ position:'relative' }}>
                        <AvatarPlaceholder name={f.name} size={42} color={d.color}/>
                        <div style={{ position:'absolute', bottom:0, right:0, width:11, height:11, borderRadius:99, background:T.emerald, border:`2px solid ${T.bg}` }}/>
                      </div>
                      <div style={{ flex:1 }}>
                        <div style={{ fontSize:13, fontWeight:700, color:T.t1 }}>{f.name}</div>
                        <div style={{ display:'flex', alignItems:'center', gap:5, marginTop:2 }}>
                          <LevelBadge level={f.level} size={18}/>
                          <span style={{ fontFamily:'"Press Start 2P",monospace', fontSize:5.5, color:T.gold, letterSpacing:.7 }}>{f.title.toUpperCase()}</span>
                        </div>
                      </div>
                      <div style={{ textAlign:'right' }}>
                        <div style={{ fontSize:13, fontWeight:800, color:d.color }}>{f.xp}</div>
                        <div style={{ fontSize:9, color:T.t4, marginTop:1 }}>XP</div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* All friends */}
            <div>
              <SectionHead label="Všichni přátelé"/>
              <div style={{ display:'flex', flexDirection:'column', gap:6 }}>
                {friends.filter(f=>!f.online).map((f, i) => {
                  const d = DOM[f.domain];
                  return (
                    <div key={i} style={{
                      borderRadius:14, padding:'11px 13px',
                      background:T.surface, border:`1px solid ${T.border}`,
                      display:'flex', alignItems:'center', gap:11,
                      opacity:0.85,
                    }}>
                      <div style={{ position:'relative' }}>
                        <AvatarPlaceholder name={f.name} size={42} color={d.color}/>
                        <div style={{ position:'absolute', bottom:0, right:0, width:11, height:11, borderRadius:99, background:T.t4, border:`2px solid ${T.bg}` }}/>
                      </div>
                      <div style={{ flex:1 }}>
                        <div style={{ fontSize:13, fontWeight:700, color:T.t2 }}>{f.name}</div>
                        <div style={{ display:'flex', alignItems:'center', gap:5, marginTop:2 }}>
                          <LevelBadge level={f.level} size={18}/>
                          <span style={{ fontFamily:'"Press Start 2P",monospace', fontSize:5.5, color:T.gold, letterSpacing:.7 }}>{f.title.toUpperCase()}</span>
                        </div>
                      </div>
                      <div style={{ textAlign:'right' }}>
                        <div style={{ fontSize:13, fontWeight:800, color:T.t2 }}>{f.xp}</div>
                        <div style={{ fontSize:9, color:T.t4, marginTop:1 }}>XP</div>
                        <div style={{ fontSize:9, color:T.t4 }}>🔥 {f.streak}d série</div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </>
        )}

        {/* ── LEADERBOARD TAB ── */}
        {tab === 'leaderboard' && (
          <>
            {/* Week toggle */}
            <div style={{ display:'flex', gap:6 }}>
              {['Tento týden','Celkem'].map((l,i) => (
                <button key={i} style={{
                  flex:1, padding:'8px 0', borderRadius:10, border:'none', cursor:'pointer',
                  background: i===0 ? T.accent : T.surface,
                  fontSize:12, fontWeight:700, color: i===0 ? '#fff' : T.t3,
                }}>{l}</button>
              ))}
            </div>

            {/* Top 3 podium */}
            <div style={{
              borderRadius:18, padding:'16px 14px',
              background:`linear-gradient(145deg, ${T.goldDim}, rgba(0,0,0,0))`,
              border:`1px solid ${T.gold}33`,
              position:'relative', overflow:'hidden',
            }}>
              <Sparkle x={85} y={10} color={T.gold} delay={0.4} scale={.8}/>
              <Sparkle x={8}  y={75} color={T.gold} delay={1.2} scale={.55}/>
              <div style={{ textAlign:'center', marginBottom:12 }}>
                <div style={{ fontSize:11, fontWeight:700, color:T.gold, textTransform:'uppercase', letterSpacing:'.1em' }}>Top hráči tohoto týdne</div>
              </div>
              <div style={{ display:'flex', alignItems:'flex-end', justifyContent:'center', gap:10 }}>
                {/* 2nd */}
                <div style={{ textAlign:'center', flex:1 }}>
                  <div style={{ fontSize:20 }}>🥈</div>
                  <div style={{ width:40, height:40, borderRadius:13, background:`${rankColors[1]}22`, border:`1.5px solid ${rankColors[1]}55`, display:'flex', alignItems:'center', justifyContent:'center', margin:'6px auto', fontSize:14, fontWeight:800, color:rankColors[1] }}>PH</div>
                  <div style={{ fontSize:10, fontWeight:700, color:T.t2 }}>Petra H.</div>
                  <div style={{ fontSize:11, fontWeight:800, color:rankColors[1] }}>2 100</div>
                  <div style={{ fontSize:9, color:T.t4 }}>XP</div>
                </div>
                {/* 1st */}
                <div style={{ textAlign:'center', flex:1 }}>
                  <div style={{ fontSize:24 }}>🥇</div>
                  <div style={{
                    width:50, height:50, borderRadius:16, background:`${rankColors[0]}28`, border:`2px solid ${rankColors[0]}88`,
                    display:'flex', alignItems:'center', justifyContent:'center', margin:'6px auto',
                    boxShadow:`0 0 16px ${T.goldGlow}`,
                    fontSize:15, fontWeight:900, color:rankColors[0],
                  }}>TK</div>
                  <div style={{ fontSize:11, fontWeight:800, color:T.t1 }}>Tomáš K.</div>
                  <div style={{ fontSize:13, fontWeight:900, color:rankColors[0] }}>2 450</div>
                  <div style={{ fontSize:9, color:T.t4 }}>XP</div>
                  <Badge label="Ty!" color={T.gold} small/>
                </div>
                {/* 3rd */}
                <div style={{ textAlign:'center', flex:1 }}>
                  <div style={{ fontSize:18 }}>🥉</div>
                  <div style={{ width:38, height:38, borderRadius:12, background:`${rankColors[2]}22`, border:`1.5px solid ${rankColors[2]}55`, display:'flex', alignItems:'center', justifyContent:'center', margin:'6px auto', fontSize:13, fontWeight:800, color:rankColors[2] }}>KN</div>
                  <div style={{ fontSize:10, fontWeight:700, color:T.t2 }}>Karolína</div>
                  <div style={{ fontSize:11, fontWeight:800, color:rankColors[2] }}>1 890</div>
                  <div style={{ fontSize:9, color:T.t4 }}>XP</div>
                </div>
              </div>
            </div>

            {/* Full list */}
            <div style={{ display:'flex', flexDirection:'column', gap:5 }}>
              {leaderboard.map((p, i) => (
                <div key={i} style={{
                  borderRadius:12, padding:'10px 13px',
                  background: p.you ? T.accentDim : T.surface,
                  border: p.you ? `1px solid ${T.accent}44` : `1px solid ${T.border}`,
                  display:'flex', alignItems:'center', gap:10,
                  boxShadow: p.you ? `0 2px 12px ${T.accentGlow}` : 'none',
                }}>
                  <div style={{
                    width:26, height:26, borderRadius:8, flexShrink:0,
                    background: i<3 ? `${rankColors[i]}22` : T.surface,
                    border: `1px solid ${i<3 ? rankColors[i]+'55' : T.border}`,
                    display:'flex', alignItems:'center', justifyContent:'center',
                    fontSize:12, fontWeight:800, color: i<3 ? rankColors[i] : T.t3,
                  }}>{p.rank}</div>
                  <div style={{ flex:1 }}>
                    <div style={{ fontSize:13, fontWeight:700, color: p.you ? T.t1 : T.t2 }}>{p.name} {p.you && '(ty)'}</div>
                    <div style={{ fontSize:10, color:T.t3, marginTop:1 }}>Level {p.level}</div>
                  </div>
                  <div style={{ fontWeight:800, fontSize:14, color: p.you ? T.accent : T.t2 }}>{p.xp.toLocaleString()} XP</div>
                </div>
              ))}
            </div>
          </>
        )}

        {/* ── FEED TAB ── */}
        {tab === 'feed' && (
          <div style={{ display:'flex', flexDirection:'column', gap:7 }}>
            <div style={{ fontSize:11, color:T.t4, fontWeight:600, textTransform:'uppercase', letterSpacing:'.1em', marginBottom:4 }}>Aktivita přátel</div>
            {feed.map((item, i) => {
              const d = DOM[item.domain];
              const typeIcons = { quest:'🏴', achievement:'🏅', level:'⬆️', streak:'🔥' };
              return (
                <div key={i} style={{
                  borderRadius:14, padding:'11px 13px',
                  background:`linear-gradient(135deg, ${d.dim}, ${T.surface})`,
                  border:`1px solid ${d.color}28`,
                  display:'flex', alignItems:'flex-start', gap:11,
                  animation:`rpg-card-in .3s ease ${i*0.04}s both`,
                }}>
                  <div style={{
                    width:38, height:38, borderRadius:12, flexShrink:0,
                    background:`${d.color}22`, border:`1.5px solid ${d.color}44`,
                    display:'flex', alignItems:'center', justifyContent:'center', fontSize:17,
                  }}>{typeIcons[item.type] || '⚡'}</div>
                  <div style={{ flex:1 }}>
                    <div style={{ fontSize:13, fontWeight:700, color:T.t1, lineHeight:1.3 }}>
                      <span style={{ color:d.color }}>{item.name}</span>
                      {' '}{item.action}
                    </div>
                    <div style={{ fontSize:12, fontWeight:600, color:T.t2, marginTop:2 }}>"{item.detail}"</div>
                    <div style={{ display:'flex', alignItems:'center', gap:8, marginTop:5 }}>
                      <span style={{ fontSize:10, color:T.t4 }}>{item.time}</span>
                      {item.xp > 0 && <Badge label={`+${item.xp} XP`} color={d.color} small/>}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Tab Bar ──────────────────────────────────────────────────
function TabBar({ active, onTab }) {
  const tabs = [
    { id:'dashboard', label:'Přehled', icon:'home'   },
    { id:'quests',    label:'Questy',  icon:'quests' },
    { id:'profile',   label:'Hero',    icon:'hero'   },
    { id:'social',    label:'Social',  icon:'glory'  },
  ];
  return (
    <div style={{ display:'flex', background:T.bg, borderTop:`1px solid ${T.border}`, paddingBottom:22, paddingTop:4, flexShrink:0 }}>
      {tabs.map(tab => {
        const on = active === tab.id;
        const c = on ? T.accent : T.t3;
        return (
          <button key={tab.id} onClick={() => onTab(tab.id)} style={{
            flex:1, display:'flex', flexDirection:'column', alignItems:'center', gap:3,
            background:'none', border:'none', cursor:'pointer', padding:'6px 0',
          }}>
            <div style={{
              width:38, height:38, borderRadius:12, display:'flex', alignItems:'center', justifyContent:'center',
              background: on ? T.accentDim : 'transparent',
              boxShadow: on ? `0 0 14px ${T.accentGlow}` : 'none',
              transition:'all .2s',
            }}>
              <TabIcon name={tab.icon} color={c} size={20}/>
            </div>
            <span style={{ fontSize:9, fontWeight: on?700:500, color:c, letterSpacing:'.04em' }}>{tab.label}</span>
          </button>
        );
      })}
    </div>
  );
}

// ─── App Root ─────────────────────────────────────────────────
function RPGApp() {
  const [screen, setScreen] = React.useState(
    () => localStorage.getItem('rpg_screen') || 'dashboard'
  );
  const [isDark, setIsDark] = React.useState(
    () => localStorage.getItem('rpg_dark') !== 'false'
  );

  // Update theme globals before every render
  T = isDark ? DARK_T : LIGHT_T;
  DOM = isDark ? DARK_DOM : LIGHT_DOM;
  _isDark = isDark;
  _toggleTheme = () => {
    const next = !isDark;
    setIsDark(next);
    localStorage.setItem('rpg_dark', String(next));
  };

  const setTab = (s) => { setScreen(s); localStorage.setItem('rpg_screen', s); };

  const screens = {
    dashboard: <DashboardScreen/>,
    quests:    <QuestsScreen/>,
    profile:   <HeroScreen/>,
    social:    <SocialScreen/>,
  };

  return (
    <div style={{ height:'100%', display:'flex', flexDirection:'column', background:T.bg, fontFamily:'Inter, sans-serif', WebkitFontSmoothing:'antialiased' }}>
      <div style={{ flex:1, overflowY:'auto', overflowX:'hidden' }}>
        {screens[screen] || screens.dashboard}
      </div>
      <TabBar active={screen} onTab={setTab}/>
    </div>
  );
}

Object.assign(window, { RPGApp });
