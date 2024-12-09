using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

[ExecuteInEditMode]
public class Rope : MonoBehaviour
{
    private static readonly int PreviousPositions = Shader.PropertyToID("PreviousPositions");
    private static readonly int PositionErrors = Shader.PropertyToID("PositionErrors");

    [field: SerializeField] public VisualEffect RopeEffect { get; private set; }
    private GraphicsBuffer _positionsBuffer;
    private GraphicsBuffer _positionErrorBuffer;

    // Start is called before the first frame update
    void Start()
    {
        _positionsBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, 32, 3 * sizeof(float));
        _positionsBuffer.SetData(new Vector3[32]);
        _positionErrorBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, 32, 3 * sizeof(float));
        _positionErrorBuffer.SetData(new Vector3[32]);
        RopeEffect.SetGraphicsBuffer(PreviousPositions, _positionsBuffer);
        RopeEffect.SetGraphicsBuffer(PositionErrors, _positionErrorBuffer);
    }

    // Update is called once per frame
    private void Update()
    {
        RopeEffect.SetGraphicsBuffer(PreviousPositions, _positionsBuffer);
        RopeEffect.SetGraphicsBuffer(PositionErrors, _positionErrorBuffer);
    }
}