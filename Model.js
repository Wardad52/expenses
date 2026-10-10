.pragma library
var CATEGORIES = ["Food & Drink", "Clothing & Apparel", "Housing & Houseware", "Transportation", "Auto/Fuel", "Vacation", "Coms", "Entertainment", "Education", "Gifts & Donate", "Medical", "Finance & Insurance", "Misc"];
// legacy ezBookkeeping names still seen on older entries
var LEGACY = ["Groceries", "Fuel", "Dining", "Other"];
function monthKey(d) {
  d = d || new Date();
  return d.getFullYear() + "-" + ("0" + (d.getMonth() + 1)).slice(-2);
}
function fmtMoney(n) {
  var v = parseFloat(n);
  if (!isFinite(v)) return "$0";
  if (v >= 1000) return "$" + (v / 1000).toFixed(1) + "k";
  return "$" + Math.round(v);
}
function totalsByCategory(entries, key) {
  var t = { total: 0, count: 0 };
  var i;
  for (i = 0; i < CATEGORIES.length; i++) t[CATEGORIES[i]] = 0;
  t.Other = t.Other || 0;
  for (i = 0; i < entries.length; i++) {
    var e = entries[i];
    if (key && String(e.date).slice(0, 7) !== key) continue;
    var c = e.category;
    if (c === "Groceries") c = "Food & Drink";
    else if (c === "Fuel") c = "Auto/Fuel";
    else if (c === "Dining") c = "Food & Drink";
    if (!t.hasOwnProperty(c)) c = "Misc";
    var a = parseFloat(e.amount) || 0;
    t[c] += a; t.total += a; t.count++;
  }
  return t;
}
// laman: comment for checked-breakdown text; checked = array of category names
function checkedBreakdown(byCat, checked) {
  var parts = [], i;
  for (i = 0; i < checked.length; i++) {
    var c = checked[i];
    parts.push(c + " $" + (byCat[c] || 0));
  }
  return parts.join(" · ");
}
