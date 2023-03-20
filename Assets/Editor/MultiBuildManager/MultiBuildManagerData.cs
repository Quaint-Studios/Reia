using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class MultiBuildManagerData : ScriptableObject
{
    public string companyName = "Company";
    public string productName = "Product";
    public string version = "0.1.0";

    public List<BuildsData> builds;
    public List<SequenceData> sequences;
}

[System.Serializable]
public struct BuildsData
{
    public string name;
    public List<string> sequences;

    public override string ToString() => sequences.ToString();
}

[System.Serializable]
public struct SequenceData
{
    public string name;
    public List<TargetData> targets;
    public List<int> scenes;

    public SequenceData(string _name, List<TargetData> _targets, List<int> _scenes)
    {
        this.name = _name == "" || _name.Length <= 0 ? "New Sequence" : _name;
        this.targets = _targets ?? new();
        scenes = _scenes ?? new();
    }
}

[System.Serializable]
public struct TargetData
{
    public BuildTarget target;
    public BuildTargetGroup targetGroup;

    public TargetData(BuildTarget _target, BuildTargetGroup _targetGroup)
    {
        target = _target;
        targetGroup = _targetGroup;
    }
}