using System;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;

[Serializable]
public class ChangelogData {

	public List<ChangelogVersionEntry> versions = new List<ChangelogVersionEntry>() { new ChangelogVersionEntry() };
	[TextArea(3, 10)] public string readme;

	public ChangelogVersionEntry GetLastVersion() {
		if (versions.Count == 0)
			return new ChangelogVersionEntry();
		return versions[versions.Count - 1];
	}

	public string GetChangelogString() {
		StringBuilder sb = new StringBuilder();

		sb.Append("Note: 📢 indicates a change inspired by community feedback!\n");

		for (int i = versions.Count - 1; i >= 0; --i) {
			versions[i].GetChangelog(ref sb);
		}

		return sb.ToString();
	}

	public string GetLastChangelogString() {
		StringBuilder sb = new StringBuilder();
		sb.Append("Note: 📢 indicates a change inspired by community feedback!\n");
		versions[versions.Count - 1].GetChangelog(ref sb);
		return sb.ToString();
	}


	#region Serialization
	const string SAVE_FILE_NOREZ = "ChangelogSettings";
	const string SAVE_FILE = "ChangelogSettings.json";
	const string SAVE_FILE_EDITORPREFS = "ChangelogSettings.Save";
	const string SAVE_FILE_EDITORPREFS_DEFAULT = "Editor/Setting/ChangelogSettings.json";

	public static void SaveChangelog(ChangelogData data) {
		if (!PlayerPrefs.HasKey(SAVE_FILE_EDITORPREFS)) {
			string[] allPath = AssetDatabase.FindAssets(SAVE_FILE_NOREZ);
			if (allPath.Length != 0)
				PlayerPrefs.SetString(SAVE_FILE_EDITORPREFS, AssetDatabase.GUIDToAssetPath(allPath[0]).Replace("Assets/", ""));
		}

		string savePath = Path.Combine(Application.dataPath, PlayerPrefs.GetString(SAVE_FILE_EDITORPREFS, SAVE_FILE_EDITORPREFS_DEFAULT));

		string json = JsonUtility.ToJson(data, true);

		if (!File.Exists(savePath)) {
			FileInfo file = new FileInfo(savePath);
			file.Directory.Create();
		}

		File.WriteAllText(savePath, json);
	}

	public static ChangelogData LoadChangelog() {
		if (!PlayerPrefs.HasKey(SAVE_FILE_EDITORPREFS)) {
			string[] allPath = AssetDatabase.FindAssets(SAVE_FILE_NOREZ);
			if (allPath.Length != 0)
				PlayerPrefs.SetString(SAVE_FILE_EDITORPREFS, AssetDatabase.GUIDToAssetPath(allPath[0]).Replace("Assets/", ""));
		}

		string savePath = Path.Combine(Application.dataPath, PlayerPrefs.GetString(SAVE_FILE_EDITORPREFS, SAVE_FILE_EDITORPREFS_DEFAULT));

		if (!File.Exists(savePath)) {
			return new ChangelogData();
		}
		else {
			string json = File.ReadAllText(savePath);
			return JsonUtility.FromJson<ChangelogData>(json);
		}
	}
	#endregion

	[Serializable]
	public class ChangelogVersionEntry {
		[NonSerialized] public bool foldout = false;

		public string version;
		public string date;
		public string updateName;

		public string descriptionText;

		public List<ChangelogNoteEntry> notes = new List<ChangelogNoteEntry>();

		public string GetVersionHeader() {
			string header;

			if (!string.IsNullOrEmpty(updateName) && !string.IsNullOrEmpty(date)) {
				header = $"{version} - {updateName} ({date})";
			}
			else if (!string.IsNullOrEmpty(updateName)) {
				header = $"{version} - {updateName}";
			}
			else if (!string.IsNullOrEmpty(date)) {
				header = $"{version} ({date})";
			}
			else {
				header = $"{version}";
			}

			return header;
		}

		public void GetChangelog(ref StringBuilder sb) {
			ChangelogEntryType lastType = (ChangelogEntryType)255;
			ChangelogEntryScope lastScope = (ChangelogEntryScope)255;

			sb.Append("\n\n---------- \n");
			sb.Append("# ");
			sb.Append(GetVersionHeader());
			sb.Append("\n");

			sb.Append(descriptionText);
			sb.Append("\n");

			for (int j = 0; j < notes.Count; ++j) {
				if (lastType != notes[j].type) {
					if (lastType != (ChangelogEntryType)255)
						sb.Append("\n");
					lastType = notes[j].type;
					lastScope = (ChangelogEntryScope)255;
					sb.Append("### ");
					sb.Append(notes[j].type);
					sb.Append(": \n");
				}

				if (lastScope != notes[j].scope) {
					lastScope = notes[j].scope;
					sb.Append("#### ");
					sb.Append(notes[j].scope);
					sb.Append(": \n");
				}

				notes[j].GetChangelog(ref sb);
			}
		}
	}

	[Serializable]
	public class ChangelogNoteEntry {
		public bool isCommunityFeedback = false;
		public ChangelogEntryType type;
		public ChangelogEntryScope scope;
		public string text;

		public void GetChangelog(ref StringBuilder sb) {
			sb.Append(" * ");
			if (isCommunityFeedback)
				sb.Append("📢 ");
			sb.Append(text);
			sb.Append("\n");
		}
	}

	public enum ChangelogEntryType : byte {
		General = 0,
		Docs = 1,
		Features = 2,
		Fixes = 3,
		Optimizations = 4,
		Improvements = 5,
		Changes = 6,
		Refactoring = 7,
		Testing = 8,
		KnownIssues = 9,
	}

	public enum ChangelogEntryScope : byte {
		General = 0,
		Gameplay = 1,
		LevelDesign = 2,
		Art = 3,
		VFX = 4,
		UI = 5,
		Music = 6,
		SFX = 7,
		Voice = 8,
		Narrative = 9,
		Miscellaneous = 10,
	}
}
