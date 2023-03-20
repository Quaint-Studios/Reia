using System;
using System.Linq;
using UnityEngine;
using UnityEditor;
using UnityEditorInternal;

public class BuildManagerWindow : EditorWindow {
	const string SETTINGS_DEFAULT_PATH = "Assets/Editor/Setting/BuildSequences.asset"; //Need Assets in path, cuz used by AssetDatabase.CreateAsset
	const string SETTINGS_PATH_KEY = "BuildManagerWindow.SettingsPath";

	static string settingsPath;
	static BuildManagerSettings settings;

	static bool globalDataFoldout = true;

	static ChangelogData changelog;
	static bool changelogFoldout = false;
	static Vector2 scrollPosChangelog = Vector2.zero;

	static Vector2 scrollPosSequence = Vector2.zero;
	static bool postBuildFoldout = false;

	static ReorderableList sequenceList;
	static ReorderableList buildList;

	[MenuItem("Window/BuildManager/Builds window &b")]
	public static void ShowWindow() {
		sequenceList = null;
		buildList = null;
		EditorWindow.GetWindow(typeof(BuildManagerWindow), false, "Builds", true);

		LoadSettings();
	}

	void OnGUI() {
		if (settings == null)
			LoadSettings();
		if (changelog == null)
			LoadChangelog();

		DrawGlobalBuildData();
		DrawChangelogInfo();

		if (!changelogFoldout) {
			DrawBuildButtons();

			EditorGUILayout.Space(20);
			scrollPosSequence = EditorGUILayout.BeginScrollView(scrollPosSequence);

			DrawSequenceList();
			DrawSelectedSequenceData();

			EditorGUILayout.EndScrollView();
		}
		else {
			EditorGUILayout.HelpBox("Close changelog to acess build data", MessageType.Warning);
		}

		EditorUtility.SetDirty(settings);
	}

	#region Main Drawers
	void DrawGlobalBuildData() {
		globalDataFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(globalDataFoldout, "Global data");
		if (globalDataFoldout) {
			++EditorGUI.indentLevel;

			//Versions
			PlayerSettings.companyName = EditorGUILayout.TextField("Company Name", PlayerSettings.companyName);
			PlayerSettings.productName = EditorGUILayout.TextField("Product Name", PlayerSettings.productName);
			PlayerSettings.bundleVersion = EditorGUILayout.TextField("Version", PlayerSettings.bundleVersion);
			PlayerSettings.Android.bundleVersionCode = EditorGUILayout.IntField("Android bundle version", PlayerSettings.Android.bundleVersionCode);

			//Defines
			GUILayout.Space(5);
			EditorGUILayout.BeginHorizontal();
			settings.scriptingDefineSymbols = EditorGUILayout.TextField("Scripting Defines", settings.scriptingDefineSymbols);
			if (GUILayout.Button($"Set defines", GUILayout.Width(100f)))
				PlayerSettings.SetScriptingDefineSymbolsForGroup(BuildPipeline.GetBuildTargetGroup(EditorUserBuildSettings.activeBuildTarget), settings.scriptingDefineSymbols);
			EditorGUILayout.EndHorizontal();

			//Itch data
			GUILayout.Space(5);
			EditorGUILayout.BeginHorizontal();
			settings.itchGameLink = EditorGUILayout.TextField("Itch.io link", settings.itchGameLink);
			if (string.IsNullOrEmpty(settings.itchGameLink))
				settings.itchGameLink = $"teamon/{BuildManager.GetProductName()}";
			if (GUILayout.Button($"Open", GUILayout.Width(100f))) {
				int slashId = settings.itchGameLink.IndexOf("/");
				string name = settings.itchGameLink.Substring(0, slashId);
				string game = settings.itchGameLink.Substring(slashId + 1);
				Application.OpenURL($"https://{name}.itch.io/{game}");
			}
			if (GUILayout.Button($"Docs", GUILayout.Width(100f))) {
				Application.OpenURL($"https://itch.io/docs/butler/pushing.html");
			}
			EditorGUILayout.EndHorizontal();

			//Github data
			GUILayout.Space(5);
			EditorGUILayout.BeginHorizontal();
			settings.GithubToken = EditorGUILayout.TextField("Github token", settings.GithubToken);
			if (GUILayout.Button($"Generate", GUILayout.Width(100f)))
				Application.OpenURL($"https://github.com/settings/tokens");
			if (GUILayout.Button($"Docs", GUILayout.Width(100f)))
				Application.OpenURL($"https://github.com/github-release/github-release");
			EditorGUILayout.EndHorizontal();

			EditorGUILayout.BeginHorizontal();
			settings.githubUserName = EditorGUILayout.TextField("Github user name", settings.githubUserName);
			if (string.IsNullOrEmpty(settings.githubUserName))
				settings.githubUserName = $"Team-on";
			if (GUILayout.Button($"Open", GUILayout.Width(100f)))
				Application.OpenURL($"https://github.com/{settings.githubUserName}");
			EditorGUILayout.EndHorizontal();

			EditorGUILayout.BeginHorizontal();
			settings.githubRepoName = EditorGUILayout.TextField("Github repo name", settings.githubRepoName);
			if (string.IsNullOrEmpty(settings.githubRepoName))
				settings.githubRepoName = BuildManager.GetProductName();
			if (GUILayout.Button($"Open", GUILayout.Width(100f)))
				Application.OpenURL($"https://github.com/{settings.githubUserName}/{settings.githubRepoName}");
			EditorGUILayout.EndHorizontal();


			--EditorGUI.indentLevel;
		}
		EditorGUILayout.EndFoldoutHeaderGroup();

		if (globalDataFoldout)
			EditorGUILayout.Space(20);
	}

