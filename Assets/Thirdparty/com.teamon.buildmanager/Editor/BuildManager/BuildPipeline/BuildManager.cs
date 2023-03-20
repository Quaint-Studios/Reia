using System;
using System.Net;
using System.Linq;
using System.Text;
using System.IO;
using System.Diagnostics;
using UnityEngine;
using UnityEditor;
using UnityEditor.Build.Reporting;
using Ionic.Zip;

using Debug = UnityEngine.Debug;

public static class BuildManager {
	const string butlerDownloadPath = "https://broth.itch.ovh/butler/windows-386/LATEST/archive/default";
	const string githubReleasesDownloadPath = "https://github.com/github-release/github-release/releases/download/v0.9.0/windows-amd64-github-release.zip";

	const string butlerRelativePath = @"Editor/Butler/butler.exe";
	const string githubReleasesRelativePath = @"Editor/Github/github-release.exe";

	static DateTime usedDate;

	static string buildNameString;

	static string[] buildsPath;

	static ChangelogData usedChangelog;

	public static void RunBuildSequnce(BuildManagerSettings settings, BuildSequence sequence, ChangelogData changelog) {
		// Start init
		usedChangelog = changelog;
		ChangelogData.ChangelogVersionEntry usedChangelogEntry = changelog.GetLastVersion();
		buildNameString = usedChangelogEntry.GetVersionHeader();

#if GAME_TEMPLATE
		TemplateGameManager.InstanceEditor.buildNameString = buildNameString;
		TemplateGameManager.InstanceEditor.productName = PlayerSettings.productName;
		EditorUtility.SetDirty(TemplateGameManager.InstanceEditor);
#endif
		usedDate = DateTime.Now;
		//End init

		Debug.Log("Start building all");
		DateTime startTime = DateTime.Now;

		//Crete release here, because build's not get pushed
		CreateGitHubReleaseIfNeeded(settings, sequence);

		Build(settings, sequence);
		PostBuild(sequence);

		Compress(sequence);

		ItchioPush(settings, sequence, changelog);
		GithubPush(settings, sequence, changelog);

		Debug.Log($"End building all. Elapsed time: {string.Format("{0:mm\\:ss}", DateTime.Now - startTime)}");

#if UNITY_EDITOR_WIN
		ShowExplorer(sequence.builds[sequence.builds.Count - 1].outputRoot);
#endif
	}

	static void Build(BuildManagerSettings settings, BuildSequence sequence) {
		BuildTarget targetBeforeStart = EditorUserBuildSettings.activeBuildTarget;
		BuildTargetGroup targetGroupBeforeStart = BuildPipeline.GetBuildTargetGroup(targetBeforeStart);
		string definesBeforeStart = PlayerSettings.GetScriptingDefineSymbolsForGroup(targetGroupBeforeStart);
		bool isVRSupported = PlayerSettings.virtualRealitySupported;    //TODO: PlayerSettings.virtualRealitySupported is deprecated. Replace with smth new	

		buildsPath = new string[sequence.builds.Count];
		for (byte i = 0; i < sequence.builds.Count; ++i) {
			BuildData data = sequence.builds[i];

			if (!data.isEnabled)
				continue;

			if (PlayerSettings.virtualRealitySupported != data.isVirtualRealitySupported)
				PlayerSettings.virtualRealitySupported = data.isVirtualRealitySupported;

			buildsPath[i] = BaseBuild(
				data.targetGroup,
				data.target,
				data.options,
				data.outputRoot + GetPathWithVars(data, data.middlePath),
				string.Concat(settings.scriptingDefineSymbols, ";", sequence.scriptingDefineSymbolsOverride, ";", data.scriptingDefineSymbolsOverride),
				data.isPassbyBuild,
				data.isReleaseBuild
			);


		}

		EditorUserBuildSettings.SwitchActiveBuildTarget(targetGroupBeforeStart, targetBeforeStart);
		PlayerSettings.SetScriptingDefineSymbolsForGroup(targetGroupBeforeStart, definesBeforeStart);
		PlayerSettings.virtualRealitySupported = isVRSupported;
	}

