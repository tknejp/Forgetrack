/* global React */
// Variant A — Dedicated avatar-picker step.
// Onboarding becomes 5 steps: Welcome → AVATAR → Account → Health → Final.
// This file renders only the avatar step (positioned as step 1 of 5).

const { useState: useStateAV } = React;

function AvatarStep() {
  const [pickedId, setPickedId] = useStateAV('pixel');
  const [uploaded, setUploaded] = useStateAV(null);

  const onUpload = () => {
    // Simulate uploaded photo by toggling between a placeholder data URL state.
    if (uploaded) setUploaded(null);
    else setUploaded('uploaded'); // sentinel — we draw a fake portrait in UploadTile
  };

  const picked = window.avatarById(pickedId);

  return (
    <window.OnboardingShell
      step={1}
      total={5}
      footer={
        <div style={{ display: 'flex', gap: 10 }}>
          <window.APBackBtn />
          <window.APPrimaryBtn label="Pokračovat" />
        </div>
      }
    >
      {/* Big preview avatar */}
      <div style={{
        margin: '8px auto 14px',
        width: 132, height: 132, position: 'relative',
        display: 'grid', placeItems: 'center',
      }}>
        <div style={{
          position: 'absolute', inset: -8, borderRadius: '50%',
          background: `radial-gradient(circle, ${picked.kind === 'mono' ? picked.hue : '#A78BFA'}55 0%, transparent 70%)`,
          filter: 'blur(14px)',
        }}/>
        <div style={{ position: 'relative' }}>
          <window.AvatarBadge id={pickedId} size="xl" ring={false} />
        </div>
        {/* level badge overlay */}
        <div style={{
          position: 'absolute', right: -2, bottom: -2,
          padding: '4px 10px', borderRadius: 999,
          background: 'linear-gradient(180deg, #1B1B3C, #0F1226)',
          border: '1px solid rgba(244,193,82,0.45)',
          fontSize: 10, fontWeight: 800, color: '#F4C152', letterSpacing: '0.06em',
          boxShadow: '0 6px 14px -4px rgba(0,0,0,0.6)',
        }}>LVL 1</div>
      </div>

      <div style={{
        fontSize: 24, fontWeight: 800, letterSpacing: '-0.02em',
        textAlign: 'center', lineHeight: 1.2,
      }}>Vyber si tvář</div>
      <div style={{
        marginTop: 6, fontSize: 14, color: 'rgba(245,243,255,0.55)',
        textAlign: 'center', lineHeight: 1.45, padding: '0 8px',
      }}>
        Takhle tě uvidí ostatní hráči v žebříčku. <span style={{ color: '#A78BFA' }}>Nemůžeš se rozhodnout?</span> Změníš to kdykoliv v profilu.
      </div>

      {/* Grid */}
      <div style={{ marginTop: 18 }}>
        <window.AvatarGrid
          selectedId={pickedId}
          onPick={setPickedId}
          onUpload={onUpload}
          uploadedUrl={uploaded ? 'assets/forest_fox.png' : null /* fake */}
          cols={4}
          tileSize={62}
          gap={12}
        />
      </div>

      {/* Class tag (derived from selection) */}
      <div style={{
        marginTop: 16,
        padding: '10px 14px',
        borderRadius: 14,
        background: 'rgba(167,139,250,0.08)',
        border: '1px solid rgba(167,139,250,0.22)',
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <div style={{
          width: 6, height: 6, borderRadius: '50%',
          background: '#A78BFA', boxShadow: '0 0 8px #A78BFA',
        }}/>
        <div style={{ flex: 1, fontSize: 12, color: 'rgba(245,243,255,0.7)' }}>
          Vybráno: <span style={{ color: '#F5F3FF', fontWeight: 700 }}>{picked.label}</span>
        </div>
      </div>
    </window.OnboardingShell>
  );
}

window.AvatarStep = AvatarStep;