	void DrawChangelogInfo() {
		changelogFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(changelogFoldout, "Changelog");
		EditorGUILayout.EndFoldoutHeaderGroup();
	
		if (changelogFoldout) {
			scrollPosChangelog = EditorGUILayout.BeginScrollView(scrollPosChangelog/*, GUILayout.Height(800f)*/);
			++EditorGUI.indentLevel;

			EditorGUILayout.LabelField("Readme");
			changelog.readme = EditorGUILayout.TextArea(changelog.readme);
			GUILayout.Space(10f);

			EditorGUILayout.BeginHorizontal();
			EditorGUILayout.LabelField("Changelog file:", GUILayout.Width(100));
			if (GUILayout.Button($"Add version"))
				changelog.versions.Add(new ChangelogData.ChangelogVersionEntry());
			EditorGUILayout.EndHorizontal();

			for (int i = changelog.versions.Count - 1; i >= 0; --i) {
				ChangelogData.ChangelogVersionEntry version = changelog.versions[i];

				EditorGUILayout.BeginHorizontal();
				version.foldout = EditorGUILayout.BeginFoldoutHeaderGroup(version.foldout, $"{version.version} - {version.date}");
				EditorGUILayout.EndFoldoutHeaderGroup();
				if (GUILayout.Button($"Remove version", GUILayout.Width(100))) {
					changelog.versions.RemoveAt(i);
					return;
				}
				EditorGUILayout.EndHorizontal();

				if (string.IsNullOrEmpty(version.version))
					version.version = PlayerSettings.bundleVersion;
				if (string.IsNullOrEmpty(version.date))
					version.date = System.DateTime.Now.ToShortDateString();

				if (version.foldout) {
					++EditorGUI.indentLevel;

					EditorGUILayout.BeginHorizontal();
					version.version = EditorGUILayout.TextField("Version", version.version);
					if (GUILayout.Button($"Curr", GUILayout.Width(70)))
						version.version = PlayerSettings.bundleVersion;
					EditorGUILayout.EndHorizontal();

					EditorGUILayout.BeginHorizontal();
					version.date = EditorGUILayout.TextField("Date", version.date);
					if (GUILayout.Button($"Now", GUILayout.Width(70)))
						version.date = System.DateTime.Now.ToShortDateString();
					EditorGUILayout.EndHorizontal();

					version.updateName = EditorGUILayout.TextField("Update name", version.updateName);
					version.descriptionText = EditorGUILayout.TextField("Description", version.descriptionText);

					EditorGUILayout.LabelField("Notes: ");

					++EditorGUI.indentLevel;
					EditorGUILayout.BeginHorizontal();
					EditorGUILayout.LabelField("Type", GUILayout.Width(150));
					EditorGUILayout.LabelField("Scope", GUILayout.Width(125));
					EditorGUILayout.LabelField("Community", GUILayout.Width(100));
					EditorGUILayout.LabelField("Description");
					EditorGUILayout.EndHorizontal();

					for (int j = 0; j < version.notes.Count; ++j) {
						ChangelogData.ChangelogNoteEntry note = version.notes[j];
						EditorGUILayout.BeginHorizontal();

						ChangelogData.ChangelogEntryType newType = (ChangelogData.ChangelogEntryType)EditorGUILayout.EnumPopup(note.type, GUILayout.Width(150));
						ChangelogData.ChangelogEntryScope newScope = (ChangelogData.ChangelogEntryScope)EditorGUILayout.EnumPopup(note.scope, GUILayout.Width(150));
						note.isCommunityFeedback = EditorGUILayout.Toggle(note.isCommunityFeedback, GUILayout.Width(70));
						note.text = EditorGUILayout.TextField(note.text);

						if (note.type != newType || note.scope != newScope) {
							note.type = newType;
							note.scope = newScope;
							version.notes = version.notes.OrderBy(_note => _note.type).ThenBy(_note => _note.scope).ToList();
							return;
						}

						if (GUILayout.Button($"-", GUILayout.Width(25))) {
							version.notes.RemoveAt(j);
							return;
						}

						EditorGUILayout.EndHorizontal();
					}
					--EditorGUI.indentLevel;
				
					if (GUILayout.Button($"Add note"))
						version.notes.Add(new ChangelogData.ChangelogNoteEntry());

					--EditorGUI.indentLevel;
				}

				EditorGUILayout.Space(10);
			}

			--EditorGUI.indentLevel;
			EditorGUILayout.EndScrollView();

#if GAME_TEMPLATE
		TemplateGameManager.InstanceEditor.buildNameString = changelog.GetLastVersion().GetVersionHeader();;
		TemplateGameManager.InstanceEditor.productName = PlayerSettings.productName;
		EditorUtility.SetDirty(TemplateGameManager.InstanceEditor);
#endif
		}

		if (GUI.changed)
			ChangelogData.SaveChangelog(changelog);

		if (changelogFoldout)
			EditorGUILayout.Space(20);
	}

