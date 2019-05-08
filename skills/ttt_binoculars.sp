#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <generics>
#include <ttt_skills>

#define BINOCULARS_MAX_LEVEL 1

public Plugin myinfo =
{
    name = "TTT Binoculars",
    author = "Popey & c0rp3n",
    description = "TTT Binoculars Skill",
    version = "0.0.1",
    url = ""
};

char soundBinoActivation[PLATFORM_MAX_PATH] = "ttt_clwo/ttt_binoculars_activate.mp3";
char soundBinoZoom[PLATFORM_MAX_PATH] = "ttt_clwo/ttt_binoculars_switch.mp3";
char soundBinoDeactivation[PLATFORM_MAX_PATH] = "ttt_clwo/ttt_binoculars_deactivate.mp3";

int initialFov[MAXPLAYERS + 1];
int zoomLevel[MAXPLAYERS + 1] = {0, ...};

public OnPluginStart()
{
    PreCache();
    RegisterCmds();
    HookEvents();
    //InitDBs();

    LoadTranslations("common.phrases");

    PrintToServer("[BNO] Loaded successfully");
}

public OnAllPluginsLoaded()
{
    Skills_RegisterSkill(Skill_Binoculars, "Binoculars", "Allows the player to zoom in with any weapon.", BINOCULARS_MAX_LEVEL);
}

public void PreCache()
{
    PrecacheSound(soundBinoActivation, true);
    PrecacheSound(soundBinoZoom);
    PrecacheSound(soundBinoDeactivation, true);

    char buffer[PLATFORM_MAX_PATH];

    Format(buffer, sizeof(buffer),"sound/%s", soundBinoActivation);
    AddFileToDownloadsTable(buffer);

    Format(buffer, sizeof(buffer),"sound/%s", soundBinoZoom);
    AddFileToDownloadsTable(buffer);

    Format(buffer, sizeof(buffer),"sound/%s", soundBinoDeactivation);
    AddFileToDownloadsTable(buffer);
}

public void RegisterCmds()
{
    RegConsoleCmd("sm_binoculars", CommandBinoculars);
}

public void HookEvents()
{
    HookEvent("weapon_zoom", OnWeaponZoom);
    HookEvent("player_spawn", OnPlayerSpawn);
}

/*
public void InitDBs()
{

}
*/

public Action CommandBinoculars(int client, int args)
{
    if (Skills_GetSkill(client, Skill_Binoculars, 0, BINOCULARS_MAX_LEVEL))
    {
        CPrintToChat(client, "{purple}[TTT] {orchid}You do not have a skill point in this skill.");
        return Plugin_Handled;
    }

    if (IsPlayerAlive(client))
    {
        CPrintToChat(client, "{purple}[TTT] {orchid}You must be alive to use this skill.");
        return Plugin_Handled;
    }

    zoomLevel[client]++;
    switch (zoomLevel[client])
    {
        case 1:
        {
            SetEntProp(client, Prop_Send, "m_iFOV", 40);
            // Play Activation Sound
            EmitSoundToClient(client, soundBinoActivation);
        }
        case 2:
        {
            SetEntProp(client, Prop_Send, "m_iFOV", 10);
            // Play Switch Sound
            EmitSoundToClient(client, soundBinoZoom);
        }
        case 3:
        {
            SetEntProp(client, Prop_Send, "m_iFOV", 0);
            zoomLevel[client] = 0;
            // Play Deactivation Sound
            EmitSoundToClient(client, soundBinoDeactivation);
        }
        default:
        {
            SetEntProp(client, Prop_Send, "m_iFOV", 0);
            zoomLevel[client] = 0;
        }
    }

    return Plugin_Handled;
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
    if (buttons & IN_ATTACK && zoomLevel[client] > 0) {
        SetEntProp(client, Prop_Send, "m_iFOV", 0);
        zoomLevel[client] = 0;
        // Play Deactivation Sound
        EmitSoundToClient(client, soundBinoDeactivation);
    }

    return Plugin_Continue;
}

public Action OnWeaponZoom(Handle event, const char[] name, bool dont_broadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    zoomLevel[client] = 0;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont_broadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    initialFov[client] = GetEntProp(client, Prop_Send, "m_iFOV");
    zoomLevel[client] = 0;
}
