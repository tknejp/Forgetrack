/* global React */
// Variant 1 — Multi-step Quest. 4 fokusované kroky.
const { useState: useStateMS } = React;

function WelcomeMultiStep() {
  const [step, setStep] = useStateMS(0);
  const STEPS = ['Vítej', 'Účet', 'Zdraví', 'Hotovo'];

  return (
    <div style={{
      position: 'relative', height: '100%',
      background:
        'radial-gradient(ellipse 80% 50% at 50% 0%, rgba(139,92,246,0.20), transparent 60%),' +
        'radial-gradient(ellipse 60% 30% at 50% 100%, rgba(63,184,175,0.10), transparent 60%),' +
        '#0B0F1E',
      overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
      paddingTop: 54, // status bar
      fontFamily: 'Inter, sans-serif',
      color: '#F5F3FF',
    }}>
      {/* Progress dots + skip */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '14px 20px 8px',
      }}>
        <div style={{ display: 'flex', gap: 6 }}>
          {STEPS.map((_, i) => (
            <div key={i} style={{
              height: 4, borderRadius: 2,
              width: i === step ? 22 : 14,
              background: i <= step ? '#A78BFA' : 'rgba(167,139,250,0.18)',
              transition: 'all 0.3s',
            }} />
          ))}
        </div>
        {step < 3 && (
          <button
            onClick={() => setStep(3)}
            style={{
              background: 'transparent', border: 'none', cursor: 'pointer',
              fontSize: 13, color: 'rgba(245,243,255,0.45)', fontWeight: 500,
              fontFamily: 'Inter, sans-serif',
            }}
          >Přeskočit</button>
        )}
      </div>

      {/* Body */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '8px 20px 12px' }}>
        {step === 0 && <StepWelcome />}
        {step === 1 && <StepAccount />}
        {step === 2 && <StepHealth />}
        {step === 3 && <StepFinal />}
      </div>

      {/* Footer */}
      <div style={{ padding: '12px 20px 28px' }}>
        <div style={{ display: 'flex', gap: 10 }}>
          {step > 0 && (
            <button
              onClick={() => setStep(s => Math.max(0, s - 1))}
              style={{
                width: 56, height: 52, borderRadius: 16,
                border: '1px solid rgba(167,139,250,0.22)',
                background: 'rgba(28,30,56,0.45)',
                color: '#C7C2E0', cursor: 'pointer',
                display: 'grid', placeItems: 'center',
              }}
            >
              <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
                <path d="M9 2L4 7l5 5" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
              </svg>
            </button>
          )}
          <PrimaryBtn
            label={
              step === 0 ? 'Začít cestu' :
              step === 1 ? 'Pokračovat' :
              step === 2 ? 'Pokračovat' :
              'Vstoupit do hry'
            }
            onClick={() => step < 3 ? setStep(s => s + 1) : null}
            arrow={step < 3}
            wand={step === 3}
          />
        </div>
      </div>
    </div>
  );
}

