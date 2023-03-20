using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public static class PredefinedBuildConfigs {
	public static BuildSequence testingSequence;
	public static BuildSequence testingSequenceZip;

	public static BuildSequence releaseLocalSequence;
	public static BuildSequence releaseLocalZipSequence;
	public static BuildSequence releaseFullSequence;

	public static BuildSequence passbySequence;

	public static BuildData[] standaloneData = new BuildData[] { 
		new BuildData(UnityEditor.BuildTargetGroup.Standalone, UnityEditor.BuildTarget.StandaloneWindows){ itchChannel = "windows-32" },
		new BuildData(UnityEditor.BuildTargetGroup.Standalone, UnityEditor.BuildTarget.StandaloneWindows64){ itchChannel = "windows-64" },
		new BuildData(UnityEditor.BuildTargetGroup.Standalone, UnityEditor.BuildTarget.StandaloneLinux64){ itchChannel = "linux-universal" },
		new BuildData(UnityEditor.BuildTargetGroup.Standalone, UnityEditor.BuildTarget.StandaloneOSX){ itchChannel = "osx-universal" },
	};

	public static BuildData[] webData = new BuildData[] {
		new BuildData(UnityEditor.BuildTargetGroup.WebGL, UnityEditor.BuildTarget.WebGL){ middlePath = "$NAME_$VERSION_$PLATFORM/", itchChannel = "webgl"},
	};

	public static BuildData[] androidData = new BuildData[] {
		new BuildData(UnityEditor.BuildTargetGroup.Android, UnityEditor.BuildTarget.Android){ middlePath = "$NAME_$VERSION_$PLATFORM$EXECUTABLE", dirPathForPostProcess = "$NAME_$VERSION_$PLATFORM$EXECUTABLE", itchChannel = "android"},
	};

	public static void Init() {
		List<BuildData> dataOriginal = new List<BuildData>();
		List<BuildData> data = new List<BuildData>();

		foreach (BuildData buildData in standaloneData) {
			dataOriginal.Add(buildData.Clone() as BuildData);
		}
		foreach (BuildData buildData in webData) {
			dataOriginal.Add(buildData.Clone() as BuildData);
		}
		foreach (BuildData buildData in androidData) {
			dataOriginal.Add(buildData.Clone() as BuildData);
		}

		FillTestingSequence(ref dataOriginal, ref data);
		FillReleaseSequence(ref dataOriginal, ref data);
	}

	static void FillTestingSequence(ref List<BuildData> dataOriginal, ref List<BuildData> data) {
		for (int i = 0; i < dataOriginal.Count; ++i) {
			data.Add(dataOriginal[i].Clone() as BuildData);
			data[i].middlePath = data[i].middlePath.Replace("_$VERSION", "");
			data[i].dirPathForPostProcess = data[i].dirPathForPostProcess.Replace("_$VERSION", "");
		}
		testingSequence = new BuildSequence("Testing", data.ToArray());
		data.Clear();

		for (int i = 0; i < dataOriginal.Count; ++i) {
			data.Add(dataOriginal[i].Clone() as BuildData);
			data[i].needZip = true;
			data[i].middlePath = data[i].middlePath.Replace("_$VERSION", "");
			data[i].dirPathForPostProcess = data[i].dirPathForPostProcess.Replace("_$VERSION", "");
		}
		testingSequenceZip = new BuildSequence("Testing + zip", data.ToArray());
		data.Clear();
	}

	static void FillReleaseSequence(ref List<BuildData> dataOriginal, ref List<BuildData> data) {
		for (int i = 0; i < dataOriginal.Count; ++i) {
			dataOriginal[i].outputRoot += "Releases/";
		}

		for (int i = 0; i < dataOriginal.Count; ++i) {
			data.Add(dataOriginal[i].Clone() as BuildData);
			data[i].isReleaseBuild = true;
		}
		releaseLocalSequence = new BuildSequence("Release", data.ToArray());
		data.Clear();

		for (int i = 0; i < dataOriginal.Count; ++i) {
			data.Add(dataOriginal[i].Clone() as BuildData);
			data[i].isReleaseBuild = true;
			data[i].needZip = true;
		}
		releaseLocalZipSequence = new BuildSequence("Release + zip", data.ToArray());
		data.Clear();

		for (int i = 0; i < dataOriginal.Count; ++i) {
			data.Add(dataOriginal[i].Clone() as BuildData);
			data[i].isReleaseBuild = true;
			data[i].needZip = true;
			data[i].needItchPush = true;
			data[i].needGithubPush = true;
		}
		releaseFullSequence = new BuildSequence("Release full", data.ToArray());
		data.Clear();

		for (int i = 0; i < dataOriginal.Count; ++i) {
			data.Add(dataOriginal[i].Clone() as BuildData);
			data[i].isReleaseBuild = true;
			data[i].isPassbyBuild = true;
			data[i].needZip = true;
			data[i].needItchPush = true;
			data[i].needGithubPush = true;
		}
		passbySequence = new BuildSequence("Passby local release", data.ToArray());
		data.Clear();
	}
}
