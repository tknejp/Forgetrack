// Glossary — sealed hierarchie jako class diagramy.

import { fetchJson, escapeHtml } from '../app.js';
import { renderMermaid, resetMermaidTheme } from '../lib/mermaid_helpers.js';

let cache = null;

async function loadData() {
  if (cache) return cache;
  cache = await fetchJson('data/glossary.json');
  return cache;
}

export async function renderGlossaryView(main) {
  const data = await loadData();
  const byCategory = {};
  for (const e of data.entries) {
    (byCategory[e.category] ||= []).push(e);
  }

  main.innerHTML = `
    <div class="view-header">
      <h1 class="view-title">Doménový slovník</h1>
      <p class="view-subtitle">${data.entries.length} sealed hierarchií a klíčových enumů. Třídní diagramy odrážejí strukturu kódu — soubor je uveden v každé sekci.</p>
    </div>
    <div class="dataflow-layout">
      <aside class="dataflow-toc">
        <h3>Obsah</h3>
        ${Object.entries(byCategory).map(([cat, items]) => `
          <div class="toc-group">
            <div class="toc-group-name">${escapeHtml(cat)}</div>
            <ul>${items.map((e) => `<li><a href="#${escapeHtml(e.id)}">${escapeHtml(e.title)}</a></li>`).join('')}</ul>
          </div>
        `).join('')}
      </aside>
      <div class="dataflow-stream">
        ${data.entries.map(entryPlaceholder).join('')}
      </div>
    </div>
  `;

  await renderAllDiagrams(data.entries);
  document.addEventListener('themechange', () => onThemeChange(data.entries));
}

function entryPlaceholder(e) {
  return `
    <section class="flow-card" id="${escapeHtml(e.id)}">
      <header>
        <span class="detail-eyebrow">${escapeHtml(e.category)}</span>
        <h2 class="flow-title">${escapeHtml(e.title)}</h2>
        <p class="flow-summary">${escapeHtml(e.summary)}</p>
        ${e.file ? `<p class="detail-id"><code>${escapeHtml(e.file)}</code></p>` : ''}
      </header>
      <div class="flow-diagram" data-glossary-id="${escapeHtml(e.id)}">
        <div class="loading">Rendering…</div>
      </div>
    </section>
  `;
}

async function renderAllDiagrams(entries) {
  for (const e of entries) {
    const host = document.querySelector(`.flow-diagram[data-glossary-id="${cssEscape(e.id)}"]`);
    if (!host) continue;
    const svg = await renderMermaid(e.diagram);
    host.innerHTML = svg;
  }
}

async function onThemeChange(entries) {
  resetMermaidTheme();
  await renderAllDiagrams(entries);
}

function cssEscape(s) {
  return s.replace(/(["\\])/g, '\\$1');
}
