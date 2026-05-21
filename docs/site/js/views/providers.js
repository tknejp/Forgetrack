// Graf providerů — orientovaný graf DI závislostí z main.dart.
// Uzly = providery, hrany = "X závisí na Y" (upstream proxy provider).

import { fetchJson, openSidePanel, escapeHtml } from '../app.js';

let dataCache = null;
let cyInstance = null;

async function loadData() {
  if (dataCache) return dataCache;
  dataCache = await fetchJson('data/providers.json');
  return dataCache;
}

// ─── Theme-aware barvy ─────────────────────────────────────────
function cssVar(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
}

function paletteForGroup(group) {
  switch (group) {
    case 'data':     return cssVar('--color-secondary');
    case 'gameplay': return cssVar('--color-accent');
    case 'sync':     return cssVar('--color-tertiary');
    case 'shell':    return cssVar('--color-on-surface-faint');
    case 'infra':    return cssVar('--color-success');
    default:         return cssVar('--color-on-surface-muted');
  }
}

function cytoscapeStyle() {
  return [
    {
      selector: 'node',
      style: {
        'background-color': (ele) => paletteForGroup(ele.data('group')),
        'border-color': cssVar('--color-card-border'),
        'border-width': 1,
        'label': 'data(label)',
        'color': cssVar('--color-on-surface'),
        'font-size': 11,
        'font-family': 'Inter, system-ui, sans-serif',
        'font-weight': 600,
        'text-valign': 'center',
        'text-halign': 'center',
        'text-wrap': 'wrap',
        'text-max-width': '80px',
        'width': 84,
        'height': 84,
        'shape': 'round-rectangle',
        'text-outline-color': cssVar('--color-bg'),
        'text-outline-width': 2,
        'transition-property': 'background-color, border-color, border-width',
        'transition-duration': '0.15s',
      },
    },
    {
      selector: 'node[eager = "true"]',
      style: {
        'border-color': cssVar('--color-warning'),
        'border-width': 2,
      },
    },
    {
      selector: 'node:selected',
      style: {
        'border-color': cssVar('--color-accent'),
        'border-width': 3,
      },
    },
    {
      selector: 'edge',
      style: {
        'curve-style': 'bezier',
        'width': 1.5,
        'line-color': cssVar('--color-card-border'),
        'target-arrow-color': cssVar('--color-on-surface-muted'),
        'target-arrow-shape': 'triangle',
        'arrow-scale': 1.1,
        'opacity': 0.7,
      },
    },
    {
      selector: 'edge.highlighted',
      style: {
        'line-color': cssVar('--color-accent'),
        'target-arrow-color': cssVar('--color-accent'),
        'width': 2.5,
        'opacity': 1,
      },
    },
    {
      selector: 'node.faded',
      style: { 'opacity': 0.25 },
    },
    {
      selector: 'edge.faded',
      style: { 'opacity': 0.1 },
    },
  ];
}

// ─── Render ────────────────────────────────────────────────────
export async function renderProvidersView(main) {
  const data = await loadData();
  if (typeof cytoscape === 'undefined') {
    main.innerHTML = `
      <div class="view-header">
        <h1 class="view-title">Graf providerů</h1>
      </div>
      <div class="empty-state">
        <p class="empty-state-title">Cytoscape.js se nenačetl</p>
        <p>CDN možná nedostupná — zkontroluj síť nebo console.</p>
      </div>
    `;
    return;
  }

  // Stats
  const total = data.providers.length;
  const withDeps = data.providers.filter((p) => p.dependsOn.length > 0).length;
  const eager = data.providers.filter((p) => p.eager).length;

  main.innerHTML = `
    <div class="view-header">
      <h1 class="view-title">Graf providerů</h1>
      <p class="view-subtitle">${total} providerů z <code>main.dart</code> · ${withDeps} s proxy závislostmi · ${eager} eager (<code>lazy: false</code>). Hrana A → B znamená "A závisí na B". Klikni na uzel pro detail.</p>
    </div>
    <div class="graph-toolbar">
      <span class="legend-item"><span class="legend-swatch" style="background:${paletteForGroup('data')}"></span>Data</span>
      <span class="legend-item"><span class="legend-swatch" style="background:${paletteForGroup('gameplay')}"></span>Gameplay</span>
      <span class="legend-item"><span class="legend-swatch" style="background:${paletteForGroup('sync')}"></span>Sync</span>
      <span class="legend-item"><span class="legend-swatch" style="background:${paletteForGroup('shell')}"></span>Shell</span>
      <span class="legend-item"><span class="legend-swatch" style="background:${paletteForGroup('infra')}"></span>Infra</span>
      <span class="legend-item"><span class="legend-swatch legend-swatch-ring" style="border-color:var(--color-warning)"></span>Eager (lazy: false)</span>
      <button type="button" class="btn-subtle" id="graph-fit">Vycentrovat</button>
    </div>
    <div class="graph-container" id="graph-container"></div>
  `;

  const elements = buildElements(data.providers);

  cyInstance = cytoscape({
    container: document.getElementById('graph-container'),
    elements,
    style: cytoscapeStyle(),
    layout: layoutConfig(),
    wheelSensitivity: 0.25,
    minZoom: 0.4,
    maxZoom: 2.5,
  });

  cyInstance.on('tap', 'node', (e) => {
    const id = e.target.data('id');
    window.location.hash = `#/providers/${id}`;
  });

  cyInstance.on('mouseover', 'node', (e) => highlightNeighbourhood(e.target, true));
  cyInstance.on('mouseout', 'node', (e) => highlightNeighbourhood(e.target, false));

  document.getElementById('graph-fit').addEventListener('click', () => cyInstance.fit(null, 40));

  document.addEventListener('themechange', onThemeChange, { once: false });
}

