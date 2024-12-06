void WriteBuffer(VFXAttributes attributes, RWStructuredBuffer<float4> buffer, uint index, float4 inPosition) {
	buffer[index] = inPosition;
}

float4 SafeNormalize(float4 inVec)
{
    float dp3 = max(0.000001, dot(inVec, inVec));
    return inVec * rsqrt(dp3);
}

void ApplyConstraint(inout VFXAttributes attributes, RWStructuredBuffer<float4> buffer, float targetDist, uint bufferSize, uint currIndex)
{   
    buffer[currIndex] = float4(attributes.position, 0.0);
    if (currIndex % 2 == 1)
    {
        [unroll(48)]
        for (uint i = 0; i < 48; ++i)
        {
            float4 current = buffer[currIndex];
            uint index = clamp(currIndex - 1, 0, bufferSize);
            float4 position = buffer[index];
            float4 delta = (position - current);
            float dist = length(delta);
            float halfDist = (dist - targetDist) / 2.0;
            if (currIndex > 0)
            {
                delta = SafeNormalize(delta);
                if (currIndex == bufferSize - 1)
                {
                    buffer[currIndex] += ((halfDist + halfDist) * delta);
                }
                else
                {
                    buffer[currIndex] += (halfDist * delta);
                    buffer[index] -= (halfDist * delta);
                }
            }
        
            if (currIndex + 1 < bufferSize)
            {
                index = currIndex + 1;
                position = buffer[index];
                delta = (position - current);
                dist = length(delta);
                halfDist = (dist - targetDist) / 2.0;
                delta = SafeNormalize(delta);
                buffer[currIndex] += (halfDist * delta);
                buffer[index] -= (halfDist * delta);
            }
        }
    }

    attributes.position = buffer[currIndex].xyz;
}