	static void PostBuild(BuildSequence sequence) {
		bool isNeedChangelogFile = usedChangelog.versions.Count != 0;
		bool isNeedReadmeFile = !string.IsNullOrEmpty(usedChangelog.readme);
		string changelogContent = "";
		string readmeContent = usedChangelog.readme;

		bool isAnyReleaseBuild = false;

		if (isNeedChangelogFile) {
			changelogContent = usedChangelog.GetChangelogString();
		}

		for (byte i = 0; i < sequence.builds.Count; ++i) {
			if (!sequence.builds[i].isEnabled)
				continue;

			if (!string.IsNullOrEmpty(buildsPath[i])) {
				if (sequence.builds[i].isReleaseBuild) {  //Destroy IL2CPP junk after build
					isAnyReleaseBuild = true;

					string buildRootPath = Path.GetDirectoryName(buildsPath[i]);
					string[] dirs = Directory.GetDirectories(buildRootPath);
					var il2cppDirs = dirs.Where(s => s.Contains("BackUpThisFolder_ButDontShipItWithYourGame"));
					foreach (var dir in il2cppDirs)
						Directory.Delete(dir, true);
				}

#if UNITY_EDITOR_WIN
				//https://forum.unity.com/threads/mac-unity-build-from-a-pc-not-opening-on-mac.947727/
				//Use git bash to execute this command
				if (sequence.builds[i].target == BuildTarget.StandaloneOSX) {
					Debug.Log($"chmod -R 777 {sequence.builds[i].outputRoot + GetPathWithVars(sequence.builds[i], sequence.builds[i].middlePath)}.app");

					Process process = new Process() {
						StartInfo = new ProcessStartInfo {
							WindowStyle = ProcessWindowStyle.Hidden,
							FileName = "cmd.exe",
							Arguments = $"start \"\" \" %PROGRAMFILES%\\Git\\bin\\sh.exe\" --chmod -R 777 {sequence.builds[i].outputRoot + GetPathWithVars(sequence.builds[i], sequence.builds[i].middlePath)}.app",
						},
					};
					process.Start();
				}
#endif

				if(sequence.builds[i].targetGroup == BuildTargetGroup.Standalone) {
					string path = Path.Combine(sequence.builds[i].outputRoot + GetPathWithVars(sequence.builds[i], sequence.builds[i].middlePath)).Replace(@"/", @"\");
					path = path.Substring(0, path.LastIndexOf("\\"));

					if (isNeedChangelogFile) {
						File.WriteAllText(
							Path.Combine(path, "Changelog.txt"),
							changelogContent
						);
					}

					if (isNeedReadmeFile) {
						File.WriteAllText(
							Path.Combine(path, "Readme.txt"),
							readmeContent
						);
					}
				}
			}
		}

		if (isAnyReleaseBuild) {
			string gitRootPath = Path.Combine(Application.dataPath, "..");

			if(!Directory.Exists(Path.Combine(gitRootPath, ".git"))) {
				gitRootPath = Path.Combine(gitRootPath, "..");

				if (!Directory.Exists(Path.Combine(gitRootPath, ".git"))) {
					gitRootPath = null;
				}
			}

			if(gitRootPath != null) {
				if (isNeedChangelogFile) {
					File.WriteAllText(
						Path.Combine(gitRootPath, "Changelog.md"),
						changelogContent
					);
				}

				if (isNeedReadmeFile) {
					File.WriteAllText(
						Path.Combine(gitRootPath, "ReadmeGame.md"),
						readmeContent
					);
				}
			}
		}
	}

	static void Compress(BuildSequence sequence) {
		for (byte i = 0; i < sequence.builds.Count; ++i) {
			if (!sequence.builds[i].needZip || !sequence.builds[i].isEnabled)
				continue;

			if (sequence.builds[i].target == BuildTarget.Android) {
				Debug.Log("Skip android build to .zip, because .apk files already compressed");
				continue;
			}

			if (!string.IsNullOrEmpty(buildsPath[i]))
				BaseCompress(sequence.builds[i].outputRoot + GetPathWithVars(sequence.builds[i], sequence.builds[i].dirPathForPostProcess));
			else
				Debug.LogWarning($"[Compressing] Can't find build for {GetBuildTargetExecutable(sequence.builds[i].target)}");
		}
	}

	static void ItchioPush(BuildManagerSettings settings, BuildSequence sequence, ChangelogData changelog) {
		for (byte i = 0; i < sequence.builds.Count; ++i) {
			if (!sequence.builds[i].isEnabled || !sequence.builds[i].needItchPush)
				continue;

			if (!string.IsNullOrEmpty(buildsPath[i])) {
				if (string.IsNullOrEmpty(settings.itchGameLink)) {
					Debug.LogWarning($"Can't push itch.io. Required data is missing");
					return;
				}

				PushItch(settings, sequence, sequence.builds[i]);
			}
			else {
				Debug.LogWarning($"[Itch.io push] Can't find build for {GetBuildTargetExecutable(sequence.builds[i].target)}");
			}
		}
	}

	static void GithubPush(BuildManagerSettings settings, BuildSequence sequence, ChangelogData changelog) {
		for (byte i = 0; i < sequence.builds.Count; ++i) {
			if (!sequence.builds[i].isEnabled || !sequence.builds[i].needGithubPush)
				continue;

			if (!string.IsNullOrEmpty(buildsPath[i])) {
				if (string.IsNullOrEmpty(settings.GithubToken) || string.IsNullOrEmpty(settings.githubUserName) || string.IsNullOrEmpty(settings.githubRepoName)) {
					Debug.LogWarning($"Can't push github release. Required data is missing");
					return;
				}

				PushGithub(settings, sequence, sequence.builds[i]);
			}
			else {
				Debug.LogWarning($"[GitHub push] Can't find build for {GetBuildTargetExecutable(sequence.builds[i].target)}");
			}
		}
	}

	#region Convert to strings
	public static string GetPathWithVars(BuildData data, string s) {
		s = s.Replace("$NAME", GetProductName());
		s = s.Replace("$PLATFORM", ConvertBuildTargetToString(data.target));
		s = s.Replace("$VERSION", PlayerSettings.bundleVersion);
		s = s.Replace("$DATESHORT", $"{usedDate.Date.Year % 100}_{usedDate.Date.Month}_{usedDate.Date.Day}");
		s = s.Replace("$YEARSHORT", $"{usedDate.Date.Year % 100}");
		s = s.Replace("$DATE", $"{usedDate.Date.Year}_{usedDate.Date.Month}_{usedDate.Date.Day}");
		s = s.Replace("$YEAR", $"{usedDate.Date.Year}");
		s = s.Replace("$MONTH", $"{usedDate.Date.Month}");
		s = s.Replace("$DAY", $"{usedDate.Date.Day}");
		s = s.Replace("$TIME", $"{usedDate.Hour}_{usedDate.Minute}");
		s = s.Replace("$EXECUTABLE", GetBuildTargetExecutable(data.target));
		return s;
	}

	public static string GetPathWithVarsForZip(BuildData data, string s) {
		s = s.Replace("$NAME", GetProductName());
		s = s.Replace("$PLATFORM", ConvertBuildTargetToString(data.target));
		s = s.Replace("$VERSION", PlayerSettings.bundleVersion);
		s = s.Replace("$DATESHORT", $"{usedDate.Date.Year % 100}_{usedDate.Date.Month}_{usedDate.Date.Day}");
		s = s.Replace("$YEARSHORT", $"{usedDate.Date.Year % 100}");
		s = s.Replace("$DATE", $"{usedDate.Date.Year}_{usedDate.Date.Month}_{usedDate.Date.Day}");
		s = s.Replace("$YEAR", $"{usedDate.Date.Year}");
		s = s.Replace("$MONTH", $"{usedDate.Date.Month}");
		s = s.Replace("$DAY", $"{usedDate.Date.Day}");
		s = s.Replace("$TIME", $"{usedDate.Hour}_{usedDate.Minute}");

		if (s.Contains("$EXECUTABLE"))
			s = s.Replace("$EXECUTABLE", GetBuildTargetExecutable(data.target));
		else
			s += ".zip";
		return s;
	}

	public static string ConvertBuildTargetToString(BuildTarget target) {
		switch (target) {
			case BuildTarget.StandaloneOSX:
				return "OSX";
			case BuildTarget.StandaloneWindows:
				return "Windows32";
			case BuildTarget.StandaloneWindows64:
				return "Windows64";
			case BuildTarget.StandaloneLinux64:
				return "Linux";
		}
		return target.ToString();
	}

	public static string GetProductName() {
		return PlayerSettings.productName
			.Replace(' ', '_')
			.Replace('/', '_')
			.Replace('\\', '_')
			.Replace(':', '_')
			.Replace('*', '_')
			.Replace('?', '_')
			.Replace('"', '_')
			.Replace('<', '_')
			.Replace('>', '_')
			.Replace('|', '_')
			;
	}

	public static string GetBuildTargetExecutable(BuildTarget target) {
		switch (target) {
			case BuildTarget.StandaloneWindows:
			case BuildTarget.StandaloneWindows64:
				return ".exe";

			case BuildTarget.StandaloneLinux64:
				return ".x86_64";

			case BuildTarget.StandaloneOSX:
				return "";

			case BuildTarget.iOS:
				return ".ipa";

			case BuildTarget.Android:
				return ".apk";

			case BuildTarget.WebGL:
				return "";
		}
		return "";
	}
	#endregion

	#region Base methods
	static string BaseBuild(BuildTargetGroup buildTargetGroup, BuildTarget buildTarget, BuildOptions buildOptions, string buildPath, string definesSymbols, bool isPassbyBuild, bool isReleaseBuild) {
		if (isPassbyBuild) {
			return buildPath;
		}

		if (buildTarget == BuildTarget.Android && PlayerSettings.Android.useCustomKeystore && string.IsNullOrEmpty(PlayerSettings.Android.keyaliasPass)) {
			PlayerSettings.Android.keyaliasPass = PlayerSettings.Android.keystorePass = "keystore";
		}

		if (isReleaseBuild) {
			switch (buildTargetGroup) {
				case BuildTargetGroup.Standalone:
					buildOptions |= BuildOptions.CompressWithLz4;

					if (buildTarget == BuildTarget.StandaloneWindows || buildTarget == BuildTarget.StandaloneWindows64 || buildTarget == BuildTarget.StandaloneLinux64)
						PlayerSettings.SetScriptingBackend(buildTargetGroup, ScriptingImplementation.IL2CPP);
					else
						PlayerSettings.SetScriptingBackend(buildTargetGroup, ScriptingImplementation.Mono2x);
					PlayerSettings.SetIl2CppCompilerConfiguration(buildTargetGroup, Il2CppCompilerConfiguration.Master);
					break;
				case BuildTargetGroup.Android:
					buildOptions |= BuildOptions.CompressWithLz4;

					PlayerSettings.SetScriptingBackend(buildTargetGroup, ScriptingImplementation.IL2CPP);
					PlayerSettings.SetIl2CppCompilerConfiguration(buildTargetGroup, Il2CppCompilerConfiguration.Master);

					PlayerSettings.Android.targetArchitectures = AndroidArchitecture.All;
					break;
				case BuildTargetGroup.WebGL:
					PlayerSettings.SetIl2CppCompilerConfiguration(buildTargetGroup, Il2CppCompilerConfiguration.Master);
					break;
				default:
					Debug.LogWarning($"{buildTargetGroup} is unsupported for release builds. No optimizations applied");
					break;
			}
		}
		else {
			switch (buildTargetGroup) {
				case BuildTargetGroup.Standalone:
					buildOptions ^= BuildOptions.CompressWithLz4;
					buildOptions ^= BuildOptions.CompressWithLz4HC;

					PlayerSettings.SetScriptingBackend(buildTargetGroup, ScriptingImplementation.Mono2x);
					PlayerSettings.SetIl2CppCompilerConfiguration(buildTargetGroup, Il2CppCompilerConfiguration.Debug);
					break;
				case BuildTargetGroup.Android:
					buildOptions ^= BuildOptions.CompressWithLz4;
					buildOptions ^= BuildOptions.CompressWithLz4HC;

					PlayerSettings.SetScriptingBackend(buildTargetGroup, ScriptingImplementation.Mono2x);
					PlayerSettings.SetIl2CppCompilerConfiguration(buildTargetGroup, Il2CppCompilerConfiguration.Debug);

					PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARMv7;
					break;
				case BuildTargetGroup.WebGL:
					PlayerSettings.SetIl2CppCompilerConfiguration(buildTargetGroup, Il2CppCompilerConfiguration.Debug);
					break;
				default:
					Debug.LogWarning($"{buildTargetGroup} is unsupported for debug builds. No optimizations applied");
					break;
			}
		}

		BuildPlayerOptions buildPlayerOptions = new BuildPlayerOptions {
			scenes = EditorBuildSettings.scenes.Where(s => s.enabled).Select(s => s.path).ToArray(),
			locationPathName = buildPath,
			targetGroup = buildTargetGroup,
			target = buildTarget,
			options = buildOptions,
		};

		PlayerSettings.SetScriptingDefineSymbolsForGroup(buildTargetGroup, definesSymbols);
		BuildReport report = BuildPipeline.BuildPlayer(buildPlayerOptions);
		BuildSummary summary = report.summary;

		if (summary.result == BuildResult.Succeeded) {
			Debug.Log($"{summary.platform} succeeded.  \t Time: {string.Format("{0:mm\\:ss}", summary.totalTime)}  \t Size: {summary.totalSize / 1048576} Mb");
		}
		else if (summary.result == BuildResult.Failed) {
			Debug.Log(
				$"{summary.platform} failed.   \t Time: {string.Format("{0:mm\\:ss}", summary.totalTime)}  \t Size: {summary.totalSize / 1048576} Mb" + "\n" +
				$"Warnings: {summary.totalWarnings}" + "\n" +
				$"Errors:   {summary.totalErrors}"
			);
		}

		return summary.result == BuildResult.Succeeded ? buildPath : "";
	}

	static void BaseCompress(string dirPath) {
		using (ZipFile zip = new ZipFile()) {
			DateTime startTime = DateTime.Now;
			if (Directory.Exists(dirPath))
				zip.AddDirectory(dirPath);
			else
				zip.AddFile(dirPath);
			zip.Save(dirPath + ".zip");

			long uncompresedSize = 0;
			long compresedSize = 0;
			foreach (var e in zip.Entries) {
				uncompresedSize += e.UncompressedSize;
				compresedSize += e.CompressedSize;
			}
			Debug.Log($"Make {dirPath}.zip.  \t Time: {string.Format("{0:mm\\:ss}", DateTime.Now - startTime)}  \t Size: {uncompresedSize / 1048576} Mb - {compresedSize / 1048576} Mb");
		}
	}

	static void PushItch(BuildManagerSettings settings, BuildSequence sequence, BuildData data) {
		StringBuilder fileName = new StringBuilder(128);
		StringBuilder args = new StringBuilder(128);


		string butlerPath = Application.dataPath + "/" + butlerRelativePath;
		if (!File.Exists(butlerPath)) {
			Debug.LogWarning("Butler not found.");
			DownloadButler();
		}

		fileName.Append(butlerPath);

		args.Append(" push \"");
		args.Append(Application.dataPath);
		args.Append("/../");
		args.Append(data.outputRoot + GetPathWithVars(data, data.dirPathForPostProcess));
		args.Append("\" ");

		args.Append($"{settings.itchGameLink}:{data.itchChannel} ");
		args.Append($"--userversion \"{buildNameString}\" ");

		Debug.Log(fileName.ToString() + args.ToString());
		Process.Start(fileName.ToString(), args.ToString());
	}

	static void CreateGitHubReleaseIfNeeded(BuildManagerSettings settings, BuildSequence sequence) {
		for (byte i = 0; i < sequence.builds.Count; ++i) {
			if (!sequence.builds[i].isEnabled || !sequence.builds[i].needGithubPush)
				continue;

			if (string.IsNullOrEmpty(settings.GithubToken) || string.IsNullOrEmpty(settings.githubUserName) || string.IsNullOrEmpty(settings.githubRepoName)) {
				Debug.LogWarning($"Can't create github release. Required data is missing");
				return;
			}

			CreateGitHubRelease(settings);
			break;
		}
	}

	static void CreateGitHubRelease(BuildManagerSettings settings) {
		StringBuilder fileName = new StringBuilder(128);
		StringBuilder args = new StringBuilder(128);

		string githubReleaseExe = Application.dataPath + "/" + githubReleasesRelativePath;
		if (!File.Exists(githubReleaseExe)) {
			Debug.LogWarning("GitHub release not found.");
			DownloadGithubRelease();
		}

		fileName.Append(githubReleaseExe);
		args.Append(" release ");
		args.Append($"--security-token \"{settings.GithubToken}\" ");
		args.Append($"--user {settings.githubUserName} ");
		args.Append($"--repo {settings.githubRepoName} ");
		args.Append($"--tag v{PlayerSettings.bundleVersion} ");
		args.Append($"--name \"{buildNameString}\" ");
		args.Append($"--description \"{usedChangelog.GetLastChangelogString()}\" ");

		Debug.Log(fileName.ToString() + args.ToString());
		Process.Start(fileName.ToString(), args.ToString());
	}

	static void PushGithub(BuildManagerSettings settings, BuildSequence sequence, BuildData data) {
		StringBuilder fileName = new StringBuilder(128);
		StringBuilder args = new StringBuilder(128);

		string githubReleaseExe = Application.dataPath + "/" + githubReleasesRelativePath;

		fileName.Append(githubReleaseExe);

		args.Append(" upload ");
		args.Append($"--security-token \"{settings.GithubToken}\" ");
		args.Append($"--user {settings.githubUserName} ");
		args.Append($"--auth-user {settings.githubUserName} ");
		args.Append($"--repo {settings.githubRepoName} ");
		args.Append($"--tag v{PlayerSettings.bundleVersion} ");
		args.Append($"--name \"{GetPathWithVars(data, data.dirPathForPostProcess)}\" ");    //download file name
		args.Append($"--label \"{GetPathWithVars(data, data.dirPathForPostProcess)}\" ");   //name in releases
		args.Append($"--file  \"{Path.Combine(Application.dataPath, "..", data.outputRoot, GetPathWithVarsForZip(data, data.dirPathForPostProcess)).Replace("\\", "/")}\" ");
		args.Append($"--replace ");

		Debug.Log(fileName.ToString() + args.ToString());

		ProcessStartInfo info = new ProcessStartInfo(fileName.ToString(), args.ToString()) {
			UseShellExecute = false,
			RedirectStandardOutput = true,
			RedirectStandardError = true
		};
		Process.Start(info);
	}
	#endregion

	#region Helpers
	static void ShowExplorer(string itemPath) {
		itemPath = itemPath.Replace(@"/", @"\");   // explorer doesn't like front slashes

		bool findFile = false;
		DirectoryInfo di = new DirectoryInfo(itemPath);
		foreach (FileInfo fi in di.GetFiles()) {
			if (fi.Name != "." && fi.Name != ".." && fi.Name != "Thumbs.db") {
				itemPath = fi.FullName;
				findFile = true;
				break;
			}
		}

		if (!findFile) {
			foreach (DirectoryInfo fi in di.GetDirectories()) {
				if (fi.Name != "." && fi.Name != ".." && fi.Name != "Thumbs.db") {
					itemPath = fi.FullName;
					break;
				}
			}
		}

		Process.Start("explorer.exe", "/select," + itemPath);
	}

	static void CreateAllFodersBeforePath(string path) {
		string[] dirs = ("Assets/" + path).Split('/');
		string allPath = dirs[0];
		for (int i = 1; i < dirs.Length - 1; ++i) {
			if (!AssetDatabase.IsValidFolder(allPath + "/" + dirs[i])) {
				AssetDatabase.CreateFolder(allPath, dirs[i]);
			}
			allPath = allPath + "/" + dirs[i];
		}
	}
	#endregion

	#region Download CLI
	[MenuItem("Window/BuildManager/Download butler(itch.io)")]
	public static void DownloadButler() {
		using (var client = new WebClient()) {
			Debug.Log("Downloading butler...");

			string butlerPath = Application.dataPath + "/" + butlerRelativePath;
			string butlerDirPath = butlerPath.Replace("butler.exe", "");
			string zipPath = butlerPath.Replace("butler.exe", "butler.zip");

			CreateAllFodersBeforePath(butlerRelativePath);

			client.DownloadFile(butlerDownloadPath, zipPath);

			using (ZipFile zip = ZipFile.Read(zipPath)) {
				foreach (ZipEntry e in zip) {
					e.Extract(butlerDirPath, ExtractExistingFileAction.OverwriteSilently);
				}
			}

			File.Delete(zipPath);
		}
	}

	[MenuItem("Window/BuildManager/Download github-release(github.com)")]
	public static void DownloadGithubRelease() {
		using (var client = new WebClient()) {
			Debug.Log("Downloading github-release...");

			string exePath = Application.dataPath + "/" + githubReleasesRelativePath;
			string dirPath = exePath.Replace("github-release.exe", "");
			string zipPath = exePath.Replace("github-release.exe", "windows-amd64-github-release.zip");

			CreateAllFodersBeforePath(githubReleasesRelativePath);

			client.DownloadFile(githubReleasesDownloadPath, zipPath);

			using (ZipFile zip = ZipFile.Read(zipPath)) {
				foreach (ZipEntry e in zip) {
					e.Extract(dirPath, ExtractExistingFileAction.OverwriteSilently);
				}
			}

			File.Copy(Path.Combine(dirPath, "bin", "windows", "amd64", "github-release.exe"), exePath);
			Directory.Delete(Path.Combine(dirPath, "bin"), true);
			File.Delete(zipPath);
		}
	}
	#endregion
}
