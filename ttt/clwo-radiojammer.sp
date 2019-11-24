#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_functions>

#include <cstrike>
#include <entity>

#define SOUND_JAMMER "ttt_clwo/ECM Jammer Sound Effect.mp3"

public Plugin myinfo =
{
    name = "CLWO radio jammer",
    author = "MarsTwix",
    description = "The radio jammer will mute everyone",
    version = "0.1.0",
    url = ""
};

public OnPluginStart()
{
    RegAdminCmd("sm_radiojammer", Command_RadioJammer, ADMFLAG_GENERIC, "spawns in a radio that will 'jam' the voice radio");
}

public OnMapStart()
{
    PrecacheSound(SOUND_JAMMER);
}

public Action Command_RadioJammer(int client, int args)
{
    float vPos[3];
    GetClientAbsOrigin(client, vPos);
    char model[PLATFORM_MAX_PATH] = "props/cs_office/radio.mdl";
    char classname[256] = "prop_dynamic_override";
    SpawnEnt(classname, model,vPos);
}

public void SpawnEnt(const char[] classname, char model[PLATFORM_MAX_PATH], float vPos[3])
{
    int iEnt = CreateEntityByName("prop_dynamic_override");

    if (!IsModelPrecached(model))
        PrecacheModel(model);
        
    SetEntityModel(iEnt, model);
	SetEntityRenderMode(iEnt, RENDER_TRANSCOLOR);

    SetEntProp(iEnt, Prop_Send, "m_nSolidType", 6);
    SetEntProp(iEnt, Prop_Send, "m_nSolidType", 1);
  
    DispatchKeyValue(iEnt, "Physics Mode", "1");
    DispatchSpawn(iEnt);
    
    TeleportEntity(iEnt, vPos, NULL_VECTOR, NULL_VECTOR);
    EmitSoundToAll(SOUND_JAMMER, iEnt);
}