	void DrawBuildButtons() {
		if ((settings?.sequences?.Count ?? 0) != 0) {
			int enabledSequence = 0;
			foreach (var sequence in settings.sequences)
				if (sequence.isEnabled)
					++enabledSequence;

			if (enabledSequence == 0)
				return;

			Color prevColor = GUI.backgroundColor;
			GUI.backgroundColor = new Color(0.773f, 0.345098f, 0.345098f);

			EditorGUILayout.LabelField("Start build sequence(they red not becouse error, but becouse build stuck your pc if you accidentaly press it)");
			EditorGUILayout.LabelField("Don't forget to manually download new version of polyglot localization if you want to update it");

			EditorGUILayout.BeginHorizontal();
			for (int i = 0; i < settings.sequences.Count; ++i) {
				BuildSequence sequence = settings.sequences[i];

				if (i != 0 && i % 3 == 0) {
					EditorGUILayout.EndHorizontal();
					EditorGUILayout.BeginHorizontal();
				}

				if (sequence.isEnabled && GUILayout.Button($"Build {sequence.editorName}")) {
					BuildManager.RunBuildSequnce(settings, sequence, changelog);
				}
			}
			EditorGUILayout.EndHorizontal();

			GUI.backgroundColor = prevColor;
		}
	}

	void DrawSequenceList() {
		if (sequenceList == null) {
			PredefinedBuildConfigs.Init();
			sequenceList = BuildSequenceReordableList.Create(settings.sequences, OnSequenceAdd, "Builds sequences");
			sequenceList.onSelectCallback += OnSequenceSelectionChanged;
			sequenceList.index = 0;
		}

		sequenceList.DoLayoutList();

		if (0 <= sequenceList.index && sequenceList.index < sequenceList.count) {
			BuildSequence selected = settings.sequences[sequenceList.index];

			EditorGUILayout.BeginHorizontal();
			selected.scriptingDefineSymbolsOverride = EditorGUILayout.TextField("Defines sequence override", selected.scriptingDefineSymbolsOverride);
			if (GUILayout.Button($"Set defines", GUILayout.Width(100f))) {
				PlayerSettings.SetScriptingDefineSymbolsForGroup(BuildPipeline.GetBuildTargetGroup(EditorUserBuildSettings.activeBuildTarget), string.Concat(settings.scriptingDefineSymbols, ";", selected.scriptingDefineSymbolsOverride));
			}
			EditorGUILayout.EndHorizontal();
		}
	}

