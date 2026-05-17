// Bottom sheet — Ready / Forging / Detail states + animation overlay

const T2 = window.__T || {
  bg: '#0b0d1a', bgSheet: '#171a2e', bgSheetSoft: '#1d2138',
  text: '#fff', textDim: '#9aa0bf', textMuted: '#6b7193',
  accent: '#7b7afb', accentSoft: 'rgba(123,122,251,0.18)',
  ember: '#ff8c2a', emberBright: '#ffd166',
  btnLight: '#e9eaf5', btnLightText: '#0c0f1e',
};

const { useState: uS, useEffect: uE, useRef: uR } = React;

// ─── Sheet shell ─────────────────────────────────────────────
function Sheet({ children, height = 'auto', style }) {
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0,
      background: T2.bgSheet, borderTopLeftRadius: 28, borderTopRightRadius: 28,
      padding: '14px 22px 28px',
      boxShadow: '0 -20px 50px rgba(0,0,0,0.5)',
      height, ...style,
    }}>
      <div style={{
        width: 56, height: 5, borderRadius: 3, background: 'rgba(255,255,255,0.18)',
        margin: '0 auto 16px',
      }} />
      {children}
    </div>
  );
}

// ─── READY sheet ─────────────────────────────────────────────
function ReadySheet({ onClaim }) {
  return (
    <Sheet>
      <div style={{
        textAlign: 'center', color: T2.accent, fontSize: 12, fontWeight: 700, letterSpacing: 1.6,
      }}>PŘIPRAVEN</div>
      <div style={{
        textAlign: 'center', color: T2.text, fontSize: 30, fontWeight: 700, marginTop: 6,
      }}>Tajemný společník</div>
      <div style={{
        textAlign: 'center', color: T2.textDim, fontSize: 15, marginTop: 8, lineHeight: 1.5,
      }}>Spojí potřebné relikvie. Vyzvedni jej v detailu.</div>

      {/* relic preview row */}
      <div style={{
        position: 'relative', height: 200, marginTop: 24,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {/* breathing aura ring */}
        <div style={{
          position: 'absolute', width: 160, height: 160, borderRadius: '50%',
          border: '1px solid rgba(255,255,255,0.10)',
          background: 'radial-gradient(circle, rgba(123,122,251,0.10), transparent 70%)',
          animation: 'breathe 2.6s ease-in-out infinite',
        }} />
        <div style={{
          position: 'absolute', width: 110, height: 110, borderRadius: '50%',
          background: 'rgba(255,255,255,0.03)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="46" height="46" viewBox="0 0 24 24" fill="rgba(255,255,255,0.20)">
            <ellipse cx="6" cy="9" rx="1.8" ry="2.4"/><ellipse cx="10" cy="6" rx="1.8" ry="2.4"/>
            <ellipse cx="14" cy="6" rx="1.8" ry="2.4"/><ellipse cx="18" cy="9" rx="1.8" ry="2.4"/>
            <path d="M12 11c-3 0-5.5 2.5-5.5 5 0 1.7 1.3 3 3 3 1 0 1.7-.5 2.5-.5s1.5.5 2.5.5c1.7 0 3-1.3 3-3 0-2.5-2.5-5-5.5-5z"/>
          </svg>
        </div>
        {/* relics floating */}
        <img src="assets/campfire_spark.png" style={{
          position: 'absolute', width: 70, height: 70, objectFit: 'contain',
          left: 'calc(50% - 130px)', top: 'calc(50% - 30px)',
          animation: 'floatA 3.4s ease-in-out infinite',
          filter: 'drop-shadow(0 6px 16px rgba(255,140,42,0.35))',
        }} />
        <img src="assets/warm_kindling.png" style={{
          position: 'absolute', width: 84, height: 84, objectFit: 'contain',
          right: 'calc(50% - 140px)', top: 'calc(50% - 38px)',
          animation: 'floatB 3.4s ease-in-out infinite',
          filter: 'drop-shadow(0 6px 16px rgba(255,140,42,0.25))',
        }} />
      </div>

      {/* relic chips */}
      <div style={{
        display: 'flex', gap: 8, justifyContent: 'center', marginTop: 6,
      }}>
        <RelicChip name="Jiskra ohniště" img="assets/campfire_spark.png" />
        <RelicChip name="Teplé třísky" img="assets/warm_kindling.png" />
      </div>

      <button onClick={onClaim} style={{
        marginTop: 22, width: '100%', height: 60, borderRadius: 18, border: 0,
        background: T2.btnLight, color: T2.btnLightText,
        fontSize: 17, fontWeight: 700, cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12,
        fontFamily: 'inherit',
        boxShadow: '0 10px 30px rgba(123,122,251,0.18)',
      }}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill={T2.btnLightText}>
          <path d="M12 2l1.8 6.2L20 10l-6.2 1.8L12 18l-1.8-6.2L4 10l6.2-1.8L12 2z"/>
        </svg>
        Vyzvedni společníka
      </button>
    </Sheet>
  );
}

function RelicChip({ name, img }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8,
      padding: '6px 12px 6px 6px', borderRadius: 100,
      background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.06)',
    }}>
      <div style={{
        width: 28, height: 28, borderRadius: '50%', background: 'rgba(255,140,42,0.10)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}><img src={img} style={{ width: 22, height: 22, objectFit: 'contain' }} /></div>
      <span style={{ color: T2.text, fontSize: 13, fontWeight: 500 }}>{name}</span>
      <svg width="14" height="14" viewBox="0 0 24 24" fill={T2.accent} style={{ marginLeft: 2 }}>
        <path d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z"/>
      </svg>
    </div>
  );
}

// ─── DETAIL sheet (after reveal) ─────────────────────────────
function DetailSheet({ companion, onReset, hideCompanion = false }) {
  return (
    <Sheet>
      <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start' }}>
        <div style={{
          width: 130, height: 130, borderRadius: 20, flexShrink: 0,
          background: hideCompanion
            ? 'transparent'
            : 'radial-gradient(circle at 50% 60%, rgba(255,200,80,0.20), transparent 65%)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          transition: 'background 0.4s ease',
        }}>
          {!hideCompanion && (
            <img src="assets/ember_sprite.png" style={{
              width: 130, height: 130, objectFit: 'contain',
              animation: 'companionIdle 3.2s ease-in-out infinite',
              filter: 'drop-shadow(0 8px 24px rgba(255,140,42,0.45))',
            }} />
          )}
        </div>
        <div style={{ flex: 1, minWidth: 0, paddingTop: 6 }}>
          <div style={{ color: T2.text, fontSize: 26, fontWeight: 700 }}>{companion.name}</div>
          <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
            <Tag>Společník</Tag>
            <Tag>{companion.rarity}</Tag>
          </div>
          <div style={{ color: T2.textMuted, fontSize: 12, marginTop: 12, fontWeight: 500 }}>
            Odemčeno {new Date().toLocaleDateString('cs-CZ', { day: 'numeric', month: 'numeric' })}.
          </div>
        </div>
      </div>

      <div style={{ color: T2.textDim, fontSize: 15, marginTop: 18, lineHeight: 1.55 }}>
        {companion.desc}
      </div>

      <div style={{
        display: 'flex', alignItems: 'center', gap: 8, marginTop: 16,
        padding: '12px 14px', borderRadius: 14,
        background: 'rgba(123,122,251,0.08)', border: '1px solid rgba(123,122,251,0.18)',
      }}>
        <Sparkle size={14} color={T2.accent} />
        <span style={{ color: T2.text, fontSize: 13, fontWeight: 500 }}>
          {companion.perk}
        </span>
      </div>

      <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
        <button onClick={onReset} style={{
          flex: '0 0 56px', height: 56, borderRadius: 16, border: 0,
          background: 'rgba(255,255,255,0.06)', color: T2.text,
          display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
        }} title="Přehrát znovu">
          <svg width="22" height="22" viewBox="0 0 24 24" fill={T2.text}>
            <path d="M12 5V1L6 7l6 6V9c3.3 0 6 2.7 6 6s-2.7 6-6 6-6-2.7-6-6H4c0 4.4 3.6 8 8 8s8-3.6 8-8-3.6-8-8-8z"/>
          </svg>
        </button>
        <button style={{
          flex: '0 0 56px', height: 56, borderRadius: 16, border: 0,
          background: 'rgba(255,140,42,0.12)', color: T2.ember,
          display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
        }} title="Přivolat">
          <svg width="22" height="22" viewBox="0 0 24 24" fill={T2.ember}>
            <path d="M12 2c-1.5 4-5 6-5 10 0 3 2.5 5 5 5s5-2 5-5c0-4-3.5-6-5-10zm0 14c-1.4 0-2.5-1.1-2.5-2.5 0-1 .5-1.5 1.2-2.5.4.4 1 .7 1.3 1.5.6-1.5 2-2.5 2-4 .8 1 1.5 2 1.5 3.5 0 2.2-1.5 4-3.5 4z"/>
          </svg>
        </button>
        <button style={{
          flex: 1, height: 56, borderRadius: 16, border: 0,
          background: T2.btnLight, color: T2.btnLightText,
          fontSize: 16, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
        }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill={T2.btnLightText}>
            <path d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z"/>
          </svg>
          Vybavit
        </button>
      </div>
    </Sheet>
  );
}

function Tag({ children }) {
  return (
    <div style={{
      padding: '5px 12px', borderRadius: 100,
      background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.08)',
      color: T2.text, fontSize: 12, fontWeight: 500,
    }}>{children}</div>
  );
}

window.ReadySheet = ReadySheet;
window.DetailSheet = DetailSheet;
window.Sheet = Sheet;
