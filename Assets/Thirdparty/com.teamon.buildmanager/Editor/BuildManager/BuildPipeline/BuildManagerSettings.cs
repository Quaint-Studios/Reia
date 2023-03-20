using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class BuildManagerSettings : ScriptableObject {
	public List<BuildSequence> sequences = new List<BuildSequence>() { new BuildSequence() };

	public string scriptingDefineSymbols;

	public string itchGameLink;

	public string GithubToken {
		get {
			if(string.IsNullOrEmpty(githubToken))
				githubToken = EditorPrefs.GetString("BuildManager.GitHub.Token", "");
			return githubToken;
		}
		set {
			githubToken = value;
			EditorPrefs.SetString("BuildManager.GitHub.Token", githubToken);
		}
	}
	string githubToken;
	public string githubUserName;
	public string githubRepoName;

    public void CloneInto(BuildManagerSettings settings) {
		scriptingDefineSymbols = settings.scriptingDefineSymbols;

		sequences = new List<BuildSequence>(settings.sequences.Count);
		for(int i = 0; i < settings.sequences.Count; ++i) {
			sequences.Add(settings.sequences[i].Clone() as BuildSequence);
		}
	}
}
