// Integrations view — externí systémy seskupené podle providera.
// Card-style grid, klik → detail s endpointy a omezeními.

import { fetchJson, openSidePanel, escapeHtml } from '../app.js';

let cache = null;
async function loadData() {
  if (cache) return cache;
  cache = await fetchJson('data/integrations.json');
  return cache;
}

const CATEGORY_ICON = {
  android: '🤖',
  google: 'G',
  firebase: '🔥',
  third_party: '🌐',
};

export async function renderIntegrationsView(main) {
  const data = await loadData();
  const byCategory = {};
  for (const itg of data.integrations) {
    if (!byCategory[itg.category]) byCategory[itg.category] = [];
    byCategory[itg.category].push(itg);
  }

  main.innerHTML = `
    <div class="view-header">
      <h1 class="view-title">Externí integrace</h1>
      <p class="view-subtitle">${data.integrations.length} externích systémů, ${Object.keys(byCategory).length} kategorií.</p>
    </div>
    ${Object.entries(byCategory).map(([catId, items]) => renderCategory(catId, items, data.categories[catId])).join('')}
  `;

  main.querySelectorAll('[data-integration-id]').forEach((card) => {
    card.addEventListener('click', () => {
      const id = card.dataset.integrationId;
      window.location.hash = `#/integrations/${id}`;
    });
  });
}

function renderCategory(catId, items, name) {
  return `
    <section class="group">
      <header class="group-header">
        <h2 class="group-name">${CATEGORY_ICON[catId] || ''} ${escapeHtml(name || catId)}</h2>
        <span class="group-count">${items.length}</span>
      </header>
      <div class="feature-grid">
        ${items.map(renderCard).join('')}
      </div>
    </section>
  `;
}

function renderCard(itg) {
  return `
    <button class="feature-tile" data-integration-id="${escapeHtml(itg.id)}">
      <div class="feature-tile-name">${escapeHtml(itg.name)}</div>
      <div class="feature-tile-id">${escapeHtml(itg.package || '')}</div>
      <div class="feature-tile-summary">${escapeHtml(itg.summary)}</div>
      <div class="feature-tile-meta">
        ${(itg.usedBy || []).slice(0, 3).map((u) => `<span class="tag">${escapeHtml(u)}</span>`).join('')}
        ${itg.usedBy && itg.usedBy.length > 3 ? `<span class="tag">+${itg.usedBy.length - 3}</span>` : ''}
      </div>
    </button>
  `;
}

export async function openIntegrationDetail(id) {
  const data = await loadData();
  const itg = data.integrations.find((i) => i.id === id);
  if (!itg) return;
  openSidePanel(renderDetail(itg, data));
}

function renderDetail(itg, data) {
  const catName = (data.categories || {})[itg.category] || itg.category;

  const usedByList = (itg.usedBy || [])
    .map((f) => `<a class="detail-link" href="#/features/${escapeHtml(f)}">${escapeHtml(f)}</a>`)
    .join('') || '<span class="detail-empty">—</span>';

  const endpoints = (itg.endpoints || [])
    .map((e) => `<li><code>${escapeHtml(e.name)}</code><br/><span class="detail-empty">${escapeHtml(e.purpose)}</span></li>`)
    .join('');

  const constraints = (itg.constraints || [])
    .map((c) => `<li>${escapeHtml(c)}</li>`)
    .join('');

  const docs = (itg.docs || [])
    .map((d) => `<li><a href="../../${escapeHtml(d)}">${escapeHtml(d)}</a></li>`)
    .join('');

  return `
    <span class="detail-eyebrow">${escapeHtml(catName)}</span>
    <h2 class="detail-title">${escapeHtml(itg.name)}</h2>
    ${itg.package ? `<p class="detail-id">${escapeHtml(itg.package)}</p>` : ''}
    <p class="detail-summary">${escapeHtml(itg.summary)}</p>

    ${itg.auth ? `
      <div class="detail-section">
        <h3>Autentizace</h3>
        <p>${escapeHtml(itg.auth)}</p>
      </div>
    ` : ''}

    ${itg.entry ? `
      <div class="detail-section">
        <h3>Entry point</h3>
        <p><code>${escapeHtml(itg.entry)}</code></p>
      </div>
    ` : ''}

    <div class="detail-section">
      <h3>Konzumováno feature</h3>
      <div>${usedByList}</div>
    </div>

    ${endpoints ? `
      <div class="detail-section">
        <h3>Klíčové endpointy</h3>
        <ul class="detail-list">${endpoints}</ul>
      </div>
    ` : ''}

    ${constraints ? `
      <div class="detail-section">
        <h3>Omezení / pozor</h3>
        <ul class="detail-list">${constraints}</ul>
      </div>
    ` : ''}

    ${docs ? `
      <div class="detail-section">
        <h3>Související dokumenty</h3>
        <ul class="detail-list">${docs}</ul>
      </div>
    ` : ''}
  `;
}
