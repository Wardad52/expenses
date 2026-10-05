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
  function submit() {
    addProc.command = ["bash", root.helper, "add", dateField.text || new Date().toISOString().slice(0, 10), storeField.text || "Store", amountField.text || "0", catBox.currentText];
    addProc.running = true;
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
        Text { text: "Groceries $" + ((root.summary.by_category || {}).Groceries || 0) + " · Fuel $" + ((root.summary.by_category || {}).Fuel || 0) + " · Dining $" + ((root.summary.by_category || {}).Dining || 0) + " · Other $" + ((root.summary.by_category || {}).Other || 0); color: root.barForeground; wrapMode: Text.WordWrap; width: parent.width }
        Text { text: root.monthEntries ? root.monthEntries : "No transactions this month."; color: root.barForeground; opacity: 0.85; wrapMode: Text.WordWrap; width: parent.width; font.pixelSize: 12 }
        Text { visible: root.attnCount > 0; text: "⚠ " + root.attnCount + " receipt(s) need attention:\n" + root.attnItems; color: "#ff9d5c"; wrapMode: Text.WordWrap; width: parent.width; font.pixelSize: 12 }
        Text { text: "— Add new expense (fills the fields below, then Add) —"; color: root.barForeground; opacity: 0.6; font.pixelSize: 11 }
        TextField { id: dateField; placeholderText: "Date YYYY-MM-DD (new expense)"; width: parent.width }
        TextField { id: storeField; placeholderText: "Store (new expense)"; width: parent.width }
        TextField { id: amountField; placeholderText: "Amount, e.g. 42.50 (new expense)"; inputMethodHints: Qt.ImhDigitsOnly; width: parent.width }
        ComboBox { id: catBox; model: ["Groceries", "Fuel", "Dining", "Other"]; width: parent.width }
        Button { text: "Add expense (local + sync to ezBookkeeping)"; width: parent.width; onClicked: submit() }
        Text { text: "Add saves locally then pushes missing entries to ezBookkeeping :9400 (needs saved API token). Manual sync: `expenses sync`."; color: root.barForeground; opacity: 0.7; wrapMode: Text.WordWrap; width: parent.width; font.pixelSize: 11 }
      }
    }
  }
}
