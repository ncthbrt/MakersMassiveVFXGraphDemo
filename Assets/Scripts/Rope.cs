using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

[ExecuteInEditMode]
public class Rope : MonoBehaviour
{
    private static readonly int Positions = Shader.PropertyToID("Positions");
    private static readonly int Mutexes = Shader.PropertyToID("Mutexes");

    [field: SerializeField] public VisualEffect RopeEffect { get; private set; }
    private GraphicsBuffer _previousPositionsBuffer;
    private GraphicsBuffer _mutexBuffer;

    void Start()
    {
        _previousPositionsBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Raw, 32, 3 * sizeof(uint));
        _previousPositionsBuffer.SetData(new byte[3* sizeof(uint) * 32]);
        _mutexBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Raw, 32, sizeof(uint));
        _mutexBuffer.SetData(new byte[sizeof(uint) * 32]);
        RopeEffect.SetGraphicsBuffer(Positions, _previousPositionsBuffer);
        RopeEffect.SetGraphicsBuffer(Mutexes, _mutexBuffer);
    }

    void Update()
    {
        RopeEffect.SetGraphicsBuffer(Positions, _previousPositionsBuffer);
        RopeEffect.SetGraphicsBuffer(Mutexes, _mutexBuffer);
    }
}