/* Only extracts usage numbers and billing dates; never credentials or subscription links. */
(function (root) {
  const quantity = /([0-9]+(?:,[0-9]{3})*(?:\.[0-9]+)?)\s*(TB|GB|MB|KB|B)\b/i;
  const usedLabel = /已使用流量|已用流量/;
  const leftLabel = /未使用流量|剩余流量/;
  function amount(text) {
    const m = text.match(quantity);
    if (!m) throw new Error('流量数值缺失');
    if (/[-−]\s*$/.test(text.slice(0, m.index))) throw new Error('流量数值无效');
    if (text.match(new RegExp(quantity.source, 'ig')).length !== 1) throw new Error('流量数值无效');
    const n = Number(m[1].replace(/,/g, ''));
    const scale = {TB: 1000, GB: 1, MB: 0.001, KB: 0.000001, B: 0.000000001};
    const value = n * scale[m[2].toUpperCase()];
    if (!Number.isFinite(value) || value < 0 || value > 1e9) throw new Error('流量数值无效');
    return value;
  }
  function date(text) {
    const parts = text.split(/[.\/-]/).map(Number);
    const [y, m, d] = parts;
    const dt = new Date(Date.UTC(y, m - 1, d));
    if (dt.getUTCFullYear() !== y || dt.getUTCMonth() !== m - 1 || dt.getUTCDate() !== d) throw new Error('流量周期无效');
    return `${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
  }
  function parseRows(rows, allText, now = Date.now()) {
    function rowValue(label, other) {
      const candidates = rows.map(x => x.replace(/\s+/g, ' ').trim())
        .filter(x => label.test(x) && !other.test(x) && quantity.test(x))
        .sort((a, b) => a.length - b.length);
      if (!candidates.length) throw new Error('没有读到流量，请在账户窗口登录机场页面');
      return amount(candidates[0]);
    }
    const usedGB = rowValue(usedLabel, leftLabel);
    const remainingGB = rowValue(leftLabel, usedLabel);
    const cycle = allText.match(/(20\d{2}[.\/-]\d{1,2}[.\/-]\d{1,2})\s*[~～—–至]\s*(20\d{2}[.\/-]\d{1,2}[.\/-]\d{1,2})/);
    if (!cycle || usedGB + remainingGB <= 0) throw new Error('没有读到有效流量周期');
    const cycleStart = date(cycle[1]), cycleEnd = date(cycle[2]);
    if (cycleEnd <= cycleStart) throw new Error('流量周期无效');
    return {usedGB, remainingGB, cycleStart, cycleEnd, capturedAt: new Date(now).toISOString()};
  }
  function parseDocument(doc) {
    const rows = [...doc.querySelectorAll('li, tr, div, section, td')]
      .map(el => el.textContent || '').filter(x => x.length < 600);
    const text = doc.body?.textContent || '';
    if (/Just a moment|Verify you are human|Checking your browser/i.test(doc.title || '')) throw new Error('站点需要验证，请打开机场页面完成验证');
    return parseRows(rows, text);
  }
  root.TrafficParser = {parseRows, parseDocument};
  if (typeof module !== 'undefined') module.exports = root.TrafficParser;
})(globalThis);
