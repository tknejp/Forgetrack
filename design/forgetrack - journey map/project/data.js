// Mocked progression ledger — Forgetrack Hero Journey
// Aligned with the data model spec from the brief:
//   level, xp, title/rank, achievement (name/icon/unlockedAt),
//   reward/quest (name/type/completedAt),
//   streak (domain/current/best/milestoneAt),
//   event { timestamp, type, optional description }

window.JOURNEY_EVENTS = [
  // Most recent first — UI re-sorts as needed.
  { id: 'e48', type: 'level',       at: '2026-04-26T08:14:00Z', level: 48, title: 'Dragon Rider', xp: 81265, desc: 'Nový level dosažen po 9 dnech.' },
  { id: 'e47', type: 'achievement', at: '2026-04-22T19:02:00Z', name: '1M XP',          icon: '⭐', rarity: 'epic',     desc: 'Překonal jsi hranici milionu zkušeností.' },
  { id: 'e46', type: 'streak',      at: '2026-04-18T07:30:00Z', domain: 'Kroky',   value: 83, best: true, desc: 'Nejlepší série kroků — 83 dní v řadě.' },
  { id: 'e45', type: 'quest',       at: '2026-04-15T20:45:00Z', name: '240 hodin / 30 dní',   questType: 'milestone', desc: 'Měsíční cíl pohybu splněn.' },
  { id: 'e44', type: 'title',       at: '2026-04-09T12:00:00Z', name: 'Dragon Rider',   from: 'Sky Walker', desc: 'Nový titul odemčen na úrovni 45.' },
  { id: 'e43', type: 'level',       at: '2026-04-04T18:22:00Z', level: 45, title: 'Sky Walker',   xp: 70840 },
  { id: 'e42', type: 'achievement', at: '2026-03-30T06:48:00Z', name: 'Level 30',       icon: '🏰', rarity: 'rare' },
  { id: 'e41', type: 'quest',       at: '2026-03-24T21:10:00Z', name: 'Týden bez cukru', questType: 'nutrition' },
  { id: 'e40', type: 'streak',      at: '2026-03-18T22:00:00Z', domain: 'Spánek',   value: 21 },
  { id: 'e39', type: 'level',       at: '2026-03-11T19:30:00Z', level: 40, title: 'Sky Walker',   xp: 54200 },
  { id: 'e38', type: 'achievement', at: '2026-03-02T07:15:00Z', name: 'Brewmaster',     icon: '🧪', rarity: 'rare' },
  { id: 'e37', type: 'quest',       at: '2026-02-21T20:00:00Z', name: '50 km běh / měsíc',  questType: 'fitness' },
  { id: 'e36', type: 'level',       at: '2026-02-08T17:40:00Z', level: 30, title: 'Wayfarer',     xp: 28900 },
  { id: 'e35', type: 'title',       at: '2026-01-28T10:05:00Z', name: 'Wayfarer',       from: 'Apprentice' },
  { id: 'e34', type: 'achievement', at: '2026-01-15T09:00:00Z', name: 'První 10K',      icon: '👟', rarity: 'common' },
  { id: 'e33', type: 'level',       at: '2026-01-02T08:00:00Z', level: 20, title: 'Apprentice',   xp: 12100 },
  { id: 'e32', type: 'quest',       at: '2025-12-22T18:30:00Z', name: 'Adventní výzva', questType: 'special' },
  { id: 'e31', type: 'level',       at: '2025-12-10T07:50:00Z', level: 10, title: 'Apprentice',   xp: 4200 },
  { id: 'e30', type: 'level',       at: '2025-11-25T20:00:00Z', level: 1,  title: 'Novice',       xp: 0, desc: 'Začátek tvé hrdinské cesty.' },
];

// Type metadata — colors, icons, czech labels
window.JOURNEY_TYPES = {
  level:       { label: 'Nový level',     color: 'gold',   accent: 'var(--gold)',     icon: '⬆', glow: 'gold'   },
  title:       { label: 'Nový titul',     color: 'purple', accent: 'var(--purple-400)', icon: '👑', glow: 'purple' },
  achievement: { label: 'Úspěch',         color: 'teal',   accent: 'var(--teal)',     icon: '🏆', glow: 'teal'   },
  streak:      { label: 'Série',          color: 'orange', accent: 'var(--orange)',   icon: '🔥', glow: 'gold'   },
  quest:       { label: 'Quest milník',   color: 'green',  accent: 'var(--green)',    icon: '⚑',  glow: 'teal'   },
};

// Czech relative time
window.czRelative = function(iso) {
  const d = new Date(iso);
  const now = new Date('2026-04-27T12:00:00Z');
  const diff = (now - d) / 1000;
  if (diff < 60) return 'právě teď';
  if (diff < 3600) return `před ${Math.floor(diff/60)} min`;
  if (diff < 86400) return `před ${Math.floor(diff/3600)} h`;
  if (diff < 86400*7) return `před ${Math.floor(diff/86400)} dny`;
  if (diff < 86400*30) return `před ${Math.floor(diff/(86400*7))} týdny`;
  if (diff < 86400*365) return `před ${Math.floor(diff/(86400*30))} měsíci`;
  return d.toLocaleDateString('cs-CZ');
};

window.czDate = function(iso) {
  const d = new Date(iso);
  return d.toLocaleDateString('cs-CZ', { day: 'numeric', month: 'long' });
};

window.czMonth = function(iso) {
  const d = new Date(iso);
  return d.toLocaleDateString('cs-CZ', { month: 'long', year: 'numeric' });
};
