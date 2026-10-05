.pragma library
var CATEGORIES = ["Groceries", "Fuel", "Dining", "Other"];
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
  var t = { Groceries: 0, Fuel: 0, Dining: 0, Other: 0, total: 0, count: 0 };
  for (var i = 0; i < entries.length; i++) {
    var e = entries[i];
    if (key && String(e.date).slice(0, 7) !== key) continue;
    var c = t.hasOwnProperty(e.category) ? e.category : "Other";
    var a = parseFloat(e.amount) || 0;
    t[c] += a; t.total += a; t.count++;
  }
  return t;
}
