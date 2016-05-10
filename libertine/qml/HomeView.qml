/**
 * @file HomeView.qml
 * @brief Libertine container apps view
 */
/*
 * Copyright 2015-2016 Canonical Ltd
 *
 * Libertine is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3, as published by the
 * Free Software Foundation.
 *
 * Libertine is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import Libertine 1.0
import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3


Page {
    id: homeView
    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Classic Apps - %1").arg(containerConfigList.getContainerName(mainView.currentContainer))
        trailingActionBar.actions: [
            Action {
                id: settingsButton
                iconName: "settings"
                onTriggered: PopupUtils.open(settingsMenu, homeView)
            },
            Action {
                iconName: "add"
                onTriggered: PopupUtils.open(addAppsMenu, homeView)
            }
        ]
    }

    Component {
        id: enterPackagePopup
        Dialog {
            id: enterPackageDialog
            title: i18n.tr("Install new package")
            text: i18n.tr("Enter exact package name or full path to a Debian package file")

            Label {
                id: appExistsWarning
                wrapMode: Text.Wrap
                visible: false
            }

            TextField {
                id: enterPackageInput
                placeholderText: i18n.tr("Package name or Debian package path")
                onAccepted: okButton.clicked()
            }

            Row {
                spacing: units.gu(1)

                Button {
                    id: okButton
                    text: i18n.tr("OK")
                    color: UbuntuColors.green
                    width: (parent.width - parent.spacing) / 2
                    onClicked: {
                        if (enterPackageInput.text != "") {
                            if (!containerConfigList.isAppInstalled(mainView.currentContainer, enterPackageInput.text)) {
                                installPackage(enterPackageInput.text)
                                mainView.currentPackage = enterPackageInput.text
                                PopupUtils.close(enterPackageDialog)
                            }
                            else {
                                appExistsWarning.text = i18n.tr("The %1 package is already installed. Please try a different package name.").arg(enterPackageInput.text)
                                appExistsWarning.visible = true
                                enterPackageInput.text = "" 
                            }
                        }
                    }
                }

                Button {
                    id: cancelButton
                    text: i18n.tr("Cancel")
                    color: UbuntuColors.red
                    width: (parent.width - parent.spacing) / 2
                    onClicked: PopupUtils.close(enterPackageDialog)
                }
            }

            Component.onCompleted: enterPackageInput.forceActiveFocus()
        }
    }

    Component {
	id: settingsMenu
	ActionSelectionPopover {
	    actions: ActionList {
		Action {
		    text: i18n.tr("Manage Container")
		    onTriggered: {
                        pageStack.push(Qt.resolvedUrl("ManageContainer.qml"))
                    }
		}
                Action {
                    text: i18n.tr("Container Information")
                    onTriggered: {
                        pageStack.push(Qt.resolvedUrl("ContainerInfoView.qml"))
                    }
                }
		Action {
		    text: i18n.tr("Switch Container")
		    onTriggered: {
                        pageStack.pop()
                        pageStack.push(Qt.resolvedUrl("ContainersView.qml"))
                    }
		}
	    }
	}
    }

    Component {
        id: addAppsMenu
        ActionSelectionPopover {
            id: addAppsActions
            actions: ActionList {
                Action {
                    text: i18n.tr("Enter package name or Debian file")
                    onTriggered: {
                        PopupUtils.open(enterPackagePopup)
                    }
                }
                Action {
                    text: i18n.tr("Choose Debian package to install")
                    onTriggered: {
                        var packages = containerConfigList.getDebianPackageFiles()
                        pageStack.push(Qt.resolvedUrl("DebianPackagePicker.qml"), {packageList: packages}) 
                   }
                }
                Action {
                    text: i18n.tr("Search archives for a package")
                    onTriggered: {
                        PopupUtils.open(Qt.resolvedUrl("SearchPackagesDialog.qml"))
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        containerConfigList.configChanged.connect(reloadAppList)
    }

    Component.onDestruction: {
        containerConfigList.configChanged.disconnect(reloadAppList)
    }

    function reloadAppList() {
        containerAppsList.setContainerApps(mainView.currentContainer)

        appsList.visible = !containerAppsList.empty()  ? true : false
    }

    UbuntuListView {
        id: appsList
        anchors {
            topMargin: pageHeader.height
            fill: parent
        }
        model: containerAppsList
        visible: !containerAppsList.empty()  ? true : false
        delegate: ListItem {
            Label {
                text: packageName
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: units.gu(2)
                }
            }
            ActivityIndicator {
                id: appActivity
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: units.gu(2)
                }
                visible: (appStatus === i18n.tr("installing") ||
                          appStatus === i18n.tr("removing")) ? true : false
                running: appActivity.visible
            }
            leadingActions: ListItemActions {
                actions: [
                    Action {
                        iconName: "delete"
                        text: i18n.tr("delete")
                        description: i18n.tr("Remove Package")
                        onTriggered: {
                            mainView.currentPackage = packageName
                            removePackage(packageName)
                        }
                    }
                ]
            }
            trailingActions: ListItemActions {
                actions: [
                    Action {
                        iconName: "info"
                        text: i18n.tr("info")
                        description: i18n.tr("Package Info")
                        onTriggered: {
                            mainView.currentPackage = packageName
                            pageStack.push(Qt.resolvedUrl("PackageInfoView.qml"))
                        }
                    }
                ]
            }
        }
    }

    Label {
        id: emptyLabel
        anchors.centerIn: parent
        visible: !appsList.visible
        wrapMode: Text.Wrap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: i18n.tr("No packages are installed")
    }

    function installPackage(package_name) {
        var comp = Qt.createComponent("ContainerManager.qml")
        var worker = comp.createObject(mainView, {"containerAction": ContainerManagerWorker.Install,
                                                  "containerId": mainView.currentContainer,
                                                  "containerType": containerConfigList.getContainerType(mainView.currentContainer),
                                                  "data": package_name})
        worker.error.connect(mainView.error)
        worker.start()
    }

    function removePackage(packageName) {
        var comp = Qt.createComponent("ContainerManager.qml")
        var worker = comp.createObject(mainView, {"containerAction": ContainerManagerWorker.Remove,
                                                  "containerId": mainView.currentContainer,
                                                  "containerType": containerConfigList.getContainerType(mainView.currentContainer),
                                                  "data": packageName})
        worker.error.connect(mainView.error)
        worker.start()
    }
}
