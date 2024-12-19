using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

[ExecuteInEditMode]
public class Rope : MonoBehaviour
{
    private static readonly int RopePositions = Shader.PropertyToID("RopePositions");

    [field: SerializeField] public VisualEffect RopeEffect { get; private set; }
    [field: SerializeField] public uint MaxParticleCount { get; private set; } = 32;
    private GraphicsBuffer _positionsBuffer;

    void Start()
    {
        _positionsBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, (int)(MaxParticleCount * 4), sizeof(int));
        _positionsBuffer.SetData(new int[4 * MaxParticleCount]);
        RopeEffect.SetGraphicsBuffer(RopePositions, _positionsBuffer);
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