// ── Step 1: Welcome with hero card preview ───────────────────────────
function StepWelcome() {
  return (
    <div style={{ paddingTop: 8 }}>
      {/* Sigil / character */}
      <div style={{
        margin: '8px auto 18px', width: 124, height: 124, position: 'relative',
      }}>
        <div style={{
          position: 'absolute', inset: 0, borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(139,92,246,0.5) 0%, transparent 70%)',
          filter: 'blur(8px)',
        }}/>
        <div style={{
          position: 'absolute', inset: 12, borderRadius: '50%',
          background: 'linear-gradient(135deg, #1A1838 0%, #0F1226 100%)',
          border: '1px solid rgba(167,139,250,0.35)',
          display: 'grid', placeItems: 'center',
          boxShadow: '0 12px 32px -8px rgba(139,92,246,0.55), inset 0 0 30px rgba(139,92,246,0.15)',
        }}>
          {/* Crystal sigil */}
          <svg width="56" height="64" viewBox="0 0 56 64" fill="none">
            <defs>
              <linearGradient id="cgrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#C4B5FD"/>
                <stop offset="100%" stopColor="#7C3AED"/>
              </linearGradient>
            </defs>
            <path d="M28 4L52 22 42 56H14L4 22z" fill="url(#cgrad)" stroke="#EDE9FE" strokeWidth="1.5" strokeLinejoin="round"/>
            <path d="M28 4L42 56M28 4L14 56M4 22L52 22M28 4L52 22 28 28 4 22z" stroke="#1A1838" strokeWidth="1" strokeLinejoin="round" opacity="0.4"/>
          </svg>
        </div>
        {/* Sparks */}
        {[
          { x: 0, y: 20, s: 0.7, d: 0 },
          { x: 100, y: 10, s: 0.9, d: 0.6 },
          { x: 95, y: 80, s: 0.6, d: 1.2 },
          { x: 5, y: 90, s: 0.8, d: 0.3 },
        ].map((s, i) => (
          <div key={i} style={{
            position: 'absolute', left: `${s.x}%`, top: `${s.y}%`,
            animation: `wm-spark 2.4s ease-in-out ${s.d}s infinite`,
          }}>
            <svg width={10*s.s} height={10*s.s} viewBox="0 0 10 10">
              <path d="M5 0L5.8 4.2 10 5 5.8 5.8 5 10 4.2 5.8 0 5 4.2 4.2 5 0z" fill="#F4C152"/>
            </svg>
          </div>
        ))}
      </div>

      <div style={{
        fontSize: 28, fontWeight: 800, letterSpacing: '-0.03em', textAlign: 'center',
        lineHeight: 1.15, marginBottom: 6,
      }}>Vítej, hrdino.</div>
      <div style={{
        fontSize: 15, color: 'rgba(245,243,255,0.55)', textAlign: 'center',
        lineHeight: 1.45, padding: '0 8px',
      }}>
        Forgetrack udělá ze tvého zdraví <span style={{ color: '#A78BFA', fontWeight: 600 }}>cestu plnou questů</span> — kroky, spánek a jídlo se mění v XP, levely a tituly.
      </div>

      {/* Mini hero preview card */}
      <div style={{
        marginTop: 22,
        padding: 14,
        borderRadius: 18,
        background: 'linear-gradient(135deg, rgba(40,38,76,0.55) 0%, rgba(22,22,46,0.85) 100%)',
        border: '1px solid rgba(148,130,220,0.22)',
      }}>
        <div style={{ fontSize: 10, fontWeight: 800, letterSpacing: '0.14em', color: '#A78BFA' }}>✦ TVŮJ START</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 10 }}>
          <div style={{
            width: 44, height: 44, borderRadius: 12,
            background: 'linear-gradient(135deg, #8B5CF6, #7C3AED)',
            display: 'grid', placeItems: 'center',
            fontWeight: 800, fontSize: 16, color: '#fff',
            boxShadow: '0 4px 14px -2px rgba(139,92,246,0.55)',
          }}>1</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: '#F4C152', letterSpacing: '0.06em' }}>NOVÁČEK</div>
            <div style={{ fontSize: 13, color: 'rgba(245,243,255,0.6)', marginTop: 2 }}>0 / 500 XP do dalšího levelu</div>
          </div>
          <div style={{
            padding: '4px 10px', borderRadius: 999,
            background: 'rgba(244,193,82,0.15)',
            border: '1px solid rgba(244,193,82,0.35)',
            fontSize: 10, fontWeight: 800, color: '#F4C152', letterSpacing: '0.06em',
          }}>+50 XP</div>
        </div>
      </div>

      <style>{`
        @keyframes wm-spark {
          0%,100% { opacity: 0; transform: scale(0.4); }
          50% { opacity: 1; transform: scale(1); }
        }
      `}</style>
    </div>
  );
}

