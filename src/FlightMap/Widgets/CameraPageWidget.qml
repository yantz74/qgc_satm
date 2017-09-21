/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.4
import QtPositioning            5.2
import QtQuick.Layouts          1.2
import QtQuick.Controls         1.4
import QtQuick.Dialogs          1.2
import QtGraphicalEffects       1.0

import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.Palette           1.0
import QGroundControl.Vehicle           1.0
import QGroundControl.Controllers       1.0
import QGroundControl.FactSystem        1.0
import QGroundControl.FactControls      1.0

/// Camera page for Instrument Panel PageView
Column {
    width:      pageWidth
    spacing:    ScreenTools.defaultFontPixelHeight

    property bool   showSettingsIcon:       _camera !== null

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _dynamicCameras:        _activeVehicle ? _activeVehicle.dynamicCameras : null
    property bool   _isCamera:              _dynamicCameras ? _dynamicCameras.cameras.count > 0 : false
    property bool   _cameraModeUndefined:   _isCamera ? _dynamicCameras.cameras.get(0).cameraMode === QGCCameraControl.CAMERA_MODE_UNDEFINED : true
    property bool   _cameraVideoMode:       _isCamera ? _dynamicCameras.cameras.get(0).cameraMode === QGCCameraControl.CAMERA_MODE_VIDEO : false
    property bool   _cameraPhotoMode:       _isCamera ? _dynamicCameras.cameras.get(0).cameraMode === QGCCameraControl.CAMERA_MODE_PHOTO : false
    property var    _camera:                _isCamera ? _dynamicCameras.cameras.get(0) : null // Single camera support for the time being
    property real   _spacers:               ScreenTools.defaultFontPixelHeight * 0.5
    property real   _labelFieldWidth:       ScreenTools.defaultFontPixelWidth * 30
    property real   _editFieldWidth:        ScreenTools.defaultFontPixelWidth * 30
    property bool   _communicationLost:     _activeVehicle ? _activeVehicle.connectionLost : false
    property bool   _hasModes:              _isCamera && _camera && _camera.hasModes

    function showSettings() {
        qgcView.showDialog(cameraSettings, _cameraVideoMode ? qsTr("Video Settings") : qsTr("Camera Settings"), 70, StandardButton.Ok)
    }

    //-- Dumb camera trigger if no actual camera interface exists
    QGCButton {
        anchors.horizontalCenter:   parent.horizontalCenter
        text:                       qsTr("Trigger Camera")
        visible:                    !_isCamera
        onClicked:                  _activeVehicle.triggerCamera()
        enabled:                    _activeVehicle
    }
    Item { width: 1; height: ScreenTools.defaultFontPixelHeight; visible: _isCamera; }
    //-- Actual controller
    QGCLabel {
        id:             cameraLabel
        text:           _isCamera ? _dynamicCameras.cameras.get(0).modelName : qsTr("Camera")
        visible:        _isCamera
        font.pointSize: ScreenTools.smallFontPointSize
        anchors.horizontalCenter: parent.horizontalCenter
    }
    //-- Camera Mode (visible only if camera has modes)
    Rectangle {
        width:      _hasModes ? ScreenTools.defaultFontPixelWidth *  12 : 0
        height:     _hasModes ? ScreenTools.defaultFontPixelWidth *   4 : 0
        color:      qgcPal.window
        radius:     height * 0.5
        visible:    _hasModes
        anchors.horizontalCenter: parent.horizontalCenter
        //-- Video Mode
        Rectangle {
            width:  parent.height * 0.9
            height: parent.height * 0.9
            color:  qgcPal.windowShadeDark
            radius: height * 0.5
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            QGCColoredImage {
                anchors.fill:       parent
                source:             "/qmlimages/camera_video.svg"
                fillMode:           Image.PreserveAspectFit
                sourceSize.height:  height
                color:              _cameraVideoMode ? qgcPal.colorGreen : qgcPal.text
                MouseArea {
                    anchors.fill:   parent
                    enabled:        _cameraPhotoMode
                    onClicked: {
                        _camera.setVideoMode()
                    }
                }
            }
        }
        //-- Photo Mode
        Rectangle {
            width:  parent.height * 0.9
            height: parent.height * 0.9
            color:  qgcPal.windowShade
            radius: height * 0.5
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            QGCColoredImage {
                anchors.fill:       parent
                source:             "/qmlimages/camera_photo.svg"
                fillMode:           Image.PreserveAspectFit
                sourceSize.height:  height
                color:              _cameraPhotoMode ? qgcPal.colorGreen : qgcPal.text
                MouseArea {
                    anchors.fill:   parent
                    enabled:        _cameraVideoMode
                    onClicked: {
                        _camera.setPhotoMode()
                    }
                }
            }
        }
    }
    //-- Shutter
    Rectangle {
        color:      Qt.rgba(0,0,0,0)
        width:      ScreenTools.defaultFontPixelWidth * 6
        height:     width
        radius:     width * 0.5
        visible:        _isCamera
        border.color: qgcPal.buttonText
        border.width: 3
        anchors.horizontalCenter: parent.horizontalCenter
        Rectangle {
            width:      parent.width * 0.75
            height:     width
            radius:     width * 0.5
            color:      _cameraModeUndefined ? qgcPal.colorGrey : qgcPal.colorRed
            anchors.centerIn:   parent
        }
        MouseArea {
            anchors.fill:   parent
            enabled:        !_cameraModeUndefined
            onClicked: {
                if(_cameraVideoMode) {
                    //-- Start/Stop Video
                } else {
                    _camera.takePhoto()
                }
            }
        }
    }
    Item { width: 1; height: ScreenTools.defaultFontPixelHeight; visible: _isCamera; }
    Component {
        id: cameraSettings
        QGCViewDialog {
            id: _cameraSettingsDialog
            QGCFlickable {
                anchors.fill:       parent
                contentHeight:      camSettingsCol.height
                flickableDirection: Flickable.VerticalFlick
                clip:               true
                Column {
                    id:             camSettingsCol
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    spacing:        _margins
                    //-------------------------------------------
                    //-- Camera Settings
                    Repeater {
                        model:      _camera ? _camera.activeSettings : []
                        Row {
                            spacing:        ScreenTools.defaultFontPixelWidth
                            anchors.horizontalCenter: parent.horizontalCenter
                            property var    _fact:      _camera.getFact(modelData)
                            property bool   _isBool:    _fact.typeIsBool
                            property bool   _isCombo:   !_isBool && _fact.enumStrings.length > 0
                            property bool   _isSlider:  _fact && !isNaN(_fact.increment)
                            property bool   _isEdit:    !_isBool && !_isSlider && _fact.enumStrings.length < 1
                            QGCLabel {
                                text:       parent._fact.shortDescription
                                width:      _labelFieldWidth
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            FactComboBox {
                                width:      parent._isCombo ? _editFieldWidth : 0
                                fact:       parent._fact
                                indexModel: false
                                visible:    parent._isCombo
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            FactTextField {
                                width:      parent._isEdit ? _editFieldWidth : 0
                                fact:       parent._fact
                                visible:    parent._isEdit
                            }
                            QGCSlider {
                                width:          parent._isSlider ? _editFieldWidth : 0
                                maximumValue:   parent._fact.max
                                minimumValue:   parent._fact.min
                                stepSize:       parent._fact.increment
                                visible:        parent._isSlider
                                updateValueWhileDragging:   false
                                anchors.verticalCenter:     parent.verticalCenter
                                Component.onCompleted: {
                                    value = parent._fact.value
                                }
                                onValueChanged: {
                                    parent._fact.value = value
                                }
                            }
                            Item {
                                width:      parent._isBool ? _editFieldWidth : 0
                                height:     factSwitch.height
                                visible:    parent._isBool
                                anchors.verticalCenter: parent.verticalCenter
                                property var _fact: parent._fact
                                Switch {
                                    id: factSwitch
                                    anchors.left:   parent.left
                                    checked:        parent._fact ? parent._fact.value : false
                                    onClicked:      parent._fact.value = checked ? 1 : 0
                                }
                            }
                        }
                    }
                    //-------------------------------------------
                    //-- Reset Camera
                    Row {
                        spacing:        ScreenTools.defaultFontPixelWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        QGCLabel {
                            text:       qsTr("Reset Camera Defaults")
                            width:      _labelFieldWidth
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        QGCButton {
                            text:       qsTr("Reset")
                            onClicked:  resetPrompt.open()
                            width:      _editFieldWidth
                            anchors.verticalCenter: parent.verticalCenter
                            MessageDialog {
                                id:                 resetPrompt
                                title:              qsTr("Reset Camera to Factory Settings")
                                text:               qsTr("Confirm resetting all settings?")
                                standardButtons:    StandardButton.Yes | StandardButton.No
                                onNo: resetPrompt.close()
                                onYes: {
                                    // TODO
                                    resetPrompt.close()
                                }
                            }
                        }
                    }
                    //-------------------------------------------
                    //-- Format Storage
                    Row {
                        spacing:        ScreenTools.defaultFontPixelWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        QGCLabel {
                            text:       qsTr("Storage")
                            width:      _labelFieldWidth
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        QGCButton {
                            text:       qsTr("Format")
                            enabled:    false
                            onClicked:  formatPrompt.open()
                            width:      _editFieldWidth
                            anchors.verticalCenter: parent.verticalCenter
                            MessageDialog {
                                id:                 formatPrompt
                                title:              qsTr("Format Camera Storage")
                                text:               qsTr("Confirm erasing all files?")
                                standardButtons:    StandardButton.Yes | StandardButton.No
                                onNo: formatPrompt.close()
                                onYes: {
                                    // TODO
                                    formatPrompt.close()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
