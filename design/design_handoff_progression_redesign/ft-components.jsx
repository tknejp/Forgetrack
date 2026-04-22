// ft-components.jsx — Forgetrack shared UI (RPG / billion-dollar JP fitness tone)

// ── Sparkles overlay ─────────────────────────────────────────────────────
function Sparkles({ color, show }) {
  if (!show) return null;
  const sp = [{x:8,y:10,s:1,d:0},{x:85,y:8,s:0.7,d:0.4},{x:92,y:75,s:0.8,d:0.9},{x:5,y:80,s:0.6,d:0.6}];
  return (
    <div style={{ position:'absolute', inset:0, pointerEvents:'none', overflow:'hidden', borderRadius:'inherit' }}>
      {sp.map((s,i)=>(
        <div key={i} style={{ position:'absolute', left:`${s.x}%`, top:`${s.y}%`, animation:`ft-spark 2.4s ease-in-out ${s.d}s infinite` }}>
          <svg width={10*s.s} height={10*s.s} viewBox="0 0 10 10"><path d="M5 0L5.8 4.2 10 5 5.8 5.8 5 10 4.2 5.8 0 5 4.2 4.2 5 0z" fill={color}/></svg>
        </div>
      ))}
    </div>
  );
}

function BgStars({ show }) {
  if (!show) return null;
  return (
    <div style={{ position:'absolute', inset:0, pointerEvents:'none', overflow:'hidden' }}>
      {[...Array(22)].map((_,i)=>(
        <div key={i} style={{
          position:'absolute', left:`${(i*37+7)%100}%`, top:`${(i*53+13)%90}%`,
          width:i%3===0?2:1, height:i%3===0?2:1, borderRadius:'50%', background:'rgba(255,255,255,0.22)',
          animation:`ft-spark ${2+(i%3)*0.7}s ease-in-out ${(i*0.3)%2}s infinite`,
        }}/>
      ))}
    </div>
  );
}

// ── Progress bar (6px, glow) ─────────────────────────────────────────────
function ProgressBar({ value, color, glow, height=6 }) {
  const pct = Math.min(1, Math.max(0, value));
  return (
    <div style={{ height, borderRadius:99, background:'rgba(255,255,255,0.08)', overflow:'hidden', position:'relative' }}>
      <div style={{
        height:'100%', width:`${pct*100}%`, borderRadius:99,
        background:`linear-gradient(90deg,${color},${color}cc)`,
        boxShadow:`0 0 8px ${glow}`,
        transition:'width 0.6s cubic-bezier(0.4,0,0.2,1)',
      }}/>
    </div>
  );
}

// ── Stat cell ────────────────────────────────────────────────────────────
function StatCell({ value, label, unit, color, compact }) {
  return (
    <div style={{ flex:1, textAlign:'center' }}>
      <div style={{ fontSize: compact?18:22, fontWeight:800, color, lineHeight:1, letterSpacing:'-0.03em' }}>
        {value}{unit && <span style={{ fontSize:compact?11:13, fontWeight:600, opacity:0.7, marginLeft:1 }}>{unit}</span>}
      </div>
      <div style={{ fontSize:10, color:'rgba(255,255,255,0.45)', marginTop:3, fontWeight:500, textTransform:'uppercase', letterSpacing:'0.06em' }}>{label}</div>
    </div>
  );
}