// ── Step 2: Account ──────────────────────────────────────────────────
function StepAccount() {
  return (
    <div style={{ paddingTop: 12 }}>
      <StepIcon emoji="🛡️" tint="#A78BFA" />
      <StepHeading
        title="Ulož si svůj postup"
        subtitle="Přihlas se přes Google a tvé levely, série a achievementy zůstanou bezpečně v cloudu — i když přejdeš na nový telefon."
      />

      {/* Google sign-in */}
      <button style={{
        width: '100%', marginTop: 22,
        padding: '16px 16px',
        borderRadius: 16,
        background: '#FFFFFF', border: 'none',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12,
        cursor: 'pointer',
        fontFamily: 'Inter, sans-serif',
        fontSize: 15, fontWeight: 600, color: '#1F1F1F',
        boxShadow: '0 4px 18px rgba(0,0,0,0.25)',
      }}>
        <GoogleG />
        Přihlásit se přes Google
      </button>

      {/* Bullet list */}
      <div style={{
        marginTop: 18, padding: '12px 14px',
        borderRadius: 14,
        background: 'rgba(167,139,250,0.06)',
        border: '1px solid rgba(167,139,250,0.16)',
      }}>
        {[
          'Synchronizace mezi tvými zařízeními',
          'Zálohovaný postup a achievementy',
          'Funguje i offline',
        ].map((t, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '6px 0',
          }}>
            <div style={{
              width: 18, height: 18, borderRadius: '50%',
              background: 'rgba(52,211,153,0.18)',
              border: '1px solid rgba(52,211,153,0.35)',
              display: 'grid', placeItems: 'center',
              flexShrink: 0,
            }}>
              <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
                <path d="M2 5l2 2 4-4" stroke="#34D399" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </div>
            <div style={{ fontSize: 13, color: 'rgba(245,243,255,0.75)' }}>{t}</div>
          </div>
        ))}
      </div>

      <div style={{
        marginTop: 14, textAlign: 'center',
        fontSize: 12, color: 'rgba(245,243,255,0.4)',
      }}>
        Nemusíš se rozhodovat hned — funguje to i bez účtu.
      </div>
    </div>
  );
}

// ── Step 3: Health connect ───────────────────────────────────────────
function StepHealth() {
  return (
    <div style={{ paddingTop: 12 }}>
      <StepIcon emoji="❤️" tint="#3FB8AF" />
      <StepHeading
        title="Připoj svoje data"
        subtitle="Forgetrack čte z Health Connectu kroky, spánek a aktivitu — a proměňuje je v XP. Tvoje záznamy z toho ven nejdou; jen se z nich čte."
      />

      {/* Data icons row */}
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8,
        marginTop: 22,
      }}>
        {[
          { i: '👣', l: 'Kroky', c: '#34D399' },
          { i: '🔥', l: 'Kalorie', c: '#FBBF24' },
          { i: '😴', l: 'Spánek', c: '#A89BFF' },
          { i: '⚔️', l: 'Aktivita', c: '#2DD4BF' },
        ].map((d, i) => (
          <div key={i} style={{
            padding: '10px 6px',
            borderRadius: 14,
            background: 'rgba(28,30,56,0.45)',
            border: `1px solid ${d.c}33`,
            textAlign: 'center',
          }}>
            <div style={{ fontSize: 22, lineHeight: 1, marginBottom: 4 }}>{d.i}</div>
            <div style={{ fontSize: 10, fontWeight: 600, color: 'rgba(245,243,255,0.7)' }}>{d.l}</div>
          </div>
        ))}
      </div>

      <button style={{
        marginTop: 18,
        width: '100%', padding: '14px 16px',
        borderRadius: 16,
        background: 'linear-gradient(180deg, rgba(63,184,175,0.30), rgba(63,184,175,0.45))',
        border: '1px solid rgba(63,184,175,0.55)',
        color: '#fff', fontWeight: 700, fontSize: 14,
        fontFamily: 'Inter, sans-serif', cursor: 'pointer',
        boxShadow: '0 8px 22px -6px rgba(63,184,175,0.45)',
      }}>
        Povolit Health Connect
      </button>

      {/* Privacy note */}
      <div style={{
        marginTop: 12,
        display: 'flex', alignItems: 'flex-start', gap: 8,
        padding: '10px 12px', borderRadius: 12,
        background: 'rgba(167,139,250,0.05)',
        border: '1px solid rgba(167,139,250,0.10)',
      }}>
        <svg width="14" height="14" viewBox="0 0 14 14" style={{ flexShrink: 0, marginTop: 1 }} fill="none">
          <path d="M7 1L2 3v4c0 3 2.5 5.5 5 6 2.5-0.5 5-3 5-6V3L7 1z" stroke="#A78BFA" strokeWidth="1.4" strokeLinejoin="round"/>
        </svg>
        <div style={{ fontSize: 11, color: 'rgba(245,243,255,0.5)', lineHeight: 1.45 }}>
          Tvá data zůstávají v Health Connectu — Forgetrack je nikdy nekopíruje ani neupravuje.
        </div>
      </div>
    </div>
  );
}