	void DrawSelectedSequenceData() {
		EditorGUILayout.Space(20);

		if (sequenceList.index < 0 || sequenceList.index >= settings.sequences.Count) {
			buildList = null;
			return;
		}

		if (buildList == null) {
			buildList = BuildDataReordableList.Create(settings.sequences[sequenceList.index].builds, OnBuildAdd, "Builds");
			buildList.onSelectCallback += OnBuildSelectionChanged; ;
			buildList.index = 0;
		}

		buildList.DoLayoutList();

		if (buildList.index < 0 || buildList.index >= settings.sequences[sequenceList.index].builds.Count)
			return;

		BuildData selected = settings.sequences[sequenceList.index].builds[buildList.index];

		SerializedObject obj = new SerializedObject(settings);

		selected.isPassbyBuild = EditorGUILayout.Toggle("Is Passby build", selected.isPassbyBuild);
		selected.isReleaseBuild = EditorGUILayout.Toggle("Is Release build", selected.isReleaseBuild);
		selected.isVirtualRealitySupported = EditorGUILayout.Toggle("VR Supported", selected.isVirtualRealitySupported);

		EditorGUILayout.Space(20);
		selected.outputRoot = EditorGUILayout.TextField("Output root", selected.outputRoot);
		selected.middlePath = EditorGUILayout.TextField("Middle path", selected.middlePath);
		selected.dirPathForPostProcess = EditorGUILayout.TextField("Dir path", selected.dirPathForPostProcess);

		EditorGUILayout.BeginHorizontal();
		selected.scriptingDefineSymbolsOverride = EditorGUILayout.TextField("Defines build override", selected.scriptingDefineSymbolsOverride);
		if (GUILayout.Button($"Set defines", GUILayout.Width(100f))) {
			PlayerSettings.SetScriptingDefineSymbolsForGroup(BuildPipeline.GetBuildTargetGroup(EditorUserBuildSettings.activeBuildTarget), string.Concat(settings.scriptingDefineSymbols, ";", settings.sequences[sequenceList.index].scriptingDefineSymbolsOverride, ";", selected.scriptingDefineSymbolsOverride));
		}
		EditorGUILayout.EndHorizontal();

		EditorGUILayout.Space(20);
		postBuildFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(postBuildFoldout, "Post build processing");
		if (postBuildFoldout) {
			++EditorGUI.indentLevel;
			selected.needZip = EditorGUILayout.Toggle("Compress", selected.needZip);
			selected.needGithubPush = EditorGUILayout.Toggle("Push to github releases", selected.needGithubPush);
			if (selected.needGithubPush && !selected.needZip) {
				selected.needZip = true;
				Debug.Log(".zip must be created before pushing to GitHub releases");
			}

			EditorGUILayout.LabelField("itch.io:");
			++EditorGUI.indentLevel;
			selected.needItchPush = EditorGUILayout.Toggle("Push to itch.io", selected.needItchPush);
			selected.itchChannel = EditorGUILayout.TextField("Channel", selected.itchChannel);
			--EditorGUI.indentLevel;

			--EditorGUI.indentLevel;
		}
		EditorGUILayout.EndFoldoutHeaderGroup();
	}
	#endregion

	#region Loaders
	static void LoadSettings() {
		settingsPath = PlayerPrefs.GetString(SETTINGS_PATH_KEY, "");
		settings = null;

		//Find path. Try to load settings
		if (!string.IsNullOrEmpty(settingsPath)) {
			settings = AssetDatabase.LoadAssetAtPath<BuildManagerSettings>(settingsPath);
			if (settings == null) {
				settingsPath = null;
			}
		}

		//No path, or cant locate asset at path. Try to find settings in assets.
		if (string.IsNullOrEmpty(settingsPath)) {
			string[] guids = AssetDatabase.FindAssets("t:BuildManagerSettings", new string[] { "Assets" });
			if (guids.Length >= 2) {
				Debug.LogError("[BuildManagerWindow]. 2+ BuildManagerSettings exist. Consider on using only 1 setting. The first one will be used.");
			}

			if (guids.Length != 0) {
				settingsPath = AssetDatabase.GUIDToAssetPath(guids[0]);
				PlayerPrefs.SetString(SETTINGS_PATH_KEY, settingsPath);
				settings = AssetDatabase.LoadAssetAtPath<BuildManagerSettings>(settingsPath);
			}
		}

		//Cant find settings. Create new
		if (settings == null) {
			BuildManagerSettings defaultSettings = AssetDatabase.LoadAssetAtPath<BuildManagerSettings>(AssetDatabase.GUIDToAssetPath(AssetDatabase.FindAssets("t:BuildManagerSettings", new string[] { "Packages" })[0]));

			settings = (BuildManagerSettings)ScriptableObject.CreateInstance(typeof(BuildManagerSettings));
			settings.CloneInto(defaultSettings);

			AssetDatabase.CreateAsset(settings, SETTINGS_DEFAULT_PATH);
			settingsPath = SETTINGS_DEFAULT_PATH;
			PlayerPrefs.SetString(SETTINGS_PATH_KEY, SETTINGS_DEFAULT_PATH);
		}
	}

	static void LoadChangelog() {
		changelog = ChangelogData.LoadChangelog();
	}

	#endregion

	#region Callbacks
	static void OnSequenceSelectionChanged(ReorderableList list) {
		buildList = null;
	}

	static void OnBuildSelectionChanged(ReorderableList list) {

	}

	static void OnSequenceAdd(object target) {
		settings.sequences.Add((target as BuildSequence).Clone() as BuildSequence);
	}

	static void OnBuildAdd(object target) {
		settings.sequences[sequenceList.index].builds.Add((target as BuildData).Clone() as BuildData);
	}

	#endregion

	#region Helpers
	void GuiLine(int i_height = 1) {
		Rect rect = EditorGUILayout.GetControlRect(false, i_height);
		rect.height = i_height;
		EditorGUI.DrawRect(rect, new Color(0.5f, 0.5f, 0.5f, 1));
	}
	#endregion
}
