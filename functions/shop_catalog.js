const { items, legacy } = require('./shop_catalog.json');
const SHOP_CATALOG = Object.fromEntries(items.map(item => [item.id, {
  ...item,
  kind: item.id === 'study_guard' ? 'studyGuard' : item.id === 'energy_pack' ? 'energyPack' : 'cosmetic',
  amount: item.id === 'energy_pack' ? 20 : undefined,
}]));
function quotePurchase(id, ownedIds) {
  const item = SHOP_CATALOG[id];
  if (!item) throw new Error('Unknown item');
  const ids = new Set(ownedIds);
  for (const owned of ownedIds) {
    for (const part of SHOP_CATALOG[owned]?.componentIds || []) ids.add(part);
    for (const part of legacy[owned] || []) ids.add(part);
  }
  const parts = item.componentIds || [];
  const owned = !!item.included || ids.has(id) || (parts.length > 0 && parts.every(p => ids.has(p)));
  const price = owned ? 0 : parts.length
    ? Math.ceil(parts.filter(p => !ids.has(p)).reduce((sum, p) => sum + SHOP_CATALOG[p].price, 0) * 80 / 100)
    : item.price;
  return { owned, price, granted: [...new Set([...ids, id, ...parts])] };
}
module.exports = { SHOP_CATALOG, quotePurchase };
