// celebration-fx.jsx — shared FX primitives (rays, particles, aura)
// All elements positioned absolute; parent must be relative + overflow hidden.

function Aura({ rarity, intensity = 1 }) {
  const r = window.RARITY[rarity];
  return (
    <div style={{
      position: 'absolute', inset: 0, pointerEvents: 'none',
      background:
        `radial-gradient(circle at 50% 38%, ${r.aura} 0%, ${r.aura.replace(/[\d.]+\)$/, '0)')} 55%)`,
      opacity: intensity,
    }}/>
  );
}

function Rays({ rarity, intensity = 1 }) {
  const r = window.RARITY[rarity];
  const op = (r.rays || 0.2) * intensity;
  if (op < 0.05) return null;
  // conic gradient sun-rays + slow rotate
  return (
    <div className="cel-rays" style={{
      position: 'absolute', left: '50%', top: '34%',
      width: 720, height: 720, marginLeft: -360, marginTop: -360,
      pointerEvents: 'none',
      background: `conic-gradient(from 0deg, transparent 0deg, ${r.color}33 6deg, transparent 12deg, transparent 30deg, ${r.color}22 35deg, transparent 41deg, transparent 60deg, ${r.color}33 65deg, transparent 72deg, transparent 90deg, ${r.color}22 95deg, transparent 102deg, transparent 120deg, ${r.color}33 126deg, transparent 132deg, transparent 150deg, ${r.color}22 154deg, transparent 162deg, transparent 180deg, ${r.color}33 186deg, transparent 192deg, transparent 210deg, ${r.color}22 215deg, transparent 222deg, transparent 240deg, ${r.color}33 245deg, transparent 252deg, transparent 270deg, ${r.color}22 276deg, transparent 282deg, transparent 300deg, ${r.color}33 305deg, transparent 312deg, transparent 330deg, ${r.color}22 335deg, transparent 342deg)`,
      opacity: op,
      mask: 'radial-gradient(circle at 50% 50%, black 5%, black 30%, transparent 70%)',
      WebkitMask: 'radial-gradient(circle at 50% 50%, black 5%, black 30%, transparent 70%)',
      animation: 'celRotate 24s linear infinite',
      filter: 'blur(0.5px)',
    }}/>
  );
}

function Particles({ rarity, count = 24, intensity = 1 }) {
  const r = window.RARITY[rarity];
  if (intensity < 0.05) return null;
  const dots = React.useMemo(() => Array.from({ length: count }, (_, i) => ({
    left: Math.random() * 100,
    delay: Math.random() * 3,
    duration: 3 + Math.random() * 4,
    size: 2 + Math.random() * (rarity === 'mythic' || rarity === 'legendary' ? 5 : 3),
    color: r.particle[i % r.particle.length],
    drift: (Math.random() - 0.5) * 60,
  })), [rarity, count]);
  return (
    <div style={{ position:'absolute', inset:0, pointerEvents:'none', overflow:'hidden' }}>
      {dots.map((d, i) => (
        <div key={i} style={{
          position:'absolute',
          left: `${d.left}%`, bottom: -10,
          width: d.size, height: d.size,
          borderRadius: '50%',
          background: d.color,
          boxShadow: `0 0 ${d.size*3}px ${d.color}`,
          opacity: 0,
          animation: `celRise ${d.duration}s ${d.delay}s linear infinite`,
          '--drift': `${d.drift}px`,
        }}/>
      ))}
    </div>
  );
}

