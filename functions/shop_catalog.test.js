const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { SHOP_CATALOG, quotePurchase } = require('./shop_catalog');

test('bundle charges only missing components with a 20 percent discount', () => {
  assert.equal(quotePurchase('skin_ninja', []).price, 200);
  assert.equal(quotePurchase('skin_ninja', ['clothing_ninja']).price, 80);
  assert.equal(quotePurchase('skin_ninja', ['accessory_ninja']).price, 120);
  assert.equal(quotePurchase('skin_ninja', ['clothing_ninja', 'accessory_ninja']).price, 0);
});
test('bundle purchase grants components and repeated purchase is free', () => {
  const first = quotePurchase('skin_ninja', []);
  assert.ok(first.granted.includes('clothing_ninja'));
  assert.ok(first.granted.includes('accessory_ninja'));
  assert.equal(quotePurchase('skin_ninja', first.granted).price, 0);
});
test('legacy bundle owners already own its separate parts', () => {
  assert.equal(quotePurchase('accessory_ninja', ['skin_ninja']).price, 0);
  assert.equal(quotePurchase('clothing_genie', ['accessory_genie_set']).price, 0);
  assert.equal(quotePurchase('accessory_perm_glasses', ['skin_perm']).price, 0);
});
test('Dart and Functions catalog IDs, prices and bundle members agree', () => {
  const dart = fs.readFileSync(path.join(__dirname, '../lib/data/shop_data.dart'), 'utf8');
  const entries = [...dart.matchAll(/ShopItem\(\s*id:\s*'([^']+)'([\s\S]*?)\n\s*\),/g)];
  assert.equal(entries.length, Object.keys(SHOP_CATALOG).length);
  for (const [,id,body] of entries) {
    assert.equal(Number(body.match(/price:\s*(\d+)/)[1]), SHOP_CATALOG[id].price, id);
    const members = body.match(/componentIds:\s*\[([^\]]*)\]/)?.[1] || '';
    assert.deepEqual([...members.matchAll(/'([^']+)'/g)].map(m => m[1]), SHOP_CATALOG[id].componentIds || [], id);
  }
});
