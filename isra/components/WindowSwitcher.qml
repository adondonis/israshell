import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

Scope {
    id: root

    readonly property string panelType: "switcher"
    property bool isOpen: false
    property var _targetScreen: null

    property var entries: []
    property int index: 0

    onIsOpenChanged: isOpen ? PanelService.opened(root, root._targetScreen) : PanelService.closed(root)

    property bool _opening: false

    function step(dir: int): void {
        if (isOpen) {
            index = (index + dir + entries.length) % entries.length;
            return;
        }
        if (_opening)
            return;
        _opening = true;
        const name = CompositorService.focusedMonitor?.name;
        const scr = Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0];
        CompositorService.fetchWindowSnapshot(all => {
            if (!_opening)
                return;
            _opening = false;
            const ws = CompositorService.monitorFor(scr).activeWorkspaceId;
            const list = all.filter(w => w.workspaceId === ws);
            if (list.length < 2)
                return;

            index = (dir + list.length) % list.length;
            entries = list;
            _targetScreen = scr;
            isOpen = true;
        });
    }

    function close(): void {
        isOpen = false;
    }

    function commit(): void {
        _opening = false;
        if (!isOpen)
            return;
        pendingAddress = entries[index]?.address ?? "";
        isOpen = false;
        focusTimer.restart();
    }

    property string pendingAddress: ""
    Timer {
        id: focusTimer
        interval: 80
        onTriggered: if (root.pendingAddress)
            CompositorService.focusWindow(root.pendingAddress)
    }

    IpcHandler {
        target: "switcher"
        function next(): void {
            root.step(1);
        }
        function prev(): void {
            root.step(-1);
        }
        function commit(): void {
            root.commit();
        }
    }
}
