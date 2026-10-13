#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float n;          // bar count
    float maxHeight;  // px
    float alpha;      // Config.cava.opacity
    float fromBottom;     // 1 = anchored to fromBottom edge
    float renderType; // 0 curve, 1 bars, 2 blocks
    float smoothCurve;
    float drawFill;
    float drawStroke;
    float colorStyle; // 0 solid, 1 loudness, 2 gradient-v, 3 gradient-h
    float loudness;
    float peak;       // max normalised value letting empty pixels exit early
    vec2 res;
    vec4 colBase;
    vec4 colAlt;
    vec4 v0;
    vec4 v1;
    vec4 v2;
    vec4 v3;
    vec4 v4;
    vec4 v5;
    vec4 v6;
    vec4 v7;
    vec4 v8;
    vec4 v9;
    vec4 v10;
    vec4 v11;
    vec4 v12;
    vec4 v13;
    vec4 v14;
    vec4 v15;
    vec4 v16;
    vec4 v17;
    vec4 v18;
    vec4 v19;
    vec4 v20;
    vec4 v21;
    vec4 v22;
    vec4 v23;
    vec4 v24;
    vec4 v25;
};

vec4 V[26];
float val(int i) { return V[i >> 2][i & 3]; }

vec3 mixc(float t) { return mix(colBase.rgb, colAlt.rgb, clamp(t, 0.0, 1.0)); }
vec4 over(vec4 top, vec4 bot) { return top + bot * (1.0 - top.a); }
vec4 px(vec3 c, float a) { return vec4(c * a, a); }

// curve: (height px above the base edge, slope dy/dx) at screen x
vec2 curve(float x, int N) {
    float s = res.x / float(N - 1);
    float u = x / s;
    int i = clamp(int(floor(u + 0.5)), 0, N - 1);
    float yi = val(i) * maxHeight;
    if (smoothCurve < 0.5) {
        int j = clamp(u < float(i) ? i - 1 : i + 1, 0, N - 1);
        float yj = val(j) * maxHeight;
        return vec2(mix(yi, yj, abs(u - float(i))), (yj - yi) * float(j - i) / s);
    }
    float yp = (yi + val(max(i - 1, 0)) * maxHeight) * 0.5;
    float yn = (yi + val(min(i + 1, N - 1)) * maxHeight) * 0.5;
    float t = u - float(i) + 0.5;
    if (i == N - 1 && t < 0.5) return vec2(mix(yp, yi, 2.0 * t), 2.0 * (yi - yp) / s);
    float y = (1.0 - t) * (1.0 - t) * yp + 2.0 * t * (1.0 - t) * yi + t * t * yn;
    return vec2(y, (2.0 * (1.0 - t) * (yi - yp) + 2.0 * t * (yn - yi)) / s);
}

