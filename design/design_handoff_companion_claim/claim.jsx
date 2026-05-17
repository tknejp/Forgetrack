// Claim animation overlay — full screen ritual

const { useState: aS, useEffect: aE, useRef: aR, useMemo: aM } = React;

const TA = {
  bg: '#0b0d1a', text: '#fff', textDim: '#9aa0bf',
  accent: '#7b7afb', ember: '#ff8c2a', emberBright: '#ffd166',
};

// easings
const easeOut = t => 1 - Math.pow(1 - t, 3);
const easeIn  = t => t * t * t;
const easeInOut = t => t < 0.5 ? 4*t*t*t : 1 - Math.pow(-2*t + 2, 3)/2;
const easeBack = (t, s=1.7) => 1 + (s+1)*Math.pow(t-1,3) + s*Math.pow(t-1,2);
const clamp = (v,a,b) => Math.max(a, Math.min(b, v));
const lerp = (a,b,t) => a + (b-a)*t;

// per-phase fraction utility
function fr(t, a, b) { return clamp((t - a) / (b - a), 0, 1); }

// ─── Claim Overlay ─────────────────────────────────────────────
function ClaimOverlay({ style, speed = 1, intensity = 1, onComplete, screenW, screenH }) {
  const [t, setT] = aS(0); // ms
  const startRef = aR(null);
  const rafRef = aR(null);
  const completedRef = aR(false);

  aE(() => {
    const tick = (now) => {
      if (!startRef.current) startRef.current = now;
      const elapsed = (now - startRef.current) * speed;
      setT(elapsed);
      if (elapsed >= 5400 && !completedRef.current) {
        completedRef.current = true;
        onComplete && onComplete();
      }
      rafRef.current = requestAnimationFrame(tick);
    };
    rafRef.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(rafRef.current);
  }, [speed]);

  // Pick variant
  const Variant = style === 'fountain' ? FountainVariant
              : style === 'shatter' ? ShatterVariant
              : OrbitVariant;

  // backdrop dim — pulls focus from sheet area
  const dim = clamp(t / 500, 0, 1);

  return (
    <div style={{
      position: 'absolute', inset: 0, pointerEvents: 'none',
      background: `rgba(11,13,26,${0.55 * dim})`,
      transition: 'background 0.3s',
    }}>
      <Variant t={t} intensity={intensity} screenW={screenW} screenH={screenH} />
    </div>
  );
}

// ─── helper: a particle field around center ──────────────────
function Particles({ count, t, lifeMs, cx, cy, spread, color, size = 3, gravity = 0, fadeOut = true, seed = 0 }) {
  // particles are derived: each particle picks a phase based on its index
  // they emit continuously
  const items = [];
  for (let i = 0; i < count; i++) {
    const phase = ((i * 97.3 + seed * 13) % lifeMs);
    const ageMs = (t + phase) % lifeMs;
    const ageFrac = ageMs / lifeMs;
    if (ageFrac > 1) continue;
    // pseudo-random direction
    const rnd1 = Math.sin(i * 12.9898 + seed * 78.233) * 43758.5453;
    const rnd2 = Math.sin(i * 39.346 + seed * 11.135) * 12345.678;
    const ang = ((rnd1 - Math.floor(rnd1)) * Math.PI * 2);
    const dist = ((rnd2 - Math.floor(rnd2)) * spread + 20);
    const x = cx + Math.cos(ang) * dist * ageFrac;
    const y = cy + Math.sin(ang) * dist * ageFrac + gravity * ageFrac * ageFrac;
    const opacity = fadeOut ? (1 - ageFrac) : Math.sin(ageFrac * Math.PI);
    const s = size * (0.6 + 0.8 * Math.sin(ageFrac * Math.PI));
    items.push(
      <div key={i} style={{
        position: 'absolute', left: x - s/2, top: y - s/2,
        width: s, height: s, borderRadius: '50%',
        background: color, opacity,
        boxShadow: `0 0 ${s*2}px ${color}`,
      }} />
    );
  }
  return <>{items}</>;
}