// ── Step 4: Final touches ───────────────────────────────────────────
function StepFinal() {
  const [kt, setKt] = useStateMS(false);
  const [ktEmail, setKtEmail] = useStateMS('');
  const [notif, setNotif] = useStateMS(true);
  const [sheet, setSheet] = useStateMS(null); // 'kt' | null

  return (
    <div style={{ paddingTop: 8 }}>
      <StepIcon emoji="🎯" tint="#F4C152" />
      <StepHeading
        title="Poslední doladění"
        subtitle="Volitelné — všechno můžeš nastavit i později v aplikaci."
      />

      <ToggleRow
        active={kt}
        onClick={() => kt ? setKt(false) : setSheet('kt')}
        title="Kalorické Tabulky"
        subtitle={kt ? (ktEmail || 'Připojeno') : 'Importovat výživu a váhu z KT deníku'}
        icon={<img src="assets/kt-logo.png" alt="KT" style={{ width:'100%', height:'100%', borderRadius:10, objectFit:'cover' }}/>}
        tint="#7BA42B"
      />
      <ToggleRow
        active={notif}
        onClick={() => setNotif(v => !v)}
        title="Notifikace"
        subtitle="Připomenutí questů a oznámení o odměnách"
        icon="🔔"
        tint="#A78BFA"
      />

      {/* Summary card */}
      <div style={{
        marginTop: 18,
        padding: 14,
        borderRadius: 16,
        background: 'linear-gradient(135deg, rgba(244,193,82,0.12), rgba(167,139,250,0.10))',
        border: '1px solid rgba(244,193,82,0.25)',
      }}>
        <div style={{
          fontSize: 10, fontWeight: 800, letterSpacing: '0.14em', color: '#F4C152',
        }}>✦ PRVNÍ QUESTY</div>
        <div style={{ marginTop: 8 }}>
          {[
            { t: 'Ujít 10 000 kroků', x: '+50 XP' },
            { t: 'Spát 7 hodin', x: '+30 XP' },
            { t: 'Otevřít aplikaci 3 dny v řadě', x: '+100 XP' },
          ].map((q, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '7px 0',
              borderBottom: i < 2 ? '1px solid rgba(255,255,255,0.06)' : 'none',
            }}>
              <div style={{
                width: 6, height: 6, borderRadius: '50%',
                background: '#F4C152', boxShadow: '0 0 8px #F4C152',
                flexShrink: 0,
              }}/>
              <div style={{ flex: 1, fontSize: 13, color: 'rgba(245,243,255,0.85)' }}>{q.t}</div>
              <div style={{
                fontSize: 10, fontWeight: 800, color: '#F4C152',
                padding: '2px 7px', borderRadius: 999,
                background: 'rgba(244,193,82,0.12)',
                border: '1px solid rgba(244,193,82,0.30)',
              }}>{q.x}</div>
            </div>
          ))}
        </div>
      </div>

      {sheet === 'kt' && (
        <KTLoginSheet
          onClose={() => setSheet(null)}
          onConnect={(email) => { setKt(true); setKtEmail(email); setSheet(null); }}
        />
      )}
    </div>
  );
}

