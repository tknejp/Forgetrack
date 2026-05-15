// RPG vrstva — jeden velký cross-cutting flowchart Journey → Chapter →
// Quest → Objective → Reward → Cosmetic, doprovozený principy.

import { fetchJson, escapeHtml } from '../app.js';
import { renderMermaid, resetMermaidTheme } from '../lib/mermaid_helpers.js';

let cache = null;

async function loadData() {
  if (cache) return cache;
  cache = await fetchJson('data/progression.json');
  return cache;
}

export async function renderProgressionView(main) {
  const data = await loadData();

  main.innerHTML = `
    <div class="view-header">
      <h1 class="view-title">RPG vrstva</h1>
      <p class="view-subtitle">${escapeHtml(data.intro)}</p>
    </div>
    <section class="flow-card">
      <header>
        <h2 class="flow-title">Tok od fitness dat k celebraci</h2>
      </header>
      <div class="flow-diagram" id="progression-flowchart">
        <div class="loading">Rendering…</div>
      </div>
    </section>
    <section class="principles">
      <h2 class="principles-title">Zásady</h2>
      <div class="principles-grid">
        ${data.principles.map((p) => `
          <div class="principle-card">
            <div class="principle-name">${escapeHtml(p.name)}</div>
            <p class="principle-detail">${escapeHtml(p.detail)}</p>
          </div>
        `).join('')}
      </div>
    </section>
  `;

  await renderFlowchart(data);
  document.addEventListener('themechange', () => onThemeChange(data));
}

async function renderFlowchart(data) {
  const host = document.getElementById('progression-flowchart');
  if (!host) return;
  const svg = await renderMermaid(data.flowchart);
  host.innerHTML = svg;
}

async function onThemeChange(data) {
  resetMermaidTheme();
  await renderFlowchart(data);
}
