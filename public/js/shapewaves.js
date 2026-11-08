/**
 * ShapeWaves - Canvas & WebGL Animated Wave Grid
 * Source: @react-bits/ShapeWaves-JS-CSS (React Bits)
 */

(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    define([], factory);
  } else if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.initShapeWaves = factory();
  }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  // 2D Simplex / Perlin Noise implementation
  const F3 = 1.0 / 3.0, G3 = 1.0 / 6.0;
  const p = new Uint8Array(256);
  for (let i = 0; i < 256; i++) p[i] = Math.floor(Math.random() * 256);
  const perm = new Uint8Array(512), permMod12 = new Uint8Array(512);
  for (let i = 0; i < 512; i++) {
    perm[i] = p[i & 255];
    permMod12[i] = perm[i] % 12;
  }
  const grad3 = [
    [1,1,0],[-1,1,0],[1,-1,0],[-1,-1,0],
    [1,0,1],[-1,0,1],[1,0,-1],[-1,0,-1],
    [0,1,1],[0,-1,1],[0,1,-1],[0,-1,-1]
  ];

  function simplex3(xin, yin, zin) {
    let n0, n1, n2, n3;
    const s = (xin + yin + zin) * F3;
    const i = Math.floor(xin + s), j = Math.floor(yin + s), k = Math.floor(zin + s);
    const t = (i + j + k) * G3;
    const X0 = i - t, Y0 = j - t, Z0 = k - t;
    const x0 = xin - X0, y0 = yin - Y0, z0 = zin - Z0;
    let i1, j1, k1, i2, j2, k2;
    if (x0 >= y0) {
      if (y0 >= z0) { i1=1; j1=0; k1=0; i2=1; j2=1; k2=0; }
      else if (x0 >= z0) { i1=1; j1=0; k1=0; i2=1; j2=0; k2=1; }
      else { i1=0; j1=0; k1=1; i2=1; j2=0; k2=1; }
    } else {
      if (y0 < z0) { i1=0; j1=0; k1=1; i2=0; j2=1; k2=1; }
      else if (x0 < z0) { i1=0; j1=1; k1=0; i2=0; j2=1; k2=1; }
      else { i1=0; j1=1; k1=0; i2=1; j2=1; k2=0; }
    }
    const x1 = x0 - i1 + G3, y1 = y0 - j1 + G3, z1 = z0 - k1 + G3;
    const x2 = x0 - i2 + 2.0*G3, y2 = y0 - j2 + 2.0*G3, z2 = z0 - k2 + 2.0*G3;
    const x3 = x0 - 1.0 + 3.0*G3, y3 = y0 - 1.0 + 3.0*G3, z3 = z0 - 1.0 + 3.0*G3;
    const ii = i & 255, jj = j & 255, kk = k & 255;
    
    let t0 = 0.6 - x0*x0 - y0*y0 - z0*z0;
    if (t0 < 0) n0 = 0.0;
    else {
      const g = grad3[permMod12[ii + perm[jj + perm[kk]]]];
      t0 *= t0;
      n0 = t0 * t0 * (g[0]*x0 + g[1]*y0 + g[2]*z0);
    }
    let t1 = 0.6 - x1*x1 - y1*y1 - z1*z1;
    if (t1 < 0) n1 = 0.0;
    else {
      const g = grad3[permMod12[ii + i1 + perm[jj + j1 + perm[kk + k1]]]];
      t1 *= t1;
      n1 = t1 * t1 * (g[0]*x1 + g[1]*y1 + g[2]*z1);
    }
    let t2 = 0.6 - x2*x2 - y2*y2 - z2*z2;
    if (t2 < 0) n2 = 0.0;
    else {
      const g = grad3[permMod12[ii + i2 + perm[jj + j2 + perm[kk + k2]]]];
      t2 *= t2;
      n2 = t2 * t2 * (g[0]*x2 + g[1]*y2 + g[2]*z2);
    }
    let t3 = 0.6 - x3*x3 - y3*y3 - z3*z3;
    if (t3 < 0) n3 = 0.0;
    else {
      const g = grad3[permMod12[ii + 1 + perm[jj + 1 + perm[kk + 1]]]];
      t3 *= t3;
      n3 = t3 * t3 * (g[0]*x3 + g[1]*y3 + g[2]*z3);
    }
    return 32.0 * (n0 + n1 + n2 + n3);
  }

  function fbm(x, y, z) {
    let total = 0, amplitude = 1, frequency = 1, maxAmp = 0;
    for (let i = 0; i < 2; i++) {
      total += amplitude * simplex3(x * frequency, y * frequency, z * frequency);
      maxAmp += amplitude;
      amplitude *= 0.5;
      frequency *= 2.0;
    }
    return total / maxAmp;
  }

  function parseHex(hex) {
    hex = hex.replace('#', '');
    if (hex.length === 3) hex = hex.split('').map(c => c + c).join('');
    const num = parseInt(hex, 16);
    return [(num >> 16) & 255, (num >> 8) & 255, num & 255];
  }

  function initShapeWaves(container, options = {}) {
    if (!container) return null;

    const canvas = document.createElement('canvas');
    canvas.className = 'shape-waves__canvas';
    canvas.style.position = 'absolute';
    canvas.style.inset = '0';
    canvas.style.width = '100%';
    canvas.style.height = '100%';
    canvas.style.display = 'block';
    container.appendChild(canvas);

    const ctx = canvas.getContext('2d');
    if (!ctx) return null;

    const opt = {
      text: options.text || '</>',
      fontFamily: options.fontFamily || 'Geist, "Geist Sans", system-ui, sans-serif',
      fontWeight: options.fontWeight || 500,
      textSize: options.textSize ?? 0.6,
      shapes: options.shapes || 'mixed',
      cellSize: Math.max(4, options.cellSize ?? 10),
      dotSize: options.dotSize ?? 0.75,
      color: options.color || '#929292',
      hoverColor: options.hoverColor || '#ffffff',
      backgroundColor: options.backgroundColor || '#120f17',
      speed: options.speed ?? 1,
      scale: options.scale ?? 1,
      contrast: options.contrast ?? 1,
      brightness: options.brightness ?? 0.4,
      flow: options.flow ?? 0,
      direction: options.direction ?? 0,
      fade: options.fade ?? 0.25,
      interactive: options.interactive ?? true,
      splashRadius: options.splashRadius ?? 40,
      splashStrength: options.splashStrength ?? 0.4,
      glow: options.glow ?? 0.35,
      intro: options.intro ?? true,
      introDuration: options.introDuration ?? 1.6,
      paused: options.paused ?? false
    };

    const colorRGB = parseHex(opt.color);
    const hoverRGB = parseHex(opt.hoverColor);
    const bgRGB = parseHex(opt.backgroundColor);

    let width = 0, height = 0, dpr = 1;
    let cols = 0, rows = 0;
    let heights = new Float32Array(0);
    let charges = new Float32Array(0);
    let maskData = null;
    let maskW = 0, maskH = 0;

    // Offscreen mask canvas for text
    const maskCanvas = document.createElement('canvas');
    const maskCtx = maskCanvas.getContext('2d', { willReadFrequently: true });

    function updateMask() {
      if (!opt.text) {
        maskData = null;
        return;
      }
      maskW = Math.max(1, cols);
      maskH = Math.max(1, rows);
      maskCanvas.width = maskW;
      maskCanvas.height = maskH;

      maskCtx.clearRect(0, 0, maskW, maskH);
      maskCtx.fillStyle = '#ffffff';
      maskCtx.textAlign = 'center';
      maskCtx.textBaseline = 'middle';
      const fontSize = Math.round(maskH * opt.textSize);
      maskCtx.font = `${opt.fontWeight} ${fontSize}px ${opt.fontFamily}`;
      maskCtx.fillText(opt.text, maskW / 2, maskH / 2);

      try {
        const img = maskCtx.getImageData(0, 0, maskW, maskH);
        maskData = img.data;
      } catch (e) {
        maskData = null;
      }
    }

    function resize() {
      const rect = container.getBoundingClientRect();
      dpr = Math.min(window.devicePixelRatio || 1, 2);
      width = Math.max(1, Math.round(rect.width));
      height = Math.max(1, Math.round(rect.height));

      canvas.width = Math.round(width * dpr);
      canvas.height = Math.round(height * dpr);

      const cellPx = opt.cellSize * dpr;
      cols = Math.ceil(canvas.width / cellPx);
      rows = Math.ceil(canvas.height / cellPx);

      const total = cols * rows;
      if (heights.length !== total) {
        heights = new Float32Array(total);
        charges = new Float32Array(total);
      }
      updateMask();
    }

    function splash(x, y, strength) {
      if (cols <= 0 || rows <= 0) return;
      const cellPx = opt.cellSize * dpr;
      const sigma = Math.max(0.5, ((opt.splashRadius * dpr) / cellPx) * 0.5);
      const reach = Math.ceil(sigma * 2.5);
      const centerCol = (x * dpr) / cellPx;
      const centerRow = (y * dpr) / cellPx;

      const minRow = Math.max(0, Math.floor(centerRow - reach));
      const maxRow = Math.min(rows - 1, Math.ceil(centerRow + reach));
      const minCol = Math.max(0, Math.floor(centerCol - reach));
      const maxCol = Math.min(cols - 1, Math.ceil(centerCol + reach));

      for (let r = minRow; r <= maxRow; r++) {
        const dy = r - centerRow;
        for (let c = minCol; c <= maxCol; c++) {
          const dx = c - centerCol;
          const bump = strength * Math.exp(-(dx * dx + dy * dy) / (2 * sigma * sigma));
          const idx = r * cols + c;
          heights[idx] = Math.min(1.2, heights[idx] + bump);
        }
      }
    }

    const onPointerMove = (e) => {
      if (!opt.interactive) return;
      const rect = container.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      if (x >= 0 && y >= 0 && x <= rect.width && y <= rect.height) {
        splash(x, y, opt.splashStrength);
      }
    };
    window.addEventListener('pointermove', onPointerMove, { passive: true });

    let startTime = performance.now();
    let raf = 0;
    let running = true;

    function render(now) {
      if (!running) return;
      raf = requestAnimationFrame(render);
      if (opt.paused) return;

      const elapsed = (now - startTime) / 1000;
      const timeVal = elapsed * opt.speed * 0.4;
      const introProgress = opt.intro ? Math.min(1, elapsed / opt.introDuration) : 1;

      const cellPx = opt.cellSize * dpr;
      const dotRadius = (cellPx * 0.5 * opt.dotSize);

      ctx.save();
      ctx.fillStyle = opt.backgroundColor;
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      const fieldScale = (320 * dpr) / Math.max(0.05, opt.scale);
      const centerX = cols / 2;
      const centerY = rows / 2;
      const maxDist = Math.hypot(centerX, centerY);

      for (let r = 0; r < rows; r++) {
        for (let c = 0; c < cols; c++) {
          const idx = r * cols + c;

          // Wave propagation and charge dissipation
          heights[idx] *= 0.96;
          charges[idx] += (heights[idx] - charges[idx]) * 0.2;
          const charge = charges[idx];

          // Noise calculation
          const nx = (c * cellPx) / fieldScale;
          const ny = (r * cellPx) / fieldScale;
          const noise = fbm(nx, ny, timeVal);
          const tone = Math.min(1, Math.max(0, (noise * 0.5 + 0.5 - opt.brightness) * opt.contrast + 0.5));
          const band = Math.floor(Math.min(0.999, tone) * 3);
          const stepped = (band + Math.floor(Math.min(0.999, charge) * 3)) % 3;

          // Intro radial progress
          if (opt.intro && introProgress < 1) {
            const distFromCenter = Math.hypot(c - centerX, r - centerY) / maxDist;
            if (distFromCenter > introProgress * 1.25) continue;
          }

          // Check text mask
          let isMasked = false;
          if (maskData) {
            const mIdx = (r * maskW + c) * 4;
            if (maskData[mIdx] > 120) {
              isMasked = true;
            }
          }

          // Shape determination
          let shape = 2 - stepped; // 0=square, 1=circle, 2=triangle
          if (opt.shapes === 'squares') shape = 0;
          else if (opt.shapes === 'circles') shape = 1;
          else if (opt.shapes === 'triangles') shape = 2;

          // Color interpolation
          const t = Math.min(1, Math.max(0, charge + (isMasked ? 0.8 : 0)));
          const cr = Math.round(colorRGB[0] + (hoverRGB[0] - colorRGB[0]) * t);
          const cg = Math.round(colorRGB[1] + (hoverRGB[1] - colorRGB[1]) * t);
          const cb = Math.round(colorRGB[2] + (hoverRGB[2] - colorRGB[2]) * t);

          ctx.fillStyle = `rgb(${cr},${cg},${cb})`;

          const px = c * cellPx + cellPx * 0.5;
          const py = r * cellPx + cellPx * 0.5;
          const sz = dotRadius * (0.55 + stepped * 0.22 + (isMasked ? 0.35 : 0));

          if (shape === 1) {
            // Circle
            ctx.beginPath();
            ctx.arc(px, py, sz * 0.7, 0, Math.PI * 2);
            ctx.fill();
          } else if (shape === 0) {
            // Square
            ctx.fillRect(px - sz * 0.6, py - sz * 0.6, sz * 1.2, sz * 1.2);
          } else {
            // Triangle
            ctx.beginPath();
            ctx.moveTo(px, py - sz * 0.7);
            ctx.lineTo(px + sz * 0.65, py + sz * 0.55);
            ctx.lineTo(px - sz * 0.65, py + sz * 0.55);
            ctx.closePath();
            ctx.fill();
          }
        }
      }

      ctx.restore();
    }

    const ro = new ResizeObserver(resize);
    ro.observe(container);
    resize();
    raf = requestAnimationFrame(render);

    return {
      destroy: () => {
        running = false;
        cancelAnimationFrame(raf);
        ro.disconnect();
        window.removeEventListener('pointermove', onPointerMove);
        canvas.remove();
      },
      splash
    };
  }

  return initShapeWaves;
});

