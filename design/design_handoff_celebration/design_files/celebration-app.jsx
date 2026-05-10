// celebration-app.jsx — App: design canvas with variants + interactive playground

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "type": "level",
  "rarity": "uncommon",
  "xp": 2500,
  "rewardCount": 1,
  "intensity": 1,
  "variant": "D"
}/*EDITMODE-END*/;

function App() {
  const [t, setTweak] = window.useTweaks(TWEAK_DEFAULTS);
  const [animKey, setAnimKey] = React.useState(0);

  // Build a multi-reward set when count > 1
  const multi = React.useMemo(() => {
    const types = ['title', 'cosmetic', 'achievement', 'location'];
    const rarities = ['legendary', 'rare', 'uncommon', 'common'];
    return Array.from({ length: t.rewardCount }, (_, i) => ({
      type: i === 0 ? t.type : types[i % types.length],
      rarity: i === 0 ? t.rarity : rarities[i % rarities.length],
    }));
  }, [t.rewardCount, t.type, t.rarity]);

  const Live = (() => {
    if (t.variant === 'B') return <window.VariantB type={t.type} rarity={t.rarity} xp={t.xp} intensity={t.intensity} animKey={animKey}/>;
    if (t.variant === 'C') return <window.VariantC rewards={multi} intensity={t.intensity} animKey={animKey}/>;
    return <window.VariantD type={t.type} rarity={t.rarity} xp={t.xp} intensity={t.intensity} animKey={animKey}/>;
  })();

  return (
    <window.DesignCanvas>
      <window.DCSection id="live" title="Live playground" subtitle={'Ovládáno přes Tweaks · stiskni Replay pro nové animace'}>
        <window.DCArtboard id="live-1" label={`Variant ${t.variant} · ${t.rarity} · ${t.type}`} width={400} height={800}>
          <div style={{ width:'100%', height:'100%', display:'flex', alignItems:'center', justifyContent:'center', background:'#0B0F1E' }}>
            {Live}
          </div>
        </window.DCArtboard>
      </window.DCSection>

      <window.DCSection id="B" title="B · Cinematic fullscreen" subtitle="Velké eventy (legendary/mythic) · plná obrazovka, paprsky, konfety">
        <window.DCArtboard id="B-legendary" label="Legendary · Title" width={400} height={800}>
          <Wrap><window.VariantB type="title" rarity="legendary" xp={10000}/></Wrap>
        </window.DCArtboard>
        <window.DCArtboard id="B-mythic" label="Mythic · Achievement" width={400} height={800}>
          <Wrap><window.VariantB type="achievement" rarity="mythic" xp={25000}/></Wrap>
        </window.DCArtboard>
      </window.DCSection>

      <window.DCSection id="C" title="C · Multi-reward stack" subtitle="Truhla · víc odměn · fanované karty s indikátorem">
        <window.DCArtboard id="C-3" label="3 odměny · mix rarit" width={400} height={800}>
          <Wrap><window.VariantC rewards={[
            { type:'title', rarity:'legendary' },
            { type:'cosmetic', rarity:'epic' },
            { type:'location', rarity:'rare' },
          ]}/></Wrap>
        </window.DCArtboard>
        <window.DCArtboard id="C-2" label="2 odměny" width={400} height={800}>
          <Wrap><window.VariantC rewards={[
            { type:'achievement', rarity:'epic' },
            { type:'cosmetic', rarity:'uncommon' },
          ]}/></Wrap>
        </window.DCArtboard>
      </window.DCSection>

      <window.DCSection id="D" title="D · Topsheet (current style + claim)" subtitle="Zachovává původní layout · přibyla animace + zlaté tlačítko Vyzvednout XP">
        <window.DCArtboard id="D-firstreward" label="Common · Získej první odměnu" width={400} height={800}>
          <Wrap><window.VariantD
            type="achievement" rarity="common" xp={205}
            title="První odměna"
            desc="Získej svou první progression odměnu."
            rewards={[{ kind:'gem', name:'Jiskra táborového ohně', rarity:'common' }]}
          /></Wrap>
        </window.DCArtboard>
        <window.DCArtboard id="D-chain" label="Uncommon · Řetěz kroků" width={400} height={800}>
          <Wrap><window.VariantD
            type="achievement" rarity="uncommon" xp={310}
            title="Řetěz kroků"
            desc="Splň denní cíl kroků 3 dny v řadě."
            rewards={[{ kind:'gem', name:'Teplé podpalí', rarity:'uncommon' }]}
          /></Wrap>
        </window.DCArtboard>
        <window.DCArtboard id="D-multi" label="Common quest · víc odměn" width={400} height={800}>
          <Wrap><window.VariantD
            type="quest" rarity="common" xp={150}
            title="Lesní zkouška · finále"
            desc="Dokončil jsi celý řetěz lesních questů."
            rewards={[
              { kind:'gem',   name:'Znak lesa',    rarity:'uncommon' },
              { kind:'flame', name:'Splněn quest', rarity:'common' },
            ]}
          /></Wrap>
        </window.DCArtboard>
      </window.DCSection>

      <ReplayButton onClick={() => setAnimKey(k => k + 1)}/>

      <window.TweaksPanel title="Tweaks">
        <window.TweakSection label="Variant">
          <window.TweakSelect tweak={t} setTweak={setTweak} k="variant" label="Layout" options={[
            { value: 'B', label: 'B · Cinematic fullscreen' },
            { value: 'C', label: 'C · Multi-reward stack' },
            { value: 'D', label: 'D · Topsheet + claim' },
          ]}/>
        </window.TweakSection>
        <window.TweakSection label="Reward">
          <window.TweakSelect tweak={t} setTweak={setTweak} k="type" label="Typ" options={[
            { value:'level', label:'Level up' },
            { value:'title', label:'Titul' },
            { value:'achievement', label:'Achievement' },
            { value:'quest', label:'Quest' },
            { value:'streak', label:'Série' },
            { value:'location', label:'Lokace' },
            { value:'cosmetic', label:'Kosmetika' },
          ]}/>
          <window.TweakSelect tweak={t} setTweak={setTweak} k="rarity" label="Rarita" options={[
            { value:'common',    label:'Obvyklé' },
            { value:'uncommon',  label:'Neobvyklé' },
            { value:'rare',      label:'Vzácné' },
            { value:'epic',      label:'Epické' },
            { value:'legendary', label:'Legendární' },
            { value:'mythic',    label:'Mytické' },
          ]}/>
          <window.TweakSlider tweak={t} setTweak={setTweak} k="xp" label="XP odměna" min={0} max={50000} step={50}/>
          <window.TweakSlider tweak={t} setTweak={setTweak} k="rewardCount" label="Počet (jen variant C)" min={1} max={5} step={1}/>
        </window.TweakSection>
        <window.TweakSection label="Animace">
          <window.TweakSlider tweak={t} setTweak={setTweak} k="intensity" label="Intenzita FX" min={0} max={1.5} step={0.05}/>
          <window.TweakButton onClick={() => setAnimKey(k => k + 1)}>↻ Replay animation</window.TweakButton>
        </window.TweakSection>
      </window.TweaksPanel>
    </window.DesignCanvas>
  );
}

function Wrap({ children }) {
  return <div style={{ width:'100%', height:'100%', display:'flex', alignItems:'center', justifyContent:'center', background:'#0B0F1E' }}>{children}</div>;
}

function ReplayButton({ onClick }) {
  return (
    <button onClick={onClick} style={{
      position:'fixed', left:24, bottom:24, zIndex:1000,
      padding:'10px 16px', borderRadius:999, cursor:'pointer',
      background:'#1f1d3a', color:'#F5F3FF', border:'1px solid rgba(167,139,250,0.4)',
      fontSize:13, fontWeight:600, fontFamily:'-apple-system,system-ui,sans-serif',
      boxShadow:'0 8px 24px -8px rgba(124,111,255,0.4)',
    }}>↻ Replay animations</button>
  );
}

ReactDOM.createRoot(document.getElementById('app')).render(<App/>);
