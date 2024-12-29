#ifndef SIM_FUNCS_SHARED
#define SIM_FUNCS_SHARED

inline int OrderPreservingFloatMap(float value)
{  
    return (int)(value * (1<<16));
}

inline float InverseOrderPreservingFloatMap(int value)
{    
    return ((float)value) / (1<<16);
}

inline int3 Float3ToInt3(float3 value)
{
    return int3(OrderPreservingFloatMap(value.x), OrderPreservingFloatMap(value.y), OrderPreservingFloatMap(value.z));
}

inline float3 Int3ToFloat3(int3 value)
{
    return float3(InverseOrderPreservingFloatMap(value.x), InverseOrderPreservingFloatMap(value.y), InverseOrderPreservingFloatMap(value.z));
}

inline void WriteToBuffer(RWStructuredBuffer<int> buffer, uint index, int3 inPosition) 
{
    int x,y,z = 0;
    InterlockedExchange(buffer[index * 3], inPosition.x, x);
    InterlockedExchange(buffer[index * 3 + 1], inPosition.y, y);
    InterlockedExchange(buffer[index * 3 + 2], inPosition.z, z);
}

inline int3 AddToBuffer(RWStructuredBuffer<int> buffer, uint index, int3 delta) 
{
    int x,y,z = 0;
    InterlockedAdd(buffer[index * 3], delta.x, x);
    InterlockedAdd(buffer[index * 3 + 1], delta.y, y);
    InterlockedAdd(buffer[index * 3 + 2], delta.z, z);
    return int3(x,y,z) + delta;
}

inline int3 AtomicReadBuffer(RWStructuredBuffer<int> buffer, uint index) 
{
    int x,y,z = 0;
    InterlockedAdd(buffer[index * 3], 0, x);
    InterlockedAdd(buffer[index * 3 + 1], 0, y);
    InterlockedAdd(buffer[index * 3 + 2], 0, z);
    return int3(x,y,z);
}

inline int3 ReadBuffer(RWStructuredBuffer<int> buffer, uint index) 
{
    return int3(buffer[index * 3], buffer[index * 3 + 1], buffer[index * 3 + 2]);
}
#endif