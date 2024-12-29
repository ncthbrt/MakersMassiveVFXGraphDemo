using UnityEngine;
using UnityEngine.VFX;

[ExecuteInEditMode]
public class SimpleRope : MonoBehaviour
{
    [field: SerializeField] public VisualEffect RopeEffect { get; private set; }
    [field: SerializeField] public string ParticleSystemName { get; private set; } = "System";
    [field: SerializeField] public string PositionsBufferName { get; private set; } = "RopeBuffer";
    private GraphicsBuffer _positionsBuffer;

    void Start()
    {
        var capacity = RopeEffect.GetParticleSystemInfo(ParticleSystemName).capacity;
        _positionsBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, (int)(capacity * 3), sizeof(int));
        _positionsBuffer.SetData(new int[3 * capacity]);
        RopeEffect.SetGraphicsBuffer(PositionsBufferName, _positionsBuffer);
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