// ─── helper: wisps that converge inward into the forming sprite ──
// progress 0..1; each wisp travels from outer ring toward center, fading as it arrives
function ConvergingWisps({ t, cx, cy, count, reach = 120 }) {
  const items = [];
  const lifeMs = 900;
  for (let i = 0; i < count; i++) {
    const phase = ((i * 73.7) % lifeMs);
    const ageMs = (t + phase) % lifeMs;
    const ageFrac = ageMs / lifeMs;
    if (ageFrac > 1) continue;
    const rnd = Math.sin(i * 12.9898) * 43758.5453;
    const ang = ((rnd - Math.floor(rnd)) * Math.PI * 2);
    const startR = reach * (0.7 + 0.5 * ((Math.sin(i * 39.346) * 12345) % 1));
    const r = lerp(startR, 0, ageFrac);
    const x = cx + Math.cos(ang) * r;
    const y = cy + Math.sin(ang) * r * 0.7; // squashed for depth
    const opacity = Math.sin(ageFrac * Math.PI);
    const s = 3 * (0.7 + 0.6 * (1 - ageFrac));
    items.push(
      <div key={i} style={{
        position: 'absolute', left: x - s/2, top: y - s/2,
        width: s, height: s, borderRadius: '50%',
        background: '#ffd166', opacity,
        boxShadow: `0 0 ${s*2}px #ffb04a`,
      }} />
    );
  }
  return <>{items}</>;
}

