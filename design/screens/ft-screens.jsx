// ft-screens.jsx — Four screens in RPG dark-fantasy premium language

// ── Screen 1: Overview ──────────────────────────────────────────────────
function OverviewScreen({ tweaks, theme }) {
  const [tab, setTab] = React.useState('Day');
  const [off, setOff] = React.useState(0);
  const c = {
    steps:    { ...DOMAINS.steps,    label:'Steps', icon:'🥾',
      stats:[{value:'7 235',label:'Current'},{value:'10 000',label:'Goal'},{value:'2 765',label:'Left'}],
      progress:0.72, badge:'72%', xp:'+144 XP' },
    calories: { ...DOMAINS.calories, label:'Calories today', icon:'🔥',
      stats:[{value:'3 321',label:'Intake',unit:'kcal'},{value:'0',label:'Burned',unit:'kcal'},{value:'−536',label:'Left',unit:'kcal'}],
      progress:1.0, badge:'100%', xp:'+200 XP' },
    weight:   { ...DOMAINS.weight,   label:'Weight', icon:'⚖️',
      stats:[{value:'103.9',label:'Weight',unit:'kg'},{value:'+0.3',label:'Change',unit:'kg'},{value:'75.0',label:'Goal',unit:'kg'}],
      progress:0.35, trophy:true },
  };
  return (
    <div style={{ flex:1, overflowY:'auto', padding:'0 14px', display:'flex', flexDirection:'column', gap:10, position:'relative' }}>
      <ScreenHeader greeting="Good morning ✦" title="Dashboard" accent={theme.accent} accentGlow={theme.accentGlow}/>
      <TabPill tabs={['Day','Week','Month']} active={tab} onChange={setTab} accent={theme.accent} accentGlow={theme.accentGlow}/>
      <DateNav offset={off} onChange={setOff}/>
      <XpBar level={14} title="Forge Knight" xp={2340} xpMax={3000} accent={theme.accent} accentGlow={theme.accentGlow}/>
      <StatCard {...c.steps}    colorDim={c.steps.dim}    colorGlow={c.steps.glow}    color={c.steps.color}    tweaks={tweaks} delay={0.05}/>
      <StatCard {...c.calories} colorDim={c.calories.dim} colorGlow={c.calories.glow} color={c.calories.color} tweaks={tweaks} delay={0.12}/>
      <StatCard {...c.weight}   colorDim={c.weight.dim}   colorGlow={c.weight.glow}   color={c.weight.color}   tweaks={tweaks} delay={0.19}/>
      <div style={{ height:8 }}/>
    </div>
  );
}

// ── Screen 2: Activities ────────────────────────────────────────────────
function ActivitiesScreen({ tweaks, theme }) {
  const [tab, setTab] = React.useState('Week');
  const d = DOMAINS.active;
  const s = DOMAINS.steps;
  const activities = [
    { type:'WALKING',  date:'Today · 16:40',       duration:'42 min', kcal:'186 kcal', xp:52, ...DOMAINS.steps },
    { type:'STRENGTH', date:'Today · 07:12',       duration:'28 min', kcal:'142 kcal', xp:78, ...DOMAINS.active },
    { type:'WALKING',  date:'Yesterday · 18:05',   duration:'1h 04m', kcal:'312 kcal', xp:96, ...DOMAINS.steps },
    { type:'STRENGTH', date:'Yesterday · 06:55',   duration:'35 min', kcal:'188 kcal', xp:88, ...DOMAINS.active },
    { type:'WALKING',  date:'Sun 19 · 14:22',      duration:'22 min', kcal:' 98 kcal', xp:32, ...DOMAINS.steps },
  ];
  const chart = [
    { label:'M', value:38 },{ label:'T', value:62 },{ label:'W', value:44 },
    { label:'T', value:88 },{ label:'F', value:56 },{ label:'S', value:102 },{ label:'S', value:74, today:true },
  ];
  return (
    <div style={{ flex:1, overflowY:'auto', padding:'0 14px', display:'flex', flexDirection:'column', gap:10, position:'relative' }}>
      <ScreenHeader greeting="Keep moving ✦" title="Activities" accent={theme.accent} accentGlow={theme.accentGlow}/>
      <TabPill tabs={['Day','Week','Month']} active={tab} onChange={setTab} accent={theme.accent} accentGlow={theme.accentGlow}/>

      <StatCard icon="⚡" label="Active minutes · week"
        color={d.color} colorDim={d.dim} colorGlow={d.glow} gradient={d.gradient}
        stats={[{value:'284',label:'This week',unit:'min'},{value:'420',label:'Goal',unit:'min'},{value:'+38',label:'vs last',unit:'%'}]}
        progress={0.68} badge="68%" xp="+420 XP" tweaks={tweaks} delay={0.05}/>

      <PlainCard gradient={s.gradient} colorDim={s.dim} colorGlow={s.glow} tweaks={tweaks} delay={0.1}>
        <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:12 }}>
          <div style={{ width:32, height:32, borderRadius:10, background:s.dim, border:`1px solid ${s.color}44`, display:'flex', alignItems:'center', justifyContent:'center', fontSize:16 }}>📈</div>
          <span style={{ fontWeight:700, fontSize:14, color:'rgba(255,255,255,0.95)', flex:1 }}>Steps · last 7 days</span>
          <span style={{ fontSize:11, fontWeight:700, color:s.color }}>avg 7.8k</span>
        </div>
        <TrendChart data={chart} color={s.color} glow={s.glow}/>
      </PlainCard>

      <PlainCard tweaks={tweaks} delay={0.15} padding="12px 14px 4px">
        <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:4 }}>
          <span style={{ fontSize:11, fontWeight:700, color:'rgba(255,255,255,0.5)', textTransform:'uppercase', letterSpacing:'0.1em' }}>Recent quests</span>
          <div style={{ flex:1 }}/>
          <span style={{ fontSize:11, color:theme.accent, fontWeight:600 }}>View all →</span>
        </div>
        {activities.map((a,i)=>(<ActivityRow key={i} {...a} isLast={i===activities.length-1}/>))}
      </PlainCard>
      <div style={{ height:8 }}/>
    </div>
  );
}