// ── Stat card (gradient + glow + sparkles) ───────────────────────────────
function StatCard({ icon, label, color, colorDim, colorGlow, gradient, stats, progress, badge, trophy, xp, alert, tweaks, children, delay=0 }) {
  const [open, setOpen] = React.useState(true);
  const compact = tweaks.compact;
  return (
    <div onClick={()=>setOpen(o=>!o)} style={{
      borderRadius:18, background:gradient,
      border:`1px solid ${colorDim}`,
      boxShadow: tweaks.glow ? `0 4px 24px ${colorGlow}, 0 1px 0 rgba(255,255,255,0.06) inset` : '0 2px 8px rgba(0,0,0,0.3)',
      padding: compact?'12px 14px':'14px 16px',
      position:'relative', overflow:'hidden', cursor:'pointer',
      animation:`ft-card-in 0.35s ease ${delay}s both`,
    }}>
      <Sparkles color={color} show={tweaks.sparkles}/>
      <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom: open?12:0 }}>
        <div style={{
          width: compact?32:36, height: compact?32:36, borderRadius:10,
          background:colorDim, border:`1px solid ${color}44`,
          display:'flex', alignItems:'center', justifyContent:'center',
          fontSize: compact?16:18, flexShrink:0,
        }}>{icon}</div>
        <span style={{ fontWeight:700, fontSize: compact?14:15, color:'rgba(255,255,255,0.95)', flex:1 }}>{label}</span>
        {badge && <div style={{ background:colorDim, border:`1px solid ${color}55`, borderRadius:99, padding:'2px 9px', fontSize:11, fontWeight:700, color }}>{badge}</div>}
        {trophy && <span style={{ fontSize:16 }}>🏆</span>}
        {xp && <div style={{ background:'rgba(124,111,255,0.18)', border:'1px solid rgba(124,111,255,0.35)', borderRadius:99, padding:'2px 8px', fontSize:10, fontWeight:700, color:'#A89BFF' }}>{xp}</div>}
        <svg width="14" height="14" viewBox="0 0 14 14" style={{ flexShrink:0, transition:'transform 0.2s', transform: open?'rotate(0deg)':'rotate(-90deg)' }}>
          <path d="M3 5l4 4 4-4" stroke="rgba(255,255,255,0.4)" strokeWidth="1.8" strokeLinecap="round" fill="none"/>
        </svg>
      </div>
      {open && <>
        {stats && (
          <div style={{ display:'flex', gap:4, marginBottom:10, paddingTop:8, borderTop:'1px solid rgba(255,255,255,0.07)' }}>
            {stats.map((s,i)=>(
              <React.Fragment key={i}>
                {i>0 && <div style={{ width:1, background:'rgba(255,255,255,0.07)', alignSelf:'stretch' }}/>}
                <StatCell {...s} color={i===0?color:'rgba(255,255,255,0.85)'} compact={compact}/>
              </React.Fragment>
            ))}
          </div>
        )}
        {typeof progress === 'number' && (<>
          <ProgressBar value={progress} color={color} glow={colorGlow} height={compact?5:6}/>
          {stats && (
            <div style={{ display:'flex', justifyContent:'space-between', marginTop:5, fontSize:10, color:'rgba(255,255,255,0.35)', fontWeight:500 }}>
              <span>{stats[0].value} / {stats[1].value}{stats[1].unit?' '+stats[1].unit:''}</span>
              <span>{Math.round(progress*100)}%</span>
            </div>
          )}
        </>)}
        {children}
      </>}
    </div>
  );
}

// ── Tab pill ─────────────────────────────────────────────────────────────
function TabPill({ tabs, active, onChange, accent, accentGlow }) {
  return (
    <div style={{ display:'flex', background:'rgba(255,255,255,0.06)', borderRadius:14, padding:3, gap:2 }}>
      {tabs.map(t=>{
        const on = t===active;
        return (
          <button key={t} onClick={()=>onChange(t)} style={{
            flex:1, height:34, borderRadius:11, border:'none', cursor:'pointer',
            background: on?`linear-gradient(135deg,${accent}cc,${accent}99)`:'transparent',
            color: on?'#fff':'rgba(255,255,255,0.45)',
            fontWeight: on?700:500, fontSize:13, fontFamily:'Inter,sans-serif',
            boxShadow: on?`0 2px 12px ${accentGlow}`:'none', transition:'all 0.2s',
          }}>{t}</button>
        );
      })}
    </div>
  );
}

