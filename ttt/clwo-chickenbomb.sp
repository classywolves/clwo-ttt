#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define SOUND_BOMB "inilo/jailbreak_v1_452489/bomb_v1_452489/bomb_explosion01_452489.mp3"

public Plugin myinfo =
{
    name = "Chicken bomb",
    author = "MarsTwix",
    description = "A chicken that can explode!!",
    version = "0.1.0",
    url = ""
};

public OnPluginStart()
{
    RegConsoleCmd("sm_spawnchicken", Command_SpawnChicken, "Spawns a chicken");
    
    PrintToServer("[CBB] Loaded succcessfully");
}

public OnMapStart()
{
    PrecacheSound(SOUND_BOMB);
}

public Action Command_SpawnChicken (int client, int args)
{
    int chicken = CreateEntityByName("chicken");

    float origin[3];
    if (!IsValidEntity(chicken))
    {
        PrintToServer("Couldnt create entity \"chicken\".");
        return Plugin_Handled;
    }

    GetClientAbsOrigin(client, origin);

    DispatchKeyValue(chicken, "ExplodeDamage", "500");
    DispatchKeyValue(chicken, "ExplodeRadius", "2000");
    DispatchSpawn(chicken);
    
    SetEntProp(chicken, Prop_Data, "m_takedamage", 0);

    origin[0] += 20.0;
    TeleportEntity(chicken, origin, NULL_VECTOR, NULL_VECTOR);
    CreateTimer(3.0, RedChicken, chicken);
    CreateTimer(6.0, NormalChicken, chicken);
    CreateTimer(9.0, RedChicken, chicken);
    CreateTimer(12.0, NormalChicken, chicken);
    CreateTimer(15.0, RedChicken, chicken);
    CreateTimer(18.0, NormalChicken, chicken);
    CreateTimer(21.0, KillChicken, chicken);

    return Plugin_Handled;
} 

public Action RedChicken(Handle timer, int chicken)
{
    DispatchKeyValue(chicken, "rendercolor", "255, 0, 0");
    return Plugin_Stop;
}

public Action NormalChicken(Handle timer, int chicken)
{
    DispatchKeyValue(chicken, "rendercolor", "255, 255, 255");
    return Plugin_Stop;
}  

public Action KillChicken(Handle timer, int chicken)
{
    AcceptEntityInput(chicken, "Kill");
    EmitSoundToAll(SOUND_BOMB, chicken);
    return Plugin_Stop;
}