// ── Screen 3: Nutrition ─────────────────────────────────────────────────
function NutritionScreen({ tweaks, theme }) {
  const [tab, setTab] = React.useState('Day');
  const cal = DOMAINS.calories;
  const macros = [
    { label:'Protein', value:102, goal:160, unit:'g', ...DOMAINS.protein },
    { label:'Fat',     value: 98, goal: 80, unit:'g', ...DOMAINS.fat },
    { label:'Carbs',   value:412, goal:320, unit:'g', ...DOMAINS.carbs },
  ];
  const meals = [
    { name:'Breakfast', time:'08:14', kcal:642, emoji:'🍳' },
    { name:'Lunch',     time:'12:48', kcal:1124, emoji:'🍱' },
    { name:'Snack',     time:'15:30', kcal:312,  emoji:'🍙' },
    { name:'Dinner',    time:'19:22', kcal:1243, emoji:'🍜' },
  ];
  return (
    <div style={{ flex:1, overflowY:'auto', padding:'0 14px', display:'flex', flexDirection:'column', gap:10, position:'relative' }}>
      <ScreenHeader greeting="Fuel up ✦" title="Nutrition" accent={theme.accent} accentGlow={theme.accentGlow}/>
      <TabPill tabs={['Day','Week','Month']} active={tab} onChange={setTab} accent={theme.accent} accentGlow={theme.accentGlow}/>

      <StatCard icon="🔥" label="Calories today"
        color={cal.color} colorDim={cal.dim} colorGlow={cal.glow} gradient={cal.gradient}
        stats={[{value:'3 321',label:'Intake',unit:'kcal'},{value:'2 785',label:'Target',unit:'kcal'},{value:'−536',label:'Over',unit:'kcal'}]}
        progress={1.0} badge="119%" tweaks={tweaks} delay={0.05}/>

      <PlainCard tweaks={tweaks} delay={0.1}>
        <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:12 }}>
          <span style={{ fontSize:11, fontWeight:700, color:'rgba(255,255,255,0.5)', textTransform:'uppercase', letterSpacing:'0.1em' }}>Macros</span>
          <div style={{ flex:1 }}/>
          <span style={{ fontSize:10, color:'rgba(255,255,255,0.35)', fontWeight:500 }}>red = over goal</span>
        </div>
        {macros.map((m,i)=>(<MacroRow key={m.label} {...m} isLast={i===macros.length-1}/>))}
      </PlainCard>

      <PlainCard tweaks={tweaks} delay={0.15} padding="12px 14px 4px">
        <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:8 }}>
          <span style={{ fontSize:11, fontWeight:700, color:'rgba(255,255,255,0.5)', textTransform:'uppercase', letterSpacing:'0.1em' }}>Today's meals</span>
          <div style={{ flex:1 }}/>
          <span style={{ fontSize:11, color:theme.accent, fontWeight:600 }}>+ Log meal</span>
        </div>
        {meals.map((m,i)=>(
          <div key={i} style={{ display:'flex', alignItems:'center', gap:12, padding:'11px 0', borderBottom: i===meals.length-1?'none':'1px solid rgba(255,255,255,0.06)' }}>
            <div style={{ width:34, height:34, borderRadius:10, background:cal.dim, border:`1px solid ${cal.color}44`, display:'flex', alignItems:'center', justifyContent:'center', fontSize:16, flexShrink:0 }}>{m.emoji}</div>
            <div style={{ flex:1, minWidth:0 }}>
              <div style={{ fontSize:13, fontWeight:800, color:'rgba(255,255,255,0.92)', letterSpacing:'0.02em' }}>{m.name.toUpperCase()}</div>
              <div style={{ fontSize:10, color:'rgba(255,255,255,0.4)', fontWeight:500, marginTop:1 }}>{m.time}</div>
            </div>
            <div style={{ fontSize:14, fontWeight:800, color:cal.color, fontVariantNumeric:'tabular-nums' }}>{m.kcal}<span style={{ fontSize:10, fontWeight:600, opacity:0.7, marginLeft:2 }}>kcal</span></div>
          </div>
        ))}
      </PlainCard>
      <div style={{ height:8 }}/>
    </div>
  );
}

