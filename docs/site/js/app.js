// Hash-based router + view dispatcher.
// Routes:
//   #/<view>                 → render view
//   #/<view>/<detail>        → render view + open side panel for detail

import { renderFeaturesView, openFeatureDetail } from './views/features.js';
import { renderProvidersView, openProviderDetail } from './views/providers.js';
import { renderStorageView, openStorageDetail } from './views/storage.js';
import { renderIntegrationsView, openIntegrationDetail } from './views/integrations.js';

// ─── Theme (light / dark) ──────────────────────────────────────
// Aplikujeme co nejdřív, ať se ve světlém režimu neflashne tmavá.
const THEME_KEY = 'forgetrack-theme';

function initialTheme() {
  const stored = localStorage.getItem(THEME_KEY);
  if (stored === 'light' || stored === 'dark') return stored;
  return window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
}

function applyTheme(theme) {
  if (theme === 'light') {
    document.documentElement.setAttribute('data-theme', 'light');
  } else {
    document.documentElement.removeAttribute('data-theme');
  }
}

function toggleTheme() {
  const current = document.documentElement.getAttribute('data-theme') === 'light' ? 'light' : 'dark';
  const next = current === 'light' ? 'dark' : 'light';
  localStorage.setItem(THEME_KEY, next);
  applyTheme(next);
  document.dispatchEvent(new CustomEvent('themechange', { detail: { theme: next } }));
}

applyTheme(initialTheme());

const VIEWS = {
  features: {
    label: 'Feature',
    render: renderFeaturesView,
    openDetail: openFeatureDetail,
  },
  providers: {
    label: 'Providery',
    render: renderProvidersView,
    openDetail: openProviderDetail,
  },
  dataflow: { label: 'Datové toky', render: renderPlaceholder('Datové toky', 'iteraci 4') },
  storage: {
    label: 'Úložiště',
    render: renderStorageView,
    openDetail: openStorageDetail,
  },
  integrations: {
    label: 'Integrace',
    render: renderIntegrationsView,
    openDetail: openIntegrationDetail,
  },
  glossary: { label: 'Slovník', render: renderPlaceholder('Doménový slovník', 'iteraci 5') },
  progression: { label: 'RPG vrstva', render: renderPlaceholder('RPG vrstva', 'iteraci 6') },
  decisions: { label: 'Rozhodnutí', render: renderPlaceholder('Rozhodnutí (ADRs)', 'iteraci 7') },
};

const DEFAULT_VIEW = 'features';

function parseHash() {
  const raw = window.location.hash.replace(/^#\//, '');
  if (!raw) return { view: DEFAULT_VIEW, detail: null };
  const [view, detail] = raw.split('/');
  return {
    view: VIEWS[view] ? view : DEFAULT_VIEW,
    detail: detail || null,
  };
}

function updateActiveNav(viewId) {
  const switcher = document.getElementById('view-switcher');
  switcher.querySelectorAll('a').forEach((a) => {
    a.classList.toggle('active', a.dataset.view === viewId);
  });
}

async function handleRoute() {
  const { view, detail } = parseHash();
  const main = document.getElementById('main');
  updateActiveNav(view);

  const def = VIEWS[view];
  main.innerHTML = '<div class="loading">Načítání…</div>';
  try {
    await def.render(main);
    if (detail && def.openDetail) {
      await def.openDetail(detail);
    } else {
      closeSidePanel();
    }
  } catch (err) {
    main.innerHTML = `<div class="empty-state"><p class="empty-state-title">Chyba při načítání</p><p>${escapeHtml(err.message)}</p></div>`;
    console.error(err);
  }
}

function renderPlaceholder(title, iteration) {
  return (main) => {
    main.innerHTML = `
      <div class="view-header">
        <h1 class="view-title">${title}</h1>
        <p class="view-subtitle">Tento pohled bude implementován v ${iteration}.</p>
      </div>
      <div class="empty-state">
        <p class="empty-state-title">Brzy k vidění</p>
        <p>Plán je v <a href="../PLAN.md">docs/PLAN.md</a>.</p>
      </div>
    `;
  };
}

// ─── Side panel ────────────────────────────────────────────────
export function openSidePanel(htmlContent) {
  const panel = document.getElementById('side-panel');
  document.getElementById('side-panel-body').innerHTML = htmlContent;
  panel.setAttribute('aria-hidden', 'false');
  document.body.style.overflow = 'hidden';
}

export function closeSidePanel() {
  const panel = document.getElementById('side-panel');
  panel.setAttribute('aria-hidden', 'true');
  document.body.style.overflow = '';
  // Strip the detail from the hash without re-routing flicker.
  const { view } = parseHash();
  if (window.location.hash !== `#/${view}`) {
    history.replaceState(null, '', `#/${view}`);
  }
}

function bindSidePanelClose() {
  document.querySelectorAll('[data-close-panel]').forEach((el) => {
    el.addEventListener('click', closeSidePanel);
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeSidePanel();
  });
}

// ─── Utilities ─────────────────────────────────────────────────
export function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export async function fetchJson(path) {
  const res = await fetch(path);
  if (!res.ok) {
    throw new Error(`Nepodařilo se načíst ${path} (HTTP ${res.status}). Spusť přes 'python -m http.server' v docs/site/.`);
  }
  return res.json();
}

// ─── Bootstrap ─────────────────────────────────────────────────
window.addEventListener('hashchange', handleRoute);
window.addEventListener('DOMContentLoaded', () => {
  bindSidePanelClose();
  const toggle = document.getElementById('theme-toggle');
  if (toggle) toggle.addEventListener('click', toggleTheme);
  handleRoute();
});
