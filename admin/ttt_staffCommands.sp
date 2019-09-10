#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

#include <ttt>
#include <colorvariables>
#include <generics>
#include <ttt_messages>
#include <ttt_ranks>
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
    RegAdminCmd("sm_slaynr", Command_SlayNextRound, ADMFLAG_GENERIC, "Slay a player before roles are assigned for the next round.");
    RegAdminCmd("sm_unslaynr", Command_RemoveSlayNextRound, ADMFLAG_GENERIC, "Remove slays for a player before roles are assigned for the next round.");
    RegAdminCmd("sm_tp", Command_Teleport, ADMFLAG_GENERIC, "Allows a staff member to teleport another player.");
    RegAdminCmd("sm_teleport", Command_Teleport, ADMFLAG_GENERIC, "Allows a staff member to teleport another player.");
}

public Action Command_BanTimes(int client, int args) {
    CPrintToChat(client, TTT_MESSAGE ... "The following are some common ban times:");
    CPrintToChat(client, TTT_MESSAGE ... "{orange}1 {default}hour  --> {orange}60    {default}minutes");
    CPrintToChat(client, TTT_MESSAGE ... "{orange}1 {default}day   --> {orange}1440  {default}minutes");
    CPrintToChat(client, TTT_MESSAGE ... "{orange}2 {default}days  --> {orange}2880  {default}minutes");
    CPrintToChat(client, TTT_MESSAGE ... "{orange}1 {default}week  --> {orange}10080 {default}minutes");
    CPrintToChat(client, TTT_MESSAGE ... "{orange}1 {default}month --> {orange}40320 {default}minutes");

    return Plugin_Handled;
}

public Action Command_ForceSpectator(int client, int args)
{
    if (args < 1)
    {
        CPrintToChat(client, TTT_USAGE ... "sm_forcespec <target>");
        return Plugin_Handled;
    }

    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, false, false);

    if(!IsValidClient(target))
    {
        CPrintToChat(client, TTT_ERROR ... "Invalid target!");
        return Plugin_Handled;
    }

    if (client == target)
    {
        CPrintToChat(client, TTT_ERROR ... "Just use /afk.");
        return Plugin_Handled;
    }
    
    if (GetClientTeam(target) == CS_TEAM_SPECTATOR)
    {
        CPrintToChat(client, TTT_ERROR ... "Target already spectating.");
        return Plugin_Handled;
    }

    ChangeClientTeam(target, CS_TEAM_SPECTATOR);
    CPrintToChatAll(TTT_MESSAGE ... "{yellow}%N {default}was forced to spectator by {yellow}%N", target, client);

    return Plugin_Handled;
}

public Action Command_ReloadPlugin(int client, int args)
{
    if (args < 1) {
        CPrintToChat(client, TTT_USAGE ... "sm_reload <plugin>");
        return Plugin_Handled;
    }

    char plugin[128];
    GetCmdArg(1, plugin, sizeof(plugin));

    char load[1024], reload[1024];
    ServerCommandEx(reload, sizeof(reload), "sm plugins reload %s", plugin);
    PrintToConsole(client, reload);
    ServerCommandEx(load, sizeof(load), "sm plugins load %s", plugin);
    PrintToConsole(client, load);
    CPrintToChat(client, TTT_MESSAGE ... "{default}Reloaded {green}%s {default}successfully!", plugin);

    return Plugin_Handled;
}

public Action Command_SlayNextRound(int client, int args)
{
    if (args < 1)
    {
        CPrintToChat(client, TTT_USAGE ... "sm_slaynr <#userid|name>");
        return Plugin_Handled;
    }

    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, false, false);
        
    if(!IsValidClient(target))
    {
        CPrintToChat(client, TTT_ERROR ... "Invalid target!");
        return Plugin_Handled;
    }
    
    if (!IsValidClient(target))
    {
        CPrintToChat(client, TTT_ERROR ... "Invalid target!");
        return Plugin_Handled;
    }
    
    if (target > 0)
    {
        TTT_AddRoundSlays(target, 1, false);
    }

    CPrintToChatAdmins(ADMFLAG_GENERIC, TTT_MESSAGE ... "{yellow}%N {default}will be slain next round.", target);
    return Plugin_Handled;
}

public Action Command_RemoveSlayNextRound(int client, int args)
{
    if (args < 1)
    {
        CPrintToChat(client, TTT_USAGE ... "sm_unslaynr <#userid|name>");
        return Plugin_Handled;
    }
	
    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, false, false);
        
    if (!IsValidClient(target))
    {
        CPrintToChat(client, TTT_ERROR ... "Invalid target!");
        return Plugin_Handled;
    }

    if (target > 0)
    {
        TTT_SetRoundSlays(target, 0, false);
    }

    CPrintToChatAdmins(ADMFLAG_GENERIC, TTT_MESSAGE ... "{yellow}%N {default}will no longer be slain next round.", target);
    return Plugin_Handled;
}

public Action Command_Teleport(int client, int args)
{
    if((Ranks_GetClientRank(client) == RANK_INFORMER) && (IsHigherStaffOnline(Ranks_GetClientRank(client))))
    {
        CPrintToChat(client, TTT_ERROR ... "Please contact higher staff.");
        return Plugin_Handled;
    } 
    
    if (args < 1)
    {
        CPrintToChat(client, TTT_USAGE ... "sm_teleport <#userid|name> <#userid|name>");
        return Plugin_Handled;
    }

    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, true, false);
        
    if(!IsValidClient(target))
    {
        CPrintToChat(client, TTT_ERROR ... "Invalid target!");
        return Plugin_Handled;
    }

    float pos[3];
    int recipient = -1;
    if (args == 1)
    {
        if (!RayTrace(client, pos))
        {
            CPrintToChat(client, TTT_ERROR ... "Please look at a valid location.");
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
    	CPrintToChatAll("{purple}[TTT] {blue}%N {yellow}teleported {blue}%N {yellow}to {blue}%N{yellow}.", client, target, recipient);
	}
	else
    {
        CPrintToChatAll("{purple}[TTT] {blue}%N {yellow}teleported {blue}%N{yellow}.", client, target);
    }

    return Plugin_Handled;
}