using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.UIElements;

public class MultiBuildManagerEditor : EditorWindow
{
    static string currentBuild = "";

    private static MultiBuildManagerData data;

    [InitializeOnLoadMethod]
    private static void OnLoad()
    {
        data = AssetDatabase.LoadAssetAtPath<MultiBuildManagerData>("Assets/Editor/MultiBuildManager/data.asset");
        if(!data)
        {
            data = CreateInstance<MultiBuildManagerData>();
            AssetDatabase.CreateAsset(data, "Assets/Editor/MultiBuildManager/data.asset");
            AssetDatabase.Refresh();
        }
    }

    [MenuItem("Tools/MultiBuildManager")]
    public static void ShowEditor()
    {
        // This method is called when the user selects the menu item in the Editor
        EditorWindow wnd = GetWindow<MultiBuildManagerEditor>();
        wnd.titleContent = new GUIContent("MultiBuildManager");

        VisualTreeAsset uiAsset = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>("Assets/Editor/MultiBuildManager/MultiBuildManager.uxml");
        VisualElement ui = uiAsset.Instantiate();

        wnd.rootVisualElement.Add(ui);

        // Load Data
        {
            var companyName = wnd.rootVisualElement.Q<TextField>("CompanyName");
            companyName.value = data.companyName;

            var productName = wnd.rootVisualElement.Q<TextField>("ProductName");
            productName.value = data.productName;

            var version = wnd.rootVisualElement.Q<TextField>("Version");
            version.value = data.version;

            var sequences = wnd.rootVisualElement.Q<ListView>("Sequences");
            Func<VisualElement> makeItem = () => new Label();
            Action<VisualElement, int> bindItem = (e, i) => (e as Label).text = data.sequences[i].name;

            sequences.fixedItemHeight = 18;
            sequences.selectionType = SelectionType.Single;

            sequences.itemsSource = data.sequences;
            sequences.makeItem = makeItem;
            sequences.bindItem = bindItem;

            sequences.onItemsChosen += objects => Debug.Log(objects);
            sequences.onSelectionChange += objects => Debug.Log(objects);

            var builds = wnd.rootVisualElement.Q<Foldout>("Builds");

            foreach(var build in data.builds)
            {
                var btn = new Button();
                btn.text = build.name;
                btn.clicked += () => Build(build);

                builds.Add(btn);
            }

        }
    }

    static void Build(BuildsData build)
    {
        if(currentBuild != build.name)
        {
            currentBuild = build.name;
            Debug.Log($"Are you sure you want to start building {build.name}? Click the same build again to confirm. This may take a while!");
            return;
        }

        Debug.Log($"Building {build.name}.");

        List<SequenceData> sequences = new();

        foreach(var sequence in build.sequences)
        {
            try
            {
                sequences.Add(data.sequences.Find(obj => obj.name == sequence));
            }
            catch(Exception ex)
            {
                Debug.LogError(ex);
            }
        }

        sequences.ForEach(sequence =>
        {
            var scenes = new List<string>();

            foreach(var sceneIndex in sequence.scenes)
            {
                scenes.Add(EditorBuildSettings.scenes[sceneIndex + 1].path);
            }

            foreach(var _target in sequence.targets)
            {
                Debug.Log($"Executing build for {sequence.name}");
                Debug.Log($"Scenes: {string.Join("|", scenes.ToArray())}");
                Debug.Log($"Path: ./Builds/MultiBuildManager/{sequence.name}/{data.productName}.exe");
                Debug.Log($"Target: {_target.target}");
                Debug.Log($"Options: None");
                Debug.Log("INITIALIZING");
                BuildPipeline.BuildPlayer(new BuildPlayerOptions
                {
                    scenes = scenes.ToArray(),
                    locationPathName = $"./Builds/MultiBuildManager/{sequence.name}/{data.productName}.exe",
                    target = _target.target == BuildTarget.LinuxHeadlessSimulation ? BuildTarget.StandaloneLinux64 : _target.target,
                    targetGroup = _target.targetGroup,
                    subtarget = _target.target == BuildTarget.LinuxHeadlessSimulation ? (int)StandaloneBuildSubtarget.Server : (int)StandaloneBuildSubtarget.Player,
                    options = BuildOptions.None
                }); ;
                Debug.Log($"Finished building {sequence.name}");
            }
        });

    }
}
