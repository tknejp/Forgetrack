// Forgetrack — Companion claim flow
// State machine: ready → forging → revealing → detail → ready (replay)

const { useState, useEffect, useRef, useMemo } = React;

// ─── Visual tokens (matches screenshots) ─────────────────────────
const T = {
  bg: '#0b0d1a',
  bgSheet: '#171a2e',
  bgSheetSoft: '#1d2138',
  card: '#1a1e34',
  cardLocked: '#23273d',
  cardBorder: 'rgba(255,255,255,0.06)',
  cardRedBorder: 'rgba(229,76,76,0.55)',
  cardRedBg: 'rgba(229,76,76,0.08)',
  cardGreenBorder: 'rgba(76,175,109,0.55)',
  cardGreenBg: 'rgba(76,175,109,0.08)',
  text: '#ffffff',
  textDim: '#9aa0bf',
  textMuted: '#6b7193',
  accent: '#7b7afb',
  accentSoft: 'rgba(123,122,251,0.18)',
  ember: '#ff8c2a',
  emberBright: '#ffd166',
  red: '#e54c4c',
  green: '#4caf6d',
  btnLight: '#e9eaf5',
  btnLightText: '#0c0f1e',
};

// ─── Static background screen (kosmetika) ────────────────────────
function KosmetikaBg({ revealed }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, background: T.bg, color: T.text,
      fontFamily: 'Inter, system-ui, sans-serif', overflow: 'hidden',
      padding: '14px 18px 0',
    }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, paddingTop: 6 }}>
        <div style={{
          width: 40, height: 40, borderRadius: 12, background: 'rgba(255,255,255,0.04)',
          border: '1px solid rgba(255,255,255,0.06)', display: 'flex',
          alignItems: 'center', justifyContent: 'center', fontSize: 18,
        }}>←</div>
        <div style={{ fontSize: 26, fontWeight: 700 }}>Kosmetika</div>
      </div>

      {/* Vybaveno */}
      <SectionLabel>VYBAVENO</SectionLabel>
      <div style={{ fontSize: 13, color: T.textDim, marginTop: 2 }}>Aktuální vzhled profilu a cesty</div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 10, marginTop: 14 }}>
        <EquipCard tone="red" label="Vyvojarsky ramecek" glyph="frame" />
        <EquipCard tone="green" label="Lesní stezka" glyph="path" />
        <EquipCard tone="red" label="Monster Energy" glyph="monster" />
      </div>

      {/* Inventář */}
      <SectionLabel style={{ marginTop: 26 }}>INVENTÁŘ</SectionLabel>
      <TabBar />

      {/* Inventory grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 10, marginTop: 12 }}>
        <EquipCard tone="red" label="Monster Energy" glyph="monster" small />
        <LockedSlot revealed={revealed} />
        <div /> {/* third cell empty */}
      </div>
    </div>
  );
}

function SectionLabel({ children, style }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8, marginTop: 18,
      color: T.accent, fontSize: 12, fontWeight: 700, letterSpacing: 1.4,
      ...style,
    }}>
      <Sparkle size={14} /> {children}
    </div>
  );
}

function Sparkle({ size = 14, color = T.accent }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <path d="M12 2l1.8 6.2L20 10l-6.2 1.8L12 18l-1.8-6.2L4 10l6.2-1.8L12 2z" fill={color} />
      <circle cx="19" cy="5" r="1.4" fill={color} />
      <circle cx="5" cy="19" r="1.1" fill={color} />
    </svg>
  );
}

function EquipCard({ tone, label, glyph, small }) {
  const palette = tone === 'green'
    ? { border: T.cardGreenBorder, bg: T.cardGreenBg, label: T.green, check: T.green }
    : { border: T.cardRedBorder, bg: T.cardRedBg, label: T.red, check: T.red };
  return (
    <div style={{
      position: 'relative', borderRadius: 18,
      border: `1px solid ${palette.border}`, background: palette.bg,
      padding: '14px 10px 10px', minHeight: small ? 132 : 168,
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'space-between',
    }}>
      <div style={{
        position: 'absolute', top: 8, right: 8, width: 22, height: 22, borderRadius: '50%',
        background: palette.check, display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 12, color: '#fff', fontWeight: 700,
      }}>✓</div>
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Glyph kind={glyph} />
      </div>
      <div style={{ color: palette.label, fontSize: 11, fontWeight: 600, textAlign: 'center', lineHeight: 1.3 }}>{label}</div>
    </div>
  );
}

