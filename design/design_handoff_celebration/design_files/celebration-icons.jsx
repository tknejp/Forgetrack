// celebration-icons.jsx — tiny inline SVG icons used in cards/badges

function IconLevel({ size=20, color='currentColor' }) {
  return (<svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path d="M12 3l3 6 6 1-4.5 4 1 6L12 17l-5.5 3 1-6L3 10l6-1 3-6z" fill={color} stroke="rgba(0,0,0,0.18)" strokeWidth="0.6"/>
  </svg>);
}
function IconTitle({ size=20, color='currentColor' }) {
  return (<svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path d="M3 7l4 3 5-6 5 6 4-3-2 12H5L3 7z" fill={color} stroke="rgba(0,0,0,0.2)" strokeWidth="0.6"/>
  </svg>);
}
function IconMedal({ size=20, color='currentColor' }) {
  return (<svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path d="M8 2h8l-2 5h-4L8 2z" fill={color} opacity="0.85"/>
    <circle cx="12" cy="14" r="6" fill={color} stroke="rgba(0,0,0,0.18)" strokeWidth="0.6"/>
    <path d="M12 11l1 2 2 .3-1.5 1.4.4 2.1L12 15.8l-1.9 1L10.5 14.7 9 13.3l2-.3 1-2z" fill="rgba(0,0,0,0.35)"/>
  </svg>);
}
function IconFlag({ size=20, color='currentColor' }) {
  return (<svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path d="M5 3v18M5 4h12l-2 4 2 4H5" fill={color} stroke={color} strokeWidth="1.5" strokeLinejoin="round"/>
  </svg>);
}
function IconFlame({ size=20, color='currentColor' }) {
  return (<svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path d="M12 2c2 4-1 6 0 9 1 3 5 3 5 7 0 3-2 5-5 5s-5-2-5-5c0-2 1-3 1-5 0-1-1-2-1-3 1-1 3-3 5-8z" fill={color}/>
  </svg>);
}
function IconMap({ size=20, color='currentColor' }) {
  return (<svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path d="M9 4l-6 2v14l6-2 6 2 6-2V4l-6 2-6-2z" stroke={color} strokeWidth="1.6" fill={color} fillOpacity="0.2"/>
    <path d="M9 4v14M15 6v14" stroke={color} strokeWidth="1.2"/>
  </svg>);
}
function IconGem({ size=20, color='currentColor' }) {
  return (<svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path d="M6 4h12l3 5-9 11L3 9l3-5z" fill={color} stroke="rgba(0,0,0,0.2)" strokeWidth="0.6"/>
    <path d="M6 4l3 5h6l3-5M9 9l3 11M15 9l-3 11" stroke="rgba(0,0,0,0.4)" strokeWidth="0.6"/>
  </svg>);
}
function IconSparkle({ size=20, color='currentColor' }) {
  return (<svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path d="M12 3v8M12 13v8M3 12h8M13 12h8" stroke={color} strokeWidth="1.6" strokeLinecap="round"/>
    <path d="M12 7l1.6 3.4L17 12l-3.4 1.6L12 17l-1.6-3.4L7 12l3.4-1.6L12 7z" fill={color}/>
  </svg>);
}
function IconClose({ size=18, color='currentColor' }) {
  return (<svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path d="M6 6l12 12M18 6L6 18" stroke={color} strokeWidth="1.8" strokeLinecap="round"/>
  </svg>);
}
function IconBolt({ size=14, color='currentColor' }) {
  return (<svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path d="M13 2L4 14h6l-1 8 9-12h-6l1-8z" fill={color}/>
  </svg>);
}
function IconShare({ size=18, color='currentColor' }) {
  return (<svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path d="M12 3v12M12 3l-4 4M12 3l4 4M5 12v8h14v-8" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>);
}

const TYPE_ICON = {
  level: IconLevel, title: IconTitle, medal: IconMedal, flag: IconFlag,
  flame: IconFlame, map: IconMap, gem: IconGem,
};

Object.assign(window, {
  IconLevel, IconTitle, IconMedal, IconFlag, IconFlame, IconMap, IconGem,
  IconSparkle, IconClose, IconBolt, IconShare, TYPE_ICON,
});
