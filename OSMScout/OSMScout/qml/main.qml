import QtQuick 2.3
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0

//import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
//import QtQuick.Controls.Styles 1.2
import QtQuick.Window 2.0

import QtPositioning 5.3
import QtSystemInfo 5.0
import QtMultimedia 5.0
import net.sf.libosmscout.map 1.0
import Qt.labs.settings 1.0


import "custom"
Window{
    //Avoid screen from going blank after some time...
    UnityScreen {
        id: screen
        keepDisplayOn: true
    }

    ScreenSaver { screenSaverEnabled: false }
    Settings {
        id: settings
        property bool metricSystem: (Qt.locale().measurementSystem===Locale.MetricSystem)
        property bool drivingDirUp: false
    }

    LocationListModel {
        id: suggestionModel
    }

    SettingsDialog {
        id: settingsDialog
    }

    DownloadMapDialog{
        id: downloadMapDialog
    }

    AboutDialog{
        id: aboutDialog
    }

    FavouritesDialog{
        id: favouritesDialog
    }

    width: units.gu(100)
    height: units.gu(160)

    id: mainWindow
    //objectName: "main"
    title: "OSMScout"
    visible: true
    property double oldX: 0;
    property double oldY: 0;
    property double previousX: 0;
    property double previousY: 0;
    property double deltaX: 0;
    property double deltaY: 0;
    property bool followMe: true;
    //property bool drivingDirUp: false;
    property string routeFrom: qsTr("<current position>");
    property string routeTo: "";
    property Location routeFromLoc;
    property Location routeToLoc;
    property bool allowRecalculation: true;
    property bool navigatehere: false;
    property bool aspectratio: false;
    //property bool pinchUpd: false;
    property bool pinchfin: false;
    property bool routeupd: false;
    property bool mouseupd: false;

    function openRoutingDialog() {
        updatescreen.stop();
        var component = Qt.createComponent("RoutingDialog.qml")
        var dialog = component.createObject(mainWindow, {})
        map.visible = false;
        positionSource.processUpdateEvents=false;
        map.enabled = false;
        dialog.opened.connect(onDialogOpened)
        dialog.closed.connect(onDialogClosed)
        dialog.open()
    }

    function openAboutDialog() {
        updatescreen.stop();
        positionSource.processUpdateEvents = false;
        var sd = PopupUtils.open(aboutDialog);
        sd.closed.connect(onDialogClosed);
    }

    function openFavouritesDialog() {
        updatescreen.stop();
        positionSource.processUpdateEvents = false;
        var sd = PopupUtils.open(favouritesDialog);
        sd.opened();
        sd.closed.connect(onDialogClosed);
    }

    function openDownloadMapDialog() {
        updatescreen.stop();
        positionSource.processUpdateEvents=false;
        var sd = PopupUtils.open(downloadMapDialog);
        sd.closed.connect(onDialogClosed);
    }

    function openSettingsDialog() {
        updatescreen.stop();
         positionSource.processUpdateEvents=false;
        var sd = PopupUtils.open(settingsDialog);
        sd.closed.connect(onDialogClosed);
    }

    function onDialogOpened() {
        positionSource.processUpdateEvents=false;
    }

    function onDialogClosed() {
        updatescreen.start();
        map.focus = true;
        positionSource.processUpdateEvents=true;
        map.enabled = true;
        map.visible = true;
    }
    Timer{
        id: followMeTimer
        repeat: false
        interval: 30000
        running: false
        onTriggered: {
            console.log("Timer expired");
            followMe = true;
        }
    }
    Timer{
        id: stopRecalucationTimer
        repeat: false
        interval: 10000
        running: false
        onTriggered: {
            console.log("Timer expired");
            allowRecalculation = true;
        }
    }
    Timer{
        id: updatescreen
        repeat: true
        interval: 1000
        running: true
        onTriggered: {
            console.log("recalculating");
            updatemap()
        }
    }
    function updatemap(){
        if(navigatehere){
            navigatehere=false;
            positionSource.processUpdateEvents = false;
            quickNav.visible=false;
            console.log("Navigate here");
            var lon, lat;

            lon = positionSource.position.coordinate.longitude;
            lat = positionSource.position.coordinate.latitude;
            console.log("Navigating from: "+lon+" "+lat);
            //var locString = (lat>0?"N":"S")+Math.abs(lat)+" "+(lon>0?"E":"W")+Math.abs(lon);
            var locString = Math.abs(lat)+(lat>0?" N ":" S ")+Math.abs(lon)+(lon>0?" E ":" W ");

            suggestionModel.setPattern(locString);
            if (suggestionModel.count>=1) {
                routeFromLoc=suggestionModel.get(0);
                routeFrom = qsTr("<current position>");
            }
            lon = map.pixelToGeoLon(quickNav.x, quickNav.y);
            lat = map.pixelToGeoLat(quickNav.x, quickNav.y);
            console.log("Navigating to: "+lon+" "+lat);
            //locString = (lat>0?"N":"S")+Math.abs(lat)+" "+(lon>0?"E":"W")+Math.abs(lon);
            locString = Math.abs(lat)+(lat>0?" N ":" S ")+Math.abs(lon)+(lon>0?" E ":" W ");
            suggestionModel.setPattern(locString);
            if (suggestionModel.count>=1) {
                routeToLoc=suggestionModel.get(0);
                routeTo = locString;
                console.log("routeto_tets: " +routeToLoc);
            }
            if(routeToLoc && routeFromLoc){
                console.log("Setting target");
                routingModel.setStartAndTarget(routeFromLoc, routeToLoc);
            }
            console.log("routing OK");
            positionSource.processUpdateEvents = true;
            //return;
        }

        if (aspectratio){
            aspectratio=false;
            map.updateFreeRect();
        }

//        if (pinchUpd*false){
//            if(!positionSource.awayFromRoute)
//                 map.zoomQuick(pinch.scale1);
//             //map.moveQuick(pinch.startCenter.x-pinch.center.x, pinch.startCenter.y-pinch.center.y);
//             var hw = map.width/2;
//             var hh = map.height/2;

//             positionCursor.x += (positionCursor.x - hw) - (positionCursor.x - hw)/(pinch.scale1/pinch.previousScale1);
//             positionCursor.y += (positionCursor.y - hh) - (positionCursor.y - hh)/(pinch.scale1/pinch.previousScale1);
//             if(quickNav.visible)
//             {
//                 quickNav.x += (quickNav.x - hw) - (quickNav.x - hw)/(pinch.scale1/pinch.previousScale1);
//                 quickNav.y += (quickNav.y - hh) - (quickNav.y - hh)/(pinch.scale1/pinch.previousScale1);
//             }
//        }

        if (pinchfin){
            pinchfin=false;
            if(followMeTimer.running)
                followMeTimer.restart();
            if(followMe)
            {
                followMe = false;
                followMeTimer.start(); //re-enable after 30 seconds
            }
            map.zoom(pinch.scale1);//, pinch.startCenter.x-pinch.center.x, pinch.startCenter.y-pinch.center.y);
            positionSource.processUpdateEvents = true;
        }

        if (mouseupd){
            mouseupd=false;
            positionSource.processUpdateEvents = true;
            map.move(deltaX, deltaY);

        }


        if (positionSource.position.latitudeValid&&routeupd) {
            routeupd=false;
            if(positionSource.position.directionValid && settings.drivingDirUp===true){
                map.setRotation(-1*positionSource.position.direction);
            }
            var routeStep = routingModel.getNext(positionSource.position.coordinate.latitude, positionSource.position.coordinate.longitude);
            positionSource.awayFromRoute = routingModel.getAwayFromRoute();
            if(reCalculatingMessage.visible === true) positionSource.awayFromRoute=true;
            if(positionSource.awayFromRoute===true)
            {
                if(allowRecalculation===false)
                {
                    positionSource.awayFromRoute = false;
                    return;
                }
                if(reCalculatingMessage.visible === false)
                {
                    reCalculatingMessage.visible = true;
                    reCalculatingMessage.update();
                    return; ///will continue on next gps update
                }
                if(map.isRendering()){
                    return;
                }
                positionSource.processUpdateEvents = false;
                console.log("Recalculating route");
                var lat = positionSource.position.coordinate.latitude;
                var lon = positionSource.position.coordinate.longitude;
                var locString = (lat>0?"N":"S")+Math.abs(lat)+" "+(lon>0?"E":"W")+Math.abs(lon);
                var tempLoc = routeFromLoc; // temporarily store current start location in case recalculation fails.
                suggestionModel.setPattern(locString);
                if (suggestionModel.count>=1) {
                    routeFromLoc=suggestionModel.get(0);
                }
                if(routeToLoc && routeFromLoc){
                    console.log("Old route had "+routingModel.count+" points");
                    routingModel.setStartAndTarget(routeFromLoc,routeToLoc);
                    console.log("New route has "+routingModel.count+" points");
                    if(routingModel.count === 0)
                    {
                        routeFromLoc = tempLoc;
                        routingModel.setStartAndTarget(routeFromLoc,routeToLoc);

                    }
                }
                reCalculatingMessage.visible = false;
                reCalculatingMessage.update();
                allowRecalculation = false;
                stopRecalucationTimer.start();
                positionSource.processUpdateEvents = true;
                return;
            }
            positionSource.awayFromRoute = false;
            playRouteInstruction(routeStep.dCurrentDistance, routeStep.icon, routeStep.index);
            routeIcon.source = "qrc:///pics/"+routeStep.icon;
            routeDistance.text = routeStep.currentDistance;
            routeDist.text = routeStep.targetDistance;
            routeTime.text = routeStep.targetTime;
            //routeInstructionText.text = "<b>"+ routeStep.description + "</b><br/>"+routeStep.distance;
            positionCursor.x = map.geoToPixelX(positionSource.position.coordinate.longitude, positionSource.position.coordinate.latitude)-positionCursor.width/2;
            positionCursor.y = map.geoToPixelY(positionSource.position.coordinate.longitude, positionSource.position.coordinate.latitude)-positionCursor.height/2;

            if(followMe==true)
            {
                map.showCoordinates(positionSource.position.coordinate.latitude, positionSource.position.coordinate.longitude);
            }
        }
    }


    property int lastPlayedIndex1: -1;
    property int lastPlayedIndex2: -1;
    property var nextAudio: soundstraight;
    property var distAudio: sound50m;
    function playRouteInstruction(distance, icon, index)
    {
        var firstDistance;
        var secondDistance;
        if(index!==lastPlayedIndex1 || index!==lastPlayedIndex2)
        {
            if(positionSource.position.speed*3.6 > 50)
            {
                distAudio = sound800m;
                firstDistance = 0.800;
                secondDistance = 0.200;
            }
            else if(positionSource.position.speed*3.6 > 15)
            {
                distAudio = sound200m;
                firstDistance = 0.200;
                secondDistance = 0.050;
            }
            else
            {
                distAudio = sound50m;
                firstDistance = 0.050;
                secondDistance = 0.015;
            }


            switch(icon)
            {
                case "routeLeft.svg":
                    nextAudio = soundgoleft;break;
                case "routeRight.svg":
                    nextAudio = soundgoright;break;
                case "routeFinish.svg":
                    nextAudio = soundfinish;break;
                case "routeMotorwayEnter.svg":
                    nextAudio = soundmwenter;break;
                case "routeMotorwayLeave.svg":
                    nextAudio = soundmwleave; break;
                case "routeRoundabout1.svg":
                    nextAudio = soundround1; break;
                case "routeRoundabout2.svg":
                    nextAudio = soundround2; break;
                case "routeRoundabout3.svg":
                    nextAudio = soundround3; break;
                case "routeRoundabout4.svg":
                    nextAudio = soundround4; break;
                case "routeRoundabout5.svg":
                    nextAudio = soundround5; break;
                case "routeSharpLeft.svg":
                    nextAudio = soundsharpleft; break;
                case "routeSharpRight.svg":
                    nextAudio = soundsharpright; break;
                case "routeSlightlyLeft.svg":
                    nextAudio = soundslightlyleft; break;
                case "routeSlightlyRight.svg":
                    nextAudio = soundslightlyright; break;
                case "routeStraight.svg":
                    nextAudio = soundstraight; break;
                default: return;
            }
            if(distance <= firstDistance && distance> secondDistance
                    && index!==lastPlayedIndex1 &&index!==lastPlayedIndex2)
            {
                if(distAudio.hasAudio && nextAudio.hasAudio)
                {
                    lastPlayedIndex1=index;
                    distAudio.play();
                }
            }

            if(distance <= secondDistance
                    && index!==lastPlayedIndex2)
            {
                if(nextAudio.hasAudio)
                {
                    lastPlayedIndex2=index;
                    nextAudio.play();
                }
            }
        }
    }


    Audio {
        id: sound200m;
        source: "../sounds/200m.mp3"
        onStopped: {
            nextAudio.play();
        }
    }
    Audio {
        id: sound50m;
        source: "../sounds/50m.mp3"
        onStopped: {
            nextAudio.play();
        }
    }
    Audio {
        id: sound800m;
        source: "../sounds/800m.mp3"
        onStopped: {
            nextAudio.play();
        }
    }
    Audio { id: soundfinish;        source: "../sounds/finish.mp3" }
    Audio { id: soundgoleft;        source: "../sounds/goleft.mp3" }
    Audio { id: soundgoright;       source: "../sounds/goright.mp3" }
    Audio { id: soundmwenter;       source: "../sounds/motorwayenter.mp3" }
    Audio { id: soundmwleave;       source: "../sounds/motorwayleave.mp3" }
    Audio { id: soundround1;        source: "../sounds/roundabout1.mp3" }
    Audio { id: soundround2;        source: "../sounds/roundabout2.mp3" }
    Audio { id: soundround3;        source: "../sounds/roundabout3.mp3" }
    Audio { id: soundround4;        source: "../sounds/roundabout4.mp3" }
    Audio { id: soundround5;        source: "../sounds/roundabout5.mp3" }
    Audio { id: soundsharpleft;     source: "../sounds/sharpleft.mp3" }
    Audio { id: soundsharpright;    source: "../sounds/sharpright.mp3" }
    Audio { id: soundslightlyleft;  source: "../sounds/slightlyleft.mp3" }
    Audio { id: soundslightlyright; source: "../sounds/slightlyright.mp3" }
    Audio { id: soundstraight;      source: "../sounds/straight.mp3" }

    PositionSource {
        id: positionSource
        property bool processUpdateEvents: true
        property bool awayFromRoute: false

        active: true

        onValidChanged: {
            console.log("Positioning is " + valid)
            console.log("Last error " + sourceError)

            for (var m in supportedPositioningMethods) {
                console.log("Method " + m)
            }
        }

        onPositionChanged: {
            routeupd=true;
        }
    }



    GridLayout {
        id: content
        anchors.fill: parent

        Map {
            id: map
            Layout.fillWidth: true
            Layout.fillHeight: true
            focus: true


            function openQuickNav(x, y){
                quickNav.x=x;
                quickNav.y=y;
                quickNav.visible=true;
            }

            function updateFreeRect() {
                searchDialog.desktopFreeSpace =  Qt.rect(Theme.horizSpace,
                                                         Theme.vertSpace+searchDialog.height+Theme.vertSpace,
                                                         map.width-2*Theme.horizSpace,
                                                         map.height-searchDialog.y-searchDialog.height-3*Theme.vertSpace)
            }

            onWidthChanged: {
                aspectratio=true;
            }

            onHeightChanged: {
                aspectratio=true;
            }


            RoutingListModel {
                id: routingModel
            }
            Rectangle{
                id: precisionCircle
                x: positionCursor.x+positionCursor.width/2-width/2
                y: positionCursor.y+positionCursor.height/2-height/2
                height: map.distanceToPixels(positionSource.position.horizontalAccuracy)/2
                width: height
                color: UbuntuColors.blue
                opacity: 0.2
                radius: width/2

            }

            Item{
                id: positionCursor
                x: positionSource.position.latitudeValid?map.geoToPixelX(positionSource.position.coordinate.longitude, positionSource.position.coordinate.latitude)-width/2:0
                y: positionSource.position.latitudeValid?map.geoToPixelY(positionSource.position.coordinate.longitude, positionSource.position.coordinate.latitude)-height/2:0

                width: units.gu(4)
                height: units.gu(4)
                Image {
                    width: units.gu(4)
                    height: units.gu(4)
                    anchors.centerIn: parent
                    source: "qrc:///pics/route.svg"
                    rotation: settings.drivingDirUp?0:(positionSource.position.directionValid?positionSource.position.direction:0)
                }
            }




            PinchArea{
                id: pinch
                property real scale1: 1.0
                property real previousScale1: 1.0

                anchors.fill: parent
                //pinch.dragAxis: Pinch.XAndYAxis
                onPinchStarted: {
                    console.log("Pinch started" );
                    positionSource.processUpdateEvents = false;
                }
                onPinchUpdated: {
                    scale1=pinch.scale;
                    previousScale1=pinch.previousScale;
                   //pinchUpd=true;

                }

                onPinchFinished: {
                    scale1=pinch.scale;
                    //QpinchUpd=false;
                    pinchfin=true;

                }
                MouseArea{

                    id: mouse
                    anchors.fill: parent
                    onPressed:
                    {
                        oldX = mouse.x;
                        oldY = mouse.y;
                        previousX = mouse.x;
                        previousY = mouse.y;
                        positionSource.processUpdateEvents = false;

                    }

                    /*onPositionChanged:
                    {
                        if(!positionSource.awayFromRoute)
                            map.moveQuick(oldX - mouse.x, oldY - mouse.y);

                        positionCursor.x += (mouse.x - previousX);
                        positionCursor.y += (mouse.y - previousY);
                        if(quickNav.visible)
                        {
                            quickNav.x += (mouse.x - previousX);
                            quickNav.y += (mouse.y - previousY);
                        }

                        previousX = mouse.x;
                        previousY = mouse.y;
                    }*/

                    onReleased:
                    {
                        deltaX=oldX - mouse.x;
                        deltaY=oldY - mouse.y;
                        if(Math.abs(deltaX)>20||Math.abs(delta.y)>20)
                            {
                                if(followMeTimer.running) followMeTimer.restart();
                                 if(followMe)
                                 {
                                     followMe = false;
                                     followMeTimer.start(); //re-enable after 30 seconds
                                 }

                           }
                        oldX = mouse.x;
                        oldY = mouse.y;
                        mouseupd=true;

                    }
                    onPressAndHold: {
                        if(Math.abs(oldX - mouse.x)<20&&Math.abs(oldY - mouse.y)<20)
                            map.openQuickNav(mouse.x, mouse.y);
                    }
                }

            }

            SearchDialog {
                id: searchDialog
                y: Theme.vertSpace
                width: parent.width - 2* Theme.horizSpace
                height: units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                desktopFreeSpace:  Qt.rect(Theme.horizSpace,Theme.vertSpace+searchDialog.height+Theme.vertSpace,map.width-2*Theme.horizSpace,map.height-searchDialog.y-searchDialog.height-3*Theme.vertSpace)
                desktop: map
                onShowLocation: {
                    map.showLocation(location)
                }
            }

            Item{
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                }
                width: parent.width
                height: statsCol.height

                id: routingInstructions
                Rectangle {
                    width: parent.width
                    height: parent.height
                    color: "black"
                    opacity: 0.5
                }
                Row{
                    id: routingRow
                    width: parent.width
                    height: parent.height
                    Image{
                        id: routeIcon
                        width: parent.height
                        height: parent.height
                        source: "qrc:///pics/route.svg"
                    }
                    Label{
                        id: routeDistance
                        anchors.verticalCenter: parent.verticalCenter
                        fontSize: "x-large"
                        color: "white"
                    }
                    Item{
                        id: spacer
                        height: parent.height
                        width: parent.width-(routeIcon.width + routeDistance.width + statsCol.width)
                    }

                    Column{
                        id: statsCol
                        Label{
                            fontSize: "x-large"
                            id: routeSpeed
                            text: positionSource.position.speedValid?(positionSource.position.speed*(settings.metricSystem?3.6:2.23694)).toFixed(1)+(settings.metricSystem?" km/h":" mi/h"):" "
                            color: "white"
                        }
                        Label{
                            fontSize: "x-large"
                            id: routeDist
                            text: " "
                            color: "white"
                        }
                        Label{
                            fontSize: "x-large"
                            id: routeTime
                            text: " "
                            color: "white"
                        }
                    }

                }
            }
            Rectangle {
                id: reCalculatingMessage
                anchors {
                    horizontalCenter: map.horizontalCenter
                    verticalCenter: map.verticalCenter
                }
                width: map.width*0.66
                height: recalcMsg.height*5
                color: UbuntuColors.orange
                visible: false
                Label {
                    id: recalcMsg
                    text: qsTr("Recalculating route")
                    anchors.centerIn: parent
                }
            }


            Rectangle {
                id: osmCopyright
                anchors {
                    right: parent.right
                    bottom: routingInstructions.top
                }
                height: copyLabel.width; //units.gu(2)
                width: copyLabel.height; //units.gu(24)
                opacity: 0.5
                Label {
                    anchors.centerIn: parent
                    id: copyLabel
                    rotation: 270
                    text: qsTr(" © OpenStreetMap contributors")
                    fontSize: "small"
                }
            }

            Rectangle{
                id: quickNav
                visible: false
                color: UbuntuColors.lightGrey
                radius: units.gu(1)
                width: qnCol.width+units.gu(2)
                height: qnCol.height+units.gu(2)
                Column{
                    anchors.centerIn: parent
                    id: qnCol
                    spacing: units.gu(1)
                    Button{
                        anchors.horizontalCenter: qnCol.horizontalCenter
                        color: UbuntuColors.orange
                        id: navHere
                        text: qsTr("Navigate here");
                        onClicked:
                        {
                           navigatehere=true
                        }
                    }
                    Button{
                        anchors.horizontalCenter: qnCol.horizontalCenter
                        color: UbuntuColors.lightGrey
                        id: qnCancel
                        text: qsTr("Cancel");
                        onClicked:
                        {
                            quickNav.visible=false;
                        }
                    }
                }
            }
            Icon{
                name: "up"
                anchors.horizontalCenter: map.horizontalCenter
                anchors.bottom: map.bottom
                visible: !panel.opened&&!panel.animating


                width: units.gu(8);
                height: units.gu(4);
                color: "white"
            }

            Panel {
               id: panel
               hideTimeout: 10000
               anchors {
                   left: parent.left
                   right: parent.right
                   bottom: parent.bottom
               }
               height: map.height/2
               Item {
                   anchors.fill: parent
                   // two properties used by the toolbar delegate:
                   property bool opened: panel.opened
                   property bool animating: panel.animating
                   Column{
                       width: parent.width
                       anchors.horizontalCenter: parent.horizontalCenter
                       spacing: units.gu(1);
                       Icon{
                           name: "up"
                           anchors.horizontalCenter: parent.horizontalCenter
                           //anchors.bottom: panel.opened?panel.top:map.bottom


                           width: units.gu(8);
                           height: units.gu(4);
                           color: "white"
                       }

                       Row{
                           anchors.horizontalCenter: parent.horizontalCenter
                           spacing: units.gu(1);
                           MapButton {
                               id: routeButton
                               //label: "#"

                               onClicked: {
                                   panel.close();
                                   openRoutingDialog()
                               }
                               Image {
                                   width: parent.width*0.66
                                   height: parent.height*0.66
                                   anchors.centerIn: parent
                                   source: "qrc:///pics/route.svg"
                               }
                           }
                           MapButton {
                               id: followButton

                               onClicked: {
                                   followMe = !followMe;
                                   followMeTimer.stop();
                               }
                               iconName: followMe ? "location" : "stock_website"
                           }
                           MapButton {
                               id: drivingDirUpButton
                               onClicked: {
                                   settings.drivingDirUp = ! settings.drivingDirUp;
                                   if(settings.drivingDirUp === false)
                                   {
                                       map.setRotation(0);
                                   }

                               }
                               Image {
                                   width: parent.width
                                   height: parent.height
                                   anchors.centerIn: parent
                                   source: settings.drivingDirUp?"qrc:///pics/directionUp.svg":"qrc:///pics/northUp.svg"
                               }
                           }
                           MapButton {
                               id: manageFavouritesButton
                               onClicked: {
                                   openFavouritesDialog();
                               }
                               iconName: "starred"
                           }
                       }
                       Row{
                           anchors.horizontalCenter: parent.horizontalCenter
                           spacing: units.gu(1);

                           MapButton {
                               id: downloadButton
                               iconName: "save"
                               onClicked: {
                                   panel.close();
                                   openDownloadMapDialog();
                               }
                           }

                           MapButton {
                               id: about
                               label: "?"

                               onClicked: {
                                   panel.close();
                                   openAboutDialog()
                               }
                           }

                           MapButton {
                               id: settingsButton

                               onClicked: {
                                   panel.close();
                                   openSettingsDialog();
                               }
                               iconName: "settings"
                           }

                       }
                   }
               }
           }

        }
    }
}
