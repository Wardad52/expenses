import QtQuick
import qs.Ui
BarWidget {
  id: root
  moduleName: "io.github.wardad52.expenses"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  function injectPanel() {
    var p = panelLoader.item
    if (!p) return
    if ("bar" in p) p.bar = root.bar
    if ("anchorItem" in p) p.anchorItem = button
    if ("hostWidget" in p) p.hostWidget = root
  }
  onBarChanged: injectPanel()
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  readonly property bool popoutSwitchClosing: false
  function closeForPopoutSwitch() {}
  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) }
  }
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: panelLoader.item && panelLoader.item.barText ? panelLoader.item.barText : "$"
    tooltipText: "Expenses — monthly spending"
    onPressed: function (btn) { root.toggle() }
  }
}