function Glyph({ kind }) {
  if (kind === 'frame') return (
    <div style={{
      width: 72, height: 72, border: '3px solid #c8a02a', borderRadius: 6, position: 'relative',
      background: 'rgba(0,0,0,0.2)', boxShadow: 'inset 0 0 0 2px #6e530c',
    }}>
      <div style={{ position: 'absolute', bottom: -6, left: -6, width: 14, height: 14, background: '#e5b842', borderRadius: '50%' }} />
    </div>
  );
  if (kind === 'path') return (
    <div style={{
      width: 80, height: 64, borderRadius: 4,
      background: 'linear-gradient(180deg,#1a2f1c 0%,#2d4a30 50%,#1a2719 100%)',
      boxShadow: 'inset 0 0 12px rgba(0,0,0,0.4)',
    }} />
  );
  if (kind === 'monster') return (
    <div style={{
      width: 52, height: 64, background: '#d6d3cc', borderRadius: 4, position: 'relative',
      boxShadow: '0 2px 4px rgba(0,0,0,0.3)',
    }}>
      <div style={{
        position: 'absolute', inset: '20% 10%', background: '#1a1a1a',
        fontSize: 9, color: '#fff', textAlign: 'center', fontWeight: 800,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>MONSTER</div>
    </div>
  );
  return null;
}

function TabBar() {
  const items = [
    { i: <Grid />, l: 'Vše' },
    { i: <Square />, l: 'Rámeček' },
    { i: <Mountain />, l: 'Pozadí' },
    { i: <Paw />, l: 'Společník', active: true },
  ];
  return (
    <div style={{
      marginTop: 12, padding: 6, background: 'rgba(255,255,255,0.03)',
      border: '1px solid rgba(255,255,255,0.05)', borderRadius: 24,
      display: 'flex', gap: 4,
    }}>
      {items.map((it, idx) => (
        <div key={idx} style={{
          flex: 1, padding: '8px 4px', borderRadius: 20,
          background: it.active ? T.accentSoft : 'transparent',
          color: it.active ? T.accent : T.textDim,
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
          fontSize: 12, fontWeight: 500,
        }}>{it.i}<span>{it.l}</span></div>
      ))}
    </div>
  );
}

const Grid = () => <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><circle cx="6" cy="6" r="1.6"/><circle cx="12" cy="6" r="1.6"/><circle cx="18" cy="6" r="1.6"/><circle cx="6" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="18" cy="12" r="1.6"/><circle cx="6" cy="18" r="1.6"/><circle cx="12" cy="18" r="1.6"/><circle cx="18" cy="18" r="1.6"/></svg>;
const Square = () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="5" y="5" width="14" height="14" rx="2"/></svg>;
const Mountain = () => <svg width="20" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M3 19l5-8 4 5 3-4 6 7H3z"/></svg>;
const Paw = () => <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><ellipse cx="6" cy="9" rx="1.8" ry="2.4"/><ellipse cx="10" cy="6" rx="1.8" ry="2.4"/><ellipse cx="14" cy="6" rx="1.8" ry="2.4"/><ellipse cx="18" cy="9" rx="1.8" ry="2.4"/><path d="M12 11c-3 0-5.5 2.5-5.5 5 0 1.7 1.3 3 3 3 1 0 1.7-.5 2.5-.5s1.5.5 2.5.5c1.7 0 3-1.3 3-3 0-2.5-2.5-5-5.5-5z"/></svg>;

// The locked card in inventory — animates state
function LockedSlot({ revealed }) {
  return (
    <div style={{
      position: 'relative', borderRadius: 18,
      border: `1px solid ${revealed ? T.cardBorder : 'rgba(255,255,255,0.10)'}`,
      background: revealed ? '#1d2138' : T.cardLocked,
      minHeight: 132, padding: '14px 10px 10px',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'space-between',
      transition: 'all .4s ease',
    }}>
      {!revealed && (
        <div style={{
          position: 'absolute', top: 8, right: 8, width: 22, height: 22, borderRadius: 6,
          background: 'rgba(255,255,255,0.04)', display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>🔒</div>
      )}
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        {revealed
          ? <img src="assets/ember_sprite.png" style={{ width: 70, height: 70, objectFit: 'contain' }} />
          : <div style={{ opacity: 0.4 }}><Paw /></div>}
      </div>
      <div style={{
        color: revealed ? T.text : T.textMuted,
        fontSize: 11, fontWeight: 600, textAlign: 'center',
      }}>{revealed ? 'Jiskřička' : 'Tajemný společník'}</div>
    </div>
  );
}

window.KosmetikaBg = KosmetikaBg;
