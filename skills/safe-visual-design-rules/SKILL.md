---
name: safe-visual-design-rules
description: A checklist of low-risk visual design defaults (colour, contrast, typography, spacing, depth) for UI work, adapted from Anthony Hobday's "Visual design rules you can safely follow every time". Use this whenever building, restyling, or reviewing any user interface — landing pages, components, dashboards, design systems, CSS/Tailwind work — or when the user says something looks "off", "cheap", "AI-generated", or asks to make it look better, even if they never say the word "design".
---

# Safe visual design rules

A set of defaults that make interfaces look intentional rather than assembled. They are not laws — break any of them with a reason. But when there's no reason to deviate, following them is always safer than guessing.

Source: Anthony Hobday, *Visual design rules you can safely follow every time* — https://anthonyhobday.com/sideprojects/saferules/ (rules paraphrased here; read the original for side-by-side visual examples).

## How to use this skill

**When building new UI:** decide the colour ramp, spacing scale, and type scale *before* writing components. Most violations below come from picking values ad hoc per component.

**When reviewing or fixing existing UI:** walk the checklist at the bottom. Report violations with the specific element and the corrected value, not vague advice like "improve the contrast".

**The meta-rule:** every value in the design should be explainable. Whitespace, alignment, size, colour, shadow — if someone points at any part of it and asks "why is it like that?", there should be an answer. Values chosen because they were the editor's default are the main source of designs that feel incoherent. When unsure what to be deliberate about, treat this list as the prompt.

---

## Colour

**Avoid pure black and pure white.** `#000` contrasts uncomfortably hard against everything, and `#fff` is glaring. Use near-black and near-white instead (e.g. `#121212`, `#FAFAF9`). Every mention of "black" and "white" below assumes this.

**Tint the neutrals.** If the interface uses an accent colour, mix a trace of that hue into the greys, blacks, and whites — under about 5% saturation in HSB. Untinted greys next to a saturated brand colour are what makes a palette feel like unrelated parts.

**Pick warm or cool, not both.** Once tinting neutrals, keep the whole set on one side. A warm background with cool foreground greys reads as a mistake rather than a choice.

**Give palette colours distinct brightness values.** Colours that differ only in hue compete with each other. Varying brightness lets them coexist and gives a natural hierarchy.

**Reserve high contrast for things that must be noticed** — primary buttons, content, calls to action. Structural elements (dividers, container edges, shadows, decorative rules) should use as little contrast as they can get away with. Contrast is an attention budget; spending it on a divider means the button gets less.

**Lower the contrast of icons paired with text.** An icon at the same colour as its label will look heavier than the label. Drop its opacity or lighten/darken its colour so the pair balances.

**Closer means lighter.** Elements nearer the user (modals, popovers, raised cards) should be lighter than what sits behind them. This holds in dark mode too — it matches how light works in the physical world, so inverting it feels subtly wrong.

**Keep container/background brightness within limits.** The HSB brightness difference between a container and the background it sits on should stay within ~12% on dark interfaces and ~7% on light ones. Bigger jumps make cards look pasted on.

**Container borders must contrast with both sides.** A card border should be lighter than *both* the card and the page behind it (or darker than both), never a value in between. A border set halfway between the two colours blurs the edge instead of defining it.

---

## Typography

**Body text at 16px or above.** That's the browser default for a reason; below it, reading gets measurably harder. Use `rem`/`em` equivalents if preferred. Larger is generally easier.

**Line length around 70 characters.** Anywhere in 60–80 is fine. Much wider and the eye loses the line return; much narrower and reading gets choppy. In CSS: `max-width: 65ch` or similar.

**Scale letter-spacing and line-height inversely with size.** Big text needs tighter tracking and tighter leading; small text needs looser. Display text at default tracking looks spread out; small text at default leading looks cramped.

Typical starting points:

| Size | Letter-spacing | Line-height |
|---|---|---|
| 48px+ (display) | −0.02em to −0.03em | 1.05–1.15 |
| 24–36px (headings) | −0.01em | 1.2–1.3 |
| 16–18px (body) | 0 | 1.5–1.6 |
| 12–14px (captions) | +0.01em to +0.02em | 1.4–1.5 |

**Two typefaces at most.** A second face can reinforce the concept and add variety. A third rarely earns its place and usually just looks unresolved. Weight, size, and colour give plenty of variation within one family.

---

## Layout, alignment, and spacing

**Everything should align with something else.** Alignment is how the eye infers relationship. An element aligned with nothing looks like it doesn't belong. Each element's position should be justifiable by what it lines up with.

**Prefer optical alignment over mathematical alignment.** Design tools centre by bounding box, but some shapes — play triangles, glyphs with overhang, icons with uneven mass — have a visual centre elsewhere. Nudge by eye until it looks centred, even if the numbers say otherwise. This applies constantly to icons inside circular buttons.

**Relate all measurements mathematically.** Spacing and sizes should come from one scale rather than being typed in per component. A base of 8 (4, 8, 16, 24, 32, 48, 64…) is a safe default. Define it as tokens up front and use only those values.

**Use 12 columns for a horizontal grid.** 12 divides cleanly into 1, 2, 3, 4, and 6, which covers nearly every layout that comes up.

