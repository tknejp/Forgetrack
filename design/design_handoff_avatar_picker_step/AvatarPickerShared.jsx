/* global React */
// Shared bits for all 4 avatar-picker placement variants.

const { useState: useStateAP } = React;

// 8 avatars: 2 real assets + 6 monogram placeholders for fantasy classes.
// In production these would be illustrated character portraits.
const AVATARS = [
  { id: 'pixel',    kind: 'img',  src: 'assets/avatar_pixel.png', label: 'Pixel hrdina' },
  { id: 'fox',      kind: 'img',  src: 'assets/forest_fox.png',   label: 'Liška' },
  { id: 'poutnik',  kind: 'mono', letter: 'P', hue: '#8B5CF6', label: 'Poutník' },
  { id: 'kovar',    kind: 'mono', letter: 'K', hue: '#F4C152', label: 'Kovář' },
  { id: 'mudrc',    kind: 'mono', letter: 'M', hue: '#3FB8AF', label: 'Mudrc' },
  { id: 'bard',     kind: 'mono', letter: 'B', hue: '#F472B6', label: 'Bard' },
  { id: 'lukos',    kind: 'mono', letter: 'L', hue: '#FB923C', label: 'Lukostřelec' },
  { id: 'mag',      kind: 'mono', letter: 'É', hue: '#A78BFA', label: 'Mág' },
];

function avatarById(id) { return AVATARS.find(a => a.id === id) || AVATARS[0]; }

// A single avatar tile / chip / circle.
// size = 'sm' | 'md' | 'lg' | 'xl'
function AvatarBadge({ id, size = 'md', selected = false, ring = true }) {
  const a = avatarById(id);
  const px = { sm: 36, md: 56, lg: 72, xl: 112 }[size];
  const fs = { sm: 14, md: 22, lg: 28, xl: 44 }[size];
  const radius = px * 0.32;

  const ringOuter = selected && ring ? `0 0 0 3px ${a.kind === 'mono' ? a.hue : '#A78BFA'}` : 'none';
  const ringInner = selected ? `inset 0 0 0 2px rgba(11,15,30,1)` : 'none';

  if (a.kind === 'img') {
    return (
      <div style={{
        width: px, height: px, borderRadius: radius,
        background: '#0B0F1E',
        boxShadow: [
          ringOuter,
          ringInner,
          selected ? `0 6px 18px -4px ${a.hue || 'rgba(167,139,250,0.6)'}` : '0 2px 8px rgba(0,0,0,0.35)',
        ].filter(s => s !== 'none').join(', ') || 'none',
        overflow: 'hidden',
        flexShrink: 0,
        position: 'relative',
      }}>
        <img src={a.src} alt={a.label} style={{
          width: '100%', height: '100%', objectFit: 'cover',
          display: 'block',
          imageRendering: a.id === 'pixel' ? 'pixelated' : 'auto',
        }}/>
      </div>
    );
  }
  // mono
  return (
    <div style={{
      width: px, height: px, borderRadius: radius,
      background: `linear-gradient(135deg, ${a.hue}, ${a.hue}aa)`,
      display: 'grid', placeItems: 'center',
      color: '#fff', fontFamily: 'Inter, sans-serif',
      fontSize: fs, fontWeight: 800, letterSpacing: '-0.02em',
      boxShadow: [
        ringOuter,
        ringInner,
        selected ? `0 6px 18px -4px ${a.hue}` : '0 2px 8px rgba(0,0,0,0.35)',
      ].filter(s => s !== 'none').join(', ') || 'none',
      flexShrink: 0,
      textShadow: '0 1px 2px rgba(0,0,0,0.35)',
    }}>{a.letter}</div>
  );
}

