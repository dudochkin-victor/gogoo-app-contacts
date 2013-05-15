/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Labs.Components 0.1 as Labs
import MeeGo.Components 0.1
import MeeGo.App.Contacts 0.1

Item {
    property string type 
    property variant currentView
    property variant pageToLoad

    width: parent.width
    height: footer_bar.height
    anchors {bottom: parent.bottom; left: parent.left; right: parent.right;}

    Labs.ApplicationsModel {
        id: appModel
    }

    function getButtonTitleText() {
        if (type == "details")
            return [scene.contextShare, scene.contextEdit];
        else if ((type == "edit") || (type == "new"))
            return [scene.contextSave, scene.contextCancel];
        else
            return ["", ""];
    }

    function getActiveState(action) {
        if (action == scene.contextSave)
            return currentView.validInput

        return true;
    }

    function handleButtonClick(action) {
        if (action == scene.contextShare) {
            peopleModel.exportContact(scene.currentContactId,  "/tmp/vcard.vcf");
            var cmd = "/usr/bin/meego-qml-launcher --app meego-app-email --fullscreen --cmd openComposer --cdata \"file:///tmp/vcard.vcf\"";
            appModel.launch(cmd);
        } else if (action == scene.contextEdit) {
            scene.addApplicationPage(pageToLoad);
        } else if (action == scene.contextSave) {
            if (type == "edit")
                currentView.contactSave(scene.currentContactId);
            else if (type == "new")
                currentView.contactSave();
            scene.applicationPage = myAppAllContacts;
        } else
            scene.applicationPage = myAppAllContacts;
    }

    Image {
        id: footer_bar
        source: "image://theme/contacts/contact_btmbar_landscape"
        anchors {bottom: parent.bottom; left: parent.left; right: parent.right;}
        opacity: 1

        Image {
            id: settingsIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            source: "image://meegotheme/icons/actionbar/show-settings"
            NumberAnimation on rotation {
                id: imageRotation
                running: false
                from: 0; to: 360
                loops: Animation.Infinite;
                duration: 2400
            }

            MouseArea {
                anchors.fill: parent
                onPressed : {
                    settingsIcon.source = "image://meegotheme/icons/actionbar/show-settings"
                }
                onReleased: {
                    settingsIcon.source = "image://meegotheme/icons/actionbar/show-settings-active"
                }
                onClicked: {
                    var cmd = "/usr/bin/meego-qml-launcher --app meego-ux-settings --opengl --fullscreen --cmd showPage --cdata \"Contacts\"";  //i18n ok
                    appModel.launch(cmd);
                }
            }
        }

        Image {
            id: divIcon
            anchors.left: settingsIcon.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            source: "image://theme/email/div"
        }

        Button{
            id: buttonLeft
            width: 146
            text: getButtonTitleText()[0]
            bgSourceUp: "image://theme/btn_grey_up"
            bgSourceActive: "image://theme/btn_grey_up"
            bgSourceDn: "image://theme/btn_grey_dn"
            visible: (buttonLeft.text == "" ? 0 : 1)
            active: getActiveState(buttonLeft.text)
            anchors {top: parent.top; topMargin: 3; 
                     bottom: parent.bottom; bottomMargin: 3; 
                     left: divIcon.left; leftMargin: 3;}

            onClicked: { handleButtonClick(buttonLeft.text); }
        }

        Button{
            id: buttonRight
            width: 146
            text: getButtonTitleText()[1]
            bgSourceUp: "image://theme/btn_grey_up"
            bgSourceActive: "image://theme/btn_grey_up"
            bgSourceDn: "image://theme/btn_grey_dn"
            visible: (buttonRight.text == "" ? 0 : 1)
            active: getActiveState(buttonRight.text)
            anchors {top: parent.top; topMargin: 3;
                     bottom: parent.bottom; bottomMargin: 3;
                     right: footer_bar.right; rightMargin: 3;}

            onClicked: { handleButtonClick(buttonRight.text); }
        }
    }
}