function layoutConfig() {
  return {
    name: 'breadthfirst',
    directed: true,
    padding: 32,
    spacingFactor: 1.2,
    avoidOverlap: true,
    grid: true,
    roots: ['AuthProvider', 'GoalsProvider', 'FitnessProvider', 'KalorickeTabulkyProvider',
            'SheetsExportProvider', 'BushidoExportProvider',
            'ConnectivityProvider', 'LocaleProvider', 'NotificationPreferencesProvider',
            'HomeCardOrderProvider', 'OnboardingProvider', 'DevToolsProvider'],
  };
}

function buildElements(providers) {
  const nodes = providers.map((p) => ({
    data: {
      id: p.id,
      label: p.displayName,
      group: p.group,
      eager: p.eager ? 'true' : 'false',
    },
  }));

  const edges = [];
  for (const p of providers) {
    for (const dep of p.dependsOn) {
      edges.push({
        data: { id: `${p.id}->${dep}`, source: p.id, target: dep },
      });
    }
  }
  return [...nodes, ...edges];
}

function highlightNeighbourhood(node, on) {
  if (!cyInstance) return;
  if (on) {
    const neighbourhood = node.closedNeighborhood();
    cyInstance.elements().difference(neighbourhood).addClass('faded');
    neighbourhood.connectedEdges().addClass('highlighted');
  } else {
    cyInstance.elements().removeClass('faded');
    cyInstance.elements().removeClass('highlighted');
  }
}

function onThemeChange() {
  if (!cyInstance) return;
  cyInstance.style(cytoscapeStyle()).update();
}

// ─── Detail panel ──────────────────────────────────────────────
export async function openProviderDetail(id) {
  const data = await loadData();
  const provider = data.providers.find((p) => p.id === id);
  if (!provider) return;
  const consumedBy = data.providers
    .filter((p) => p.dependsOn.includes(id))
    .map((p) => p.id);
  openSidePanel(renderDetail(provider, consumedBy, data));
}

function renderDetail(p, consumedBy, data) {
  const kindHint = data.kinds[p.kind] || {};
  const groupName = data.groups[p.group] || p.group;

  const depsList = p.dependsOn
    .map((d) => `<a class="detail-link" href="#/providers/${escapeHtml(d)}">${escapeHtml(d)}</a>`)
    .join('') || '<span class="detail-empty">Žádné — root provider.</span>';

  const consumedList = consumedBy.length
    ? consumedBy.map((c) => `<a class="detail-link" href="#/providers/${escapeHtml(c)}">${escapeHtml(c)}</a>`).join('')
    : '<span class="detail-empty">Žádný downstream provider.</span>';

  const featureLink = p.feature && p.feature !== 'core'
    ? `<a class="detail-link" href="#/features/${escapeHtml(p.feature)}">${escapeHtml(p.feature)}</a>`
    : `<span class="detail-empty">${escapeHtml(p.feature || '—')}</span>`;

  return `
    <span class="detail-eyebrow">${escapeHtml(groupName)}</span>
    <h2 class="detail-title">${escapeHtml(p.displayName)}</h2>
    <p class="detail-id">${escapeHtml(p.id)}${p.eager ? ' · <strong style="color: var(--color-warning)">eager</strong>' : ''}</p>
    <p class="detail-summary">${escapeHtml(p.summary)}</p>

    <div class="detail-section">
      <h3>Kind</h3>
      <p><code>${escapeHtml(p.kind)}</code> — ${escapeHtml(kindHint.hint || '')}</p>
    </div>

    <div class="detail-section">
      <h3>Soubor</h3>
      <p><code>${escapeHtml(p.file)}</code></p>
    </div>

    <div class="detail-section">
      <h3>Feature</h3>
      <div>${featureLink}</div>
    </div>

    <div class="detail-section">
      <h3>Závisí na (upstream)</h3>
      <div>${depsList}</div>
    </div>

    <div class="detail-section">
      <h3>Konzumováno (downstream)</h3>
      <div>${consumedList}</div>
    </div>
  `;
}
