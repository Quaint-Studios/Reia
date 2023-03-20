using System.IO;
using UnityEditor;
using UnityEngine;

#if UNITY_EDITOR
public class MapGenerator : EditorWindow
{
    [MenuItem("Generate/Map/Generate Texture Layers")]
    private static void Generate()
    {
        string folder = EditorUtility.OpenFolderPanel("Select Map Folder", default, default);

        if(folder.Length == 0) return;

        folder = folder.Substring(folder.IndexOf("/Assets") + 1);

        string texturesPath = folder + "/Textures";
        string terrainBasePath = folder + "/TerrainBase";

        // Textures Base Folder
        {
            DirectoryInfo directory = new(@texturesPath);

            FileInfo[] terrainAlbedoFiles = directory.GetFiles("Terrain_Albedo_*.png");
            FileInfo[] terrainNormalMapFiles = directory.GetFiles("Terrain_NormalMap_*.png");

            int max = System.Math.Max(terrainAlbedoFiles.Length, terrainNormalMapFiles.Length);

            var rx = new System.Text.RegularExpressions.Regex(@"[^\d]+");
            string FormatLoc(string loc)
            {
                return rx.Replace(loc, "");
            }

            for(int i = 0; i < max; i++)
            {
                Texture2D albedoContent = (Texture2D)AssetDatabase.LoadAssetAtPath($"{texturesPath}/{terrainAlbedoFiles[i].Name}", typeof(Texture2D));
                if(albedoContent == null)
                {
                    Debug.Log($"{texturesPath}/{terrainAlbedoFiles[i].Name} is null");
                    continue;
                }

                Texture2D normalMapContent = (Texture2D)AssetDatabase.LoadAssetAtPath($"{texturesPath}/{terrainNormalMapFiles[i].Name}", typeof(Texture2D));
                if(normalMapContent == null)
                {
                    Debug.Log($"{texturesPath}/{terrainAlbedoFiles[i].Name} is null");
                    continue;
                }

                string[] locs = terrainAlbedoFiles[i].FullName.Split("_");

                int xLoc = int.TryParse(FormatLoc(locs[^2]), out int xLocOut) ? xLocOut : -1; // Get the 2nd to last index (x coord).
                int yLoc = int.TryParse(FormatLoc(locs[^1]), out int yLocOut) ? yLocOut : -1; // Get the last index (y coord).

                TerrainLayer tl = new();
                tl.diffuseTexture = albedoContent;
                tl.normalMapTexture = normalMapContent;

                tl.normalScale = 0.33f;
                tl.tileSize = new Vector2(333, 333);
                tl.metallic = 0.1f;
                tl.smoothness = 0.5f;

                string finalPath = $"{terrainBasePath}/Terrain_{xLoc}_{yLoc}.terrainlayer";

                Debug.Log(finalPath);

                AssetDatabase.CreateAsset(tl, $"{terrainBasePath}/Terrain_{xLoc}_{yLoc}.terrainlayer");

                GameObject terrainGroup = GameObject.FindGameObjectWithTag("NewTerrainGroup");

                foreach(Terrain terrain in terrainGroup.GetComponentsInChildren<Terrain>())
                {
                    Debug.Log(terrain.name);
                    // Preserve existing terrain layers and prepend the new layer.
                    TerrainLayer tlAsset = (TerrainLayer)AssetDatabase.LoadAssetAtPath($"{terrainBasePath}/{terrain.name}.terrainlayer", typeof(TerrainLayer));
                    terrain.terrainData.terrainLayers = new[] { tlAsset };
                }

                terrainGroup.tag = "TerrainGroup";

            }
        }
    }
}
#endif