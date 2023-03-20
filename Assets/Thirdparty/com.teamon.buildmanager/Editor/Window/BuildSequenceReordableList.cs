using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class BuildSequenceReordableList {
	public static UnityEditorInternal.ReorderableList Create(List<BuildSequence> configsList, GenericMenu.MenuFunction2 menuItemHandler, string header) {
		var reorderableList = new UnityEditorInternal.ReorderableList(configsList, typeof(BuildSequence), true, false, true, true);

		reorderableList.elementHeight = EditorGUIUtility.singleLineHeight + 4;
		reorderableList.drawHeaderCallback = (Rect rect) => { EditorGUI.LabelField(rect, header); };
		reorderableList.drawElementCallback = (position, index, isActive, isFocused) => {
			const float enabledWidth = 15f;
			const float space = 10f;
			const float minNameWidth = 100f;
			
			BuildSequence sequence = configsList[index];
			var nameWidth = position.width - space * 3 - enabledWidth;
			if (nameWidth < minNameWidth)
				nameWidth = minNameWidth;

			position.y += 2;
			position.height -= 4;

			position.x += space;
			position.width = enabledWidth;
			sequence.isEnabled = EditorGUI.Toggle(position, sequence.isEnabled);
			EditorGUI.BeginDisabledGroup(!sequence.isEnabled);

			position.x += position.width + space;
			position.width = nameWidth;
			sequence.editorName = EditorGUI.TextField(position, sequence.editorName);

			EditorGUI.EndDisabledGroup();
		};

		reorderableList.onAddDropdownCallback = (buttonRect, list) => {
			var menu = new GenericMenu();

			menu.AddItem(new GUIContent("Custom"), false, menuItemHandler, new BuildSequence("Custom", new BuildData()));
			menu.AddSeparator("");

			string label = $"{PredefinedBuildConfigs.testingSequence.editorName}";
			menu.AddItem(new GUIContent(label), false, menuItemHandler, PredefinedBuildConfigs.testingSequence);

			label = $"{PredefinedBuildConfigs.testingSequenceZip.editorName}";
			menu.AddItem(new GUIContent(label), false, menuItemHandler, PredefinedBuildConfigs.testingSequenceZip);


			menu.AddSeparator("");
			label = $"{PredefinedBuildConfigs.releaseLocalSequence.editorName}";
			menu.AddItem(new GUIContent(label), false, menuItemHandler, PredefinedBuildConfigs.releaseLocalSequence);

			label = $"{PredefinedBuildConfigs.releaseLocalZipSequence.editorName}";
			menu.AddItem(new GUIContent(label), false, menuItemHandler, PredefinedBuildConfigs.releaseLocalZipSequence);

			label = $"{PredefinedBuildConfigs.releaseFullSequence.editorName}";
			menu.AddItem(new GUIContent(label), false, menuItemHandler, PredefinedBuildConfigs.releaseFullSequence);


			menu.AddSeparator("");
			label = $"{PredefinedBuildConfigs.passbySequence.editorName}";
			menu.AddItem(new GUIContent(label), false, menuItemHandler, PredefinedBuildConfigs.passbySequence);


			menu.ShowAsContext();
		};

		return reorderableList;
	}
}
