// Kosher Low-Carb Kitchen — Google Sheet backend
// Paste into Extensions > Apps Script of a Google Sheet, then Deploy > New deployment > Web app
// Execute as: Me · Who has access: Anyone

var SHEETS = {
  ratings: ['recipe_id', 'stars', 'voter', 'created_at'],
  submissions: ['name', 'by_name', 'category', 'kosher', 'ingredients', 'instructions', 'notes', 'created_at'],
  requests: ['dish', 'by_name', 'notes', 'status', 'recipe_id', 'created_at']
};

function getSheet(name) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sh = ss.getSheetByName(name);
  if (!sh) { sh = ss.insertSheet(name); sh.appendRow(SHEETS[name]); }
  return sh;
}

function doGet() {
  var out = {};
  for (var name in SHEETS) {
    var sh = getSheet(name);
    var rows = sh.getDataRange().getValues();
    var head = rows.shift() || SHEETS[name];
    out[name] = rows.map(function (r) {
      var o = {};
      head.forEach(function (h, i) { o[h] = r[i]; });
      return o;
    });
  }
  return ContentService.createTextOutput(JSON.stringify(out)).setMimeType(ContentService.MimeType.JSON);
}

function doPost(e) {
  var body = JSON.parse(e.postData.contents);
  var name = body.table;
  if (!SHEETS[name]) {
    return ContentService.createTextOutput(JSON.stringify({ ok: false, error: 'bad table' })).setMimeType(ContentService.MimeType.JSON);
  }
  var sh = getSheet(name);
  var row = SHEETS[name].map(function (h) {
    if (h === 'created_at') return new Date().toISOString();
    if (h === 'status' && body[h] === undefined) return 'pending';
    var v = body[h];
    if (v === undefined || v === null) return '';
    return (typeof v === 'object') ? JSON.stringify(v) : v;
  });
  sh.appendRow(row);
  return ContentService.createTextOutput(JSON.stringify({ ok: true })).setMimeType(ContentService.MimeType.JSON);
}
