# קיטוש — מדריך למעצב 🎨

ברוך הבא אליה! זה כל מה שצריך כדי להתחיל לעצב את קיטוש.

**האתר החי:** https://hraanan.github.io/kosher-lowcarb-kitchen/
**הריפו:** https://github.com/hraanan/kosher-lowcarb-kitchen

## איך זה בנוי

- **`template.html` — זה הקובץ שלך.** כל האתר: ה-HTML, כל ה-CSS (בבלוק `<style>` אחד למעלה) וה-JS. אתה עובד רק כאן.
- `data/recipes/*.json` — תוכן המתכונים. **לא לגעת.**
- `build.py` / `build.ps1` — מזריקים את המתכונים לתוך template ומייצרים את `book.html` + `index.html`.
- `index.html`, `book.html` — **קבצים מיוצרים. אף פעם לא לערוך ידנית** (כל בנייה דורסת אותם).
- `apps-script.gs`, `data/supabase-config.json` — החיבור לגיליון Google (דירוגים/בקשות/תמונות). לא לגעת.

## סבב עבודה

```bash
git clone https://github.com/hraanan/kosher-lowcarb-kitchen.git
cd kosher-lowcarb-kitchen
# עורכים את template.html
python build.py          # או: powershell -File build.ps1 (בווינדוס)
python -m http.server 8000   # ואז פותחים http://localhost:8000/book.html
# מרוצים? →
git add -A && git commit -m "design: ..." && git push
# האתר הציבורי מתעדכן לבד תוך כדקה
```

## מערכת העיצוב הנוכחית

- **טוקנים**: כל הצבעים מוגדרים כמשתני CSS ב-`:root` (ראש הקובץ). **שינוי צבע = שינוי טוקן**, לא צבע קשיח בקומפוננטה.
- **דארק-מוד**: יש שלושה בלוקים שחייבים להישאר מסונכרנים — `:root` (לייט), `@media (prefers-color-scheme: dark)` עם `:root:not([data-theme="light"])`, ו-`:root[data-theme="dark"]`. כל טוקן חדש חייב להופיע בשלושתם.
- **צבעי כשרות (מוסכמה — לא לשנות משמעות):** חלבי=כחול, בשרי=אדום, פרווה=ירוק. קיטו=ענברי.
- **טיפוגרפיה**: כותרות `Fraunces` (אנגלית) / `Heebo` (עברית); טקסט `Karla`/`Heebo`. נטענות מ-Google Fonts בראש הקובץ.
- **RTL**: האתר דו-כיווני! משתמשים אך ורק ב-logical properties: `margin-inline-start` ולא `margin-left`, `inset-inline-end` ולא `right`, `text-align:start` ולא `left`. שינוי עם left/right ישבור את העברית.
- **הדפסה**: יש `@media print` בסוף ה-CSS — מדפיס מתכון בודד או ספר שלם. לבדוק שלא נשבר.
- **איורים**: כל מתכון מקבל איור SVG לפי סוג המנה — הספרייה `ICONS` וכללי ההתאמה `ILLUS_RULES` בתוך ה-JS. הצבעים שלהם מגיעים מהטוקנים (מחלקות `.f1`–`.f4`, `.a`, `.k`).

## צ'קליסט לפני כל push

1. ✅ `python build.py` רץ בלי שגיאות
2. ✅ נראה טוב בלייט **וגם** בדארק (DevTools → Rendering → prefers-color-scheme)
3. ✅ עברית (כפתור עברית — כל הפריסה מתהפכת RTL) וגם אנגלית
4. ✅ מובייל (DevTools בצד, 375px)
5. ✅ הדפסת מתכון בודד (Ctrl+P מתוך מתכון)
6. ✅ לא נגעת ב-`data/`, `index.html`, `book.html`, קובצי backend

שאלות על הקוד? חגי מדבר עם קלוד והתשובות חוזרות מהר 🙂
