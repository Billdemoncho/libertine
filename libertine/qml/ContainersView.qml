/**
 * @file ContainersView.qml
 * @brief Libertine containers view
 */
/*
 * Copyright 2015 Canonical Ltd
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
import QtQuick 2.4
import Ubuntu.Components 1.2


/**
 * View providing a list of available containers and their (possibly animated)
 * states.
 */
Page {
    id: containersView
    title: i18n.tr("My Containers")

    head.actions: [
        Action {
            iconName: "add"
            onTriggered: mainView.state = "ADD_CONTAINER"
        }
    ]

    UbuntuListView {
        anchors.fill: parent
        model: containerConfigList
        delegate: ListItem {
            Label {
                text: name
            }

            leadingActions: ListItemActions {
                actions: [
                    Action {
                        iconName: "delete"
                        text: i18n.tr("delete")
                        description: i18n.tr("Delete Container")
                        onTriggered: {
                            console.log("delete container " + containerId)
                        }
                    }
                ]
            }

            trailingActions: ListItemActions {
                actions: [
                    Action {
                        iconName: "info"
                        text: i18n.tr("info")
                        description: i18n.tr("Container Info")
                        onTriggered: {
                            console.log("info for container " + containerId)
                        }
                    },
                    Action {
                        iconName: "edit"
                        text: i18n.tr("edit")
                        description: i18n.tr("Container Apps")
                        onTriggered: {
                            console.log("edit container " + containerId)
                            mainView.currentContainer = containerId
                            mainView.state = "HOMEPAGE"
                        }
                    }
                ]
            }
        }
    }
}