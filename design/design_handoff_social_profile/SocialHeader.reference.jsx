// SocialHeader.reference.jsx
// ─────────────────────────────────────────────────────────────────────
// DESIGN REFERENCE — Forgetrack Social profile header (friend's view).
//
// This file is a self-contained extract of the inline-styled React
// prototype. It is NOT meant to be shipped as-is — port it into the
// target codebase's component / styling system. See README.md for the
// full spec (tokens, behavior, asset notes).
//
// Components in this file:
//   FramedAvatar     · pixel avatar inside the wildwood frame, with
//                      optional LVL pin overlay
//   TitleRow         · pill carrying the hero's title (emblem optional)
//   GroundGlow       · soft radial glow used under the companion
//   EmblemSlot       · single slot — unlocked / locked / end-game
//   EmblemCollection · 11-slot collection, supports 4 layouts;
//                      Social uses the 4·4·3 grid
//   SocialHeader     · the actual deliverable
//   SocialScreen     · demo wrapper showing the header in context
//   PhoneChrome      · status-bar / notch shell used by the demo only
// ─────────────────────────────────────────────────────────────────────

// Placeholder paths — replace with cosmetic URLs from your asset pipeline.
const COSMETICS = {
  bg:        'assets/forest_trail.png',
  companion: 'assets/forest_fox.png',
  emblem:    'assets/forest_mark.png',
  frame:     'assets/wildwood_frame.png',
  avatar:    'assets/avatar_pixel.png',
};

// Placeholder profile data — in the real app this comes from props.
const HERO = {
  name:  'Tomáš Knejp',
  handle:'@sigisere',
  level: 5,
  title: 'Průzkumník stezek',
};

