// celebration-variants.jsx — the four celebration variants

// ───────────────────────────────────────────────────────────
// Shared chrome — the surface the variant lives on (phone-shape)
// ───────────────────────────────────────────────────────────
function PhoneFrame({ children, w = 380, h = 780, bg }) {
  return (
    <div style={{
      width: w, height: h, borderRadius: 38, position:'relative', overflow:'hidden',
      background: bg || 'radial-gradient(ellipse at 50% 0%, #1A1638 0%, #0B0F1E 55%, #050714 100%)',
      boxShadow: '0 30px 80px -30px rgba(0,0,0,0.8), 0 0 0 1px rgba(167,139,250,0.08)',
      color:'#F5F3FF', fontFamily:'"Inter","SF Pro Text",system-ui,sans-serif',
    }}>{children}</div>
  );
}

// Faux app underneath (shown blurred behind some variants)
function FauxApp() {
  return (
    <div style={{ position:'absolute', inset:0, padding:'56px 16px 0', opacity:0.55, filter:'blur(2px)' }}>
      <div style={{ height:14, width:'40%', background:'rgba(167,139,250,0.25)', borderRadius:4, marginBottom:18 }}/>
      {[0,1,2,3].map(i => (
        <div key={i} style={{
          height: 84, marginBottom: 10, borderRadius: 16,
          background:'linear-gradient(180deg, rgba(40,38,76,0.55), rgba(22,22,46,0.85))',
          border:'1px solid rgba(148,130,220,0.12)',
        }}/>
      ))}
    </div>
  );
}

// Type icon badge (corner on the card) — colored by reward TYPE, not rarity.
function TypeBadge({ type, rarityColor }) {
  const meta = window.REWARD_TYPE[type];
  if (!meta) return null;
  const Ico = window.TYPE_ICON[meta.icon] || window.IconSparkle;
  return (
    <div style={{
      display:'inline-flex', alignItems:'center', gap:6,
      padding:'5px 9px', borderRadius:999,
      background: 'rgba(11,15,30,0.7)',
      border: `1px solid ${rarityColor}55`,
      backdropFilter:'blur(6px)',
      whiteSpace:'nowrap',
    }}>
      <Ico size={13} color={rarityColor}/>
      <span style={{ fontSize:9, fontWeight:800, letterSpacing:'0.16em', color:'#F5F3FF', whiteSpace:'nowrap' }}>{meta.label}</span>
    </div>
  );
}

// XP pill — appears below the reward; pulses
function XpPill({ amount, rarity }) {
  const r = window.RARITY[rarity];
  return (
    <div style={{
      display:'inline-flex', alignItems:'center', gap:6,
      padding:'8px 14px', borderRadius:999,
      background: `linear-gradient(180deg, ${r.color}33, ${r.color}14)`,
      border: `1px solid ${r.color}77`,
      boxShadow: `0 0 24px -4px ${r.glow}`,
      animation: 'celPulse 2.4s ease-in-out infinite',
    }}>
      <window.IconBolt size={14} color={r.color}/>
      <span style={{ fontSize:14, fontWeight:800, color:'#F5F3FF', letterSpacing:'0.02em' }}>+{amount.toLocaleString('cs-CZ')} XP</span>
    </div>
  );
}

function ActionRow({ rarity, onPrimary, onShare, primary='Pokračovat' }) {
  const r = window.RARITY[rarity];
  return (
    <div style={{ display:'flex', gap:10, padding:'0 18px 22px' }}>
      <button onClick={onShare} style={{
        flex:'0 0 52px', height:52, borderRadius:14,
        background:'rgba(28,30,56,0.55)',
        border:'1px solid rgba(148,130,220,0.22)',
        color:'#C7C2E0', cursor:'pointer',
        display:'flex', alignItems:'center', justifyContent:'center',
      }}><window.IconShare size={18}/></button>
      <button onClick={onPrimary} style={{
        flex:1, height:52, borderRadius:14, cursor:'pointer',
        background: `linear-gradient(180deg, ${r.color2}, ${r.color})`,
        border:'none', color: rarity === 'common' ? '#0B0F1E' : (rarity === 'legendary' ? '#0B0F1E' : '#0B0F1E'),
        fontSize:15, fontWeight:800, letterSpacing:'0.02em',
        boxShadow: `0 8px 24px -8px ${r.glow}, inset 0 1px 0 rgba(255,255,255,0.45)`,
      }}>{primary}</button>
    </div>
  );
}