// ─── ORBIT variant ───────────────────────────────────────────
// Phases:
//   0-600:    relics fly up from sheet positions to orbit start
//   600-2400: orbit around center, accelerating + spiraling inward
//   2400-2700: pull to center
//   2700-3000: burst flash
//   3000-4400: companion fade-in + float up
//   4400-5200: settle
function OrbitVariant({ t, intensity, screenW, screenH }) {
  const cx = screenW / 2;
  const cy = screenH * 0.45;

  // relic start positions (from sheet)
  const sparkStart = { x: cx - 130, y: screenH * 0.62 };
  const kindlingStart = { x: cx + 130, y: screenH * 0.62 };

  // orbit params
  const orbitStart = { x: cx - 80, y: cy };
  const orbitStart2 = { x: cx + 80, y: cy };

  // PHASE 0-1: fly into orbit
  const fly = fr(t, 0, 600);
  // PHASE 1-2: orbit + spiral
  const orbit = fr(t, 600, 2400);
  // PHASE 2-3: pull to center
  const pull = fr(t, 2400, 2700);
  // PHASE 3-4: burst
  const burst = fr(t, 2700, 3100);
  // PHASE 4-5: companion reveal
  const reveal = fr(t, 3000, 4400);
  // PHASE 5+: idle float
  const settle = fr(t, 4800, 5400);

  // relic positions
  let sparkX, sparkY, kindlingX, kindlingY;
  if (t < 600) {
    sparkX = lerp(sparkStart.x, orbitStart.x, easeOut(fly));
    sparkY = lerp(sparkStart.y, orbitStart.y, easeOut(fly));
    kindlingX = lerp(kindlingStart.x, orbitStart2.x, easeOut(fly));
    kindlingY = lerp(kindlingStart.y, orbitStart2.y, easeOut(fly));
  } else if (t < 2700) {
    const o = clamp((t - 600) / 2100, 0, 1);
    const turns = 2.5;
    const ang = o * turns * Math.PI * 2 * (1 + o * 1.5); // accelerate
    const r = lerp(80, 0, easeInOut(o));
    sparkX = cx + Math.cos(ang) * r;
    sparkY = cy + Math.sin(ang) * r;
    kindlingX = cx + Math.cos(ang + Math.PI) * r;
    kindlingY = cy + Math.sin(ang + Math.PI) * r;
  } else {
    sparkX = sparkY = kindlingX = kindlingY = -9999;
  }

  // relic scale: hidden after pull
  const relicVisible = t < 2700;
  const relicScale = relicVisible ? lerp(1, 0.3, fr(t, 2400, 2700)) : 0;
  const relicOpacity = relicVisible ? 1 : 0;

  // orbit trail (afterglow circle)
  const trailOpacity = orbit > 0 && t < 2700 ? clamp(orbit * 1.5, 0, 1) : 0;
  const trailR = lerp(80, 12, t < 2700 ? clamp((t - 600) / 2100, 0, 1) : 1);

  // burst flash
  const flashScale = burst < 0.5 ? lerp(0, 1.4, easeOut(burst * 2)) : lerp(1.4, 2.6, (burst - 0.5) * 2);
  const flashOpacity = burst < 0.3 ? burst / 0.3 : lerp(1, 0, (burst - 0.3) / 0.7);

  // companion materialization — slow grow, no pop
  // 2700-3300: aura blooms under center while particles still flying
  // 2800-4800: sprite grows from tiny+whispy to full size
  // 4800+: idle float settle
  const auraReveal = fr(t, 2700, 3300);
  const spriteReveal = fr(t, 2800, 4800);
  const compScale = lerp(0.12, 1, easeOut(spriteReveal));
  const compRise = lerp(40, 0, easeOut(spriteReveal));
  const compY = cy - 30 - compRise + (settle > 0 ? Math.sin(t / 350) * 6 : 0);
  // soft ease-in opacity so it stays whispy at first, then settles
  const compOpacity = Math.pow(spriteReveal, 1.6);
  const compBlur = lerp(14, 0, easeOut(spriteReveal));

  // particles intensity
  const orbitParticles = orbit > 0 && t < 2700 ? Math.floor(40 * intensity) : 0;
  const burstParticles = burst > 0 && burst < 1 ? Math.floor(60 * intensity) : 0;
  const revealParticles = reveal > 0 ? Math.floor(30 * intensity) : 0;

  return (
    <>
      {/* glow under whole scene during reveal */}
      <div style={{
        position: 'absolute', left: cx - 220, top: cy - 220, width: 440, height: 440,
        borderRadius: '50%',
        background: `radial-gradient(circle, rgba(255,200,80,${0.35 * Math.max(auraReveal, 0)}) 0%, rgba(123,122,251,${0.15 * spriteReveal}) 35%, transparent 70%)`,
        pointerEvents: 'none',
      }} />

      {/* orbit trail */}
      {trailOpacity > 0 && (
        <div style={{
          position: 'absolute', left: cx - trailR, top: cy - trailR,
          width: trailR * 2, height: trailR * 2, borderRadius: '50%',
          border: `1px solid rgba(255,180,60,${trailOpacity * 0.5})`,
          boxShadow: `0 0 ${30 * trailOpacity}px rgba(255,140,42,${trailOpacity * 0.5}) inset, 0 0 ${20 * trailOpacity}px rgba(255,140,42,${trailOpacity * 0.4})`,
        }} />
      )}

      {/* orbit particles */}
      {orbitParticles > 0 && (
        <Particles count={orbitParticles} t={t} lifeMs={700}
          cx={cx} cy={cy} spread={trailR + 30}
          color="#ffb04a" size={3} seed={1} />
      )}

      {/* relic: spark (ember in coals) */}
      {relicVisible && (
        <img src="assets/campfire_spark.png" style={{
          position: 'absolute', left: sparkX - 36, top: sparkY - 36,
          width: 72, height: 72, objectFit: 'contain',
          transform: `scale(${relicScale})`, opacity: relicOpacity,
          filter: `drop-shadow(0 0 ${12 + 16 * orbit}px rgba(255,140,42,${0.5 + 0.5 * orbit}))`,
          pointerEvents: 'none',
        }} />
      )}
      {/* relic: kindling */}
      {relicVisible && (
        <img src="assets/warm_kindling.png" style={{
          position: 'absolute', left: kindlingX - 42, top: kindlingY - 42,
          width: 84, height: 84, objectFit: 'contain',
          transform: `scale(${relicScale}) rotate(${orbit * 360}deg)`, opacity: relicOpacity,
          filter: `drop-shadow(0 0 ${10 + 14 * orbit}px rgba(255,160,80,${0.4 + 0.4 * orbit}))`,
          pointerEvents: 'none',
        }} />
      )}

      {/* burst — particles only (full-screen flash rings removed per design) */}

      {/* burst particles — shoot outward */}
      {burstParticles > 0 && (
        <Particles count={burstParticles} t={t - 2700} lifeMs={1100}
          cx={cx} cy={cy} spread={260}
          color="#ffd166" size={4} seed={5} gravity={20} />
      )}

      {/* small focused aura that blooms before the sprite appears */}
      {auraReveal > 0 && spriteReveal < 1 && (
        <div style={{
          position: 'absolute', left: cx, top: cy - 30,
          width: 1, height: 1,
          transform: `translate(-50%, -50%) scale(${lerp(40, 220, auraReveal)})`,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(255,220,140,0.9) 0%, rgba(255,160,60,0.4) 40%, transparent 70%)',
          opacity: lerp(0.9, 0, spriteReveal),
          mixBlendMode: 'screen',
        }} />
      )}

      {/* companion reveal */}
      {spriteReveal > 0 && (
        <img src="assets/ember_sprite.png" style={{
          position: 'absolute', left: cx - 110, top: compY - 110,
          width: 220, height: 220, objectFit: 'contain',
          transform: `scale(${compScale})`,
          opacity: compOpacity,
          filter: `drop-shadow(0 12px 32px rgba(255,140,42,${0.55 * compOpacity})) blur(${compBlur}px)`,
          pointerEvents: 'none',
        }} />
      )}

      {/* converging wisps that pour into the forming sprite */}
      {spriteReveal > 0 && spriteReveal < 0.95 && (
        <ConvergingWisps t={t - 2800} cx={cx} cy={compY} count={Math.floor(20 * intensity)} reach={150} />
      )}

      {/* gentle floating sparks around companion */}
      {revealParticles > 0 && spriteReveal > 0.3 && (
        <Particles count={revealParticles} t={t - 3300} lifeMs={2000}
          cx={cx} cy={compY - 10} spread={120}
          color="#ffd166" size={2.5} seed={9} gravity={-15} />
      )}

      {/* status text */}
      <ClaimStatus t={t} screenW={screenW} screenH={screenH} />
    </>
  );
}

