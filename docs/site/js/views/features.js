// Features map — 4 skupiny, grid dlaždic, klik → side panel s detailem.

import { fetchJson, openSidePanel, escapeHtml } from '../app.js';

let cache = null;

async function loadData() {
  if (cache) return cache;
  cache = await fetchJson('data/features.json');
  return cache;
}

export async function renderFeaturesView(main) {
  const data = await loadData();
  const groups = data.groups;
  const features = data.features;

  const grouped = groups.map((g) => ({
    ...g,
    items: features.filter((f) => f.group === g.id),
  }));

  main.innerHTML = `
    <div class="view-header">
      <h1 class="view-title">Mapa feature</h1>
      <p class="view-subtitle">${features.length} feature seskupených podle role. Kliknutím se otevře detail.</p>
    </div>
    ${grouped.map(renderGroup).join('')}
  `;

  main.querySelectorAll('[data-feature-id]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const id = btn.dataset.featureId;
      window.location.hash = `#/features/${id}`;
    });
  });
}

function renderGroup(group) {
  return `
    <section class="group">
      <header class="group-header">
        <h2 class="group-name">${escapeHtml(group.name)}</h2>
        <span class="group-count">${group.items.length}</span>
      </header>
      <div class="feature-grid">
        ${group.items.map((f) => renderTile(f, group.id)).join('')}
      </div>
    </section>
  `;
}

function renderTile(feature, groupId) {
  const providers = (feature.providers || []).slice(0, 2);
  const moreProviders = (feature.providers || []).length - providers.length;
  return `
    <button class="feature-tile" data-feature-id="${escapeHtml(feature.id)}" data-group="${escapeHtml(groupId)}">
      <div class="feature-tile-name">${escapeHtml(feature.displayName)}</div>
      <div class="feature-tile-id">lib/features/${escapeHtml(feature.id)}/</div>
      <div class="feature-tile-summary">${escapeHtml(feature.summary)}</div>
      <div class="feature-tile-meta">
        ${providers.map((p) => `<span class="tag tag-accent">${escapeHtml(p)}</span>`).join('')}
        ${moreProviders > 0 ? `<span class="tag">+${moreProviders}</span>` : ''}
      </div>
    </button>
  `;
}

export async function openFeatureDetail(id) {
  const data = await loadData();
  const feature = data.features.find((f) => f.id === id);
  if (!feature) return;

  const group = data.groups.find((g) => g.id === feature.group);
  openSidePanel(renderDetail(feature, group, data.features));
}

function renderDetail(feature, group, allFeatures) {
  const consumesList = (feature.consumes || []).map((cid) => {
    const c = allFeatures.find((f) => f.id === cid);
    const label = c ? c.displayName : cid;
    return `<a class="detail-link" href="#/features/${escapeHtml(cid)}">${escapeHtml(label)}</a>`;
  }).join('');

  const providersList = (feature.providers || [])
    .map((p) => `<span class="detail-link">${escapeHtml(p)}</span>`)
    .join('');

  const signalsList = (feature.producedSignals || [])
    .map((s) => `<li><code>${escapeHtml(s)}</code></li>`)
    .join('');

  const filesList = Object.entries(feature.files || {})
    .map(([layer, path]) => `<li><strong>${escapeHtml(layer)}:</strong> <code>${escapeHtml(path)}</code></li>`)
    .join('');

  const docsList = (feature.docs || [])
    .map((d) => `<li><a href="../../${escapeHtml(d)}">${escapeHtml(d)}</a></li>`)
    .join('');

  return `
    <span class="detail-eyebrow">${escapeHtml(group ? group.name : feature.group)}</span>
    <h2 class="detail-title">${escapeHtml(feature.displayName)}</h2>
    <p class="detail-id">lib/features/${escapeHtml(feature.id)}/</p>
    <p class="detail-summary">${escapeHtml(feature.summary)}</p>

    ${feature.description ? `
      <div class="detail-section">
        <h3>Detail</h3>
        <p>${escapeHtml(feature.description)}</p>
      </div>
    ` : ''}

    ${providersList ? `
      <div class="detail-section">
        <h3>Providery</h3>
        <div>${providersList}</div>
      </div>
    ` : ''}

    ${consumesList ? `
      <div class="detail-section">
        <h3>Konzumuje</h3>
        <div>${consumesList}</div>
      </div>
    ` : ''}

    ${signalsList ? `
      <div class="detail-section">
        <h3>Produkuje signály</h3>
        <ul class="detail-list">${signalsList}</ul>
      </div>
    ` : ''}

    ${filesList ? `
      <div class="detail-section">
        <h3>Klíčové soubory</h3>
        <ul class="detail-list">${filesList}</ul>
      </div>
    ` : ''}

    ${docsList ? `
      <div class="detail-section">
        <h3>Související dokumenty</h3>
        <ul class="detail-list">${docsList}</ul>
      </div>
    ` : ''}
  `;
}