// ── Screen 4: Body ──────────────────────────────────────────────────────
function BodyScreen({ tweaks, theme }) {
  const [tab, setTab] = React.useState('Month');
  const w = DOMAINS.weight;
  const sl = DOMAINS.sleep;
  const chart = [
    { label:'M1', value:104.2 },{ label:'M2', value:104.0 },{ label:'M3', value:103.6 },
    { label:'M4', value:103.9 },{ label:'M5', value:103.7 },{ label:'M6', value:103.5 },
    { label:'Now', value:103.9, today:true },
  ];
  return (
    <div style={{ flex:1, overflowY:'auto', padding:'0 14px', display:'flex', flexDirection:'column', gap:10, position:'relative' }}>
      <ScreenHeader greeting="The long game ✦" title="Body" accent={theme.accent} accentGlow={theme.accentGlow}/>
      <TabPill tabs={['Week','Month','Year']} active={tab} onChange={setTab} accent={theme.accent} accentGlow={theme.accentGlow}/>

      <StatCard icon="⚖️" label="Weight"
        color={w.color} colorDim={w.dim} colorGlow={w.glow} gradient={w.gradient}
        stats={[{value:'103.9',label:'Current',unit:'kg'},{value:'+0.3',label:'Change',unit:'kg'},{value:'75.0',label:'Goal',unit:'kg'}]}
        progress={0.35} trophy={true} tweaks={tweaks} delay={0.05}/>

      <PlainCard gradient={w.gradient} colorDim={w.dim} colorGlow={w.glow} tweaks={tweaks} delay={0.1}>
        <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:12 }}>
          <div style={{ width:32, height:32, borderRadius:10, background:w.dim, border:`1px solid ${w.color}44`, display:'flex', alignItems:'center', justifyContent:'center', fontSize:16 }}>📉</div>
          <span style={{ fontWeight:700, fontSize:14, color:'rgba(255,255,255,0.95)', flex:1 }}>Weight trend · 6 weeks</span>
          <span style={{ fontSize:11, fontWeight:700, color:w.color }}>−0.3 kg</span>
        </div>
        <TrendChart data={chart} color={w.color} glow={w.glow}/>
      </PlainCard>

      <StatCard icon="🌙" label="Sleep · last night"
        color={sl.color} colorDim={sl.dim} colorGlow={sl.glow} gradient={sl.gradient}
        stats={[{value:'7h 24m',label:'Duration'},{value:'82',label:'Score'},{value:'23:48',label:'Bedtime'}]}
        progress={0.82} badge="82" xp="+60 XP" tweaks={tweaks} delay={0.15}/>

      <PlainCard tweaks={tweaks} delay={0.2} padding="12px 14px">
        <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:12 }}>
          <span style={{ fontSize:11, fontWeight:700, color:'rgba(255,255,255,0.5)', textTransform:'uppercase', letterSpacing:'0.1em' }}>Achievements</span>
        </div>
        <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:8 }}>
          {[
            { e:'🏆', t:'7-day streak', c:'#FBBF24', unlocked:true },
            { e:'⚔️', t:'100 quests',   c:'#7C6FFF', unlocked:true },
            { e:'🔥', t:'Fat burner',    c:'#F472B6', unlocked:true },
            { e:'🛡️', t:'10k/day',      c:'#34D399', unlocked:false },
            { e:'💎', t:'−5 kg goal',    c:'#60A5FA', unlocked:false },
            { e:'👑', t:'Level 20',      c:'#A89BFF', unlocked:false },
          ].map((a,i)=>(
            <div key={i} style={{
              aspectRatio:'1', borderRadius:12,
              background: a.unlocked ? `linear-gradient(135deg, ${a.c}22, ${a.c}08)` : 'rgba(255,255,255,0.03)',
              border: a.unlocked ? `1px solid ${a.c}44` : '1px solid rgba(255,255,255,0.06)',
              display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', gap:4,
              opacity: a.unlocked?1:0.45,
              boxShadow: a.unlocked && tweaks.glow ? `0 2px 12px ${a.c}33` : 'none',
            }}>
              <div style={{ fontSize:22, filter: a.unlocked?'none':'grayscale(1)' }}>{a.e}</div>
              <div style={{ fontSize:9, fontWeight:700, color: a.unlocked?a.c:'rgba(255,255,255,0.4)', textTransform:'uppercase', letterSpacing:'0.05em' }}>{a.t}</div>
            </div>
          ))}
        </div>
      </PlainCard>
      <div style={{ height:8 }}/>
    </div>
  );
}

Object.assign(window, { OverviewScreen, ActivitiesScreen, NutritionScreen, BodyScreen });