function ClaimStatus({ t, screenW, screenH }) {
  let label = '';
  let sub = '';
  let opacity = 1;
  if (t < 600) { label = 'Připravuji rituál…'; sub = ''; }
  else if (t < 2400) { label = 'Spojuji relikvie…'; }
  else if (t < 2900) { label = ''; }
  else if (t < 4700) { label = 'Probouzím společníka…'; }
  else { label = 'Jiskřička'; sub = 'Tvůj nový společník'; }
  // (typo guard removed — label already set correctly above)

  // bottom area (above where the detail sheet will live)
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: screenH * 0.18,
      textAlign: 'center', pointerEvents: 'none',
    }}>
      {label && (
        <div style={{
          color: t < 4700 ? TA.textDim : TA.text,
          fontSize: t < 4700 ? 15 : 30,
          fontWeight: t < 4700 ? 500 : 700,
          letterSpacing: t < 4700 ? 0.3 : 0,
          textShadow: t >= 4700 ? '0 0 20px rgba(255,180,80,0.4)' : 'none',
          transition: 'font-size 0.4s ease',
        }}>{label}</div>
      )}
      {sub && (
        <div style={{
          color: TA.textDim, fontSize: 14, marginTop: 6,
        }}>{sub}</div>
      )}
    </div>
  );
}