// User-uploaded "photo" tile (placeholder = no photo yet).
function UploadTile({ size = 56, onClick, hasPhoto = false, photoUrl }) {
  return (
    <button
      onClick={onClick}
      style={{
        width: size, height: size,
        borderRadius: size * 0.32,
        background: hasPhoto ? '#0B0F1E' : 'rgba(28,30,56,0.55)',
        border: hasPhoto ? '1px solid rgba(167,139,250,0.45)' : '1px dashed rgba(167,139,250,0.45)',
        display: 'grid', placeItems: 'center',
        cursor: 'pointer', padding: 0,
        flexShrink: 0,
        position: 'relative',
        overflow: 'hidden',
        fontFamily: 'Inter, sans-serif',
      }}
    >
      {hasPhoto && photoUrl ? (
        <img src={photoUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }}/>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
          <svg width={size > 60 ? 22 : 18} height={size > 60 ? 22 : 18} viewBox="0 0 24 24" fill="none">
            <rect x="3" y="6" width="18" height="13" rx="2" stroke="#A78BFA" strokeWidth="1.6"/>
            <circle cx="12" cy="13" r="3.5" stroke="#A78BFA" strokeWidth="1.6"/>
            <path d="M9 6l1.2-2h3.6L15 6" stroke="#A78BFA" strokeWidth="1.6" strokeLinejoin="round"/>
          </svg>
          {size >= 70 && (
            <span style={{ fontSize: 9, color: 'rgba(167,139,250,0.85)', fontWeight: 600, letterSpacing: 0.4 }}>Foto</span>
          )}
        </div>
      )}
    </button>
  );
}

// Grid of avatars + upload tile. selectedId controls highlight; onPick to choose.
function AvatarGrid({ selectedId, onPick, onUpload, uploadedUrl, cols = 4, tileSize = 60, gap = 10 }) {
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: `repeat(${cols}, 1fr)`,
      gap, justifyItems: 'center',
    }}>
      {AVATARS.map(a => (
        <button
          key={a.id}
          onClick={() => onPick(a.id)}
          style={{
            background: 'transparent', border: 'none', padding: 0, cursor: 'pointer',
            display: 'grid', placeItems: 'center',
          }}
        >
          <AvatarBadge id={a.id} size={tileSize >= 70 ? 'lg' : 'md'} selected={a.id === selectedId} />
        </button>
      ))}
      <UploadTile
        size={tileSize >= 70 ? 72 : 56}
        onClick={onUpload}
        hasPhoto={Boolean(uploadedUrl)}
        photoUrl={uploadedUrl}
      />
    </div>
  );
}

// Horizontal scrolling rail of avatars (compact placement).
function AvatarRail({ selectedId, onPick, onUpload, uploadedUrl }) {
  return (
    <div style={{
      display: 'flex', gap: 10, overflowX: 'auto', padding: '4px 2px',
      scrollbarWidth: 'none',
    }} className="hide-scroll">
      {AVATARS.map(a => (
        <button
          key={a.id}
          onClick={() => onPick(a.id)}
          style={{
            background: 'transparent', border: 'none', padding: 0, cursor: 'pointer',
            display: 'grid', placeItems: 'center', flexShrink: 0,
          }}
        >
          <AvatarBadge id={a.id} size="md" selected={a.id === selectedId} />
        </button>
      ))}
      <UploadTile
        size={56}
        onClick={onUpload}
        hasPhoto={Boolean(uploadedUrl)}
        photoUrl={uploadedUrl}
      />
      <style>{`.hide-scroll::-webkit-scrollbar { display: none; }`}</style>
    </div>
  );
}

// Bottom sheet variant of the picker (for inline placements).
function AvatarSheet({ selectedId, onPick, onUpload, uploadedUrl, onClose }) {
  return (
    <div
      onClick={onClose}
      style={{
        position: 'absolute', inset: 0, zIndex: 100,
        background: 'rgba(0,0,0,0.55)',
        display: 'flex', alignItems: 'flex-end',
        animation: 'ap-fade 0.18s ease-out',
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          width: '100%',
          background: 'linear-gradient(180deg, #1A1838 0%, #0F1226 100%)',
          borderRadius: '24px 24px 0 0',
          padding: '14px 20px 24px',
          borderTop: '1px solid rgba(167,139,250,0.25)',
          animation: 'ap-rise 0.22s cubic-bezier(.2,.7,.3,1)',
        }}
      >
        <div style={{
          width: 38, height: 4, borderRadius: 2,
          background: 'rgba(255,255,255,0.18)', margin: '0 auto 14px',
        }}/>
        <div style={{ fontSize: 17, fontWeight: 800, color: '#F5F3FF', letterSpacing: '-0.01em' }}>
          Vyber si tvář
        </div>
        <div style={{ fontSize: 12, color: 'rgba(245,243,255,0.55)', marginTop: 3, marginBottom: 14 }}>
          Hrdino, takhle se budeš zobrazovat v žebříčku.
        </div>
        <AvatarGrid
          selectedId={selectedId}
          onPick={onPick}
          onUpload={onUpload}
          uploadedUrl={uploadedUrl}
          cols={5}
          tileSize={56}
          gap={10}
        />
        <button
          onClick={onClose}
          style={{
            marginTop: 18, width: '100%', height: 48, borderRadius: 14,
            background: 'linear-gradient(180deg, #8B5CF6 0%, #7C3AED 100%)',
            border: 'none', color: '#fff',
            fontFamily: 'Inter, sans-serif', fontSize: 14, fontWeight: 700,
            cursor: 'pointer',
            boxShadow: '0 8px 22px -6px rgba(139,92,246,0.6)',
          }}
        >Hotovo</button>

        <style>{`
          @keyframes ap-fade { from { opacity: 0; } to { opacity: 1; } }
          @keyframes ap-rise { from { transform: translateY(20px); opacity: 0.6; } to { transform: translateY(0); opacity: 1; } }
        `}</style>
      </div>
    </div>
  );
}

