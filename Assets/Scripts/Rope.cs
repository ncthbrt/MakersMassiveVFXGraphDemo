using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

[ExecuteInEditMode]
public class Rope : MonoBehaviour
{
    private static readonly int RopePositions = Shader.PropertyToID("RopePositions");

    [field: SerializeField] public VisualEffect RopeEffect { get; private set; }
    private GraphicsBuffer _positionsBuffer;
    void Start()
    {
        _positionsBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, 32 * 4, sizeof(int));
        _positionsBuffer.SetData(new int[4 * 32]);
        RopeEffect.SetGraphicsBuffer(RopePositions, _positionsBuffer);
    }

    void Update()
    {
        //RopeEffect.SetGraphicsBuffer(RopePositions, _positionsBuffer);
    }

    void OnDestroy()
    {
        if (_positionsBuffer != null)
        {
            _positionsBuffer.Dispose();
            _positionsBuffer = null;
        }
    }
}