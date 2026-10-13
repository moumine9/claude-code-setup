// MediaRecorder writes WebM files without a Duration element, so players cannot seek
// and show no total length. This inserts Segment > Info > Duration (float64, ms).
// Usage: node fix-duration.mjs <in.webm> <out.webm> <durationMs>
// Read durationMs by loading the raw file in Chrome, setting video.currentTime = 1e9 and reading video.duration.
import { readFileSync, writeFileSync } from 'node:fs';
const [, , input, output, durationMs] = process.argv;
const buf = readFileSync(input);
// read an EBML variable-length integer at offset
const vint = (o, keepMarker) => { const b = buf[o]; let len = 1, mask = 0x80; while (!(b & mask)) { len++; mask >>= 1; } let v = keepMarker ? b : b & (mask - 1); for (let i = 1; i < len; i++) v = v * 256 + buf[o + i]; return { len, v }; };
const find = (id, from, to) => { let o = from; while (o < to) { const i = vint(o, true); const s = vint(o + i.len); if (i.v === id) return { o, idLen: i.len, sizeLen: s.len, size: s.v, data: o + i.len + s.len }; const unknown = s.v === 2 ** (7 * s.len) - 1; o = unknown ? o + i.len + s.len : o + i.len + s.len + s.v; } return null; };
const ebml = find(0x1a45dfa3, 0, buf.length);
const seg = find(0x18538067, ebml.data + ebml.size, buf.length);
const info = find(0x1549a966, seg.data, buf.length);
if (find(0x4489, info.data, info.data + info.size)) throw new Error('Duration already present');
const dur = Buffer.alloc(11); dur[0] = 0x44; dur[1] = 0x89; dur[2] = 0x88; dur.writeDoubleBE(Number(durationMs), 3);
const newSize = info.size + dur.length;
const sizeVint = Buffer.alloc(8); sizeVint[0] = 0x01; sizeVint.writeUIntBE(newSize, 2, 6);
const out = Buffer.concat([buf.subarray(0, info.o + info.idLen), sizeVint, buf.subarray(info.data, info.data + info.size), dur, buf.subarray(info.data + info.size)]);
writeFileSync(output, out);
console.log('info size', info.size, '->', newSize, 'bytes', buf.length, '->', out.length);
