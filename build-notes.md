# Kosher Low-Carb Recipe Book — Build Notes

Personal recipe book for Hagai. English first, Hebrew translation second. Web page (single self-contained `book.html`) with mobile layout and print stylesheets, published as a private Artifact.

## Categories (logical order)

| # | id | Name | Kosher notes |
|---|----|------|--------------|
| 1 | dairy-vegetarian-mains | Dairy & Vegetarian Mains | dairy or pareve |
| 1b | legumes-grains | Low-Carb Legumes & Grains (קטניות ודגנים) | pareve; strict portion caps keep quinoa/lentils ≤20g net |
| 2 | snacks | Snacks | dairy or pareve (fish = pareve label) |
| 3 | baking-savory | Low-Carb Baking — Savory | prefer pareve (goes with meat meals) |
| 4 | baking-sweet | Low-Carb Baking — Sweet | dairy or pareve |
| 5 | desserts-dairy | Desserts — Dairy | always dairy |
| 6 | desserts-pareve | Desserts — Non-Dairy (Pareve) | ZERO dairy — safe after meat meals |

Target: ≥20 recipes per category (120+ total). Data lives in `data\recipes\*.json`, two files per category (`<cat>-1.json`, `<cat>-2.json`), each a JSON array of 10 recipes.

## Recipe schema

```json
{
  "id": "kebab-case-unique",
  "name": "Recipe Name",
  "category": "<category id>",
  "kosherType": "dairy | pareve",
  "dietTags": "keto (net carbs <=10g) | lowcarb (10-20g)",
  "servings": 4,
  "prepTimeMin": 10, "cookTimeMin": 20,
  "difficulty": "easy | medium",
  "ingredients": [{"amount": "1 cup / 100 g", "item": "...", "israelNote": "optional Israeli product mapping"}],
  "instructions": ["..."],
  "nutrition": {"calories":0,"fatG":0,"satFatG":0,"proteinG":0,"carbsG":0,"fiberG":0,"netCarbsG":0,"sugarG":0,"sodiumMg":0},
  "ketoVariant": "optional — how to make it keto",
  "lowCarbVariant": "optional — flexible variation",
  "tips": "optional",
  "sources": [{"creator":"...","url":"..."}],
  "comparedVersions": "what was compared, why this version won",
  "nameHe": "...", "ingredientsHe": [...], "instructionsHe": [...]   // Phase 4
}
```

Nutrition is per serving. Net carbs = total carbs − fiber − sugar alcohols. Keto ≤10 g net; lowcarb ≤20 g net; nothing above 20 g enters the book.

## Kosher rules checklist

- Every recipe labeled **dairy** or **pareve** (no meat recipes in current categories).
- Dairy = any butter, cream, milk, cheese, whey, milk powder, milk chocolate.
- Pareve desserts section: zero dairy including hidden dairy (chocolate chips usually contain milk solids → "pareve dark chocolate, check label").
- No gelatin unless explicitly kosher; prefer agar-agar.
- No pork, shellfish, or non-kosher species anywhere. Fish (tuna/salmon) labeled pareve.

## Israel ingredient glossary (EN → what to buy in Israel)

| English | In Israel |
|---|---|
| almond flour | קמח שקדים (kemach shkedim) |
| coconut flour | קמח קוקוס |
| heavy cream | שמנת מתוקה 38% |
| cream cheese | גבינת שמנת (נפוליאון / סקי) |
| white cheese | גבינה לבנה 5% |
| cottage cheese | קוטג' 5% |
| Greek yogurt | יוגורט יווני 5–10% |
| feta | גבינה צפתית / בולגרית |
| parmesan | פרמזן או קשקבל |
| mozzarella shredded | מוצרלה מגוררת (טרה/גד) |
| labneh | לאבנה |
| tahini (raw) | טחינה גולמית (הר ברכה / אחוה) |
| coconut cream | קרם קוקוס 22%+ |
| almond milk unsweetened | משקה שקדים ללא סוכר |
| erythritol / monk fruit / stevia | אריתריטול / סטיביה — סופרים וחנויות טבע |
| psyllium husk | פסיליום — סופר-פארם / חנויות טבע |
| xanthan gum | קסנטן גאם — חנויות טבע |
| agar-agar | אגר-אגר — חנויות טבע |
| sugar-free dark chocolate | שוקולד מריר 85%+ (לפרווה — לבדוק סימון) |
| chia seeds | זרעי צ'יה |
| rose water | מי ורדים |
| aquafaba | מי חומוס (נוזל משימורי חומוס) |

## Pipeline

1. 12 research agents → `data\recipes\*.json` (done in batches; compare 2–4 versions per dish, credit sources).
2. Validate: JSON parse, required fields, kosher audit, net-carb caps (`build.ps1` does checks + build).
3. `build.ps1` merges all JSON into `template.html` → `book.html`.
4. Publish `book.html` as private Artifact; verify mobile (375 px) and print rendering.
5. Hebrew translation agents fill `nameHe/ingredientsHe/instructionsHe` (+ He variants/tips) → rebuild with EN/HE toggle.

## Progress

- [x] Plan approved (2026-08-28)
- [x] 128 recipes researched & written (12 agents + extra pareve-breads batch `baking-savory-3.json`)
- [x] All category JSON validated + kosher audit (one known false positive: "cream of tartar" flagged in pareve aquafaba mousse — it is not dairy)
- [x] Dish illustrations (SVG library + keyword classifier in template.html; only cabbage-steaks falls back to the generic cloche icon)
- [x] book.html built & published as private Artifact: https://claude.ai/code/artifact/7e78cdb9-5d6c-4c80-9387-8746b6a069b4
- [x] Hebrew translation complete (all 128 recipes, EN/HE toggle with RTL)
- [x] QA: mobile 375px, print (single + whole book with TOC), filters, search, Hebrew view

Rebuild any time with `powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1`, then republish book.html to the same artifact URL. Local preview: `.claude\launch.json` serves the folder at http://localhost:8641.