// ───────────────────────────────────────────────────────────
// Variant A — Centered Modal (default for 1 reward)
// ───────────────────────────────────────────────────────────
function VariantA({ type='level', rarity='uncommon', xp=2500, intensity=1, animKey=0 }) {
  const r = window.RARITY[rarity];
  const meta = window.REWARD_TYPE[type];
  const reward = window.sampleRewards(type)[0] || { kind:'badge', name:'—', sub:'' };
  return (
    <PhoneFrame>
      <div style={{ position:'absolute', inset:0 }}>
        <FauxApp/>
        <div style={{ position:'absolute', inset:0, background:'rgba(5,7,20,0.78)', backdropFilter:'blur(14px)' }}/>
      </div>
      <Aura rarity={rarity} intensity={intensity}/>
      <Rays rarity={rarity} intensity={intensity}/>
      <Particles key={'p'+animKey} rarity={rarity} count={20} intensity={intensity}/>

      <div style={{ position:'absolute', top:18, right:14 }}>
        <button style={{
          width:36, height:36, borderRadius:'50%', border:'1px solid rgba(255,255,255,0.12)',
          background:'rgba(11,15,30,0.6)', color:'#C7C2E0', cursor:'pointer',
          display:'flex', alignItems:'center', justifyContent:'center', backdropFilter:'blur(6px)',
        }}><window.IconClose/></button>
      </div>

      <div key={animKey} style={{
        position:'absolute', left:0, right:0, top:'50%', transform:'translateY(-50%)',
        padding:'0 22px',
        animation: 'celEnter 0.8s cubic-bezier(.16,1,.3,1) both',
      }}>
        {/* type kicker */}
        <div style={{ textAlign:'center', marginBottom:10 }}>
          <TypeBadge type={type} rarityColor={r.color}/>
        </div>

        {/* big icon disc */}
        <div style={{
          width:140, height:140, margin:'0 auto 18px', position:'relative',
        }}>
          <div style={{
            position:'absolute', inset:-18, borderRadius:'50%',
            background:`radial-gradient(circle, ${r.glow}, transparent 70%)`,
            animation:'celBreathe 3s ease-in-out infinite',
          }}/>
          <div style={{
            position:'absolute', inset:0, borderRadius:'50%',
            background:`linear-gradient(180deg, ${r.color2}, ${r.color})`,
            border:`2px solid ${r.rim}`,
            boxShadow:`0 0 0 6px ${r.color}22, 0 0 60px ${r.glow}, inset 0 4px 24px rgba(255,255,255,0.45), inset 0 -8px 16px rgba(0,0,0,0.25)`,
            display:'flex', alignItems:'center', justifyContent:'center',
            color:'#0B0F1E',
          }}>
            <window.RewardThumb kind={reward.kind} color="#0B0F1E" size={62}/>
          </div>
          {/* shine sweep */}
          <div style={{
            position:'absolute', inset:0, borderRadius:'50%', overflow:'hidden',
            mask:'radial-gradient(circle, black 100%, black)', WebkitMask:'radial-gradient(circle, black 100%, black)',
          }}>
            <div style={{
              position:'absolute', top:'-30%', left:'-30%', width:'60%', height:'160%',
              background:'linear-gradient(90deg, transparent, rgba(255,255,255,0.55), transparent)',
              transform:'rotate(20deg)',
              animation:'celShine 3s ease-in-out infinite',
            }}/>
          </div>
        </div>

        {/* rarity label */}
        <div style={{
          textAlign:'center', fontSize:11, fontWeight:800, letterSpacing:'0.22em',
          color: r.color, marginBottom:6,
          textShadow:`0 0 18px ${r.glow}`,
        }}>{r.label}</div>

        {/* title */}
        <div style={{
          textAlign:'center', fontSize:26, fontWeight:800, color:'#F5F3FF',
          lineHeight:1.15, padding:'0 12px', marginBottom:6,
          textWrap:'balance',
        }}>{reward.name}</div>

        {/* subtitle */}
        <div style={{ textAlign:'center', fontSize:13, color:'#C7C2E0', marginBottom:18, padding:'0 22px', lineHeight:1.4 }}>
          {meta?.sub} · {type === 'level' ? 'Dosáhl jsi levelu 15' : reward.sub}
        </div>

        {xp > 0 && <div style={{ textAlign:'center', marginBottom:6 }}><XpPill amount={xp} rarity={rarity}/></div>}
      </div>

      <div style={{ position:'absolute', left:0, right:0, bottom:0 }}>
        <ActionRow rarity={rarity} onPrimary={()=>{}} onShare={()=>{}}/>
      </div>
    </PhoneFrame>
  );
}

