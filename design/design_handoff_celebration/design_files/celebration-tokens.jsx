// celebration-tokens.jsx — Rarity + reward-type token system

// RARITY drives the AURA, GLOW, PARTICLES, ACCENT NAME.
// 6 tiers — calibrated against existing Forgetrack accents.
const RARITY = {
  common: {
    label: 'OBVYKLÉ',
    color: '#9CA3AF',                       // cool silver
    color2: '#D1D5DB',
    glow: 'rgba(156,163,175,0.45)',
    aura: 'rgba(156,163,175,0.32)',
    rim: 'rgba(209,213,219,0.55)',
    particle: ['#D1D5DB', '#9CA3AF', '#E5E7EB'],
    rays: 0.10,
  },
  uncommon: {
    label: 'NEOBVYKLÉ',
    color: '#3FB8AF',                       // teal (matches existing screen)
    color2: '#6FE3D8',
    glow: 'rgba(63,184,175,0.55)',
    aura: 'rgba(63,184,175,0.36)',
    rim: 'rgba(111,227,216,0.65)',
    particle: ['#6FE3D8', '#3FB8AF', '#A7F3D0'],
    rays: 0.18,
  },
  rare: {
    label: 'VZÁCNÉ',
    color: '#60A5FA',
    color2: '#93C5FD',
    glow: 'rgba(96,165,250,0.6)',
    aura: 'rgba(96,165,250,0.42)',
    rim: 'rgba(147,197,253,0.7)',
    particle: ['#BFDBFE', '#60A5FA', '#3B82F6'],
    rays: 0.28,
  },
  epic: {
    label: 'EPICKÉ',
    color: '#A78BFA',
    color2: '#C4B5FD',
    glow: 'rgba(167,139,250,0.7)',
    aura: 'rgba(167,139,250,0.5)',
    rim: 'rgba(196,181,253,0.78)',
    particle: ['#DDD6FE', '#A78BFA', '#7C3AED'],
    rays: 0.42,
  },
  legendary: {
    label: 'LEGENDÁRNÍ',
    color: '#F4C152',
    color2: '#FFD980',
    glow: 'rgba(244,193,82,0.85)',
    aura: 'rgba(244,193,82,0.6)',
    rim: 'rgba(255,217,128,0.85)',
    particle: ['#FFE9A8', '#F4C152', '#E5A833'],
    rays: 0.62,
  },
  mythic: {
    label: 'MYTICKÉ',
    color: '#F472B6',
    color2: '#FB7185',
    glow: 'rgba(244,114,182,0.95)',
    aura: 'rgba(244,114,182,0.72)',
    rim: 'rgba(251,113,133,0.92)',
    particle: ['#FBCFE8', '#F472B6', '#EC4899', '#FB7185'],
    rays: 0.85,
    rainbow: true,
  },
};

// REWARD TYPES drive the small TYPE ICON inside the card — never the whole scene.
// (so "epic location" reward stays purple, but "common location" stays silver.)
const REWARD_TYPE = {
  level:       { label: 'LEVEL UP',       sub: 'Nová úroveň',       icon: 'level' },
  title:       { label: 'TITUL ODEMČEN',  sub: 'Nový titul',         icon: 'title' },
  achievement: { label: 'ÚSPĚCH',         sub: 'Achievement',        icon: 'medal' },
  quest:       { label: 'QUEST DOKONČEN', sub: 'Cíl splněn',         icon: 'flag'  },
  streak:      { label: 'SÉRIE',          sub: 'Milník konzistence', icon: 'flame' },
  location:    { label: 'NOVÁ LOKACE',    sub: 'Lokace odemčena',    icon: 'map'   },
  cosmetic:    { label: 'KOSMETIKA',      sub: 'Předmět odemčen',    icon: 'gem'   },
};

// Reward objects shown INSIDE the card (the things you earned). These use
// rarity to color their thumbnail border, regardless of reward-type.
function sampleRewards(type) {
  if (type === 'level')       return [{ kind:'title',    name:'Strážce průsmyku', sub:'Nový titul' }];
  if (type === 'title')       return [{ kind:'title',    name:'Dragon Rider',     sub:'Z titulu Sky Walker' }];
  if (type === 'achievement') return [{ kind:'badge',    name:'1 milion XP',      sub:'Mistr zkušenosti' }];
  if (type === 'quest')       return [{ kind:'xp',       name:'+1 705 XP',        sub:'Mistrovství výživy' }];
  if (type === 'streak')      return [{ kind:'flame',    name:'83 dní v řadě',    sub:'Kroky · nový rekord' }];
  if (type === 'location')    return [{ kind:'location', name:'Skalní rokle',     sub:'Nová oblast' }];
  if (type === 'cosmetic')    return [{ kind:'frame',    name:'Rám hvězdné brány',sub:'Profilový rámeček' }];
  return [];
}

Object.assign(window, { RARITY, REWARD_TYPE, sampleRewards });
