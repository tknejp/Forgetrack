// Data flows — sequence diagramy hlavních scénářů. Mermaid + theme-aware.

import { fetchJson, escapeHtml } from '../app.js';
import { renderMermaid, resetMermaidTheme } from '../lib/mermaid_helpers.js';

let cache = null;

async function loadData() {
  if (cache) return cache;
  cache = await fetchJson('data/dataflows.json');
  return cache;
}

export async function renderDataflowView(main) {
  const data = await loadData();
  const byCategory = {};
  for (const f of data.flows) {
    (byCategory[f.category] ||= []).push(f);
  }

  // TOC (sticky nav) + diagrams
  main.innerHTML = `
    <div class="view-header">
      <h1 class="view-title">Datové toky</h1>
      <p class="view-subtitle">${data.flows.length} klíčových scénářů jako sekvenční diagramy. Klik na položku v obsahu pro skok.</p>
    </div>
    <div class="dataflow-layout">
      <aside class="dataflow-toc">
        <h3>Obsah</h3>
        ${Object.entries(byCategory).map(([cat, flows]) => `
          <div class="toc-group">
            <div class="toc-group-name">${escapeHtml(cat)}</div>
            <ul>${flows.map((f) => `<li><a href="#${escapeHtml(f.id)}">${escapeHtml(f.title)}</a></li>`).join('')}</ul>
          </div>
        `).join('')}
      </aside>
      <div class="dataflow-stream" id="dataflow-stream">
        ${data.flows.map((f) => flowPlaceholder(f)).join('')}
      </div>
    </div>
  `;

  // Render Mermaid pro každý diagram po DOM mountu.
  await renderAllDiagrams(data.flows);

  // Re-render při změně tématu.
  document.addEventListener('themechange', () => onThemeChange(data.flows));
}

function flowPlaceholder(f) {
  return `
    <section class="flow-card" id="${escapeHtml(f.id)}">
      <header>
        <span class="detail-eyebrow">${escapeHtml(f.category)}</span>
        <h2 class="flow-title">${escapeHtml(f.title)}</h2>
        <p class="flow-summary">${escapeHtml(f.summary)}</p>
      </header>
      <div class="flow-diagram" data-flow-id="${escapeHtml(f.id)}">
        <div class="loading">Rendering…</div>
      </div>
    </section>
  `;
}

async function renderAllDiagrams(flows) {
  for (const f of flows) {
    const host = document.querySelector(`.flow-diagram[data-flow-id="${cssEscape(f.id)}"]`);
    if (!host) continue;
    const svg = await renderMermaid(f.diagram);
    host.innerHTML = svg;
  }
}

async function onThemeChange(flows) {
  resetMermaidTheme();
  // Re-render všech diagramů s novou theme.
  await renderAllDiagrams(flows);
}

function cssEscape(s) {
  return s.replace(/(["\\])/g, '\\$1');
}
