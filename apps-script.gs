// Kosher Low-Carb Kitchen — Google Sheet backend
// Paste into Extensions > Apps Script of a Google Sheet, then Deploy > New deployment > Web app
// Execute as: Me · Who has access: Anyone

var SHEETS = {
  ratings: ['recipe_id', 'stars', 'voter', 'created_at'],
  submissions: ['name', 'by_name', 'category', 'kosher', 'ingredients', 'instructions', 'notes', 'created_at'],
  requests: ['dish', 'by_name', 'notes', 'status', 'recipe_id', 'created_at'],
  photos: ['recipe_id', 'url', 'file_id', 'by_name', 'status', 'created_at']
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
  // photo uploads: save the image into Drive, share view-only, store its URL
  if (name === 'photos' && body.image) {
    var m = String(body.image).match(/^data:(image\/[\w.+-]+);base64,(.+)$/);
    if (!m) {
      return ContentService.createTextOutput(JSON.stringify({ ok: false, error: 'bad image' })).setMimeType(ContentService.MimeType.JSON);
    }
    var blob = Utilities.newBlob(Utilities.base64Decode(m[2]), m[1], 'recipe-photo-' + Date.now() + '.jpg');
    var it = DriveApp.getFoldersByName('Recipe Book Photos');
    var folder = it.hasNext() ? it.next() : DriveApp.createFolder('Recipe Book Photos');
    var file = folder.createFile(blob);
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    body.file_id = file.getId();
    body.url = 'https://drive.google.com/thumbnail?id=' + file.getId() + '&sz=w1000';
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