// ───────────────────────────────────────────────────────────
// Variant B — Cinematic fullscreen (legendary+)
// ───────────────────────────────────────────────────────────
function VariantB({ type='title', rarity='legendary', xp=10000, intensity=1, animKey=0 }) {
  const r = window.RARITY[rarity];
  const meta = window.REWARD_TYPE[type];
  const reward = window.sampleRewards(type)[0] || { kind:'title', name:'—', sub:'' };
  return (
    <PhoneFrame bg={`radial-gradient(ellipse at 50% 30%, ${r.color}1f 0%, #0B0F1E 50%, #02030B 100%)`}>
      <Rays rarity={rarity} intensity={intensity * 1.3}/>
      <Aura rarity={rarity} intensity={intensity * 1.2}/>
      <Particles key={'p'+animKey} rarity={rarity} count={36} intensity={intensity}/>
      <Confetti key={'c'+animKey} rarity={rarity} n={28}/>

      {/* spotlight */}
      <div style={{
        position:'absolute', left:'50%', top:'8%', width:8, height:'100%',
        background: `linear-gradient(180deg, ${r.color}, transparent 60%)`,
        transform:'translateX(-50%) skewX(-2deg)',
        filter:'blur(40px)', opacity: 0.4 * intensity,
      }}/>

      <div key={animKey} style={{
        position:'absolute', inset:0, display:'flex', flexDirection:'column',
      }}>
        <div style={{ paddingTop: 90, textAlign:'center', animation:'celEnter 0.9s cubic-bezier(.16,1,.3,1) 0.1s both' }}>
          <div style={{
            display:'inline-block', padding:'6px 14px', borderRadius:999,
            background:`linear-gradient(180deg, ${r.color}33, ${r.color}11)`,
            border:`1px solid ${r.color}77`, marginBottom:18,
            fontSize:10, fontWeight:800, letterSpacing:'0.22em', color: r.color,
          }}>{r.label} · {meta?.label}</div>
        </div>

        {/* The reward block */}
        <div style={{ flex:1, display:'flex', alignItems:'center', justifyContent:'center', position:'relative', padding:'0 26px' }}>
          <div style={{ animation:'celRise2 1s cubic-bezier(.16,1,.3,1) 0.25s both', textAlign:'center', width:'100%' }}>
            <div style={{
              width:200, height:200, margin:'0 auto 24px', position:'relative',
              transform:'rotate(-2deg)',
            }}>
              <div style={{
                position:'absolute', inset:-30, borderRadius:32,
                background:`radial-gradient(circle, ${r.glow}, transparent 70%)`,
                animation:'celBreathe 2.6s ease-in-out infinite',
              }}/>
              <div style={{
                position:'absolute', inset:0, borderRadius:28,
                background:`linear-gradient(160deg, ${r.color2}, ${r.color} 60%, ${r.color}cc)`,
                border:`2px solid ${r.rim}`,
                boxShadow:`0 0 0 8px ${r.color}1f, 0 30px 80px -10px ${r.glow}, inset 0 4px 30px rgba(255,255,255,0.5), inset 0 -16px 24px rgba(0,0,0,0.35)`,
                display:'flex', alignItems:'center', justifyContent:'center',
                color:'#0B0F1E',
              }}>
                <window.RewardThumb kind={reward.kind} color="#0B0F1E" size={92}/>
              </div>
            </div>
            <div style={{
              fontSize:34, fontWeight:900, color:'#F5F3FF', lineHeight:1.05,
              letterSpacing:'-0.01em', textShadow:`0 4px 30px ${r.glow}`,
              padding:'0 8px',
            }}>{reward.name}</div>
            <div style={{
              fontSize:14, color:'#C7C2E0', marginTop:10, lineHeight:1.4,
            }}>{type === 'title' && reward.sub ? `Povýšení ${reward.sub.replace(/^Z titulu /,'z titulu ')}` : reward.sub}</div>
          </div>
        </div>

        {xp > 0 && (
          <div style={{ textAlign:'center', marginBottom:18, animation:'celEnter 0.6s 0.7s both' }}>
            <XpPill amount={xp} rarity={rarity}/>
          </div>
        )}

        <div style={{ animation:'celEnter 0.6s 0.85s both' }}>
          <ActionRow rarity={rarity} onPrimary={()=>{}} onShare={()=>{}} primary={type==='cosmetic'?'Vybavit':'Pokračovat'}/>
        </div>
      </div>
    </PhoneFrame>
  );
}

