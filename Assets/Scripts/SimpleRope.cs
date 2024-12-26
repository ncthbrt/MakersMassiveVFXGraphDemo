using UnityEngine;
using UnityEngine.VFX;

[ExecuteInEditMode]
public class SimpleRope : MonoBehaviour
{   
    [field: SerializeField] public VisualEffect RopeEffect { get; private set; }
    [field: SerializeField] public string ParticleSystemName { get; private set; } = "System";
    [field: SerializeField] public string PositionsBufferName { get; private set; } = "RopeBuffer";
    [field: SerializeField] public string StripBufferName { get; private set; } = "StripBuffer";
    [field: SerializeField] public uint StripCount { get; private set; } = 1;
    private GraphicsBuffer _positionsBuffer;
    private GraphicsBuffer _stripBuffer;

    void Start()
    {
        var capacity = RopeEffect.GetParticleSystemInfo(ParticleSystemName).capacity;
        _positionsBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, (int)(capacity * 4), sizeof(int));
        _positionsBuffer.SetData(new int[4 * capacity]);
        _stripBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, (int)(StripCount + 2), sizeof(uint));
        _stripBuffer.SetData(new uint[StripCount + 2]);
        RopeEffect.SetGraphicsBuffer(PositionsBufferName, _positionsBuffer);
        RopeEffect.SetGraphicsBuffer(StripBufferName, _stripBuffer);
    }

    void OnDestroy()
    {
        if (_positionsBuffer != null)
        {
            _positionsBuffer.Dispose();
            _positionsBuffer = null;
        }
        if (_stripBuffer != null)
        {
            _stripBuffer.Dispose();
            _stripBuffer = null;
        }
    }
}