// ─────────────────────────────────────────────────────────────────────
// FramedAvatar — pixel avatar inside the wildwood frame.
// Props:
//   size      number  outer width/height (Social uses 140)
//   tilt      number  rotate the whole block (Social uses -3 for character)
//   levelPin  bool    show the "LVL N" pill at the bottom-center
// ─────────────────────────────────────────────────────────────────────
function FramedAvatar({ size = 130, tilt = 0, levelPin = false }) {
  const inset = Math.round(size * 0.10);
  return (
    <div style={{
      position:'relative', width: size, height: size,
      transform: tilt ? `rotate(${tilt}deg)` : undefined,
      filter:'drop-shadow(0 14px 20px rgba(0,0,0,0.55))',
      flexShrink: 0,
    }}>
      {/* pixel-art avatar, inset so the wildwood frame surrounds it */}
      <img src={COSMETICS.avatar} alt="" style={{
        position:'absolute', inset, width: size - inset*2, height: size - inset*2,
        objectFit:'cover', imageRendering:'pixelated', borderRadius: 6,
      }}/>
      {/* decorative wildwood frame on top */}
      <img src={COSMETICS.frame} alt="" style={{
        position:'absolute', inset:0, width:'100%', height:'100%', objectFit:'contain',
      }}/>
      {levelPin && (
        // Neutral-gray pill at the bottom of the avatar. Counter-rotates
        // the parent tilt so the text stays horizontal.
        // Future: tint by level rarity.
        <div style={{
          position:'absolute', bottom: -8, left:'50%',
          transform: `translateX(-50%) rotate(${-tilt}deg)`,
          padding:'3px 12px', borderRadius: 999,
          background:'linear-gradient(180deg, #5A5871, #36344A)',
          color:'#E4E1F0', fontSize: 11, fontWeight: 800, letterSpacing:'0.08em',
          boxShadow:'0 4px 10px rgba(0,0,0,0.45), inset 0 1px 0 rgba(255,255,255,0.18)',
          border:'1px solid rgba(255,255,255,0.10)',
          whiteSpace:'nowrap',
        }}>LVL {HERO.level}</div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// TitleRow — pill carrying the hero's chosen title.
// In Social we use hideEmblem because the emblem lives in the collection
// at the bottom; the pill is text-only here.
// ─────────────────────────────────────────────────────────────────────
function TitleRow({ size = 'md', hideEmblem = false }) {
  const dim = { sm: 22, md: 28, lg: 34 }[size];
  return (
    <div style={{
      display:'inline-flex', alignItems:'center', gap: 8,
      padding:'4px 10px 4px 8px', borderRadius: 999,
      background:'rgba(255,255,255,0.05)',
      border:'1px solid rgba(255,255,255,0.10)',
    }}>
      {!hideEmblem && (
        <div style={{
          width: dim, height: dim, position:'relative',
          filter:'drop-shadow(0 2px 6px rgba(0,0,0,0.5))',
        }}>
          <img src={COSMETICS.emblem} alt="" style={{width:'100%', height:'100%', objectFit:'contain'}}/>
        </div>
      )}
      <span style={{
        fontSize: size === 'lg' ? 12 : 11, fontWeight: 700, color:'#C7C2E0',
        letterSpacing: '0.16em', textTransform:'uppercase', whiteSpace:'nowrap',
      }}>{HERO.title}</span>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// EmblemSlot — single cell in the collection.
// States:
//   unlocked + pinned → image with purple halo + cyan-tinted drop shadow
//   unlocked          → image with neutral drop shadow
//   locked            → dashed empty square with a dot
//   locked + endGame  → dashed empty square with a faint star glyph
// ─────────────────────────────────────────────────────────────────────
function EmblemSlot({ unlocked, src, pinned, endGame, size = 36 }) {
  if (unlocked) {
    return (
      <div title={pinned ? 'Připnutý emblem' : 'Odemčený emblem'} style={{
        width: size, height: size, position:'relative', flexShrink: 0,
        filter: pinned
          ? 'drop-shadow(0 2px 6px rgba(63,184,175,0.55)) drop-shadow(0 3px 6px rgba(0,0,0,0.5))'
          : 'drop-shadow(0 2px 4px rgba(0,0,0,0.5))',
      }}>
        {pinned && (
          <div style={{
            position:'absolute', inset:'-12%',
            background:'radial-gradient(circle, rgba(124,111,255,0.35), transparent 65%)',
            filter:'blur(4px)',
          }}/>
        )}
        <img src={src} alt="" style={{position:'relative', width:'100%', height:'100%', objectFit:'contain'}}/>
      </div>
    );
  }
  return (
    <div style={{
      width: size, height: size, borderRadius: 9,
      background:'rgba(255,255,255,0.025)',
      border:'1px dashed rgba(255,255,255,0.09)',
      display:'flex', alignItems:'center', justifyContent:'center',
      flexShrink: 0,
    }}>
      {endGame ? (
        <svg width={size*0.45} height={size*0.45} viewBox="0 0 24 24" fill="none"
             stroke="rgba(255,255,255,0.22)" strokeWidth="1.6" strokeLinejoin="round">
          <path d="M12 3 L13.5 10.5 L21 12 L13.5 13.5 L12 21 L10.5 13.5 L3 12 L10.5 10.5 Z"/>
        </svg>
      ) : (
        <div style={{
          width: 4, height: 4, borderRadius: 999,
          background:'rgba(255,255,255,0.18)',
        }}/>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// EmblemCollection — 11 slots in a 4·4·3 grid (slot 11 is end-game).
// The reference file also supports other layouts ('row', 'grid2',
// 'honeycomb') — Social uses 'grid3' (4·4·3).
// ─────────────────────────────────────────────────────────────────────
function EmblemCollection({ unlockedCount = 1, pinnedIndex = 0, size = 36, gap = 4, layout = 'grid3' }) {
  const slots = Array.from({length: 11}, (_, i) => ({
    unlocked: i < unlockedCount,
    pinned:   i === pinnedIndex,
    endGame:  i === 10,
    src:      COSMETICS.emblem, // for now all unlocked emblems use the same icon
  }));

  if (layout === 'grid3') {
    // 4 + 4 + 3, end-game stays in the last row
    const rows = [slots.slice(0,4), slots.slice(4,8), slots.slice(8,11)];
    return (
      <div style={{display:'flex', flexDirection:'column', gap}}>
        {rows.map((row, ri) => (
          <div key={ri} style={{display:'flex', gap}}>
            {row.map((s, i) => <EmblemSlot key={i} {...s} size={size}/>)}
          </div>
        ))}
      </div>
    );
  }

  // (Other layouts omitted from this handoff — Social only needs grid3.
  // Fall back to a single row.)
  return (
    <div style={{display:'flex', gap, alignItems:'center'}}>
      {slots.map((s, i) => <EmblemSlot key={i} {...s} size={size}/>)}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// GroundGlow — warm radial ellipse used under the companion, sells the
// figure as a standing object with light coming from below.
// ─────────────────────────────────────────────────────────────────────
function GroundGlow({ left, right, bottom, width = 110, color = 'rgba(244,193,82,0.5)' }) {
  return (
    <div style={{
      position:'absolute', left, right, bottom, width, height: 14,
      background:`radial-gradient(ellipse, ${color}, transparent 70%)`,
      filter:'blur(4px)',
    }}/>
  );
}

// ─────────────────────────────────────────────────────────────────────
// SocialHeader — THE DELIVERABLE.
// 412 × 400 (full width, fixed height). Layered: background image →
// radial darken → vertical fade → avatar / identity → companion + glow
// → emblem collection.
// ─────────────────────────────────────────────────────────────────────
function SocialHeader() {
  return (
    <div style={{position:'relative', overflow:'hidden'}}>
      <div style={{position:'relative', height: 400}}>
        {/* background scene */}
        <img src={COSMETICS.bg} alt="" style={{
          position:'absolute', inset:0, width:'100%', height:'100%',
          objectFit:'cover', objectPosition:'center 30%',
        }}/>
        {/* radial darken — pull focus to centre */}
        <div style={{
          position:'absolute', inset:0,
          background:'radial-gradient(ellipse at 50% 35%, transparent 0%, rgba(10,14,28,0.45) 70%, rgba(10,14,28,0.95) 100%)',
        }}/>
        {/* vertical fade — dim top (status bar) and bottom (seam into page) */}
        <div style={{
          position:'absolute', inset:0,
          background:'linear-gradient(180deg, rgba(10,14,28,0.5) 0%, transparent 22%, transparent 55%, rgba(10,14,28,0.96) 100%)',
        }}/>

        {/* AVATAR with -3° tilt + LVL pin */}
        <div style={{position:'absolute', left: 16, top: 16}}>
          <FramedAvatar size={140} tilt={-3} levelPin/>
        </div>

        {/* Camera edit button — owner-only. HIDE in friend's view.
            Render this conditionally on `isOwnProfile`. */}
        <button style={{
          position:'absolute', left: 130, top: 130,
          width: 32, height: 32, borderRadius: 999,
          background:'linear-gradient(180deg, #7C6FFF, #5D4FE0)',
          border:'2px solid #0A0E1C', color:'#fff', cursor:'pointer',
          display:'flex', alignItems:'center', justifyContent:'center',
          boxShadow:'0 6px 14px rgba(124,111,255,0.45)', padding: 0, zIndex: 4,
        }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
            <path d="M3 7h3l2-3h8l2 3h3v13H3z"/><circle cx="12" cy="13" r="4"/>
          </svg>
        </button>

        {/* IDENTITY BLOCK — name / handle / title pill */}
        <div style={{position:'absolute', left: 172, top: 24, right: 16, zIndex: 5}}>
          <div style={{
            fontSize: 26, fontWeight: 800, color:'#F5F3FF', letterSpacing:'-0.02em',
            lineHeight: 1.05, textShadow:'0 4px 16px rgba(0,0,0,0.65)',
          }}>{HERO.name}</div>
          <div style={{
            fontSize: 12, color:'#9C8FE0', marginTop: 3, fontWeight: 500, marginBottom: 12,
          }}>{HERO.handle}</div>
          <TitleRow size="md" hideEmblem/>
        </div>

        {/* COMPANION — bottom-right with ground glow */}
        <GroundGlow right={20} bottom={10} width={120} color="rgba(244,193,82,0.45)"/>
        <img src={COSMETICS.companion} alt="" style={{
          position:'absolute', right: 6, bottom: 14, width: 134, height: 134,
          objectFit:'contain', filter:'drop-shadow(0 12px 14px rgba(0,0,0,0.55))',
          zIndex: 3,
        }}/>

        {/* EMBLEM COLLECTION — 4·4·3 grid, bottom-left */}
        <div style={{position:'absolute', left: 16, bottom: 16, zIndex: 5}}>
          <EmblemCollection unlockedCount={1} pinnedIndex={0} size={52} gap={6} layout="grid3"/>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// Below: demo-only — NOT part of the deliverable.
// SocialScreen embeds the SocialHeader inside a phone shell so the
// design can be reviewed in context. The stat cards / friends row /
// "PŘIPNUTÉ ACHIEVEMENTY" copy are placeholders representing whatever
// the real profile screen below the header contains; ignore them.
// ─────────────────────────────────────────────────────────────────────

function PhoneChrome({ children, label }) {
  return (
    <div style={{
      width: 412, height: 860, background: '#05060B',
      borderRadius: 40, overflow: 'hidden', position: 'relative',
      boxShadow: '0 30px 60px -30px rgba(0,0,0,0.55), 0 0 0 1px rgba(255,255,255,0.04) inset',
      fontFamily: 'Inter, "SF Pro Text", system-ui, sans-serif',
      color: '#F5F3FF',
    }}>
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 44,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '0 24px', fontSize: 14, fontWeight: 600, zIndex: 50, letterSpacing: '-0.01em',
      }}>
        <span>9:41</span>
        <span style={{display:'flex', gap:6, alignItems:'center', opacity:0.85}}>
          <svg width="16" height="11" viewBox="0 0 16 11" fill="none">
            <path d="M8 2.5C9.7 2.5 11.3 3.1 12.6 4.3L13.6 3.2C12 1.8 10.1 1 8 1S4 1.8 2.4 3.2L3.4 4.3C4.7 3.1 6.3 2.5 8 2.5Z" fill="currentColor"/>
          </svg>
          <svg width="22" height="11" viewBox="0 0 22 11" fill="none">
            <rect x="0.5" y="0.5" width="18" height="10" rx="2.5" stroke="currentColor" opacity="0.4"/>
            <rect x="2" y="2" width="13" height="7" rx="1" fill="currentColor"/>
            <rect x="19.5" y="3.5" width="1.5" height="4" rx="0.5" fill="currentColor" opacity="0.4"/>
          </svg>
        </span>
      </div>
      <div style={{
        position:'absolute', top: 10, left: '50%', transform:'translateX(-50%)',
        width: 110, height: 26, background: '#000', borderRadius: 14, zIndex: 60,
      }}/>
      <div style={{
        position: 'absolute', top: 54, left: 22, fontSize: 11, fontWeight: 700,
        letterSpacing: '0.18em', color: '#9C8FE0', textTransform: 'uppercase', zIndex: 40,
      }}>{label}</div>
      {children}
    </div>
  );
}

function SocialScreen() {
  return (
    <PhoneChrome label="SOCIAL · profil přítele">
      <div style={{position:'absolute', inset: 0, paddingTop: 78, background:'#0A0E1C', overflow:'hidden'}}>
        <SocialHeader/>
        {/* Below: placeholder profile content. Out of scope. */}
      </div>
    </PhoneChrome>
  );
}

// Export pattern depends on your build — adapt as needed.
// export { SocialHeader, FramedAvatar, TitleRow, EmblemCollection, EmblemSlot, GroundGlow };
