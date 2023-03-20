using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class BuildDataReordableList {
	public static UnityEditorInternal.ReorderableList Create(List<BuildData> configsList, GenericMenu.MenuFunction2 menuItemHandler, string header) {
		var reorderableList = new UnityEditorInternal.ReorderableList(configsList, typeof(BuildData), true, false, true, true);

		reorderableList.elementHeight = EditorGUIUtility.singleLineHeight + 4;
		reorderableList.drawHeaderCallback = (Rect rect) => { EditorGUI.LabelField(rect, header); };
		reorderableList.drawElementCallback = (position, index, isActive, isFocused) => {
			const float enabledWidth = 15f;
			const float buildTargetGroupWidth = 125f;
			const float buildTargetWidth  = 150f;
			const float minbuildOptionsWidth = 100f;
			const float space = 10f;

			float buildOptionsWidth = position.width - space * 6 - enabledWidth - buildTargetWidth - buildTargetGroupWidth;
			if (buildOptionsWidth < minbuildOptionsWidth)
				buildOptionsWidth = minbuildOptionsWidth;

			BuildData data = configsList[index];

			position.y += 2;
			position.height -= 4;

			position.x += space;
			position.width = enabledWidth;
			data.isEnabled = EditorGUI.Toggle(position, data.isEnabled);
			EditorGUI.BeginDisabledGroup(!data.isEnabled);

			position.x += position.width + space;
			position.width = buildTargetGroupWidth;
			data.targetGroup = (BuildTargetGroup)EditorGUI.EnumPopup(position, data.targetGroup);

			position.x += position.width + space;
			position.width = buildTargetWidth;
			data.target = (BuildTarget)EditorGUI.EnumPopup(position, data.target);

			position.x += position.width + space;
			position.width = buildOptionsWidth;
			data.options = (BuildOptions)EditorGUI.EnumFlagsField(position, data.options);

			EditorGUI.EndDisabledGroup();
		};

		reorderableList.onAddDropdownCallback = (buttonRect, list) => {
			var menu = new GenericMenu();

			menu.AddItem(new GUIContent("Custom"), false, menuItemHandler, new BuildData());
			menu.AddSeparator("");

			foreach (BuildData config in PredefinedBuildConfigs.standaloneData) {
				var label = /*"Standalone/" +*/ BuildManager.ConvertBuildTargetToString(config.target);
				menu.AddItem(new GUIContent(label), false, menuItemHandler, config);
			}
			menu.AddSeparator("");

			foreach (BuildData config in PredefinedBuildConfigs.androidData) {
				var label = /*"Android/" +*/ BuildManager.ConvertBuildTargetToString(config.target);
				menu.AddItem(new GUIContent(label), false, menuItemHandler, config);
			}
			menu.AddSeparator("");

			foreach (BuildData config in PredefinedBuildConfigs.webData) {
				var label = /*"WebGL/"+ */ BuildManager.ConvertBuildTargetToString(config.target);
				menu.AddItem(new GUIContent(label), false, menuItemHandler, config);
			}
			menu.AddSeparator("");


			menu.ShowAsContext();
		};

		return reorderableList;
	}
}