**Measure spacing between points of high contrast.** The eye finds edges by contrast, so spacing should run contrast-point to contrast-point — not element bounding box to element bounding box. If a paragraph sits inside a dark section on a light page, the gap runs from the previous paragraph to the *section edge*, then from the section edge to the paragraph, not straight between the two paragraphs.

**Outer padding ≥ inner padding.** Inside a container, the gap between the contents and the container edge should be at least as large as the gaps between the contents themselves. Things that are more closely related belong closer together, and items inside a card are more related to each other than to the card.

**Buttons: horizontal padding twice the vertical.** The recognisable button shape is wider than it is tall — e.g. 12px top/bottom with 24px left/right. Following the pattern is what makes it read as a button at a glance.

**Nest corner radii properly.** Inner radius = outer radius − the gap between them. A 16px outer radius with 8px padding gives an 8px inner radius. Mismatched nesting makes the gap look uneven even when it's uniform.

**Order elements by visual weight.** In a row or column of mixed-weight items (a solid button, an outline button, a text link), arrange them in weight order rather than at random, with the heaviest element on the outside edge. Right-aligned in a footer, the heaviest goes rightmost.

---

## Depth and surfaces

**Shadow blur = 2× the Y distance.** A shadow offset 4px down gets 8px of blur. As an element rises toward the viewer, also reduce shadow opacity — real shadows get softer and fainter as the object nears the light.

**No shadows on dark interfaces.** Either the background must be light enough to reveal the shadow, or the shadow must be hard enough to be conspicuous — both cost more attention than depth is worth. Use lighter surface colours for elevation instead (which is also the "closer is lighter" rule).

**Don't mix depth techniques.** Pick one — soft shadows, hard offset shadows, borders, or elevation-by-lightness — and keep it consistent. Any one of them is fine; switching between them mid-interface is what looks unprofessional.

**Don't put two hard divides next to each other.** Background transitions, container edges, and rules each create a hard visual divide. Stacked, they create clutter and pull the eye to something unimportant. If a card edge already divides, drop the background change or the border there.

**Simple on complex, or complex on simple.** Rich backgrounds (gradients, photos, patterns) want plain foregrounds, and detailed foregrounds want plain backgrounds. Simple on simple is safe but flat. Complex on complex is hard to pull off and usually just reads as noise.

---

## Review checklist

Run this over any interface before calling it done. Cite the element and the fix for each violation.

- [ ] No pure `#000` or `#fff`
- [ ] Neutrals tinted with the accent hue, all warm or all cool
- [ ] Palette colours differ in brightness, not only hue
- [ ] High contrast only where attention is wanted; dividers and structure are quiet
- [ ] Icons paired with text are lower contrast than the text
- [ ] Raised surfaces are lighter than what's behind them
- [ ] Container/background brightness gap within ~7% (light) or ~12% (dark)
- [ ] Borders contrast with both the container and the background
- [ ] Body text ≥16px; measure ~60–80 characters
- [ ] Tracking/leading tightened for large text, loosened for small
- [ ] Two typefaces maximum
- [ ] Every element aligns with something; icons optically centred
- [ ] All spacing and sizes come from one scale (8px base)
- [ ] Spacing measured between contrast edges
- [ ] Outer padding ≥ inner padding in every container
- [ ] Button horizontal padding ≈ 2× vertical
- [ ] Nested radii = outer − gap
- [ ] Mixed-weight element groups ordered, heaviest to the outside
- [ ] Shadow blur = 2× offset; no shadows in dark mode; one depth technique throughout
- [ ] No stacked hard divides
- [ ] Complexity on only one side of any foreground/background pair
- [ ] Every value in the design is explainable

---

## Example: applying the rules

**Before** (defaults, ad hoc values):

```css
.card {
  background: #fff;
  border: 1px solid #888;        /* between card and page — blurs the edge */
  border-radius: 12px;
  padding: 10px;                  /* outer < inner gap below */
  gap: 18px;                      /* off-scale */
  box-shadow: 0 4px 4px rgba(0,0,0,.4);  /* blur ≠ 2× offset, too strong */
}
.card p { font-size: 14px; color: #000; line-height: 1.6; }
.card button { padding: 12px 14px; border-radius: 12px; }  /* not 2:1; radius doesn't nest */
```

**After:**

```css
:root {
  --bg: #FAFAF9;          /* near-white, warm */
  --surface: #FFFFFE;
  --border: #E3E0DA;      /* lighter than both surface and bg */
  --text: #1C1A17;        /* near-black, warm */
  --space-2: 8px; --space-3: 16px; --space-4: 24px;
}
.card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: var(--space-4);              /* outer ≥ inner */
  gap: var(--space-3);
  box-shadow: 0 4px 8px rgba(28,26,23,.08);  /* blur = 2× offset, low contrast */
}
.card p { font-size: 16px; color: var(--text); line-height: 1.55; max-width: 65ch; }
.card button { padding: 12px 24px; border-radius: 8px; }  /* 2:1; 16 − 8 gap = 8 */
```

Note what changed and why when presenting work — showing the reasoning is what lets the user disagree with a specific choice instead of the whole result.
