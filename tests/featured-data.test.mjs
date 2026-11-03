import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {illustrativeScore,industryView} from '../src/lab/data.js';
const source=JSON.parse(readFileSync('dist/assets/shiny/explorer.json','utf8'));
const preview=JSON.parse(readFileSync('dist/assets/lab/emissions.json','utf8'));
test('preview industry totals preserve all saved source flows',()=>{for(const [year,d] of Object.entries(source)){const totals={};for(const [industry,,kg]of d.flows)totals[industry]=(totals[industry]||0)+kg;assert.deepEqual(preview[year].industries,totals);assert.ok(Math.abs(industryView(preview[year]).total-preview[year].total)<1e-7);for(const f of preview[year].facilities){assert.ok(d.facilities.some(original=>original.name===f.name&&original.kg===f.kg&&original.lat===f.lat&&original.lng===f.lng));assert.ok(f.lat>=-90&&f.lat<=90&&f.lng>=-180&&f.lng<=180);}}});
test('industry filters use the same subset for quantities and facility points',()=>{const d=preview['2023/2024'];const view=industryView(d,'Manufacturing');assert.equal(view.total,d.industries.Manufacturing);assert.ok(view.facilities.every(f=>f.industry==='Manufacturing'));});
test('illustrative input sandbox is bounded and deterministic, not an estimator',()=>{assert.equal(illustrativeScore({alcohol:10.5,acidity:7,sulphates:.6}),5.605);for(const alcohol of [8,15])for(const acidity of [4,15])for(const sulphates of [.3,1.5]){const score=illustrativeScore({alcohol,acidity,sulphates});assert.ok(score>=0&&score<=10);}});
