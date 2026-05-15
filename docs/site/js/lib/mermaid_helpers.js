// Mermaid wrapper — theme-aware init + render helper.
// Mermaid uses inline SVG IDs, takže každý render volá s unique ID.

let counter = 0;
let initialized = false;

function currentTheme() {
  return document.documentElement.getAttribute('data-theme') === 'light' ? 'default' : 'dark';
}

function ensureInit() {
  if (!window.mermaid) throw new Error('Mermaid se nenačetl (CDN).');
  // Re-init při změně tématu — Mermaid drží globální state pro theme.
  const theme = currentTheme();
  if (!initialized || initialized !== theme) {
    window.mermaid.initialize({
      startOnLoad: false,
      theme,
      fontFamily: 'Inter, system-ui, sans-serif',
      securityLevel: 'loose',
      sequence: { useMaxWidth: true, mirrorActors: false, showSequenceNumbers: false },
      flowchart: { curve: 'basis', useMaxWidth: true },
      class: { useMaxWidth: true },
    });
    initialized = theme;
  }
}

export async function renderMermaid(definition) {
  ensureInit();
  const id = `mermaid_${++counter}_${Date.now()}`;
  try {
    const { svg } = await window.mermaid.render(id, definition);
    return svg;
  } catch (err) {
    return `<div class="mermaid-error">Chyba renderování diagramu: ${String(err.message || err)}</div>`;
  }
}

export function resetMermaidTheme() {
  initialized = false;
}
