#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

ConVar cv_CustomGMNR = null;

public void OnPluginStart()
{
    cv_CustomGMNR = CreateConVar("cv_CustomGMNR", "false", "Is it a custom gamemode next round");
    RegAdminCmd("sm_reloadgm", Command_ReloadGM, ADMFLAG_GENERIC, "sm_reloadgm - Reload custom gamemodes");
}

public Action Command_ReloadGM(int client, int args)
{
    char buffer[256];
    cv_CustomGMNR.SetBool(false, false, true);

    ServerCommandEx(buffer, sizeof(buffer), "sm plugins reload clwo/gameplay/hidden");
    PrintToConsole(client, "%s", buffer);

    ServerCommandEx(buffer, sizeof(buffer), "sm plugins reload clwo/gameplay/tdm");
    PrintToConsole(client, "%s", buffer);

    ServerCommandEx(buffer, sizeof(buffer), "sm plugins reload clwo/gameplay/juggernaut");
    PrintToConsole(client, "%s", buffer);

    ServerCommandEx(buffer, sizeof(buffer), "sm plugins reload clwo/gameplay/gmhelper");
    PrintToConsole(client, "%s", buffer);
    
    return Plugin_Handled;
}