// ─── FOUNTAIN variant ───────────────────────────────────────
// Relics drop into a central well; geyser of sparks erupts; companion rises with the geyser.
function FountainVariant({ t, intensity, screenW, screenH }) {
  const cx = screenW / 2;
  const cy = screenH * 0.55;

  // PHASE 0-1: relics drop in
  const drop = fr(t, 0, 900);
  // PHASE 1-2: well charges (glow grows)
  const charge = fr(t, 900, 1800);
  // PHASE 2-3: geyser erupts
  const geyser = fr(t, 1800, 3400);
  // PHASE 3+: companion grows out of the geyser — slow, no pop
  const auraReveal = fr(t, 2200, 3000);
  const spriteReveal = fr(t, 2400, 4500); // longer entrance
  const settle = fr(t, 4500, 5300);

  // relics
  const sparkStart = { x: cx - 130, y: screenH * 0.62 };
  const kindlingStart = { x: cx + 130, y: screenH * 0.62 };
  const sparkX = lerp(sparkStart.x, cx, easeIn(drop));
  const sparkY = lerp(sparkStart.y, cy + 30, easeIn(drop));
  const kindlingX = lerp(kindlingStart.x, cx, easeIn(drop));
  const kindlingY = lerp(kindlingStart.y, cy + 30, easeIn(drop));
  const relicScale = lerp(1, 0, fr(t, 700, 1000));
  const relicVisible = t < 1100;

  // well glow
  const wellR = lerp(30, 60, charge) * (1 + 0.1 * Math.sin(t / 100));
  const wellOpacity = charge > 0 ? clamp(charge * 1.5, 0, 1) : 0;

  // geyser column
  const colH = lerp(0, 320, easeOut(geyser));
  const colOpacity = geyser > 0 ? (geyser < 0.8 ? 1 : lerp(1, 0.3, (geyser - 0.8) / 0.2)) : 0;

  // companion grows out of the well — starts tiny+deep, rises while scaling, no overshoot
  const compY = lerp(cy + 20, screenH * 0.4, easeOut(spriteReveal));
  const compScale = lerp(0.12, 1, easeOut(spriteReveal));
  // opacity uses a soft ease-in so it stays whispy at first, then settles
  const compOpacity = Math.pow(spriteReveal, 1.6);
  const compBlur = lerp(14, 0, easeOut(spriteReveal));

  return (
    <>
      {/* warm wash */}
      <div style={{
        position: 'absolute', left: cx - 220, top: cy - 280, width: 440, height: 440,
        borderRadius: '50%',
        background: `radial-gradient(circle, rgba(255,180,80,${0.3 * Math.max(charge, spriteReveal)}) 0%, transparent 70%)`,
      }} />

      {/* well — pulsing circle on ground */}
      {wellOpacity > 0 && (
        <div style={{
          position: 'absolute', left: cx - wellR, top: cy + 40 - wellR/3,
          width: wellR * 2, height: wellR * 2/3, borderRadius: '50%',
          background: 'radial-gradient(ellipse, rgba(255,220,140,0.9) 0%, rgba(255,140,42,0.4) 40%, transparent 80%)',
          opacity: wellOpacity,
          filter: `blur(${4 * (1 - charge)}px)`,
        }} />
      )}

      {/* relics */}
      {relicVisible && (
        <>
          <img src="assets/campfire_spark.png" style={{
            position: 'absolute', left: sparkX - 36, top: sparkY - 36,
            width: 72, height: 72, objectFit: 'contain',
            transform: `scale(${relicScale})`,
            filter: `drop-shadow(0 0 ${20 * drop}px rgba(255,140,42,${0.8 * drop}))`,
          }} />
          <img src="assets/warm_kindling.png" style={{
            position: 'absolute', left: kindlingX - 42, top: kindlingY - 42,
            width: 84, height: 84, objectFit: 'contain',
            transform: `scale(${relicScale})`,
            filter: `drop-shadow(0 0 ${20 * drop}px rgba(255,160,80,${0.7 * drop}))`,
          }} />
        </>
      )}

      {/* geyser column — column of sparks */}
      {colOpacity > 0 && (
        <div style={{
          position: 'absolute', left: cx - 30, top: cy + 30 - colH,
          width: 60, height: colH, opacity: colOpacity,
          background: 'linear-gradient(180deg, rgba(255,210,120,0) 0%, rgba(255,180,80,0.4) 30%, rgba(255,140,42,0.6) 80%, rgba(255,200,80,0.9) 100%)',
          borderRadius: '40% 40% 50% 50% / 60% 60% 50% 50%',
          filter: 'blur(2px)',
          mixBlendMode: 'screen',
        }} />
      )}
      {/* geyser sparks — many shooting up */}
      {geyser > 0 && geyser < 1 && (
        <Particles count={Math.floor(80 * intensity)} t={t - 1800} lifeMs={1400}
          cx={cx} cy={cy + 40} spread={60}
          color="#ffd166" size={3.5} seed={7} gravity={-260} />
      )}

      {/* small aura blooming from the well before sprite */}
      {auraReveal > 0 && spriteReveal < 1 && (
        <div style={{
          position: 'absolute', left: cx, top: cy + 20,
          width: 1, height: 1,
          transform: `translate(-50%, -50%) scale(${lerp(40, 180, auraReveal)})`,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(255,220,140,0.85) 0%, rgba(255,160,60,0.35) 40%, transparent 70%)',
          opacity: lerp(0.85, 0, spriteReveal),
          mixBlendMode: 'screen',
        }} />
      )}

      {/* companion grows out of the geyser */}
      {spriteReveal > 0 && (
        <img src="assets/ember_sprite.png" style={{
          position: 'absolute', left: cx - 110, top: compY - 110 + (settle > 0 ? Math.sin(t/350)*6 : 0),
          width: 220, height: 220, objectFit: 'contain',
          transform: `scale(${compScale})`,
          opacity: compOpacity,
          filter: `drop-shadow(0 12px 32px rgba(255,140,42,${0.55 * compOpacity})) blur(${compBlur}px)`,
        }} />
      )}

      {/* converging wisps that pour into the forming sprite */}
      {spriteReveal > 0 && spriteReveal < 0.95 && (
        <ConvergingWisps t={t - 2400} cx={cx} cy={compY} count={Math.floor(20 * intensity)} reach={140} />
      )}

      <ClaimStatus t={t} screenW={screenW} screenH={screenH} />
    </>
  );
}

