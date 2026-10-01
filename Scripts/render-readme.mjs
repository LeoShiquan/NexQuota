import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const { marked } = await import(process.env.NEXQUOTA_MARKED_MODULE || 'marked');
const [source, output] = process.argv.slice(2);
if (!source || !output) throw new Error('Pass README path and output HTML path');
const content = marked.parse(await readFile(resolve(source), 'utf8'));
const css = `
:root{color-scheme:light;--ink:#1f2328;--muted:#59636e;--line:#d8dee4;--teal:#087d80}
*{box-sizing:border-box}body{margin:0;background:#f6f8fa;color:var(--ink);font:16px/1.65 -apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif}
.shell{max-width:1040px;margin:32px auto;border:1px solid var(--line);border-radius:12px;background:white;overflow:hidden}
.bar{padding:15px 28px;background:#f6f8fa;border-bottom:1px solid var(--line);display:flex;align-items:center;justify-content:space-between;gap:16px;font-size:14px}.bar strong{font-weight:650}.bar span{color:var(--muted)}
article{padding:30px 44px 38px}h1,h2,h3{line-height:1.3;font-weight:650;letter-spacing:-.025em}h1{font-size:34px;padding-bottom:14px;border-bottom:1px solid var(--line);margin:0 0 16px}h2{font-size:24px;padding-bottom:10px;border-bottom:1px solid var(--line);margin:34px 0 18px}h3{font-size:20px;margin:25px 0 12px}p{margin:14px 0}a{color:var(--teal);text-decoration:none}a:hover{text-decoration:underline}a:focus-visible{outline:3px solid var(--teal);outline-offset:3px}img{max-width:100%;height:auto}blockquote{margin:16px 0;padding:0 16px;border-left:4px solid #b9d7d5;color:var(--muted)}blockquote p{font-size:20px;margin:0}em{color:var(--muted);font-size:14px}table{border-collapse:collapse;max-width:100%;margin:18px 0;width:100%}td,th{border:1px solid var(--line);padding:10px 14px;text-align:left}th{background:#f6f8fa;font-weight:650}tr:nth-child(even){background:#fbfcfd}td img{display:block;border-radius:10px;max-width:100%}code{font:13px/1.6 ui-monospace,SFMono-Regular,Menlo,monospace;background:#eff1f3;border-radius:4px;padding:2px 5px;overflow-wrap:anywhere}pre{background:#f6f8fa;border:1px solid #e7ebef;border-radius:8px;padding:16px;overflow-x:auto}pre code{padding:0;background:transparent}li{margin:7px 0}ul,ol{padding-left:26px}strong{font-weight:650}.footer{border-top:1px solid var(--line);padding:16px 44px;font-size:13px;color:var(--muted)}
@media(max-width:700px){.shell{margin:12px}.bar{padding:12px 18px}.bar span{font-size:12px}article{padding:22px 20px}h1{font-size:29px}h2{font-size:22px}td,th{padding:8px}table{font-size:14px}.footer{padding:14px 20px}}
`;
await writeFile(resolve(output), `<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="referrer" content="no-referrer"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src file: data:; style-src 'unsafe-inline'; base-uri file:"><base href="../../"><title>NexQuota README 预览</title><style>${css}</style></head><body><main class="shell"><header class="bar"><strong>NexQuota / README.md</strong><span>本地文档预览 · 演示数据</span></header><article>${content}</article><footer class="footer">由仓库 README.md 生成 · 图像来自同一套原生视图 · 无真实账户信息</footer></main></body></html>`, 'utf8');
console.log('Generated README preview HTML');
