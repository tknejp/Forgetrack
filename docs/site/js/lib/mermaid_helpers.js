// Mermaid wrapper — theme-aware init + render helper.
// Mermaid uses inline SVG IDs, takže každý render volá s unique ID.
// Po render() (úspěch i error) odklízíme orphan DOM elementy, které
// Mermaid v body zanechá při parse erroru — bombs by jinak visely
// napříč view-switchi.

const ORPHAN_SELECTOR = ':scope > [id^="dmermaid_"], :scope > [id^="mermaid_"]';

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
      // Class diagramy mohou mít hodně potomků — necháme natural width
      // a spoléháme na overflow-x v containeru. Lépe čitelné než scale-down.
      class: { useMaxWidth: false },
    });
    initialized = theme;
  }
}

/** Odstraní temp DOM elementy, které Mermaid zanechá v body při parse erroru. */
export function cleanupMermaidOrphans() {
  document.body.querySelectorAll(ORPHAN_SELECTOR).forEach((el) => el.remove());
}

export async function renderMermaid(definition) {
  ensureInit();
  const id = `mermaid_${++counter}_${Date.now()}`;
  try {
    const { svg } = await window.mermaid.render(id, definition);
    return svg;
  } catch (err) {
    return `<div class="mermaid-error">Chyba renderování diagramu: ${String(err.message || err)}</div>`;
  } finally {
    cleanupMermaidOrphans();
  }
}

export function resetMermaidTheme() {
  initialized = false;
}