// ─── SHATTER variant ────────────────────────────────────────
// Relics charge → slam together → impact crack with shards → companion forms.
function ShatterVariant({ t, intensity, screenW, screenH }) {
  const cx = screenW / 2;
  const cy = screenH * 0.45;

  const charge = fr(t, 0, 1300);
  const slam = fr(t, 1300, 1700);
  const crack = fr(t, 1700, 2300);
  const auraReveal = fr(t, 2100, 2700);
  const spriteReveal = fr(t, 2300, 4700); // longer, slower grow
  const settle = fr(t, 4700, 5400);

  // shake amount during charge (increases)
  const shake = charge < 1 ? Math.sin(t / 30) * 6 * Math.pow(charge, 2) : 0;
  const shake2 = charge < 1 ? Math.cos(t / 28) * 6 * Math.pow(charge, 2) : 0;

  // relic positions: charge moves them closer
  const startL = cx - 120;
  const startR = cx + 120;
  const slamL = cx - 8;
  const slamR = cx + 8;
  const sparkX = charge < 1
    ? lerp(startL, lerp(startL, cx - 60, charge), easeIn(charge)) + shake
    : lerp(cx - 60, slamL, easeIn(slam));
  const kindlingX = charge < 1
    ? lerp(startR, lerp(startR, cx + 60, charge), easeIn(charge)) + shake2
    : lerp(cx + 60, slamR, easeIn(slam));
  const relicY = cy + shake;
  const relicVisible = t < 1700;
  const relicScale = lerp(1, 0.7, fr(t, 1500, 1700));

  // crack rays
  const crackOpacity = crack > 0 ? (crack < 0.4 ? crack / 0.4 : lerp(1, 0, (crack - 0.4) / 0.6)) : 0;
  const crackScale = lerp(0.2, 2.4, easeOut(crack));

  // companion grows slowly out of the shards
  const compScale = lerp(0.12, 1, easeOut(spriteReveal));
  const compOpacity = Math.pow(spriteReveal, 1.6);
  const compBlur = lerp(14, 0, easeOut(spriteReveal));

  return (
    <>
      {/* aura */}
      <div style={{
        position: 'absolute', left: cx - 220, top: cy - 220, width: 440, height: 440,
        borderRadius: '50%',
        background: `radial-gradient(circle, rgba(255,180,80,${0.35 * Math.max(spriteReveal, auraReveal*0.6)}) 0%, transparent 70%)`,
      }} />

      {/* pre-charge sparks between relics */}
      {charge > 0.3 && t < 1700 && (
        <Particles count={Math.floor(20 * intensity * charge)} t={t} lifeMs={400}
          cx={cx} cy={cy} spread={50}
          color="#ffd166" size={2} seed={3} />
      )}

      {/* relics */}
      {relicVisible && (
        <>
          <img src="assets/campfire_spark.png" style={{
            position: 'absolute', left: sparkX - 36, top: relicY - 36,
            width: 72, height: 72, objectFit: 'contain',
            transform: `scale(${relicScale})`,
            filter: `drop-shadow(0 0 ${10 + 20 * charge}px rgba(255,140,42,${0.5 + 0.5 * charge}))`,
          }} />
          <img src="assets/warm_kindling.png" style={{
            position: 'absolute', left: kindlingX - 42, top: relicY - 42,
            width: 84, height: 84, objectFit: 'contain',
            transform: `scale(${relicScale})`,
            filter: `drop-shadow(0 0 ${10 + 20 * charge}px rgba(255,160,80,${0.4 + 0.5 * charge}))`,
          }} />
        </>
      )}

      {/* crack — radiating lines */}
      {crackOpacity > 0 && (
        <svg style={{
          position: 'absolute', left: cx - 180, top: cy - 180,
          width: 360, height: 360, opacity: crackOpacity,
          transform: `scale(${crackScale})`, mixBlendMode: 'screen',
        }} viewBox="-180 -180 360 360">
          {Array.from({ length: 12 }).map((_, i) => {
            const ang = (i / 12) * Math.PI * 2 + i * 0.07;
            const len = 140 + (i % 3) * 30;
            return (
              <line key={i}
                x1={0} y1={0}
                x2={Math.cos(ang) * len} y2={Math.sin(ang) * len}
                stroke="#ffe4a3" strokeWidth={2 + (i % 2)}
                strokeLinecap="round"
                style={{ filter: 'drop-shadow(0 0 6px #ffb04a)' }} />
            );
          })}
          <circle r={20 + crack * 60} fill="rgba(255,255,255,0.9)" />
        </svg>
      )}

      {/* slam shockwave ring removed — keeping crack rays + shards only */}

      {/* shards flying outward */}
      {crack > 0 && (
        <Particles count={Math.floor(50 * intensity)} t={t - 1700} lifeMs={1200}
          cx={cx} cy={cy} spread={300}
          color="#ffd166" size={4} seed={11} gravity={30} />
      )}

      {/* small aura blooming before sprite */}
      {auraReveal > 0 && spriteReveal < 1 && (
        <div style={{
          position: 'absolute', left: cx, top: cy,
          width: 1, height: 1,
          transform: `translate(-50%, -50%) scale(${lerp(40, 220, auraReveal)})`,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(255,220,140,0.9) 0%, rgba(255,160,60,0.4) 40%, transparent 70%)',
          opacity: lerp(0.9, 0, spriteReveal),
          mixBlendMode: 'screen',
        }} />
      )}

      {/* companion */}
      {spriteReveal > 0 && (
        <img src="assets/ember_sprite.png" style={{
          position: 'absolute', left: cx - 110, top: cy - 110 + (settle > 0 ? Math.sin(t/350)*6 : 0),
          width: 220, height: 220, objectFit: 'contain',
          transform: `scale(${compScale})`,
          opacity: compOpacity,
          filter: `drop-shadow(0 12px 32px rgba(255,140,42,${0.55 * compOpacity})) blur(${compBlur}px)`,
        }} />
      )}

      {/* converging wisps that pour into the forming sprite */}
      {spriteReveal > 0 && spriteReveal < 0.95 && (
        <ConvergingWisps t={t - 2300} cx={cx} cy={cy} count={Math.floor(20 * intensity)} reach={140} />
      )}

      <ClaimStatus t={t} screenW={screenW} screenH={screenH} />
    </>
  );
}