// ── Date nav ─────────────────────────────────────────────────────────────
function DateNav({ offset, onChange }) {
  const d = new Date(2026, 3, 21+offset);
  const days=['Sun','Mon','Tue','Wed','Thu','Fri','Sat'], months=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  const label = `${days[d.getDay()]} ${d.getDate()} ${months[d.getMonth()]}`;
  return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', padding:'0 4px' }}>
      <button onClick={()=>onChange(offset-1)} style={{ width:32, height:32, borderRadius:10, border:'none', background:'rgba(255,255,255,0.08)', color:'rgba(255,255,255,0.7)', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center' }}>
        <svg width="8" height="14" viewBox="0 0 8 14"><path d="M7 1L1 7l6 6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" fill="none"/></svg>
      </button>
      <div style={{ textAlign:'center' }}>
        <div style={{ fontSize:14, fontWeight:700, color:'#fff', letterSpacing:'-0.01em' }}>{label}</div>
        <div style={{ fontSize:10, color:'rgba(255,255,255,0.4)', marginTop:1, fontWeight:500 }}>Synced 17:19</div>
      </div>
      <button onClick={()=>onChange(offset+1)} style={{ width:32, height:32, borderRadius:10, border:'none', background:'rgba(255,255,255,0.08)', color:'rgba(255,255,255,0.7)', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center' }}>
        <svg width="8" height="14" viewBox="0 0 8 14"><path d="M1 1l6 6-6 6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" fill="none"/></svg>
      </button>
    </div>
  );
}

// ── XP bar (RPG-themed) ──────────────────────────────────────────────────
function XpBar({ level, title, xp, xpMax, accent, accentGlow }) {
  return (
    <div style={{ background:'rgba(255,255,255,0.05)', borderRadius:12, padding:'8px 12px', display:'flex', alignItems:'center', gap:10, border:'1px solid rgba(255,255,255,0.07)' }}>
      <div style={{ width:28, height:28, borderRadius:8, background:`linear-gradient(135deg,${accent},${accent}88)`, display:'flex', alignItems:'center', justifyContent:'center', fontSize:12, fontWeight:800, color:'#fff', flexShrink:0 }}>{level}</div>
      <div style={{ flex:1 }}>
        <div style={{ display:'flex', justifyContent:'space-between', marginBottom:4 }}>
          <span style={{ fontSize:10, fontWeight:700, color:accent, textTransform:'uppercase', letterSpacing:'0.06em' }}>Level {level} · {title}</span>
          <span style={{ fontSize:10, color:'rgba(255,255,255,0.35)', fontWeight:500 }}>{xp} / {xpMax} XP</span>
        </div>
        <ProgressBar value={xp/xpMax} color={accent} glow={accentGlow} height={5}/>
      </div>
    </div>
  );
}

// ── Section header ───────────────────────────────────────────────────────
function SectionHead({ label, color }) {
  return (
    <div style={{ display:'flex', alignItems:'center', gap:8, padding:'4px 2px' }}>
      <svg width="10" height="10" viewBox="0 0 10 10"><path d="M5 0L5.8 4.2 10 5 5.8 5.8 5 10 4.2 5.8 0 5 4.2 4.2 5 0z" fill={color}/></svg>
      <span style={{ fontSize:11, fontWeight:700, color, textTransform:'uppercase', letterSpacing:'0.1em' }}>{label}</span>
    </div>
  );
}

// ── Activity row ─────────────────────────────────────────────────────────
function ActivityRow({ type, date, duration, kcal, color, colorDim, isLast, xp }) {
  const emoji = type==='WALKING' ? '🥾' : '⚔️';
  return (
    <div style={{ display:'flex', alignItems:'center', gap:12, padding:'11px 0', borderBottom: isLast?'none':'1px solid rgba(255,255,255,0.06)' }}>
      <div style={{ width:34, height:34, borderRadius:10, background:colorDim, border:`1px solid ${color}44`, display:'flex', alignItems:'center', justifyContent:'center', fontSize:15, flexShrink:0 }}>{emoji}</div>
      <div style={{ flex:1, minWidth:0 }}>
        <div style={{ fontSize:13, fontWeight:800, color:'rgba(255,255,255,0.92)', letterSpacing:'0.02em' }}>{type}</div>
        <div style={{ fontSize:10, color:'rgba(255,255,255,0.4)', fontWeight:500, marginTop:1 }}>{date}</div>
      </div>
      <div style={{ textAlign:'right' }}>
        <div style={{ fontSize:13, fontWeight:700, color:'rgba(255,255,255,0.88)', fontVariantNumeric:'tabular-nums' }}>{duration}</div>
        <div style={{ fontSize:10, color:'rgba(255,255,255,0.4)', fontWeight:500, marginTop:1 }}>{kcal} · <span style={{ color:'#A89BFF' }}>+{xp} XP</span></div>
      </div>
    </div>
  );
}

// ── Macro row ────────────────────────────────────────────────────────────
function MacroRow({ label, value, goal, unit, color, glow, isLast }) {
  const over = value > goal;
  const barColor = over ? '#F87171' : color;
  const barGlow = over ? 'rgba(248,113,113,0.3)' : glow;
  return (
    <div style={{ paddingBottom: isLast?0:12, marginBottom: isLast?0:12, borderBottom: isLast?'none':'1px solid rgba(255,255,255,0.06)' }}>
      <div style={{ display:'flex', alignItems:'baseline', justifyContent:'space-between', marginBottom:7 }}>
        <span style={{ fontSize:13, fontWeight:700, color:'rgba(255,255,255,0.85)' }}>{label}</span>
        <span style={{ fontSize:12, fontWeight:700, color: over?barColor:'rgba(255,255,255,0.6)', fontVariantNumeric:'tabular-nums' }}>{value} / {goal} {unit}</span>
      </div>
      <ProgressBar value={Math.min(value/goal,1.3)} color={barColor} glow={barGlow} height={5}/>
    </div>
  );
}

// ── Trend chart ──────────────────────────────────────────────────────────
function TrendChart({ data, color, glow }) {
  const max = Math.max(...data.map(d=>d.value));
  return (
    <div style={{ display:'flex', gap:6, alignItems:'flex-end', height:80 }}>
      {data.map((d,i)=>{
        const pct = d.value/max;
        return (
          <div key={i} style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', gap:5, height:'100%', justifyContent:'flex-end' }}>
            <div style={{
              width:'100%', borderRadius:5, height:`${Math.max(pct*70,6)}px`,
              background: d.today ? `linear-gradient(180deg,${color},${color}cc)` : `${color}40`,
              boxShadow: d.today ? `0 0 10px ${glow}` : 'none',
              animation:`ft-bar-grow 0.5s cubic-bezier(0.4,0,0.2,1) ${i*0.05}s both`,
            }}/>
            <div style={{ fontSize:9, color: d.today?color:'rgba(255,255,255,0.35)', fontWeight: d.today?700:500 }}>{d.label}</div>
          </div>
        );
      })}
    </div>
  );
}

// ── Bottom nav ───────────────────────────────────────────────────────────
const NAV_ITEMS = [
  { id:'overview', label:'Overview', icon:(c)=><svg width="22" height="22" viewBox="0 0 22 22" fill="none"><rect x="2" y="2" width="8" height="8" rx="2" fill={c}/><rect x="12" y="2" width="8" height="8" rx="2" fill={c} opacity="0.5"/><rect x="2" y="12" width="8" height="8" rx="2" fill={c} opacity="0.5"/><rect x="12" y="12" width="8" height="8" rx="2" fill={c} opacity="0.5"/></svg> },
  { id:'activities', label:'Activities', icon:(c)=><svg width="22" height="22" viewBox="0 0 22 22" fill="none"><path d="M11 3l2 5h5l-4 3 1.5 5L11 13l-4.5 3L8 11 4 8h5z" fill={c}/></svg> },
  { id:'nutrition', label:'Nutrition', icon:(c)=><svg width="22" height="22" viewBox="0 0 22 22" fill="none"><path d="M7 3c0 3-3 4-3 7a7 7 0 0014 0c0-3-3-4-3-7" stroke={c} strokeWidth="1.8" strokeLinecap="round" fill="none"/><path d="M11 10v5" stroke={c} strokeWidth="1.8" strokeLinecap="round"/></svg> },
  { id:'body', label:'Body', icon:(c)=><svg width="22" height="22" viewBox="0 0 22 22" fill="none"><circle cx="11" cy="5" r="2.5" fill={c}/><path d="M6 9h10l-1 4H7L6 9z" fill={c} opacity="0.6"/><path d="M8 13l-1 6M14 13l1 6" stroke={c} strokeWidth="1.8" strokeLinecap="round"/></svg> },
];

function BottomNav({ active, onChange, accent, accentGlow }) {
  return (
    <div style={{ display:'flex', background:'rgba(13,15,28,0.95)', borderTop:'1px solid rgba(255,255,255,0.07)', paddingBottom:24, paddingTop:10, paddingLeft:8, paddingRight:8, flexShrink:0 }}>
      {NAV_ITEMS.map(item=>{
        const on = item.id===active;
        return (
          <button key={item.id} onClick={()=>onChange(item.id)} style={{ flex:1, border:'none', background:'transparent', cursor:'pointer', display:'flex', flexDirection:'column', alignItems:'center', gap:3, padding:'4px 0' }}>
            <div style={{
              width:42, height:32, borderRadius:10,
              background: on?`linear-gradient(135deg,${accent}33,${accent}18)`:'transparent',
              border: on?`1px solid ${accent}44`:'1px solid transparent',
              display:'flex', alignItems:'center', justifyContent:'center',
              transition:'all 0.2s', boxShadow: on?`0 2px 10px ${accentGlow}`:'none',
            }}>{item.icon(on?accent:'rgba(255,255,255,0.35)')}</div>
            <span style={{ fontSize:10, fontWeight: on?700:500, color: on?accent:'rgba(255,255,255,0.35)', fontFamily:'Inter,sans-serif' }}>{item.label}</span>
          </button>
        );
      })}
    </div>
  );
}

// ── Screen header (greeting + avatar) ────────────────────────────────────
function ScreenHeader({ greeting, title, accent, accentGlow }) {
  return (
    <div style={{ padding:'4px 0 2px', display:'flex', alignItems:'center', justifyContent:'space-between' }}>
      <div>
        <div style={{ fontSize:12, color:'rgba(255,255,255,0.4)', fontWeight:500 }}>{greeting}</div>
        <div style={{ fontSize:20, fontWeight:800, color:'#fff', letterSpacing:'-0.03em', marginTop:1 }}>{title}</div>
      </div>
      <div style={{ width:36, height:36, borderRadius:12, background:`linear-gradient(135deg,${accent}55,${accent}22)`, border:`1px solid ${accent}44`, display:'flex', alignItems:'center', justifyContent:'center', fontSize:18, boxShadow:`0 4px 16px ${accentGlow}` }}>⚔️</div>
    </div>
  );
}

// ── Plain card wrapper (for Activities/Nutrition non-stat cards) ─────────
function PlainCard({ children, gradient, colorDim, colorGlow, tweaks, delay=0, padding }) {
  return (
    <div style={{
      borderRadius:18, background: gradient || 'rgba(255,255,255,0.03)',
      border:`1px solid ${colorDim || 'rgba(255,255,255,0.07)'}`,
      boxShadow: tweaks.glow && colorGlow ? `0 4px 24px ${colorGlow}, 0 1px 0 rgba(255,255,255,0.06) inset` : '0 2px 8px rgba(0,0,0,0.25)',
      padding: padding || (tweaks.compact?'12px 14px':'14px 16px'),
      position:'relative', overflow:'hidden',
      animation:`ft-card-in 0.35s ease ${delay}s both`,
    }}>
      {children}
    </div>
  );
}

Object.assign(window, {
  Sparkles, BgStars, ProgressBar, StatCell, StatCard, TabPill, DateNav,
  XpBar, SectionHead, ActivityRow, MacroRow, TrendChart, BottomNav, ScreenHeader, PlainCard,
});
