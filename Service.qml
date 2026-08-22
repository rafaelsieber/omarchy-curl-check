import QtQuick
import Quickshell.Io

// Headless service: each time the plugin loads (enable, shell start), it re-runs
// the idempotent integration script, which links the CLI tool into ~/.local/bin
// and keeps the Install > Curl Check menu entry up to date.
Item {
  id: root

  readonly property string pluginDir: {
    var url = Qt.resolvedUrl(".").toString()
    return url.indexOf("file://") === 0 ? url.substring(7) : url
  }

  Process {
    id: integrate
    command: ["bash", root.pluginDir + "bin/curl-check-integrate", "install"]
    running: true
  }
}
