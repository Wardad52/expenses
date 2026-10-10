import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as M

Panel {
  id: root
  moduleName: "io.github.wardad52.expenses"
  manageIpc: false
  property var anchorItem: null
  property var hostWidget: null
  readonly property string helper: Qt.resolvedUrl("bin/expenses").toString().replace("file://", "")
  property string barText: "$"
  property string month: M.monthKey(new Date())
  property var summary: ({ total: 0, count: 0, by_category: {} })
  property string monthEntries: ""
  property int attnCount: 0
  property string attnItems: ""
  property var income: ({ total: 0, count: 0 })
  property bool showCatPage: false
  property var checkedCats: []
  property string checkedText: ""
  function updateCheckedText() {
    var bc = root.summary.by_category || {};
    var parts = [];
    for (var i = 0; i < root.checkedCats.length; i++) {
      var c = root.checkedCats[i];
      parts.push(c + " $" + (bc[c] || 0));
    }
    root.checkedText = parts.join(" · ") || "No categories checked";
  }
  onCheckedCatsChanged: updateCheckedText()
  onSummaryChanged: updateCheckedText()
  Component.onCompleted: refresh()
  onOpenedChanged: if (opened) refresh()
  function shiftMonth(delta) {
    var y = parseInt(root.month.slice(0, 4)), m = parseInt(root.month.slice(5, 7)) + delta;
    if (m < 1) { m = 12; y--; } if (m > 12) { m = 1; y++; }
    root.month = y + "-" + ("0" + m).slice(-2);
    loadMonth();
  }
  function refresh() {
    var d = new Date();
    root.month = d.getFullYear() + "-" + ("0" + (d.getMonth() + 1)).slice(-2);
    loadMonth();
  }
  function loadMonth() {
    sumProc.command = ["bash", root.helper, "summary", root.month];
    sumProc.running = true;
    listProc.command = ["bash", root.helper, "list-month", root.month];
    listProc.running = true;
    attnProc.command = ["bash", root.helper, "attention"];
    attnProc.running = true;
    incProc.command = ["bash", root.helper, "income-summary", root.month];
    incProc.running = true;
  }
  Process {
    id: attnProc
    command: []
    stdout: StdioCollector {}
    onExited: function (code) {
      try {
        var a = JSON.parse(String(stdout.text).trim());
        root.attnCount = a.count || 0;
        root.attnItems = (a.items || []).slice(0, 5).join("\n");
        var now = M.monthKey(new Date());
        var base = (root.summary.month === now ? "" : root.summary.month.slice(5) + " ") + M.fmtMoney(root.summary.total) + " · " + root.summary.count;
        root.barText = (root.attnCount > 0 ? "⚠" + root.attnCount + " " : "") + base;
      } catch (e) {}
    }
  }
  Process {
    id: sumProc
    command: []
    stdout: StdioCollector {}
    onExited: function (code) {
      try {
        var s = JSON.parse(String(stdout.text).trim());
        root.summary = s;
        var now = M.monthKey(new Date());
        var base2 = (s.month === now ? "" : s.month.slice(5) + " ") + M.fmtMoney(s.total) + " · " + s.count;
        root.barText = (root.attnCount > 0 ? "⚠" + root.attnCount + " " : "") + base2;
      } catch (e) {}
    }
  }
  Process {
    id: listProc
    command: []
    stdout: StdioCollector {}
    onExited: function (code) { root.monthEntries = String(stdout.text).trim(); }
  }
  Process {
    id: addProc
    command: []
    stdout: StdioCollector {}
    onExited: function (code) { syncProc.command = ["bash", root.helper, "sync"]; syncProc.running = true; }
  }
  Process {
    id: syncProc
    command: []
    stdout: StdioCollector {}
    onExited: function (code) { loadMonth(); dateField.text = ""; storeField.text = ""; amountField.text = ""; }
  }
  Process {
    id: incProc
    command: []
    stdout: StdioCollector {}
    onExited: function (code) {
      try { root.income = JSON.parse(String(stdout.text).trim()); } catch (e) {}
    }
  }
  Process {
    id: addIncomeProc
    command: []
    stdout: StdioCollector {}
    onExited: function (code) { loadMonth(); incDate.text = ""; incSource.text = ""; incAmount.text = ""; }
  }
  Process {
    id: pullProc
    command: []
    stdout: StdioCollector {}
    onExited: function (code) { loadMonth() }
  }
  function refreshFromEz() {
    pullProc.command = ["bash", root.helper, "pull", root.month];
    pullProc.running = true;
  }
  function submit() {
    addProc.command = ["bash", root.helper, "add", dateField.text || new Date().toISOString().slice(0, 10), storeField.text || "Store", amountField.text || "0", catBox.currentText];
    addProc.running = true;
  }
  function submitIncome() {
    addIncomeProc.command = ["bash", root.helper, "add-income", incDate.text || new Date().toISOString().slice(0, 10), incSource.text || "Paycheck", incAmount.text || "0"];
    addIncomeProc.running = true;
  }
  function open() { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? close() : open() }
  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)
    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      Column {
        id: content
        width: parent.width
        spacing: Style.space(8)
        RowLayout {
          width: parent.width
          Button { text: "◀"; onClicked: shiftMonth(-1) }
          Text { text: "$ " + root.month + " — $" + (root.summary.total || 0) + " (" + (root.summary.count || 0) + ")"; color: root.barForeground; font.bold: true; font.pixelSize: Style.font.subtitle; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
          Button { text: "▶"; onClicked: shiftMonth(1) }
        }
        Button { text: "Cat list"; width: parent.width; visible: !root.showCatPage; onClicked: root.showCatPage = true }
        Text { text: root.checkedText; color: root.barForeground; wrapMode: Text.WordWrap; width: parent.width; font.pixelSize: 12; visible: !root.showCatPage }
        Text { text: root.monthEntries ? root.monthEntries : "No transactions this month."; color: root.barForeground; opacity: 0.85; wrapMode: Text.WordWrap; width: parent.width; font.pixelSize: 12; visible: !root.showCatPage }
        Text { visible: root.attnCount > 0 && !root.showCatPage; text: "⚠ " + root.attnCount + " receipt(s) need attention:\n" + root.attnItems; color: "#ff9d5c"; wrapMode: Text.WordWrap; width: parent.width; font.pixelSize: 12 }
        Text { text: "— Add new expense (fills the fields below, then Add) —"; color: root.barForeground; opacity: 0.6; font.pixelSize: 11; visible: !root.showCatPage }
        TextField { id: dateField; placeholderText: "Date YYYY-MM-DD (new expense)"; width: parent.width; visible: !root.showCatPage }
        TextField { id: storeField; placeholderText: "Store (new expense)"; width: parent.width; visible: !root.showCatPage }
        TextField { id: amountField; placeholderText: "Amount, e.g. 42.50 (new expense)"; inputMethodHints: Qt.ImhDigitsOnly; width: parent.width; visible: !root.showCatPage }
        ComboBox { id: catBox; model: ["Food & Drink", "Clothing & Apparel", "Housing & Houseware", "Transportation", "Auto/Fuel", "Vacation", "Coms", "Entertainment", "Education", "Gifts & Donate", "Medical", "Finance & Insurance", "Misc"]; width: parent.width; visible: !root.showCatPage }
        Button { text: "Add expense (local + sync to ezBookkeeping)"; width: parent.width; onClicked: submit(); visible: !root.showCatPage }
        Button { text: "Refresh from ezBookkeeping"; width: parent.width; onClicked: refreshFromEz(); visible: !root.showCatPage }
        Text { text: "Income this month: $" + (root.income.total || 0) + " (" + (root.income.count || 0) + ")"; color: root.barForeground; font.bold: true; visible: !root.showCatPage }
        TextField { id: incDate; placeholderText: "Date YYYY-MM-DD (income)"; width: parent.width; visible: !root.showCatPage }
        TextField { id: incSource; placeholderText: "Source, e.g. Paycheck"; width: parent.width; visible: !root.showCatPage }
        TextField { id: incAmount; placeholderText: "Amount, e.g. 1250.00 (income)"; inputMethodHints: Qt.ImhDigitsOnly; width: parent.width; visible: !root.showCatPage }
        Button { text: "Add income (sync to ezBookkeeping)"; width: parent.width; onClicked: submitIncome(); visible: !root.showCatPage }
        Text { text: "Add saves locally then pushes missing entries to ezBookkeeping :9400 (needs saved API token). Manual sync: `expenses sync`."; color: root.barForeground; opacity: 0.7; wrapMode: Text.WordWrap; width: parent.width; font.pixelSize: 11; visible: !root.showCatPage }
        Text { text: "Cat list — check categories to include in front-page breakdown"; color: root.barForeground; font.bold: true; visible: root.showCatPage; wrapMode: Text.WordWrap; width: parent.width }
        Repeater {
          model: ["Food & Drink", "Clothing & Apparel", "Housing & Houseware", "Transportation", "Auto/Fuel", "Vacation", "Coms", "Entertainment", "Education", "Gifts & Donate", "Medical", "Finance & Insurance", "Misc"]
          delegate: CheckBox {
            visible: root.showCatPage
            text: modelData + " $" + ((root.summary.by_category || {})[modelData] || 0)
            checked: root.checkedCats.indexOf(modelData) >= 0
            onToggled: {
              var a = root.checkedCats.slice();
              var i = a.indexOf(modelData);
              if (checked && i < 0) a.push(modelData);
              if (!checked && i >= 0) a.splice(i, 1);
              root.checkedCats = a;
            }
          }
        }
        Button { text: "◀ Back"; width: parent.width; visible: root.showCatPage; onClicked: root.showCatPage = false }
      }
    }
  }
}
