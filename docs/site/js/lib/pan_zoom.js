// svg-pan-zoom helper — wrappers s životním cyklem pro Mermaid SVGy.
// Class diagramy mají často moc tříd v řádce, aby se vešly do šířky containeru;
// pan+zoom umožní uživateli si je přečíst.

const instances = new Map();
const DEFAULT_HEIGHT = 520;

/**
 * Aplikuje svg-pan-zoom na SVG uvnitř hostElement. Idempotentní —
 * předchozí instance pro stejné key se destrojí. Vyžaduje, aby
 * svg-pan-zoom byl načtený (CDN).
 *
 * @param {HTMLElement} hostElement   container, který drží <svg>
 * @param {string} key                stabilní klíč (např. ID diagramu) pro destroy lifecycle
 * @param {object} [opts]
 * @param {number} [opts.height]      výška pan-zoom plátna v px
 */
export function enablePanZoom(hostElement, key, opts = {}) {
  if (!window.svgPanZoom) return null;
  const svg = hostElement.querySelector('svg');
  if (!svg) return null;

  // Zrušit starou instanci, pokud existuje (re-render po theme change apod.).
  destroyPanZoom(key);

  // svg-pan-zoom potřebuje SVG s pevnou velikostí. Mermaid svg má
  // viewBox; nastavíme width/height fixně, ať pan-zoom dostane bounded
  // canvas.
  const height = opts.height || DEFAULT_HEIGHT;
  svg.setAttribute('width', '100%');
  svg.setAttribute('height', String(height));
  svg.style.width = '100%';
  svg.style.height = `${height}px`;
  svg.style.maxWidth = 'none';
  svg.style.display = 'block';

  const instance = window.svgPanZoom(svg, {
    zoomEnabled: true,
    panEnabled: true,
    controlIconsEnabled: true,
    fit: true,
    center: true,
    minZoom: 0.4,
    maxZoom: 6,
    zoomScaleSensitivity: 0.25,
    contain: false,
  });

  instances.set(key, instance);
  return instance;
}

export function destroyPanZoom(key) {
  const inst = instances.get(key);
  if (inst) {
    try { inst.destroy(); } catch (_) { /* may be detached */ }
    instances.delete(key);
  }
}

export function destroyAllPanZoom() {
  for (const key of [...instances.keys()]) destroyPanZoom(key);
}