// ───────────────────────────────────────────────────────────
// Variant C — Multi-reward (treasure with fanned cards)
// ───────────────────────────────────────────────────────────
function VariantC({ rewards, intensity = 1, animKey = 0 }) {
  // rewards: [{ type, rarity }]
  const [active, setActive] = React.useState(0);
  React.useEffect(() => { setActive(0); }, [animKey, rewards.length]);
  const cur = rewards[active] || rewards[0];
  const r = window.RARITY[cur.rarity];
  const headRarity = rewards.reduce((acc, x) => RARITY_RANK[x.rarity] > RARITY_RANK[acc] ? x.rarity : acc, rewards[0].rarity);
  const head = window.RARITY[headRarity];

  return (
    <PhoneFrame bg={`radial-gradient(ellipse at 50% 25%, ${head.color}22 0%, #0B0F1E 55%, #02030B 100%)`}>
      <Aura rarity={headRarity} intensity={intensity * 0.7}/>
      <Rays rarity={headRarity} intensity={intensity * 0.5}/>
      <Particles key={'p'+animKey} rarity={headRarity} count={14} intensity={intensity * 0.7}/>

      <div style={{ position:'absolute', top:18, right:14 }}>
        <button style={{
          width:36, height:36, borderRadius:'50%', border:'1px solid rgba(255,255,255,0.12)',
          background:'rgba(11,15,30,0.6)', color:'#C7C2E0', cursor:'pointer',
          display:'flex', alignItems:'center', justifyContent:'center',
        }}><window.IconClose/></button>
      </div>

      <div key={animKey} style={{
        position:'absolute', inset:0, display:'flex', flexDirection:'column',
        animation:'celEnter 0.7s cubic-bezier(.16,1,.3,1) both',
      }}>
        <div style={{ textAlign:'center', paddingTop: 76 }}>
          <div style={{ fontSize:11, fontWeight:800, letterSpacing:'0.24em', color: head.color, marginBottom:6, textShadow:`0 0 16px ${head.glow}` }}>
            VELKÁ ODMĚNA
          </div>
          <div style={{ fontSize:24, fontWeight:800, color:'#F5F3FF' }}>
            Získal jsi {rewards.length} {plural(rewards.length, 'odměnu','odměny','odměn')}
          </div>
        </div>

        {/* Fanned cards stack — tap a card to focus, tap focused to advance, drag to swipe */}
        <SwipeStack rewards={rewards} active={active} setActive={setActive}/>

        {/* dots */}
        <div style={{ display:'flex', gap:8, justifyContent:'center', padding:'0 0 16px' }}>
          {rewards.map((rw, i) => {
            const rar = window.RARITY[rw.rarity];
            const on = i === active;
            return (
              <button key={i} onClick={()=>setActive(i)} style={{
                width: on ? 26 : 8, height:8, borderRadius:6, border:'none',
                background: on ? rar.color : 'rgba(199,194,224,0.25)',
                boxShadow: on ? `0 0 12px ${rar.glow}` : 'none',
                transition:'all .3s', cursor:'pointer', padding:0,
              }}/>
            );
          })}
        </div>

        <ActionRow rarity={headRarity} primary={active < rewards.length - 1 ? 'Další odměna' : 'Pokračovat'} onPrimary={()=> setActive(a => Math.min(rewards.length - 1, a + 1))}/>
        <div style={{ display:'flex', justifyContent:'center', padding:'0 0 18px', marginTop:-6 }}>
          <button style={{
            background:'transparent', border:'none', cursor:'pointer',
            color:'#C7C2E0', fontSize:13, fontWeight:600, letterSpacing:'0.01em',
            padding:'8px 14px', borderRadius:10,
            display:'inline-flex', alignItems:'center', gap:6,
          }}>
            Otevřít inventář
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
              <path d="M9 6l6 6-6 6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </button>
        </div>
      </div>
    </PhoneFrame>
  );
}