window.ClaimOverlay = ClaimOverlay;

// ─── MorphTransition ─────────────────────────────────────────
// Bridges the final reveal frame and the detail sheet: companion glides
// from its overlay position into the detail-sheet companion slot.
function MorphTransition({ screenW, screenH, animStyle }) {
  const [t, setT] = aS(0);
  aE(() => {
    // double-rAF so the initial styles commit before transition kicks in
    const r1 = requestAnimationFrame(() =>
      requestAnimationFrame(() => setT(1))
    );
    return () => cancelAnimationFrame(r1);
  }, []);

  // Source position — matches the companion's final position inside ClaimOverlay
  const cx = screenW / 2;
  // each variant ends with the companion at a slightly different y
  const cy = animStyle === 'fountain' ? screenH * 0.4
           : animStyle === 'orbit'    ? screenH * 0.45 - 30
           :                            screenH * 0.45;

  // Destination position — matches the detail sheet's 130×130 companion box
  // Sheet padding 22 left, inner top ≈ 35 (handle + margin) inside Sheet,
  // and the detail sheet itself sits with bottom=0 in the frame.
  // The detail sheet renders ~395px tall, so its top ≈ screenH-395.
  const DEST_W = 130;
  const sheetTop = screenH - 395;
  const destCx = 22 + DEST_W / 2;     // = 87
  const destCy = sheetTop + 35 + DEST_W / 2; // box centre

  // overlay companion is 220 wide → scale to 130 (~0.59)
  const SRC_W = 220;

  return (
    <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
      {/* lingering glow under the companion that fades */}
      <div style={{
        position: 'absolute',
        left: (t ? destCx : cx) - 160,
        top:  (t ? destCy : cy) - 160,
        width: 320, height: 320, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(255,200,80,0.30) 0%, rgba(123,122,251,0.10) 40%, transparent 70%)',
        opacity: t ? 0 : 1,
        transition: 'all 1150ms cubic-bezier(.22,.8,.2,1)',
      }} />

      {/* companion morphs from overlay center → detail sheet slot */}
      <img src="assets/ember_sprite.png" style={{
        position: 'absolute',
        left: (t ? destCx : cx) - SRC_W / 2,
        top:  (t ? destCy : cy) - SRC_W / 2,
        width: SRC_W, height: SRC_W, objectFit: 'contain',
        transform: `scale(${t ? DEST_W / SRC_W : 1})`,
        transformOrigin: 'center',
        filter: `drop-shadow(0 ${t ? 8 : 12}px ${t ? 18 : 32}px rgba(255,140,42,${t ? 0.45 : 0.55}))`,
        transition: 'left 1150ms cubic-bezier(.22,.8,.2,1), top 1150ms cubic-bezier(.22,.8,.2,1), transform 1150ms cubic-bezier(.22,.8,.2,1), filter 1100ms ease',
      }} />

      {/* trailing sparks fading out */}
      <div style={{
        position: 'absolute',
        left: cx - 100, top: cy - 100, width: 200, height: 200,
        opacity: t ? 0 : 1,
        transition: 'opacity 600ms ease-out',
      }}>
        {Array.from({ length: 12 }).map((_, i) => {
          const ang = (i / 12) * Math.PI * 2;
          const r = 60;
          return (
            <div key={i} style={{
              position: 'absolute',
              left: 100 + Math.cos(ang) * r - 2,
              top: 100 + Math.sin(ang) * r - 2,
              width: 4, height: 4, borderRadius: '50%',
              background: '#ffd166',
              boxShadow: '0 0 8px #ffb04a',
            }} />
          );
        })}
      </div>
    </div>
  );
}

window.MorphTransition = MorphTransition;