void main() {
    vec2 p = qt_TexCoord0 * res;
    float d = fromBottom > 0.5 ? res.y - p.y : p.y;
    int N = int(n);
    if (N < 2 || d > peak * maxHeight + 10.0) { fragColor = vec4(0.0); return; }
    V = vec4[26](v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,v16,v17,v18,v19,v20,v21,v22,v23,v24,v25);

    float strokeA = min(1.0, alpha * 2.5);
    vec4 acc = vec4(0.0);

    if (renderType < 0.5) {
        vec2 cy = curve(p.x, N);
        float e = cy.x - d;
        float g = sqrt(cy.y * cy.y + 1.0);
        if (drawFill > 0.5) {
            float cov = clamp(e / g + 0.5, 0.0, 1.0);
            vec3 c; float a;
            if (colorStyle > 2.5) {
                c = mixc(p.x / res.x); a = alpha;
            } else {
                float t = clamp(d / maxHeight, 0.0, 1.0);
                float tip = colorStyle < 0.5 ? 0.0 : alpha;
                vec3 endC = colorStyle < 0.5 ? colBase.rgb : colorStyle < 1.5 ? mix(colBase.rgb, colAlt.rgb, loudness) : colAlt.rgb;
                c = mix(colBase.rgb, endC, t); a = mix(alpha, tip, t);
            }
            acc = px(c, a * cov);
        }
        if (drawStroke > 0.5) {
            float cov = clamp(0.75 - abs(e) / g + 0.5, 0.0, 1.0);
            vec3 c = colorStyle > 2.5 ? mixc(p.x / res.x)
                   : colorStyle > 1.5 ? colAlt.rgb
                   : colorStyle > 0.5 ? mix(colBase.rgb, colAlt.rgb, loudness) : colBase.rgb;
            acc = over(px(c, strokeA * cov), acc);
        }
    } else {
        float spacing = 4.0;
        float bw = (res.x - spacing * float(N - 1)) / float(N);
        float pitch = bw + spacing;

        if (renderType < 1.5) {
            // bars
            int i = clamp(int(floor(p.x / pitch)), 0, N - 1);
            float pct = val(i);
            float h = pct * maxHeight;
            float x0 = float(i) * pitch;
            float inX = clamp(min(p.x - x0, x0 + bw - p.x) + 0.5, 0.0, 1.0);
            float inY = clamp(min(d, h - d) + 0.5, 0.0, 1.0);
            float cov = inX * inY;
            float t = h > 0.0 ? clamp(d / h, 0.0, 1.0) : 0.0;
            vec3 sC = colorStyle < 0.5 ? colBase.rgb : colorStyle < 1.5 ? mixc(pct) : colorStyle < 2.5 ? colBase.rgb : mixc(x0 / res.x);
            vec3 eC = colorStyle < 0.5 ? colBase.rgb : colorStyle < 1.5 ? mixc(pct) : colorStyle < 2.5 ? mixc(pct) : mixc(x0 / res.x);
            if (drawFill > 0.5 && h > 0.0) {
                vec3 c; float a;
                if (colorStyle > 1.5 && colorStyle < 2.5) {
                    c = mix(sC, eC, min(1.0, t / 0.65));
                    a = alpha * pow(1.0 - t, 1.3);
                } else {
                    c = mix(sC, eC, t);
                    a = alpha * (1.0 - t);
                }
                acc = px(c, a * cov);
            }
            if (drawStroke > 0.5 && h > 0.0) {
                float dx = min(p.x - x0, x0 + bw - p.x);
                float dy = min(d, h - d);
                float inside = dx >= -0.5 && dy >= -0.5 ? 1.0 : 0.0;
                float edge = min(dx, dy);
                float cv = inside * clamp(0.5 - abs(edge) + 0.5, 0.0, 1.0);
                acc = over(px(eC, strokeA * cv), acc);
            }
        } else {
            // blocks
            float bh = 6.0, gap = 2.0, bp = bh + gap;
            float maxBlocks = floor(maxHeight / bp);
            int i = clamp(int(floor(p.x / pitch)), 0, N - 1);
            float pct = val(i);
            float act = floor(pct * maxHeight / bp + 0.5);
            float x0 = float(i) * pitch;
            if (drawFill > 0.5) {
                float b = floor(d / bp);
                float inX = clamp(min(p.x - x0, x0 + bw - p.x) + 0.5, 0.0, 1.0);
                float inY = clamp(min(d - b * bp, b * bp + bh - d) + 0.5, 0.0, 1.0);
                if (b < act) {
                    vec3 c = colorStyle < 0.5 ? colBase.rgb
                           : colorStyle < 1.5 ? mixc(pct)
                           : colorStyle < 2.5 ? mixc(b / max(1.0, maxBlocks - 1.0))
                           : mixc(x0 / res.x);
                    float fall = (colorStyle > 1.5 && colorStyle < 2.5) ? 0.15 : 0.4;
                    acc = px(c, alpha * (1.0 - b / maxBlocks * fall) * inX * inY);
                }
            }
            if (drawStroke > 0.5) {
                int c = clamp(int(floor((p.x + spacing * 0.5) / pitch)), 0, N - 1);
                float cact = floor(val(c) * maxHeight / bp + 0.5);
                float pk = cact > 0.0 ? (cact - 1.0) * bp + bh : 0.0;
                float cov = clamp(0.75 - abs(d - pk) + 0.5, 0.0, 1.0);
                for (int k = 0; k < 2; k++) {
                    int nb = c + (k == 0 ? -1 : 1);
                    if (nb < 0 || nb >= N) continue;
                    float bx = (k == 0 ? float(c) : float(c + 1)) * pitch - spacing * 0.5;
                    float nact = floor(val(nb) * maxHeight / bp + 0.5);
                    float npk = nact > 0.0 ? (nact - 1.0) * bp + bh : 0.0;
                    float lo = min(pk, npk) - 0.75, hi = max(pk, npk) + 0.75;
                    if (d >= lo && d <= hi)
                        cov = max(cov, clamp(0.75 - abs(p.x - bx) + 0.5, 0.0, 1.0));
                }
                vec3 sc = colorStyle > 2.5 ? mixc(p.x / res.x)
                        : colorStyle > 0.5 && colorStyle < 1.5 ? mix(colBase.rgb, colAlt.rgb, loudness) : colBase.rgb;
                acc = over(px(sc, strokeA * cov), acc);
            }
        }
    }
    fragColor = acc * qt_Opacity;
}
