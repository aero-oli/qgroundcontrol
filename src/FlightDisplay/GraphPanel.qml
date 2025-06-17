import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls
import QGroundControl.Controllers
import QGroundControl.Palette
import QGroundControl.ScreenTools

Rectangle {
    id: root
    color: qgcPal.window

    property var controller: null
    property var _activeSystem: null
    property var _curMessage: null

    // Signal handler for when the controller is assigned from FlyView
    onControllerChanged: {
        if (controller) {
            // Initial setup
            _updateActiveSystem(controller.activeSystem);

            // Connect to the controller's signal for future changes
            controller.activeSystemChanged.connect(_handleActiveSystemChanged);
        }
    }

    // Handlers for system and message changes
    function _handleActiveSystemChanged() {
        _updateActiveSystem(controller.activeSystem);
    }
    
    function _updateActiveSystem(system) {
        _activeSystem = system;
        mainLayout.visible = (_activeSystem !== null);
        disconnectedMessage.visible = (_activeSystem === null);
        
        if (_activeSystem) {
            _activeSystem.selectedChanged.connect(_handleSelectedMessageChanged);
            _updateSelectedMessage(_activeSystem.selectedMsg());
            messageCombo.model = _activeSystem.messages;
        } else {
            _updateSelectedMessage(null);
            messageCombo.model = [];
        }
    }

    function _handleSelectedMessageChanged() {
        if (_activeSystem) {
            _updateSelectedMessage(_activeSystem.selectedMsg());
        }
    }

    function _updateSelectedMessage(message) {
        _curMessage = message;
        // The repeater's model will update automatically due to binding
    }

    // "Disconnected" message
    QGCLabel {
        id: disconnectedMessage
        anchors.centerIn: parent
        text: qsTr("Connect to a vehicle to view telemetry graphs.")
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        visible: !_activeSystem
    }

    // Main content, visible only when connected
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: ScreenTools.defaultFontPixelWidth
        visible: _activeSystem

        QGCLabel {
            text: qsTr("Telemetry Graphs")
            font.pointSize: ScreenTools.largeFontPointSize
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: ScreenTools.defaultFontPixelHeight
        }

        // System Selector
        QGCComboBox {
            id: systemCombo
            visible:    controller && controller.systems.count > 1
            Layout.fillWidth: true
            model:      controller ? controller.systemNames : []
            
            onActivated: (index) => {
                if (controller && controller.systems && index < controller.systems.count) {
                    controller.setActiveSystem(controller.systems.get(index).id)
                }
            }
        }
        
        // Message Selector
        QGCLabel { text: qsTr("Select Message:") }
        QGCComboBox {
            id: messageCombo
            Layout.fillWidth: true
            textRole: "name"
            
            onActivated: (index) => {
                if (_activeSystem) {
                    _activeSystem.selected = index
                }
            }
        }

        // Fields list
        QGCLabel { text: qsTr("Fields to Plot:") }
        QGCFlickable {
            Layout.fillWidth: true
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 10
            contentHeight: fieldGrid.height
            clip: true
            
            GridLayout {
                id: fieldGrid
                columns: 2
                width: parent.width
                
                Repeater {
                    model: _curMessage ? _curMessage.fields : []
                    
                    QGCCheckBox {
                        text: modelData.name
                        checked: modelData.series !== null
                        enabled: modelData.isNumeric
                        onClicked: {
                            if (checked) {
                                chart1.addDimension(modelData)
                            } else {
                                chart1.delDimension(modelData)
                            }
                        }
                    }
                }
            }
        }

        // Chart Area
        MAVLinkChart {
            id: chart1
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
} 