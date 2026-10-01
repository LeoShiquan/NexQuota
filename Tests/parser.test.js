const assert = require('node:assert/strict');
const {parseRows} = require('../Resources/usage-parser.js');
let count = 0;
function test(name, fn) {fn(); count++; console.log(`PASS ${name}`);}
const cycle = '2026.10.01~2026.11.01 本月流量使用情况';
const sample = ['125 GB 1 已使用流量', '375GB 2 未使用流量'];
test('读取演示网页展示的数值顺序', () => {
  const x = parseRows(sample, cycle, 1790899200000);
  assert.equal(x.usedGB, 125); assert.equal(x.remainingGB, 375);
  assert.equal(x.usedGB + x.remainingGB, 500);
  assert.equal(x.cycleStart, '2026-10-01'); assert.equal(x.cycleEnd, '2026-11-01');
});
test('支持数值在标签后方与换行', () => {assert.equal(parseRows(['已使用流量\n12.5 GB', '剩余流量 487.5 GB'], cycle).usedGB, 12.5);});
test('忽略同时包含两项的父容器', () => {assert.equal(parseRows([sample.join(' '), ...sample], cycle).remainingGB, 375);});
test('支持千位分隔与单位换算', () => {const x = parseRows(['已使用流量 1,500 MB','未使用流量 1 TB'], cycle); assert.equal(x.usedGB, 1.5); assert.equal(x.remainingGB, 1000);});
test('零用量可用', () => {assert.equal(parseRows(['已使用流量 0 GB', '未使用流量 500 GB'], cycle).usedGB, 0);});
test('流量耗尽可用', () => {assert.equal(parseRows(['已使用流量 500 GB', '未使用流量 0 GB'], cycle).remainingGB, 0);});
test('登录页面不能被误识别', () => {assert.throws(() => parseRows(['用户名','密码','登录'], ''), /没有读到/);});
test('缺少剩余不能产生部分结果', () => {assert.throws(() => parseRows([sample[0]], cycle));});
test('缺少周期不能产生结果', () => {assert.throws(() => parseRows(sample, ''));});
test('日期越界被拒绝', () => {assert.throws(() => parseRows(sample, '2026.02.30~2026.03.31'));});
test('倒序周期被拒绝', () => {assert.throws(() => parseRows(sample, '2026.11.01~2026.10.01'));});
test('空额度被拒绝', () => {assert.throws(() => parseRows(['已使用流量 0 GB', '未使用流量 0 GB'], cycle));});
test('不相关的节点数值不能代替流量', () => {assert.throws(() => parseRows(['已使用流量', '未使用流量', 'Hong Kong 76 GB'], cycle));});
test('负数被拒绝', () => {assert.throws(() => parseRows(['已使用流量 -1 GB', '未使用流量 500 GB'], cycle));});
test('同一行多个流量值被拒绝', () => {assert.throws(() => parseRows(['已使用流量 1 GB 5 GB', '未使用流量 500 GB'], cycle));});
console.log(`${count} parser tests passed`);
