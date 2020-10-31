#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorlib>
#include <generics>
#include <ttt_skills>

#define NIGHTVISION_MAX_LEVEL 1

public Plugin myinfo =
{
    name = "TTT NightVision",
    author = "c0rp3n",
    description = "TTT Night Vision Skill",
    version = "0.0.1",
    url = ""
};

ConVar matFullbright;

char soundTurnOn[PLATFORM_MAX_PATH] = "ttt_clwo/nightvision/nvon.mp3";

bool nightVisionEnabled[MAXPLAYERS + 1] = { false, ... };

public OnPluginStart()
{
    PreCache();
    GetConVars();
    RegisterCmds();

    PrintToServer("[NVS] Loaded successfully");
}

public OnAllPluginsLoaded()
{
    Skills_RegisterSkill(Skill_NightVision, "Night Vision", "Allows the player to see clearly even in the darkest of places.", NIGHTVISION_MAX_LEVEL);
}

public void PreCache()
{
    PrecacheSound(soundTurnOn, true);

    char buffer[PLATFORM_MAX_PATH];
    Format(buffer, sizeof(buffer),"sound/%s", soundTurnOn);
    AddFileToDownloadsTable(buffer);
}

public void GetConVars()
{
    matFullbright = FindConVar("mat_fullbright");
}

public void RegisterCmds()
{
    RegConsoleCmd("sm_nv", Command_NightVision, "Toggles Night Vision for the player.");
}

public Action Command_NightVision(int client, int args)
{
    if (Skills_GetSkill(client, Skill_NightVision, 0, NIGHTVISION_MAX_LEVEL))
    {
        int iFlags = matFullbright.Flags;
        matFullbright.Flags = iFlags &~ FCVAR_CHEAT;

        if (nightVisionEnabled[client])
        {
            nightVisionEnabled[client] = false;
            //CPrintToChat(client, "{yellow}[TTT] {yellow}NV is {red}deactivated{yellow}.");
            SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0); // Night Vision Off
            matFullbright.ReplicateToClient(client, "0");
        }
        else
        {
            nightVisionEnabled[client] = true;
            //CPrintToChat(client, "{yellow}[TTT] {yellow}NV is {green}activated{yellow}.");
            EmitSoundToClient(client, soundTurnOn);
            SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1); // Night Vision On
            matFullbright.ReplicateToClient(client, "1");
        }

        matFullbright.Flags = iFlags | FCVAR_CHEAT;
    }
    else
    {
        CPrintToChat(client, "{purple}[TTT] {orchid}You have not yet unlocked the night vision skill.");
    }
}
