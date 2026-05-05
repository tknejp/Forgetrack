// PNG-backed quest icons with category-tinted glow halo (no outer frame)

function PngIcon({ src, size = 64, accentRgb = '160, 122, 255', glowStrength = 'mild' }) {
  const glowMap = {
    mild:   `drop-shadow(0 0 6px rgba(${accentRgb}, 0.35)) drop-shadow(0 0 14px rgba(${accentRgb}, 0.20))`,
    strong: `drop-shadow(0 0 8px rgba(${accentRgb}, 0.55)) drop-shadow(0 0 22px rgba(${accentRgb}, 0.30))`,
    none:   'none',
  };
  return (
    <div style={{
      width: size, height: size, flexShrink: 0,
      position: 'relative',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      {/* soft radial halo behind icon */}
      <span style={{
        position: 'absolute', inset: '-10%',
        background: `radial-gradient(circle, rgba(${accentRgb}, ${glowStrength === 'strong' ? 0.22 : 0.12}), transparent 65%)`,
        pointerEvents: 'none',
      }}/>
      <img src={src} alt="" style={{
        width: '100%', height: '100%', objectFit: 'contain',
        filter: glowMap[glowStrength] || glowMap.mild,
        position: 'relative',
      }}/>
    </div>
  );
}

// Treasure chest (kept as SVG — used for completed claimable)
function AssetChest({ size = 48, glowStrength = 'mild' }) {
  return (
    <div style={{
      width: size, height: size, flexShrink: 0,
      position: 'relative',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <span style={{
        position: 'absolute', inset: '-10%',
        background: `radial-gradient(circle, rgba(255, 200, 70, 0.28), transparent 65%)`,
      }}/>
      <svg width={size * 0.92} height={size * 0.92} viewBox="0 0 64 64" fill="none" style={{
        filter: 'drop-shadow(0 0 8px rgba(255, 200, 70, 0.55))',
        position: 'relative',
      }}>
        <path d="M32 6 L34 14 L32 16 L30 14 Z" fill="#fff5a8" opacity="0.7"/>
        <path d="M12 26 Q12 18 20 18 L44 18 Q52 18 52 26 L52 32 L12 32 Z"
              fill="#d68a2a" stroke="#3a2410" strokeWidth="2" strokeLinejoin="round"/>
        <path d="M14 26 Q14 20 20 20 L44 20 Q50 20 50 26 L50 30 L14 30 Z" fill="#f2b04a"/>
        <rect x="12" y="32" width="40" height="20" rx="2" fill="#b97520" stroke="#3a2410" strokeWidth="2"/>
        <rect x="14" y="34" width="36" height="3" fill="#d68a2a"/>
        <rect x="28" y="34" width="8" height="10" rx="1.5" fill="#ffd84a" stroke="#5a3d00" strokeWidth="1.5"/>
        <circle cx="32" cy="39" r="1.5" fill="#5a3d00"/>
        <circle cx="22" cy="22" r="3" fill="#ffd84a" stroke="#5a3d00" strokeWidth="1.2"/>
        <circle cx="32" cy="18" r="3" fill="#ffe26a" stroke="#5a3d00" strokeWidth="1.2"/>
        <circle cx="42" cy="22" r="3" fill="#ffd84a" stroke="#5a3d00" strokeWidth="1.2"/>
      </svg>
    </div>
  );
}

function AssetCrystal({ size = 48 }) {
  return (
    <div style={{
      width: size, height: size, flexShrink: 0,
      position: 'relative',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      opacity: 0.85,
    }}>
      <svg width={size * 0.9} height={size * 0.9} viewBox="0 0 64 64" fill="none">
        <path d="M32 8 L46 28 L38 54 L26 54 L18 28 Z"
              fill="#3eb87a" stroke="#0e3d28" strokeWidth="2" strokeLinejoin="round"/>
        <path d="M32 8 L32 54 L26 54 L18 28 Z" fill="#5fd49a"/>
        <path d="M32 8 L46 28 L32 32 Z" fill="#2a9c5f"/>
        <circle cx="46" cy="48" r="9" fill="#0a0b14" stroke="#3eb87a" strokeWidth="2"/>
        <path d="M42 48 L45 51 L50 45" stroke="#5fd49a" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
      </svg>
    </div>
  );
}

Object.assign(window, { PngIcon, AssetChest, AssetCrystal });
