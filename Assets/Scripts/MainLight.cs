using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class MainLight : MonoBehaviour
{
    private static readonly int LightPosition = Shader.PropertyToID("_LightPosition");
    private static readonly int LightColor = Shader.PropertyToID("_LightColor");

    [field: SerializeField, ColorUsage(true, true)] public Color Color { get; private set; }

    // Start is called before the first frame update
    void Start()
    {
        Shader.SetGlobalColor(LightColor, Color);
        Shader.SetGlobalVector(LightPosition, transform.position);
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalColor(LightColor, Color);
        Shader.SetGlobalVector(LightPosition, transform.position);
    }
}