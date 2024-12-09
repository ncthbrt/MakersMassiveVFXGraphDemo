void WriteBuffer(VFXAttributes attributes, RWStructuredBuffer<float3> buffer, uint index, float3 value) {
    float _x,_y,_z = 0;
    InterlockedExchange(buffer[index].x, value.x, _x);
    InterlockedExchange(buffer[index].y, value.y, _y);
    InterlockedExchange(buffer[index].z, value.z, _z);
}

void ExchangeBuffer(RWStructuredBuffer<float3> buffer, uint index, float3 current, out float3 prev) {
    float _x,_y,_z = 0;
    InterlockedExchange(buffer[index].x, current.x, prev.x);
    InterlockedExchange(buffer[index].y, current.y, prev.y);
    InterlockedExchange(buffer[index].z, current.z, prev.z);
}


void IntegrateVerlet(inout VFXAttributes attributes, float deltaTime)
{
    attributes.position = 2 * attributes.position - attributes.oldPosition + ((deltaTime*deltaTime) * attributes.acceleration);
}

void ApplyConstraint(inout VFXAttributes attributes, RWStructuredBuffer<float3> positionsBuffer, RWStructuredBuffer<float3> errorBuffer, float targetDist, uint bufferSize, uint currIndex)
{   
    float3 thisPosition = attributes.position;
    float3 nextThisPosition = attributes.position;
    if (currIndex > 0)
    {
        [unroll(48)]
        for (uint i = 0; i < 48; ++i)
        {
            ExchangeBuffer(positionsBuffer, currIndex, nextThisPosition, thisPosition);
            uint index = currIndex - 1;
            float3 position = positionsBuffer[index];
            float3 delta = (position - current);
            float dist = length(delta);
            float halfDist = (dist - targetDist) / 2.0;                
            delta = SafeNormalize(delta);
            if (currIndex == bufferSize - 1)
            {
                next += ((halfDist + halfDist) * delta);
            }
            else
            {
                next += (halfDist * delta);
            }
            
            if (currIndex + 1 < bufferSize)
            {
                current = positionsBuffer[currIndex];
                index = currIndex + 1;
                position = positionsBuffer[index];
                delta = (position - current);
                dist = length(delta);
                halfDist = (dist - targetDist) / 2.0;
                delta = SafeNormalize(delta);
                next += (halfDist * delta);
            }
        }
        attributes.position =  next;
    }
}
