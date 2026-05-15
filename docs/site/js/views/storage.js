// Storage view — Isar / Firestore / SharedPreferences / Secure / Firebase Storage.
// Strukturovaný přehled "co kde žije", bez grafu — card-style sekce.

import { fetchJson, openSidePanel, escapeHtml } from '../app.js';

let cache = null;
async function loadData() {
  if (cache) return cache;
  cache = await fetchJson('data/storage.json');
  return cache;
}

const BUCKET_ICON = {
  'local-typed': '🗄',
  'local-keyvalue': '🔑',
  'local-secure': '🔒',
  'cloud-document': '☁',
  'cloud-blob': '🖼',
};

export async function renderStorageView(main) {
  const data = await loadData();
  const totalStores = data.buckets.reduce((acc, b) => acc + b.stores.length, 0);

  main.innerHTML = `
    <div class="view-header">
      <h1 class="view-title">Úložiště</h1>
      <p class="view-subtitle">${data.buckets.length} typů úložiště · ${totalStores} stores. Klik na položku pro detail.</p>
    </div>
    ${data.buckets.map(renderBucket).join('')}
  `;

  main.querySelectorAll('[data-store-bucket]').forEach((card) => {
    card.addEventListener('click', () => {
      const bucketId = card.dataset.storeBucket;
      const storeId = card.dataset.storeId;
      window.location.hash = `#/storage/${bucketId}.${storeId}`;
    });
  });
}

function renderBucket(bucket) {
  return `
    <section class="group">
      <header class="group-header">
        <h2 class="group-name">${BUCKET_ICON[bucket.kind] || ''} ${escapeHtml(bucket.name)}</h2>
        <span class="group-count">${bucket.stores.length}</span>
      </header>
      <p class="bucket-summary">${escapeHtml(bucket.summary)}</p>
      <div class="feature-grid">
        ${bucket.stores.map((s) => renderStoreCard(s, bucket.id)).join('')}
      </div>
    </section>
  `;
}

function renderStoreCard(store, bucketId) {
  const meta = [];
  if (store.collections) meta.push(`${store.collections.length} kolekce`);
  if (store.path && !store.collections) meta.push('cesta');

  return `
    <button class="feature-tile" data-store-bucket="${escapeHtml(bucketId)}" data-store-id="${escapeHtml(store.id)}">
      <div class="feature-tile-name">${escapeHtml(store.name)}</div>
      ${store.path ? `<div class="feature-tile-id">${escapeHtml(store.path)}</div>` : ''}
      <div class="feature-tile-summary">${escapeHtml(store.role)}</div>
      ${meta.length ? `
        <div class="feature-tile-meta">
          ${meta.map((m) => `<span class="tag">${escapeHtml(m)}</span>`).join('')}
        </div>
      ` : ''}
    </button>
  `;
}

export async function openStorageDetail(compositeId) {
  const data = await loadData();
  const [bucketId, storeId] = compositeId.split('.');
  const bucket = data.buckets.find((b) => b.id === bucketId);
  if (!bucket) return;
  const store = bucket.stores.find((s) => s.id === storeId);
  if (!store) return;
  openSidePanel(renderStoreDetail(bucket, store));
}

function renderStoreDetail(bucket, store) {
  const collectionsList = (store.collections || [])
    .map((c) => `<li><strong>${escapeHtml(c.name)}</strong><br/><span class="detail-empty">${escapeHtml(c.purpose)}</span></li>`)
    .join('');

  const writers = (store.writers || []).map((w) => `<li><code>${escapeHtml(w)}</code></li>`).join('');
  const readers = (store.readers || []).map((r) => `<li><code>${escapeHtml(r)}</code></li>`).join('');

  return `
    <span class="detail-eyebrow">${escapeHtml(bucket.name)}</span>
    <h2 class="detail-title">${escapeHtml(store.name)}</h2>
    ${store.path ? `<p class="detail-id">${escapeHtml(store.path)}</p>` : ''}
    <p class="detail-summary">${escapeHtml(store.role)}</p>

    ${store.modelsPath ? `
      <div class="detail-section">
        <h3>Modely</h3>
        <p><code>${escapeHtml(store.modelsPath)}</code></p>
      </div>
    ` : ''}

    ${collectionsList ? `
      <div class="detail-section">
        <h3>Kolekce</h3>
        <ul class="detail-list">${collectionsList}</ul>
      </div>
    ` : ''}

    ${writers ? `
      <div class="detail-section">
        <h3>Zapisuje</h3>
        <ul class="detail-list">${writers}</ul>
      </div>
    ` : ''}

    ${readers ? `
      <div class="detail-section">
        <h3>Čte</h3>
        <ul class="detail-list">${readers}</ul>
      </div>
    ` : ''}
  `;
}