// Standard progress dots used across onboarding.
function ProgressDots({ step, total }) {
  return (
    <div style={{ display: 'flex', gap: 6 }}>
      {Array.from({ length: total }).map((_, i) => (
        <div key={i} style={{
          height: 4, borderRadius: 2,
          width: i === step ? 22 : 14,
          background: i <= step ? '#A78BFA' : 'rgba(167,139,250,0.18)',
          transition: 'all 0.3s',
        }} />
      ))}
    </div>
  );
}

// Primary purple gradient button (matches existing onboarding).
function APPrimaryBtn({ label, onClick, arrow = true, wand = false, disabled = false }) {
  return (
    <button
      onClick={disabled ? undefined : onClick}
      style={{
        flex: 1, height: 52, borderRadius: 16,
        background: disabled
          ? 'rgba(139,92,246,0.25)'
          : 'linear-gradient(180deg, #8B5CF6 0%, #7C3AED 100%)',
        border: 'none', color: disabled ? 'rgba(255,255,255,0.5)' : '#fff',
        fontFamily: 'Inter, sans-serif', fontSize: 15, fontWeight: 700,
        cursor: disabled ? 'not-allowed' : 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        boxShadow: disabled ? 'none' : '0 8px 24px -6px rgba(139,92,246,0.65), inset 0 1px 0 rgba(255,255,255,0.18)',
      }}
    >
      {wand && <span style={{ fontSize: 16 }}>✦</span>}
      {label}
      {arrow && (
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <path d="M5 2l5 5-5 5" stroke="#fff" strokeWidth="2" strokeLinecap="round"/>
        </svg>
      )}
    </button>
  );
}

// Onboarding shell (gradient bg, top progress, footer slot).
function OnboardingShell({ step, total, children, footer, hideSkip = false }) {
  return (
    <div style={{
      position: 'relative', height: '100%',
      background:
        'radial-gradient(ellipse 80% 50% at 50% 0%, rgba(139,92,246,0.20), transparent 60%),' +
        'radial-gradient(ellipse 60% 30% at 50% 100%, rgba(63,184,175,0.10), transparent 60%),' +
        '#0B0F1E',
      overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
      fontFamily: 'Inter, sans-serif',
      color: '#F5F3FF',
    }}>
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '14px 20px 8px',
      }}>
        <ProgressDots step={step} total={total} />
        {!hideSkip && (
          <button style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            fontSize: 13, color: 'rgba(245,243,255,0.55)', fontWeight: 500,
            fontFamily: 'Inter, sans-serif',
          }}>Přeskočit</button>
        )}
      </div>
      <div style={{ flex: 1, overflowY: 'auto', padding: '8px 20px 12px' }}>
        {children}
      </div>
      <div style={{ padding: '12px 20px 20px' }}>
        {footer}
      </div>
    </div>
  );
}

// Back button used in footer alongside primary CTA.
function APBackBtn() {
  return (
    <button style={{
      width: 56, height: 52, borderRadius: 16,
      border: '1px solid rgba(167,139,250,0.22)',
      background: 'rgba(28,30,56,0.45)',
      color: '#C7C2E0', cursor: 'pointer',
      display: 'grid', placeItems: 'center', flexShrink: 0,
    }}>
      <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
        <path d="M9 2L4 7l5 5" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
      </svg>
    </button>
  );
}

Object.assign(window, {
  AVATARS, avatarById,
  AvatarBadge, UploadTile, AvatarGrid, AvatarRail, AvatarSheet,
  ProgressDots, APPrimaryBtn, APBackBtn, OnboardingShell,
});
