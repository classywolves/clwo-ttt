#pragma semicolon 1

/*
* Base CS:GO plugin requirements.
*/
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
* Custom include files.
*/
#include <ttt>
#include <colorvariables>
#include <generics>
#include <ttt_ranks>
#include <ttt_messages>
#include <ttt_targeting>
#include <raytrace>

public Plugin myinfo =
{
    name = "TTT Staff Commands",
    author = "Popey & c0rp3n",
    description = "General staff commands for CLWO TTT.",
    version = "1.0.0",
    url = ""
};

public OnPluginStart()
{
    RegisterCmds();

    PrintToServer("[SCM] Loaded successfully");
}

public void RegisterCmds()
{
    RegAdminCmd("sm_bantimes", Command_BanTimes, ADMFLAG_GENERIC, "List Common Time Lengths.");
    RegAdminCmd("sm_forcespec", Command_ForceSpectator, ADMFLAG_GENERIC, "Moves a player to spectator.");
    RegAdminCmd("sm_reloadplugin", Command_ReloadPlugin, ADMFLAG_RCON, "Reloads the passed plugin.");
    RegAdminCmd("sm_slaynr", Command_SlayNextRound, ADMFLAG_SLAY, "Slay a player before roles are assigned for the next round.");
    RegAdminCmd("sm_unslaynr", Command_RemoveSlayNextRound, ADMFLAG_SLAY, "Remove slays for a player before roles are assigned for the next round.");
    RegAdminCmd("sm_tp", Command_Teleport, ADMFLAG_GENERIC, "Allows a staff member to teleport another player.");
    RegAdminCmd("sm_teleport", Command_Teleport, ADMFLAG_GENERIC, "Allows a staff member to teleport another player.");
}

public Action Command_BanTimes(int client, int args) {
    TTT_Message(client, "The following are some common ban times:");
    TTT_Message(client, "{orange}1 {default}hour  --> {orange}60    {default}minutes");
    TTT_Message(client, "{orange}1 {default}day   --> {orange}1440  {default}minutes");
    TTT_Message(client, "{orange}2 {default}days  --> {orange}2880  {default}minutes");
    TTT_Message(client, "{orange}1 {default}week  --> {orange}10080 {default}minutes");
    TTT_Message(client, "{orange}1 {default}month --> {orange}40320 {default}minutes");

    return Plugin_Handled;
}

public Action Command_ForceSpectator(int client, int args)
{
    if (args < 1)
    {
        TTT_Usage(client, "sm_forcespec <target>");
        return Plugin_Handled;
    }

    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, false, false);

    if (client == target)
    {
        TTT_Error(client, "Just use /afk.");
        return Plugin_Handled;
    }
    
    int targetTeam = GetClientTeam(target);
    if (targetTeam == CS_TEAM_SPECTATOR)
    {
        TTT_Error(client, "Target already spectating.");
        return Plugin_Handled;
    }

    ChangeClientTeam(target, CS_TEAM_SPECTATOR);
    TTT_MessageAll("{yellow}%N {default}was forced to spectator by {yellow}%N", target, client);

    return Plugin_Handled;
}

public Action Command_ReloadPlugin(int client, int args)
{
    if (args < 1) {
        TTT_Usage(client, "sm_reload <plugin>");
        return Plugin_Handled;
    }

    char plugin[128];
    GetCmdArg(1, plugin, sizeof(plugin));

    char load[1024], reload[1024];
    ServerCommandEx(reload, sizeof(reload), "sm plugins reload %s", plugin);
    PrintToConsole(client, reload);
    ServerCommandEx(load, sizeof(load), "sm plugins load %s", plugin);
    PrintToConsole(client, load);
    TTT_Message(client, "{default}Reloaded {green}%s {default}successfully!", plugin);

    return Plugin_Handled;
}

public Action Command_SlayNextRound(int client, int args)
{
    if (args < 1)
    {
        TTT_Usage(client, "sm_slaynr <#userid|name>");
        return Plugin_Handled;
    }

    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, false, false);
    
    if (target > 0)
    {
        TTT_AddRoundSlays(target, 1, false);
    }

    TTT_MessageStaff(ADMFLAG_GENERIC, "{yellow}%N {orange}will be slain next round.", target);
    return Plugin_Handled;
}

public Action Command_RemoveSlayNextRound(int client, int args)
{
    if (args < 1)
    {
        TTT_Usage(client, "sm_unslaynr <#userid|name>");
        return Plugin_Handled;
    }
	
    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, false, false);

    if (target > 0)
    {
        TTT_SetRoundSlays(target, 0, false);
    }

    TTT_MessageStaff(ADMFLAG_GENERIC, "{yellow}%N {orange}will no longer be slain next round.", target);
    return Plugin_Handled;
}

public Action Command_Teleport(int client, int args)
{
    if (args < 1)
    {
        TTT_Usage(client, "sm_teleport <#userid|name> <#userid|name>");
        return Plugin_Handled;
    }

    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, true, false);
    
    float pos[3];
    int recipient = -1;
    if (args == 1)
    {
        if (!RayTrace(client, pos))
        {
            TTT_Error(client, "Please look at a valid location.");
            return Plugin_Handled;
        }
    }
    else
    {
        GetCmdArg(2, buffer, MAX_NAME_LENGTH);
        recipient = TTT_Target(buffer, client, true, true, false);
        if (!IsValidClient(recipient)) { return Plugin_Handled; }

        GetClientEyePosition(recipient, pos);
    }

    TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR);
    
    if (recipient > 0)
    {
    	TTT_MessageAll("{yellow}%N {default}teleported {yellow}%N {default}to {yellow}%N", client, target, recipient);
	}
	else
    {
        TTT_MessageAll("{yellow}%N {default}teleported {yellow}%N", client, target);
    }

    return Plugin_Handled;
}
