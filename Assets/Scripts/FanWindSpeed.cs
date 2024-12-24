using UnityEngine;
using UnityEngine.VFX;

public class FanWindSpeed : MonoBehaviour
{
    [field: SerializeField] public float MaxSpeed { get; private set; }
    [field: SerializeField] public float TimeToMaxSpeed { get; private set; }
    [field: SerializeField] public VisualEffect VisualEffect { get; private set; }
    private float _startTime;
    void Start()
    {
        _startTime = Time.time;
    }

    // Update is called once per frame
    void Update()
    {
        var factor = Mathf.Clamp01((Time.time - _startTime) / TimeToMaxSpeed);
        VisualEffect.SetFloat("FanSpeed", factor * MaxSpeed);
    }
}
