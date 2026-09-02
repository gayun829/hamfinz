/**
 * Firestore Rules 배포 (gcloud access token).
 *
 *   node scripts/deploy_firestore_rules.mjs              # 개발 (firestore.rules)
 *   node scripts/deploy_firestore_rules.mjs --production # 프로덕션 (firestore.rules.production)
 */
import { readFileSync } from 'node:fs';
import { execSync } from 'node:child_process';

const production = process.argv.includes('--production');
const rulesPath = production ? 'firestore.rules.production' : 'firestore.rules';
const projectId = 'hamfins-719b8';
const rules = readFileSync(rulesPath, 'utf8');
const token = execSync('gcloud auth print-access-token', { encoding: 'utf8' }).trim();

const createRes = await fetch(
  `https://firebaserules.googleapis.com/v1/projects/${projectId}/rulesets`,
  {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      'x-goog-user-project': projectId,
    },
    body: JSON.stringify({
      source: {
        files: [{ name: 'firestore.rules', content: rules }],
      },
    }),
  },
);

if (!createRes.ok) {
  console.error('ruleset create failed:', createRes.status, await createRes.text());
  process.exit(1);
}

const ruleset = await createRes.json();
console.log('ruleset:', ruleset.name);

const releaseRes = await fetch(
  `https://firebaserules.googleapis.com/v1/projects/${projectId}/releases/cloud.firestore`,
  {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      'x-goog-user-project': projectId,
    },
    body: JSON.stringify({
      release: {
        name: `projects/${projectId}/releases/cloud.firestore`,
        rulesetName: ruleset.name,
      },
    }),
  },
);

if (!releaseRes.ok) {
  console.error('release failed:', releaseRes.status, await releaseRes.text());
  process.exit(1);
}

const release = await releaseRes.json();
console.log(`OK: cloud.firestore (${production ? 'production' : 'development'}) ->`, release.rulesetName);
