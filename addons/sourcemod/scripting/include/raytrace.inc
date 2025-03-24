#if defined _raytrace_include
  #endinput
#endif
#define _raytrace_include

#include <sourcemod>
#include <sdktools>

stock bool RayTrace(int client, float pos[3]) {
    float vOrigin[3], vAngles[3];

    GetClientEyePosition(client, vOrigin);
    GetClientEyeAngles(client, vAngles);

    Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
    if(TR_DidHit(trace)) {
        TR_GetEndPosition(pos, trace);
        CloseHandle(trace);

        return true;
    }

    CloseHandle(trace);
    return false;
}

stock bool TraceEntityFilterPlayer(entity, contentsMask)
{
    return entity > MaxClients;
}