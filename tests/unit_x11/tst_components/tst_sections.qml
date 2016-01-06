/*
 * Copyright 2015 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Test 1.0
import Ubuntu.Components 1.3

Rectangle {
    id: root
    width: 400
    height: 600
    color: "white"

    property list<Action> actionList: [
        Action {
            text: "first";
            onTriggered: label.text = "First action triggered.";
        },
        Action {
            text: "second";
            onTriggered: label.text = "Second action triggered.";
        },
        Action {
            text: "third";
            onTriggered: label.text = "Third action triggered.";
        }
    ]

    property var stringList: [
        "string one", "string two", "string three"
    ]

    property var longStringList: [
        "one", "two", "three", "four", "five", "six", "seven",
        "eight", "nine", "ten", "eleven", "twelve", "thirteen",
        "fourteen", "fifteen", "sixteen", "seventeen",
        "eighteen", "nineteen", "twenty"
    ]

    Column {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: units.gu(2)
        }
        spacing: units.gu(2)

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Sections with actions"
        }
        Label {
            anchors.left: parent.left
            text: "actions in-line:"
            textSize: Label.Small
        }

        Sections {
            // Not used in the tests below, but added here to
            //  verify that the Actions can be defined directly
            //  inside the list of actions.
            actions: [
                Action { text: "inline action 1" },
                Action { text: "inline action 2" }
            ]
        }
        Label {
            anchors.left: parent.left
            text: "enabled:"
            textSize: Label.Small
        }
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(2)
            }
            color: UbuntuColors.blue
            height: units.gu(5)
            Label {
                id: label
                anchors.centerIn: parent
                text: "No action triggered."
                color: "white"
            }
        }
        Sections {
            id: enabledSections
            actions: root.actionList
        }
        Label {
            text: "disabled:"
            textSize: Label.Small
        }
        Sections {
            id: disabledSections
            actions: root.actionList
            enabled: false
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Sections with strings"
        }
        Label {
            anchors.left: parent.left
            text: "enabled:"
            textSize: Label.Small
        }
        Sections {
            id: enabledStringSections
            model: root.stringList
        }
        Label {
            anchors.left: parent.left
            text: "disabled:"
            textSize: Label.Small
        }
        Sections {
            id: disabledStringSections
            model: root.stringList
            enabled: false
        }
        Sections {
            id: selectedIndexSections
            property bool action0Triggered: false;
            property bool action1Triggered: false;
            property bool action2Triggered: false;
            property Action action0: Action {
                text: "action0"
                onTriggered: selectedIndexSections.action0Triggered = true;
            }
            property Action action1: Action {
                text: "action1"
                onTriggered: selectedIndexSections.action1Triggered = true;
            }
            property Action action2: Action {
                text: "action2"
                onTriggered: selectedIndexSections.action2Triggered = true;
            }
            actions: [action0, action1, action2]
            selectedIndex: 1
        }
    }

    UbuntuTestCase {
        id: testCase
        name: "SectionsApi"
        when: windowShown

        function initTestCase() {
            // The initially selected actions must be triggered.
            compare(label.text, "First action triggered.",
                    "The first action was not triggered automatically.");
            compare(selectedIndexSections.action0Triggered, false,
                    "Action 0 was triggered with selectedIndex: 1.");
            compare(selectedIndexSections.action1Triggered, true,
                    "Action 1 was not automatically triggered with selectedIndex: 1.");
        }

        function init() {
            enabledSections.actions = root.actionList;
            enabledSections.model = root.actionList;
            enabledSections.selectedIndex = 0;
            disabledSections.selectedIndex = 0;
            enabledStringSections.selectedIndex = 0;
            disabledStringSections.selectedIndex = 0;
            label.text = "No action triggered."
        }

        function wait_for_animation(sections) {
            // TODO when animations are added
        }

        function get_number_of_section_buttons(sections) {
            var listview = findChild(sections, "sections_listview");
            return listview.count;
        }

        // return the index of the selected section button,
        //  or -1 if no selected section button is found.
        function get_selected_section_button_index(sections) {
            var n = get_number_of_section_buttons(sections);
            var button;
            for (var i=0; i < n; i++) {
                button = findChild(sections, "section_button_"+i);
                if (button.selected) {
                    return i;
                }
            }
            return -1;
        }

        function get_selected_section_button_text(sections) {
            var index = get_selected_section_button_index(sections);
            if (index < 0) return "BUTTON NOT FOUND.";
            var button = findChild(sections, "section_button_label_"+index);
            return button.text;
        }

        function click_section_button(sections, sectionName) {
            var index = -1;
            var object;
            for (index = 0; index < sections.model.length; index++) {
                object = sections.model[index];
                // object may be a string or an Action
                if (object.hasOwnProperty("text")) {
                    if (object.text === sectionName) {
                        break;
                    }
                } else {
                    if (object === sectionName) {
                        break;
                    }
                }
            }
            verify(index >= 0, "Button with name \'"+sectionName+"\' not found.");
            var button = findChild(sections, "section_button_"+index);
            mouseClick(button, button.width/2, button.height/2);
        }

        function check_selected_section(sections, index, name) {
            var v = sections.selectedIndex;
            compare(v, index, "selectedIndex "+v+" does not match "+index);
            v = get_selected_section_button_index(sections);
            compare(v, index, "selected button index "+v+" does not match "+index);
            if (v === -1) return;
            var w = get_selected_section_button_text(sections);
            compare(w, name, "selected button text \'"+w+"\' does not match \'"+name+"\'");
        }

        // in each test function below, test the desired behavior
        //  for both enabledSections and disabledSections.

        function test_0_first_section_initially_selected_actions_enabled() {
            check_selected_section(enabledSections, 0, "first");
        }
        function test_0_first_section_initially_selected_actions_disabled() {
            check_selected_section(disabledSections, 0, "first");
        }
        function test_0_first_section_initially_selected_strings_enabled() {
            check_selected_section(enabledStringSections, 0, "string one");
        }
        function test_0_first_section_initially_selected_strings_disabled() {
            check_selected_section(disabledStringSections, 0, "string one");
        }

        function test_number_of_section_buttons() {
            var n = root.actionList.length;
            compare(get_number_of_section_buttons(enabledSections), n,
                    "Showing incorrect number of sections.");
            compare(get_number_of_section_buttons(disabledSections), n,
                    "Showing incorrect number of disabled sections.")
        }

        function test_click_to_select_section_and_trigger_action() {
            var index = 2;
            var name = "third";
            click_section_button(enabledSections, name);
            wait_for_animation(enabledSections);
            check_selected_section(enabledSections, index, name);
            var text = "Third action triggered.";
            compare(label.text, text, "Action for clicked button not triggered.");
        }

        function test_click_disabled_section_action() {
            var index = 2;
            var name = "third";
            click_section_button(disabledSections, name);
            wait_for_animation(disabledSections);
            // first button should still be selected:
            index = 0;
            name = "first";
            check_selected_section(disabledSections, index, name);
            var text = "No action triggered.";
            compare(label.text, text, "Clicking disabled button triggered something.");
        }

        function test_click_to_select_section_string() {
            var index = 2;
            var name = "string three";
            click_section_button(enabledStringSections, name);
            wait_for_animation(enabledStringSections);
            check_selected_section(enabledStringSections, index, name);
        }

        function test_click_disabled_section_string() {
            var name = "string three";
            click_section_button(disabledStringSections, name);
            wait_for_animation(disabledStringSections);
            // first button should still be selected:
            var index = 0;
            name = "string one";
            check_selected_section(disabledStringSections, index, name);
        }

        function test_set_selectedIndex_to_select_section_and_trigger_action_enabled() {
            var index = 1;
            var name = "second";
            enabledSections.selectedIndex = index;
            wait_for_animation(enabledSections);
            check_selected_section(enabledSections, index, name);
            var text = "Second action triggered.";
            compare(label.text, text, "Changing selected index did not trigger action.");
        }

        function test_set_selectedIndex_to_select_section_and_trigger_action_disabled() {
            var index = 2;
            var name = "third";
            disabledSections.selectedIndex = index;
            wait_for_animation(disabledSections);
            check_selected_section(disabledSections, index, name);
            var text = "Third action triggered.";
            compare(label.text, text, "Changing selected index for disabled Sections " +
                    "did not trigger action.");
        }

        function test_set_selectedIndex_to_select_section_string_enabled() {
            var index = 1;
            var name = "string two";
            enabledStringSections.selectedIndex = index;
            wait_for_animation(enabledStringSections);
            check_selected_section(enabledStringSections, index, name);
        }

        function test_set_selectedIndex_to_select_section_string_disabled() {
            var index = 2;
            var name = "string three";
            disabledStringSections.selectedIndex = index;
            check_selected_section(disabledStringSections, index, name);
        }

        function test_selectedIndex_when_model_changes_bug1513933() {
            enabledSections.model = ["1", "2", "3"];
            enabledSections.selectedIndex = 2;
            enabledSections.model = ["1", "2"];
            wait_for_animation(enabledSections);
            compare(enabledSections.selectedIndex, 0,
                    "Changing the model does not set the selected index to 0.");
            check_selected_section(enabledSections, 0, "1");
            enabledSections.model = [];
            wait_for_animation(enabledSections);
            compare(enabledSections.selectedIndex, -1,
                    "Setting an empty model does not set the selected index to -1.");
            enabledSections.model = ["1", "2", "3"];
            wait_for_animation(enabledSections);
            compare(enabledSections.selectedIndex, 0,
                    "Setting a non-empty model does not set the selected index to 0.");
            check_selected_section(enabledSections, 0, "1");
        }

        function test_model_changes_triggers_action_0() {
            selectedIndexSections.action0Triggered = false;
            selectedIndexSections.action1Triggered = false;
            selectedIndexSections.action2Triggered = false;
            var originalActions = selectedIndexSections.actions;
            selectedIndexSections.actions = [
                        selectedIndexSections.action0,
                        selectedIndexSections.action2
                    ]
            wait_for_animation(selectedIndexSections);
            compare(selectedIndexSections.action0Triggered, true,
                    "Changing the model does not trigger the first action.");
            compare(selectedIndexSections.action1Triggered, false,
                    "Changing the model triggers the second action.");
            compare(selectedIndexSections.action2Triggered, false,
                    "Changing the model triggers the third action.");
            selectedIndexSections.actions = originalActions;
            wait_for_animation(selectedIndexSections);
        }
    }
}
