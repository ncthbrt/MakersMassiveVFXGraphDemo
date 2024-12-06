using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

[ExecuteInEditMode]
public class Rope : MonoBehaviour
{
    private static readonly int PreviousPositions = Shader.PropertyToID("PreviousPositions");

    [field: SerializeField] public VisualEffect RopeEffect { get; private set; }
    private GraphicsBuffer _previousPositionsBuffer;
    
    // Start is called before the first frame update
    void Start()
    {
        _previousPositionsBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, 32, 4 * sizeof(float));
        _previousPositionsBuffer.SetData(new Vector4[32]);
        RopeEffect.SetGraphicsBuffer(PreviousPositions, _previousPositionsBuffer);
    }

    // Update is called once per frame
    void Update()
    {
        RopeEffect.SetGraphicsBuffer(PreviousPositions, _previousPositionsBuffer);
    }
}