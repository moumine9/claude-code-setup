// Decodes the JSON that chrome-devtools evaluate_script saved with `filePath`
// ({ bytes, b64 } wrapped in tool text) into a .webm file.
// Usage: node decode-b64.mjs <saved.json> <out.webm>
import { readFileSync, writeFileSync } from 'node:fs';
const [, , input, output] = process.argv;
const raw = readFileSync(input, 'utf8');
const o = JSON.parse(raw.slice(raw.indexOf('{'), raw.lastIndexOf('}') + 1));
writeFileSync(output, Buffer.from(o.b64, 'base64'));
console.log(o.bytes, 'bytes ->', output);