// ── KT Login bottom sheet ────────────────────────────────────────────
function KTLoginSheet({ onClose, onConnect }) {
  const [email, setEmail] = useStateMS('');
  const [pwd, setPwd] = useStateMS('');
  const [showPwd, setShowPwd] = useStateMS(false);
  const ready = email.includes('@') && pwd.length >= 4;

  return (
    <div
      onClick={onClose}
      style={{
        position: 'absolute', inset: 0, zIndex: 100,
        background: 'rgba(0,0,0,0.55)',
        display: 'flex', alignItems: 'flex-end',
        animation: 'kt-fade 0.18s ease-out',
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          width: '100%',
          background: 'linear-gradient(180deg, #1A1838 0%, #0F1226 100%)',
          borderRadius: '24px 24px 0 0',
          padding: '14px 20px 28px',
          borderTop: '1px solid rgba(167,139,250,0.25)',
          animation: 'kt-rise 0.22s cubic-bezier(.2,.7,.3,1)',
        }}
      >
        <div style={{
          width: 38, height: 4, borderRadius: 2,
          background: 'rgba(255,255,255,0.18)', margin: '0 auto 14px',
        }}/>

        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
          <div style={{ width: 44, height: 44, borderRadius: 12, overflow: 'hidden', flexShrink: 0 }}>
            <img src="assets/kt-logo.png" alt="Kalorické Tabulky" style={{ width:'100%', height:'100%', objectFit:'cover', display:'block' }}/>
          </div>
          <div>
            <div style={{ fontSize: 16, fontWeight: 800, color: '#F5F3FF' }}>Kalorické Tabulky</div>
            <div style={{ fontSize: 11, color: 'rgba(245,243,255,0.5)' }}>Přihlas se ke svému KT účtu</div>
          </div>
        </div>

        <KTField
          placeholder="E-mail KT"
          type="email"
          value={email}
          onChange={setEmail}
        />
        <div style={{ height: 8 }}/>
        <KTField
          placeholder="Heslo"
          type={showPwd ? 'text' : 'password'}
          value={pwd}
          onChange={setPwd}
          trailing={(
            <button
              type="button"
              onClick={() => setShowPwd(v => !v)}
              style={{
                background: 'transparent', border: 'none', cursor: 'pointer',
                color: 'rgba(245,243,255,0.45)', padding: 4,
                display: 'grid', placeItems: 'center',
              }}
            >
              {showPwd ? (
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <path d="M2 8s2.5-4.5 6-4.5S14 8 14 8s-2.5 4.5-6 4.5S2 8 2 8z" stroke="currentColor" strokeWidth="1.4"/>
                  <circle cx="8" cy="8" r="2" stroke="currentColor" strokeWidth="1.4"/>
                </svg>
              ) : (
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <path d="M2 8s2.5-4.5 6-4.5S14 8 14 8s-2.5 4.5-6 4.5S2 8 2 8z" stroke="currentColor" strokeWidth="1.4"/>
                  <path d="M2.5 2.5l11 11" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round"/>
                </svg>
              )}
            </button>
          )}
        />

        <button
          disabled={!ready}
          onClick={() => ready && onConnect(email)}
          style={{
            marginTop: 14, width: '100%', height: 50, borderRadius: 14,
            background: ready
              ? 'linear-gradient(180deg, #8FBE3D 0%, #6E9527 100%)'
              : 'rgba(123,164,43,0.25)',
            border: 'none',
            color: ready ? '#fff' : 'rgba(255,255,255,0.5)',
            fontFamily: 'Inter, sans-serif', fontSize: 15, fontWeight: 700,
            cursor: ready ? 'pointer' : 'not-allowed',
            boxShadow: ready ? '0 8px 24px -6px rgba(123,164,43,0.55)' : 'none',
            transition: 'all 0.15s',
          }}
        >
          Přihlásit a propojit
        </button>

        <div style={{
          marginTop: 10, textAlign: 'center',
          fontSize: 11, color: 'rgba(245,243,255,0.4)',
        }}>
          Forgetrack používá tvé přihlášení jen ke čtení deníku z KT.
        </div>
      </div>

      <style>{`
        @keyframes kt-fade { from { opacity: 0; } to { opacity: 1; } }
        @keyframes kt-rise { from { transform: translateY(20px); opacity: 0.6; } to { transform: translateY(0); opacity: 1; } }
      `}</style>
    </div>
  );
}

function KTField({ placeholder, type='text', value, onChange, trailing }) {
  const [focus, setFocus] = useStateMS(false);
  return (
    <div style={{
      padding: '4px 12px',
      borderRadius: 12,
      background: 'rgba(11,15,30,0.6)',
      border: `1px solid ${focus ? 'rgba(143,190,61,0.55)' : 'rgba(167,139,250,0.18)'}`,
      display: 'flex', alignItems: 'center',
      transition: 'border-color 0.15s',
    }}>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        onFocus={() => setFocus(true)}
        onBlur={() => setFocus(false)}
        placeholder={placeholder}
        style={{
          flex: 1, height: 38,
          background: 'transparent', border: 'none', outline: 'none',
          color: '#F5F3FF', fontSize: 14,
          fontFamily: 'Inter, sans-serif',
        }}
      />
      {trailing}
    </div>
  );
}

// ── Shared sub-components ────────────────────────────────────────────
function StepIcon({ emoji, tint }) {
  return (
    <div style={{
      margin: '0 auto', width: 72, height: 72, borderRadius: 22,
      background: `linear-gradient(135deg, ${tint}33, ${tint}11)`,
      border: `1px solid ${tint}44`,
      display: 'grid', placeItems: 'center',
      fontSize: 32, lineHeight: 1,
      boxShadow: `0 8px 24px -8px ${tint}66`,
    }}>{emoji}</div>
  );
}

