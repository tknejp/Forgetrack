// ft-tokens.jsx — Redesign visual language tokens

const THEMES = {
  violet: { accent:'#7C6FFF', accentGlow:'rgba(124,111,255,0.35)' },
  cyan:   { accent:'#22D3EE', accentGlow:'rgba(34,211,238,0.35)' },
  rose:   { accent:'#F472B6', accentGlow:'rgba(244,114,182,0.35)' },
};

const DOMAINS = {
  steps:    { color:'#34D399', dim:'rgba(52,211,153,0.18)',  glow:'rgba(52,211,153,0.25)',  gradient:'linear-gradient(135deg, rgba(52,211,153,0.22) 0%, rgba(16,185,129,0.08) 100%)' },
  calories: { color:'#FBBF24', dim:'rgba(251,191,36,0.18)',  glow:'rgba(251,191,36,0.25)',  gradient:'linear-gradient(135deg, rgba(251,191,36,0.22) 0%, rgba(245,158,11,0.06) 100%)' },
  weight:   { color:'#60A5FA', dim:'rgba(96,165,250,0.18)',  glow:'rgba(96,165,250,0.25)',  gradient:'linear-gradient(135deg, rgba(96,165,250,0.22) 0%, rgba(59,130,246,0.06) 100%)' },
  sleep:    { color:'#A89BFF', dim:'rgba(168,155,255,0.18)', glow:'rgba(168,155,255,0.25)', gradient:'linear-gradient(135deg, rgba(168,155,255,0.22) 0%, rgba(124,111,255,0.06) 100%)' },
  active:   { color:'#2DD4BF', dim:'rgba(45,212,191,0.18)',  glow:'rgba(45,212,191,0.25)',  gradient:'linear-gradient(135deg, rgba(45,212,191,0.22) 0%, rgba(20,184,166,0.06) 100%)' },
  protein:  { color:'#60A5FA', dim:'rgba(96,165,250,0.18)',  glow:'rgba(96,165,250,0.25)',  gradient:'linear-gradient(135deg, rgba(96,165,250,0.18) 0%, rgba(59,130,246,0.05) 100%)' },
  fat:      { color:'#FBBF24', dim:'rgba(251,191,36,0.18)',  glow:'rgba(251,191,36,0.25)',  gradient:'linear-gradient(135deg, rgba(251,191,36,0.18) 0%, rgba(245,158,11,0.05) 100%)' },
  carbs:    { color:'#F472B6', dim:'rgba(244,114,182,0.18)', glow:'rgba(244,114,182,0.25)', gradient:'linear-gradient(135deg, rgba(244,114,182,0.18) 0%, rgba(236,72,153,0.05) 100%)' },
};

Object.assign(window, { THEMES, DOMAINS });