function SwipeStack({ rewards, active, setActive }) {
  const [drag, setDrag] = React.useState(0);
  const startX = React.useRef(null);
  const onDown = (e) => {
    const x = e.touches ? e.touches[0].clientX : e.clientX;
    startX.current = x;
  };
  const onMove = (e) => {
    if (startX.current == null) return;
    const x = e.touches ? e.touches[0].clientX : e.clientX;
    setDrag(x - startX.current);
  };
  const onUp = () => {
    if (startX.current == null) return;
    if (drag < -45 && active < rewards.length - 1) setActive(a => a + 1);
    else if (drag > 45 && active > 0) setActive(a => a - 1);
    startX.current = null; setDrag(0);
  };
  return (
    <div
      onMouseDown={onDown} onMouseMove={onMove} onMouseUp={onUp} onMouseLeave={onUp}
      onTouchStart={onDown} onTouchMove={onMove} onTouchEnd={onUp}
      style={{ flex:1, position:'relative', marginTop:30, touchAction:'pan-y', userSelect:'none' }}>
      {rewards.map((rw, i) => {
        const offset = i - active;
        const isActive = i === active;
        const rar = window.RARITY[rw.rarity];
        const reward = window.sampleRewards(rw.type)[0];
        const dragNudge = isActive ? drag : drag * 0.4;
        return (
          <div key={i} onClick={(e)=>{
            e.stopPropagation();
            if (isActive) {
              if (active < rewards.length - 1) setActive(a => a + 1);
            } else {
              setActive(i);
            }
          }} style={{
            position:'absolute', left:'50%', top:0,
            width:240, height:300, marginLeft:-120,
            transform: `translateX(${offset * 40 + dragNudge}px) translateY(${Math.abs(offset)*8}px) rotate(${offset * 4 + (isActive ? drag * 0.04 : 0)}deg) scale(${isActive ? 1 : 0.92})`,
            transition: drag === 0 ? 'transform .45s cubic-bezier(.2,.9,.3,1)' : 'none',
            zIndex: 10 - Math.abs(offset),
            cursor: 'pointer',
            opacity: Math.abs(offset) > 2 ? 0 : 1,
          }}>
            <RewardCard rarity={rw.rarity} type={rw.type} reward={reward} active={isActive}/>
          </div>
        );
      })}
      {rewards.length > 1 && (
        <div style={{
          position:'absolute', bottom:8, left:0, right:0, textAlign:'center',
          fontSize:10, fontWeight:600, letterSpacing:'0.14em', color:'#5C597A',
          textTransform:'uppercase', pointerEvents:'none',
        }}>{active < rewards.length - 1 ? 'Tapni nebo přejeď →' : 'Hotovo'}</div>
      )}
    </div>
  );
}

