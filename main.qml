/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Components 0.1
import MeeGo.Labs.Components 0.1 as Labs
import MeeGo.App.Contacts 0.1

Labs.Window {
    id: scene
    title: qsTr("Contacts")
    showsearch: false;

    property string currentContactId: ""
    property int currentContactIndex: 0
    property string currentContactName: ""
    property bool callFromRemote: false

    property string filterNew: qsTr("New contact")
    property string filterAll: qsTr("All")
    property string filterFavorites: qsTr("Favorites")
    property string filterWhosOnline: qsTr("Who's online")

    property string contextView: qsTr("View")
    property string contextShare: qsTr("Share")
    property string contextEmail: qsTr("Email")
    property string contextFavorite: qsTr("Favorite")
    property string contextEdit: qsTr("Edit")
    property string contextSave: qsTr("Save")
    property string contextCancel: qsTr("Cancel")
    property string contextDelete: qsTr("Delete")
    property string deleteConfirmation: qsTr("Delete Confirmation")
    property int dateFormat: Qt.DefaultLocaleLongDate

    property string labelGroupedView: qsTr("Contacts")
    property string labelDetailView: qsTr("Contact details")
    property string labelNewContactView: qsTr("New contact")
    property string labelEditView: qsTr("Edit contacts")

    property string contactname : (scene.currentContactName ? scene.currentContactName : qsTr("this contact"))
    property string promptStr: qsTr("Are you sure you want to remove %1 from your contacts?").arg(contactname)

    property int animationDuration: 250

    applicationPage: myAppAllContacts

    Connections {
        target: mainWindow
        onCall: {
            var cmd = parameters[0];
            //var data = parameters[1]; //data: one of 234-2342 or joe@gmail.com
            //var type = parameters[2]; //type: one of email or phone

            //callFromRemote = true;
            if (cmd == "launchNewContact") {
                //REVISIT: need to pass data and type to NewContactPage
                scene.addApplicationPage(myAppNewContact);
            }
            else if (cmd == "launchDetailView")
            {
                var contactId = parameters[1];
                if(contactId)
                    scene.currentContactIndex = contactId;
                scene.addApplicationPage(myAppDetails);
            }
        }
    }

    Loader{
        id: dialogLoader
        anchors.fill: parent
    }

    onFilterTriggered: {
        if(index == 0){
            peopleModel.setFilter(PeopleModel.AllFilter);
            scene.applicationPage = myAppAllContacts;
        }else if(index == 1){
            peopleModel.setFilter(PeopleModel.FavoritesFilter);
            scene.applicationPage = myAppAllContacts;
        }else if(index == 2){
            peopleModel.setFilter(PeopleModel.OnlineFilter);
            scene.applicationPage = myAppAllContacts;
        }
    }

    Component {
        id: myAppAllContacts
        Labs.ApplicationPage {
            id: groupedViewPage
            title: labelGroupedView
            Component.onCompleted : {
                scene.title = labelGroupedView;
                disableSearch = false;
                showsearch = true;
            }
            onSearch: {
                peopleModel.searchContacts(needle);
            }
            GroupedViewPortrait{
                id: gvp
                parent: groupedViewPage.content
                anchors.fill: parent
                dataModel: peopleModel
                sortModel: proxyModel
                newPage: myAppNewContact //REVISIT: Need to do this?
                detailsPage: myAppDetails //REVISIT: Need to do this?
                onAddNewContact:{
                    groupedViewPage.addApplicationPage(myAppNewContact);
                }
            }
            FooterBar { 
                id: groupedViewFooter 
                type: ""
                currentView: gvp
                pageToLoad: myAppAllContacts
            }
            menuContent: ActionMenu {
                id: actions
                model: [labelNewContactView]
                onTriggered: {
                    if(index == 0) {
                        groupedViewPage.addApplicationPage(myAppNewContact);
                    }
                    groupedViewPage.closeMenu();
                }
            }
            onTypeChanged: {
                if(groupedViewPage.type < 2){
                    peopleModel.setFilter(PeopleModel.AllFilter, false);
                    scene.filterModel =  [filterAll, filterFavorites, filterWhosOnline];
                }
            }
        }
    }

    Component {
        id: myAppDetails
        Labs.ApplicationPage {
            id: detailViewPage
            title: labelDetailView
            Component.onCompleted : {
                scene.title = labelDetailView;
                disableSearch = true;
            }
            DetailViewPortrait{
                id: detailViewContact
                anchors.fill:  parent
                parent: detailViewPage.content
                detailModel: peopleModel
                index: proxyModel.getSourceRow(scene.currentContactIndex)
            }
            FooterBar { 
                id: detailsFooter 
                type: "details"
                currentView: detailViewContact
                pageToLoad: myAppEdit
            }
            menuContent: ActionMenu {
                id: actions
                model: [contextShare, contextEdit]
                onTriggered: {
                    if(index == 0) {
                        peopleModel.exportContact(scene.currentContactId,  "/tmp/vcard.vcf");
                        var cmd = "/usr/bin/meego-qml-launcher --app meego-app-email --fullscreen --cmd openComposer --cdata \"file:///tmp/vcard.vcf\"";
                        appModel.launch(cmd);
                    }
                    else if(index == 1) {
                        scene.addApplicationPage(myAppEdit);
                    }
                    detailViewPage.closeMenu();
                }
            }
            onTypeChanged: {
                if(detailViewPage.type == 0){
                    scene.filterModel = [];
                }
            }
        }
    }

    Component {
        id: myAppEdit
	Labs.ApplicationPage {
            id: editViewPage
            title: labelEditView
            Component.onCompleted : {
                scene.title = labelEditView;
                disableSearch = true;
            }
            EditViewPortrait{
                id: editContact
                parent: editViewPage.content
                dataModel: peopleModel
                index: proxyModel.getSourceRow(scene.currentContactIndex)
                anchors.fill: parent
            }
            FooterBar { 
                id: editFooter 
                type: "edit"
                currentView: editContact
                pageToLoad: myAppAllContacts
            }
            menuContent: ActionMenu {
                id: actions
                model: (scene.currentContactId == 2147483647 ? (editContact.validInput ? [contextSave, contextCancel] : [contextCancel]) : (editContact.validInput ? [contextSave, contextCancel, contextDelete] : [contextCancel, contextDelete]))
                onTriggered: {
                    if(model[index] == contextSave) {
                        applicationPage = myAppAllContacts;
                        editContact.contactSave(scene.currentContactId);
                    }
                    else if(model[index] == contextCancel) {
                        applicationPage = myAppAllContacts;
                    }
                    else if(model[index] == contextDelete) {
                        confirmDelete.show();
                        actions.visible = false;
                    }
                    editViewPage.closeMenu();
                }
            }
            onTypeChanged: {
                if( editViewPage.type == 0){
                    scene.filterModel = [];
                }
            }
        }
    }

    Component {
        id: myAppNewContact
        Labs.ApplicationPage {
            id: newContactViewPage
            title: labelNewContactView
            Component.onCompleted : {
                scene.title = labelNewContactView;
                disableSearch = true;
            }
            NewContactViewPortrait{
                id: newContact
                parent: newContactViewPage.content
                dataModel: peopleModel
            }
            FooterBar { 
                id: newFooter 
                type: "new"
                currentView: newContact
                pageToLoad: myAppAllContacts
            }
            menuContent:
                ActionMenu{
                id: menu
                model: (newContact.validInput) ? [contextSave, contextCancel] : [contextCancel]
                onTriggered: {
                    if(index == 0) {
                        scene.applicationPage = myAppAllContacts;
                        newContact.contactSave();
                    }else if(index == 1) {
                        scene.applicationPage = myAppAllContacts;
                    }
                    newContactViewPage.closeMenu();
                }
            }
            onTypeChanged: {
                if(newContactViewPage.type == 0){
                    scene.filterModel = [];
                }
            }
        }
    }

    PeopleModel{
        id: peopleModel
    }

    ProxyModel{
        id: proxyModel
        Component.onCompleted:{
            proxyModel.setModel(peopleModel); //Calls setSorting() on model
        }
    }

    Labs.ApplicationsModel{
        id: appModel
    }

    ModalDialog {
        id:confirmDelete
        cancelButtonText: contextCancel
        acceptButtonText: contextDelete
        title:  deleteConfirmation
        acceptButtonImage: "image://theme/btn_red_up"
        acceptButtonImagePressed: "image://theme/btn_red_dn"
        anchors {verticalCenter: parent.verticalCenter; horizontalCenter: parent.horizontalCenter}
        content: Text {
            id: text
            wrapMode: Text.WordWrap
            text: promptStr
            color: theme_fontColorNormal
            font.pointSize: theme_fontPixelSizeMedium
            anchors {horizontalCenter: parent.horizontalCenter}
            smooth: true
            opacity: 1
        }
        onAccepted: {
            peopleModel.deletePerson(scene.currentContactId);
            if (applicationPage != myAppAllContacts)
                applicationPage = myAppAllContacts;
        }
    }
}

