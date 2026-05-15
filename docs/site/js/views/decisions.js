// Architecture Decision Records — lightweight ADR seznam.

import { fetchJson, openSidePanel, escapeHtml } from '../app.js';

let cache = null;

async function loadData() {
  if (cache) return cache;
  cache = await fetchJson('data/decisions.json');
  return cache;
}

export async function renderDecisionsView(main) {
  const data = await loadData();

  main.innerHTML = `
    <div class="view-header">
      <h1 class="view-title">Architektonická rozhodnutí</h1>
      <p class="view-subtitle">${escapeHtml(data.intro)}</p>
    </div>
    <ol class="adr-list">
      ${data.decisions.map((d, i) => renderRow(d, i + 1, data.statusLabels)).join('')}
    </ol>
  `;

  main.querySelectorAll('[data-adr-id]').forEach((row) => {
    row.addEventListener('click', () => {
      const id = row.dataset.adrId;
      window.location.hash = `#/decisions/${id}`;
    });
  });
}

function renderRow(adr, number, statusLabels) {
  const statusLabel = statusLabels[adr.status] || adr.status;
  return `
    <li class="adr-row" data-adr-id="${escapeHtml(adr.id)}">
      <div class="adr-number">ADR-${String(number).padStart(2, '0')}</div>
      <div class="adr-body">
        <div class="adr-title">${escapeHtml(adr.title)}</div>
        <div class="adr-meta">
          <span class="adr-status adr-status-${escapeHtml(adr.status)}">${escapeHtml(statusLabel)}</span>
          <span class="adr-date">${escapeHtml(adr.date)}</span>
        </div>
        <p class="adr-preview">${escapeHtml(adr.decision)}</p>
      </div>
    </li>
  `;
}

export async function openDecisionDetail(id) {
  const data = await loadData();
  const adr = data.decisions.find((d) => d.id === id);
  if (!adr) return;
  const number = data.decisions.findIndex((d) => d.id === id) + 1;
  openSidePanel(renderDetail(adr, number, data.statusLabels));
}

function renderDetail(adr, number, statusLabels) {
  const statusLabel = statusLabels[adr.status] || adr.status;
  const consequences = (adr.consequences || [])
    .map((c) => `<li>${escapeHtml(c)}</li>`)
    .join('');
  const links = (adr.links || [])
    .map((l) => `<li><a href="../../${escapeHtml(l)}">${escapeHtml(l)}</a></li>`)
    .join('');

  return `
    <span class="detail-eyebrow">ADR-${String(number).padStart(2, '0')} · <span class="adr-status adr-status-${escapeHtml(adr.status)}">${escapeHtml(statusLabel)}</span></span>
    <h2 class="detail-title">${escapeHtml(adr.title)}</h2>
    <p class="detail-id">${escapeHtml(adr.date)}</p>

    <div class="detail-section">
      <h3>Kontext</h3>
      <p>${escapeHtml(adr.context)}</p>
    </div>

    <div class="detail-section">
      <h3>Rozhodnutí</h3>
      <p>${escapeHtml(adr.decision)}</p>
    </div>

    ${consequences ? `
      <div class="detail-section">
        <h3>Důsledky</h3>
        <ul class="detail-list">${consequences}</ul>
      </div>
    ` : ''}

    ${adr.alternatives ? `
      <div class="detail-section">
        <h3>Zvažované alternativy</h3>
        <p>${escapeHtml(adr.alternatives)}</p>
      </div>
    ` : ''}

    ${links ? `
      <div class="detail-section">
        <h3>Související</h3>
        <ul class="detail-list">${links}</ul>
      </div>
    ` : ''}
  `;
}