const RARITY_RANK = { common:1, uncommon:2, rare:3, epic:4, legendary:5, mythic:6 };

function plural(n, one, few, many) {
  if (n === 1) return one;
  if (n >= 2 && n <= 4) return few;
  return many;
}

function RewardCard({ rarity, type, reward, active }) {
  const r = window.RARITY[rarity];
  const meta = window.REWARD_TYPE[type];
  return (
    <div style={{
      position:'relative', width:'100%', height:'100%', borderRadius:24,
      overflow:'hidden',
      background:`linear-gradient(180deg, ${r.color}38 0%, rgba(20,22,46,0.96) 60%, rgba(15,18,38,0.98))`,
      border:`1.5px solid ${r.color}88`,
      boxShadow: active
        ? `0 0 0 1px ${r.color}66, 0 18px 40px -12px ${r.glow}, inset 0 1px 0 rgba(255,255,255,0.08)`
        : `0 10px 24px -10px rgba(0,0,0,0.55), inset 0 1px 0 rgba(255,255,255,0.04)`,
      backdropFilter:'blur(8px)',
    }}>
      <div style={{
        position:'absolute', top:-40, left:-40, right:-40, height:200,
        background:`radial-gradient(ellipse at 50% 50%, ${r.glow}, transparent 70%)`,
        opacity: active ? 0.6 : 0.22, pointerEvents:'none',
      }}/>
      {/* corner type badge */}
      <div style={{ position:'absolute', top:12, left:12 }}>
        <TypeBadge type={type} rarityColor={r.color}/>
      </div>

      <div style={{ display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', height:'100%', padding:'40px 20px 22px', position:'relative' }}>
        <div style={{
          width:108, height:108, borderRadius:'50%', position:'relative',
          marginBottom:16,
          background:`linear-gradient(180deg, ${r.color2}, ${r.color})`,
          border:`2px solid ${r.rim}`,
          boxShadow:`0 0 30px ${r.glow}, inset 0 3px 18px rgba(255,255,255,0.4), inset 0 -8px 12px rgba(0,0,0,0.3)`,
          display:'flex', alignItems:'center', justifyContent:'center',
        }}>
          <window.RewardThumb kind={reward.kind} color="#0B0F1E" size={52}/>
        </div>
        <div style={{
          fontSize:10, fontWeight:800, letterSpacing:'0.22em', color: r.color,
          marginBottom:4, textShadow:`0 0 12px ${r.glow}`,
        }}>{r.label}</div>
        <div style={{
          fontSize:18, fontWeight:800, color:'#F5F3FF', textAlign:'center',
          lineHeight:1.2, marginBottom:4, textWrap:'balance',
        }}>{reward.name}</div>
        <div style={{ fontSize:11, color:'#C7C2E0', textAlign:'center' }}>{reward.sub}</div>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────────────
// Variant D — Topsheet (matches existing Forgetrack topsheet pattern)
// Header: typeBadge icon-square + ÚSPĚCH ODEMČEN kicker + title + desc + close
// Body:   ODMĚNY section listing reward chips (with rarity)
// CTA:    Vyzvednout +XP — gold pill, primary action
// ───────────────────────────────────────────────────────────
function VariantD({
  type='achievement',
  rarity='common',
  xp=205,
  title='První odměna',
  desc='Získej svou první progression odměnu.',
  rewards,
  intensity = 1, animKey = 0,
}) {
  const r = window.RARITY[rarity];
  const meta = window.REWARD_TYPE[type];
  // accent for the type-icon square (matches existing app: achievement=teal, quest=green, level=gold, title=purple)
  const TYPE_ACCENT = {
    achievement: '#3FB8AF', quest:'#34D399', level:'#F4C152', title:'#A78BFA',
    streak:'#FB923C', location:'#60A5FA', cosmetic:'#A78BFA',
  };
  const typeAccent = TYPE_ACCENT[type] || '#3FB8AF';
  const Ico = window.TYPE_ICON[meta.icon] || window.IconSparkle;
  const list = rewards || [{ kind:(window.sampleRewards(type)[0]||{}).kind || 'badge', name:(window.sampleRewards(type)[0]||{}).name||'', rarity }];

  const [claimed, setClaimed] = React.useState(false);
  React.useEffect(()=>{ setClaimed(false); }, [animKey]);

  return (
    <PhoneFrame>
      <FauxApp/>
      <div key={animKey} style={{
        position:'absolute', top:14, left:12, right:12,
        borderRadius:22, overflow:'hidden',
        background:'linear-gradient(180deg, rgba(15,18,38,0.92), rgba(11,15,30,0.95))',
        border:`1.5px solid ${typeAccent}55`,
        boxShadow:`0 0 0 1px ${typeAccent}1f, 0 14px 40px -10px ${typeAccent}66`,
        backdropFilter:'blur(14px)',
        animation:'celTop 0.7s cubic-bezier(.16,1,.3,1) both',
      }}>
        {/* internal aura */}
        <div style={{
          position:'absolute', top:-30, left:-30, right:-30, height:160,
          background:`radial-gradient(ellipse at 50% 0%, ${typeAccent}33, transparent 70%)`,
          pointerEvents:'none',
        }}/>
        <div style={{ position:'absolute', inset:0, overflow:'hidden', pointerEvents:'none' }}>
          <Particles rarity={rarity === 'common' ? 'uncommon' : rarity} count={8} intensity={intensity * 0.5}/>
        </div>

        {/* HEADER */}
        <div style={{ position:'relative', padding:'14px 14px 0', display:'flex', gap:14 }}>
          <div style={{
            width:64, height:64, flexShrink:0, borderRadius:14,
            background:`linear-gradient(180deg, ${typeAccent}33, ${typeAccent}11)`,
            border:`1px solid ${typeAccent}66`,
            boxShadow:`0 0 18px -4px ${typeAccent}99, inset 0 1px 0 rgba(255,255,255,0.06)`,
            display:'flex', alignItems:'center', justifyContent:'center',
            color: typeAccent,
            animation: 'celBadgePop 0.6s cubic-bezier(.16,1,.3,1) 0.1s both',
          }}>
            <Ico size={32} color={typeAccent}/>
          </div>
          <div style={{ minWidth:0, flex:1, paddingTop:2 }}>
            <div style={{ fontSize:11, fontWeight:800, letterSpacing:'0.18em', color: typeAccent, textTransform:'uppercase' }}>
              {meta.label.replace('LEVEL UP','LEVEL UP').replace('TITUL ODEMČEN','TITUL ODEMČEN').replace('ÚSPĚCH','ÚSPĚCH ODEMČEN')}
            </div>
            <div style={{ fontSize:22, fontWeight:800, color:'#F5F3FF', lineHeight:1.15, marginTop:4, textWrap:'balance' }}>
              {title}
            </div>
            <div style={{ fontSize:13, color:'#8A85A8', marginTop:4, lineHeight:1.4 }}>
              {desc}
            </div>
          </div>
          <button style={{
            width:36, height:36, borderRadius:10, flexShrink:0, alignSelf:'flex-start',
            border:'1px solid rgba(255,255,255,0.08)',
            background:'rgba(255,255,255,0.03)', color:'#8A85A8', cursor:'pointer',
            display:'flex', alignItems:'center', justifyContent:'center',
          }}><window.IconClose size={16}/></button>
        </div>

        {/* REWARDS SECTION */}
        <div style={{ position:'relative', padding:'14px 14px 0' }}>
          <div style={{
            fontSize:11, fontWeight:800, letterSpacing:'0.16em', color: typeAccent,
            textTransform:'uppercase', marginBottom:8,
          }}>Odměny</div>
          <div style={{ display:'flex', flexDirection:'column', gap:8 }}>
            {list.map((rw, i) => (
              <div key={i} style={{
                animation: `celEnter 0.5s cubic-bezier(.16,1,.3,1) ${0.25 + i * 0.08}s both`,
              }}>
                <DTopsheetRewardRow reward={rw}/>
              </div>
            ))}
          </div>
        </div>

        {/* CLAIM XP CTA — gold pill */}
        {xp > 0 && (
          <div style={{ position:'relative', padding:'10px 14px 14px', display:'flex', justifyContent:'flex-end' }}>
            <button
              onClick={() => !claimed && setClaimed(true)}
              disabled={claimed}
              style={{
                height:34, padding:'0 14px', borderRadius:999, cursor: claimed ? 'default' : 'pointer',
                border:'none', position:'relative', overflow:'hidden',
                background: claimed
                  ? 'rgba(63,184,175,0.14)'
                  : 'linear-gradient(180deg, #FFD980, #E5A833)',
                color: claimed ? '#3FB8AF' : '#0B0F1E',
                fontSize:13, fontWeight:800, letterSpacing:'0.01em',
                boxShadow: claimed
                  ? '0 0 0 1px rgba(63,184,175,0.4) inset'
                  : '0 4px 12px -4px rgba(244,193,82,0.7), inset 0 1px 0 rgba(255,255,255,0.5), inset 0 -1.5px 0 rgba(0,0,0,0.12)',
                animation: claimed ? 'none' : 'celClaimPulse 2.2s ease-in-out infinite',
                transition: 'all .25s',
                display:'inline-flex', alignItems:'center', gap:6,
              }}>
              {!claimed && (
                <span style={{
                  position:'absolute', top:0, bottom:0, left:'-30%', width:'40%',
                  background:'linear-gradient(90deg, transparent, rgba(255,255,255,0.55), transparent)',
                  transform:'skewX(-18deg)', animation:'celShine 2.8s ease-in-out infinite',
                  pointerEvents:'none',
                }}/>
              )}
              <window.IconBolt size={13} color={claimed ? '#3FB8AF' : '#0B0F1E'}/>
              <span style={{ position:'relative' }}>
                {claimed ? `Vyzvednuto · +${xp.toLocaleString('cs-CZ')} XP` : `Vyzvednout +${xp.toLocaleString('cs-CZ')} XP`}
              </span>
            </button>
          </div>
        )}
      </div>
    </PhoneFrame>
  );
}

// Reward row inside topsheet — chip with rarity-tinted thumb + name + rarity label
function DTopsheetRewardRow({ reward }) {
  const r = window.RARITY[reward.rarity || 'common'];
  return (
    <div style={{
      display:'flex', alignItems:'center', gap:12,
      padding:'8px 10px', borderRadius:12,
      background:'rgba(255,255,255,0.03)',
      border:`1px solid ${r.color}33`,
      boxShadow: `inset 0 0 0 1px rgba(255,255,255,0.02)`,
    }}>
      <div style={{
        width:42, height:42, borderRadius:10, flexShrink:0,
        background:`linear-gradient(180deg, ${r.color}26, ${r.color}0a)`,
        border:`1px solid ${r.color}55`,
        display:'flex', alignItems:'center', justifyContent:'center',
        position:'relative', overflow:'hidden',
      }}>
        <window.RewardThumb kind={reward.kind} color={r.color} size={22}/>
      </div>
      <div style={{ minWidth:0, flex:1 }}>
        <div style={{
          fontSize:14, fontWeight:700, color:'#F5F3FF', lineHeight:1.2,
          textOverflow:'ellipsis', overflow:'hidden', whiteSpace:'nowrap',
        }}>{reward.name}</div>
        <div style={{ fontSize:10, fontWeight:800, letterSpacing:'0.16em', color: r.color, marginTop:3, textTransform:'uppercase' }}>
          {r.label}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { VariantA, VariantB, VariantC, VariantD, PhoneFrame });