// Confetti burst — fires once on mount
function Confetti({ rarity, n = 30 }) {
  const r = window.RARITY[rarity];
  const bits = React.useMemo(() => Array.from({ length: n }, (_, i) => {
    const angle = (Math.PI * 2 * i) / n + (Math.random() - 0.5) * 0.4;
    const dist = 120 + Math.random() * 200;
    return {
      x: Math.cos(angle) * dist,
      y: Math.sin(angle) * dist - 40,
      rot: Math.random() * 720 - 360,
      delay: Math.random() * 0.15,
      size: 4 + Math.random() * 6,
      color: r.particle[i % r.particle.length],
      shape: i % 3,
    };
  }), [rarity, n]);
  return (
    <div style={{ position:'absolute', left:'50%', top:'42%', pointerEvents:'none' }}>
      {bits.map((b, i) => (
        <div key={i} style={{
          position:'absolute', left:0, top:0,
          width: b.size, height: b.shape === 0 ? b.size * 1.6 : b.size,
          background: b.color,
          borderRadius: b.shape === 2 ? '50%' : 2,
          boxShadow: `0 0 8px ${b.color}88`,
          opacity: 0,
          animation: `celBurst 1.6s ${b.delay}s cubic-bezier(.2,.7,.3,1) forwards`,
          '--tx': `${b.x}px`, '--ty': `${b.y}px`, '--rot': `${b.rot}deg`,
        }}/>
      ))}
    </div>
  );
}

// Reusable card chip showing a single reward
function RewardChip({ rarity, reward, size = 'md' }) {
  const r = window.RARITY[rarity];
  const big = size === 'lg';
  const thumb = big ? 84 : 56;
  return (
    <div style={{
      display:'flex', alignItems:'center', gap: big ? 16 : 12,
      padding: big ? '14px 16px' : '10px 12px',
      borderRadius: big ? 18 : 14,
      background: `linear-gradient(180deg, ${r.color}14, ${r.color}05)`,
      border: `1px solid ${r.color}55`,
      boxShadow: `0 0 0 1px ${r.color}22, 0 8px 24px -10px ${r.glow}`,
      backdropFilter: 'blur(6px)',
      width: big ? '100%' : 'auto',
    }}>
      <div style={{
        width: thumb, height: thumb, borderRadius: big ? 16 : 12,
        flexShrink: 0,
        background: `linear-gradient(135deg, ${r.color}33, ${r.color2}1f)`,
        border: `1px solid ${r.rim}`,
        display:'flex', alignItems:'center', justifyContent:'center',
        position:'relative', overflow:'hidden',
      }}>
        <RewardThumb kind={reward.kind} color={r.color} size={big ? 44 : 30}/>
        <div style={{ // shine
          position:'absolute', inset: 0,
          background: `linear-gradient(135deg, transparent 40%, ${r.color2}66 50%, transparent 60%)`,
          mixBlendMode:'screen', opacity:0.7,
          animation: 'celShimmer 4s ease-in-out infinite',
        }}/>
      </div>
      <div style={{ minWidth:0, flex:1 }}>
        <div style={{
          fontSize: big ? 18 : 15, fontWeight: 700, color:'#F5F3FF',
          lineHeight: 1.2, marginBottom: 2,
          textOverflow:'ellipsis', overflow:'hidden', whiteSpace:'nowrap',
        }}>{reward.name}</div>
        <div style={{
          fontSize: big ? 11 : 10, fontWeight: 800, letterSpacing:'0.14em',
          textTransform:'uppercase', color: r.color,
        }}>{r.label}{reward.sub ? ` · ` : ''}<span style={{ color:'#8A85A8', fontWeight:600, letterSpacing:'0.06em' }}>{reward.sub}</span></div>
      </div>
    </div>
  );
}

function RewardThumb({ kind, color, size = 30 }) {
  const I = ({ children }) => <div style={{ color, filter: `drop-shadow(0 0 6px ${color}99)` }}>{children}</div>;
  if (kind === 'title')    return <I><window.IconTitle size={size} color={color}/></I>;
  if (kind === 'badge')    return <I><window.IconMedal size={size} color={color}/></I>;
  if (kind === 'flame')    return <I><window.IconFlame size={size} color={color}/></I>;
  if (kind === 'flag')     return <I><window.IconFlag size={size} color={color}/></I>;
  if (kind === 'location') return <I><window.IconMap size={size} color={color}/></I>;
  if (kind === 'frame')    return <I><window.IconGem size={size} color={color}/></I>;
  if (kind === 'xp')       return <I><window.IconBolt size={size} color={color}/></I>;
  return <I><window.IconSparkle size={size} color={color}/></I>;
}

Object.assign(window, { Aura, Rays, Particles, Confetti, RewardChip, RewardThumb });