function StepHeading({ title, subtitle }) {
  return (
    <>
      <div style={{
        marginTop: 18, fontSize: 24, fontWeight: 800, letterSpacing: '-0.02em',
        textAlign: 'center', lineHeight: 1.2,
      }}>{title}</div>
      <div style={{
        marginTop: 8, fontSize: 14, color: 'rgba(245,243,255,0.55)',
        textAlign: 'center', lineHeight: 1.5, padding: '0 4px',
      }}>{subtitle}</div>
    </>
  );
}

function ToggleRow({ active, onClick, title, subtitle, icon, tint }) {
  return (
    <button
      onClick={onClick}
      style={{
        marginTop: 12, width: '100%',
        padding: '14px 14px',
        borderRadius: 16,
        background: active
          ? `linear-gradient(135deg, ${tint}22, ${tint}0d)`
          : 'rgba(28,30,56,0.45)',
        border: `1px solid ${active ? tint+'66' : 'rgba(148,130,220,0.18)'}`,
        display: 'flex', alignItems: 'center', gap: 12,
        cursor: 'pointer', textAlign: 'left',
        transition: 'all 0.2s',
        fontFamily: 'Inter, sans-serif',
      }}
    >
      <div style={{
        width: 38, height: 38, borderRadius: 12,
        background: active ? `${tint}22` : 'rgba(255,255,255,0.04)',
        border: `1px solid ${active ? tint+'55' : 'rgba(255,255,255,0.06)'}`,
        display: 'grid', placeItems: 'center', fontSize: 18,
        flexShrink: 0,
      }}>{icon}</div>
      <div style={{ flex: 1 }}>
        <div style={{
          fontSize: 14, fontWeight: 700, color: '#F5F3FF', letterSpacing: '-0.01em',
        }}>{title}</div>
        <div style={{
          fontSize: 11, color: 'rgba(245,243,255,0.5)', marginTop: 1,
        }}>{subtitle}</div>
      </div>
      {/* iOS-style toggle */}
      <div style={{
        width: 42, height: 24, borderRadius: 999,
        background: active ? tint : 'rgba(255,255,255,0.10)',
        position: 'relative', transition: 'all 0.2s',
        boxShadow: active ? `0 0 12px ${tint}66` : 'none',
        flexShrink: 0,
      }}>
        <div style={{
          position: 'absolute', top: 2, left: active ? 20 : 2,
          width: 20, height: 20, borderRadius: '50%',
          background: '#fff', transition: 'left 0.2s',
          boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
        }}/>
      </div>
    </button>
  );
}

function PrimaryBtn({ label, onClick, arrow, wand }) {
  return (
    <button
      onClick={onClick}
      style={{
        flex: 1, height: 52, borderRadius: 16,
        background: 'linear-gradient(180deg, #8B5CF6 0%, #7C3AED 100%)',
        border: 'none', color: '#fff',
        fontFamily: 'Inter, sans-serif', fontSize: 15, fontWeight: 700,
        cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        boxShadow: '0 8px 24px -6px rgba(139,92,246,0.65), inset 0 1px 0 rgba(255,255,255,0.18)',
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

function GoogleG() {
  return (
    <svg width="20" height="20" viewBox="0 0 20 20">
      <path d="M19.6 10.2c0-.7-.1-1.4-.2-2H10v3.8h5.4c-.2 1.2-.9 2.3-2 3v2.5h3.2c1.9-1.7 3-4.3 3-7.3z" fill="#4285F4"/>
      <path d="M10 20c2.7 0 5-1 6.6-2.5l-3.2-2.5c-.9.6-2 1-3.4 1-2.6 0-4.8-1.7-5.6-4.1H1.1V14c1.7 3.5 5.2 6 8.9 6z" fill="#34A853"/>
      <path d="M4.4 11.9c-.2-.6-.3-1.3-.3-1.9s.1-1.3.3-1.9V5.5H1.1C.4 6.9 0 8.4 0 10s.4 3.1 1.1 4.5l3.3-2.6z" fill="#FBBC05"/>
      <path d="M10 4c1.5 0 2.8.5 3.8 1.5L16.7 2.7C15 1 12.7 0 10 0 6.3 0 2.8 2.5 1.1 6l3.3 2.5C5.2 6.1 7.4 4 10 4z" fill="#EA4335"/>
    </svg>
  );
}

window.WelcomeMultiStep = WelcomeMultiStep;
