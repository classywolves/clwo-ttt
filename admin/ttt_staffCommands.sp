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
    RegAdminCmd("sm_scsay", Command_SCSay, ADMFLAG_CHAT, "Targeted CSay.");
    RegAdminCmd("sm_smsay", Command_SMSay, ADMFLAG_CHAT, "Targeted MSay.");
    RegAdminCmd("sm_tp", Command_Teleport, ADMFLAG_GENERIC, "Allows a staff member to teleport another player.");
    RegAdminCmd("sm_teleport", Command_Teleport, ADMFLAG_GENERIC, "Allows a staff member to teleport another player.");
}

public Action Command_BanTimes(int client, int args) {
    CPrintToChat(client, "{purple}[TTT] {yellow}The following are some common ban times:");
    CPrintToChat(client, "{purple}[TTT] {yellow} - {blue}1 {yellow}hour  --> {blue}60    {yellow}minutes");
    CPrintToChat(client, "{purple}[TTT] {yellow} - {blue}1 {yellow}day   --> {blue}1440  {yellow}minutes");
    CPrintToChat(client, "{purple}[TTT] {yellow} - {blue}2 {yellow}days  --> {blue}2880  {yellow}minutes");
    CPrintToChat(client, "{purple}[TTT] {yellow} - {blue}1 {yellow}week  --> {blue}10080 {yellow}minutes");
    CPrintToChat(client, "{purple}[TTT] {yellow} - {blue}1 {yellow}month --> {blue}40320 {yellow}minutes");

    return Plugin_Handled;
}

public Action Command_ForceSpectator(int client, int args)
{
    if (args < 1)
    {
        TTT_Error(client, "Usage: sm_forcespec <target>.");
        return Plugin_Handled;
    }

    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, false, false);
    
    int targetTeam = GetClientTeam(target);
    if (targetTeam == CS_TEAM_SPECTATOR)
    {
        TTT_Error(client, "Target already spectating.");
        return Plugin_Handled;
    }

    ChangeClientTeam(target, CS_TEAM_SPECTATOR);
    CPrintToChat(target, "{purple}[TTT] {yellow}You were forced to spectator by %N.", client);
    CPrintToChatAll("{purple}[TTT] {blue]%N {yellow}was forced to spectator by %N.", target, client);

    return Plugin_Handled;
}

public Action Command_ReloadPlugin(int client, int args)
{
    if (args < 1) {
        TTT_Error(client, "Usage: sm_reload <plugin>.");
        return Plugin_Handled;
    }

    char plugin[128];
    GetCmdArg(1, plugin, sizeof(plugin));

    char load[1024], reload[1024];
    ServerCommandEx(reload, sizeof(reload), "sm plugins reload %s", plugin);
    PrintToConsole(client, reload);
    ServerCommandEx(load, sizeof(load), "sm plugins load %s", plugin);
    PrintToConsole(client, load);
    CPrintToChat(client, "{purple}[TTT] {yellow}Reloaded {green}%s {yellow}successfully!", plugin);

    return Plugin_Handled;
}

public Action Command_SlayNextRound(int client, int args)
{
    if (args < 1)
    {
        TTT_Error(client, "Invalid Usage: sm_slaynr <target name>");
        return Plugin_Handled;
    }

    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, false, false);
    
    if (target > 0)
    {
        TTT_AddRoundSlays(target, 1, false);
    }

    CPrintToChatStaff("{purple}[TTT] {red}%N {yellow}will be slain next round.", target);
    return Plugin_Handled;
}

public Action Command_RemoveSlayNextRound(int client, int args)
{
    if (args < 1)
    {
        TTT_Error(client, "Invalid Usage: sm_unslaynr <target name>");
        return Plugin_Handled;
    }
	
    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, false, false);

    if (target > 0)
    {
        TTT_SetRoundSlays(target, 0, false);
    }

    CPrintToChatStaff("{purple}[TTT] {red}%N {yellow}will no longer be slain next round.", target);
    return Plugin_Handled;
}
	
public Action Command_SMSay(int client, int args)
{
	if (args < 2)
    {
		TTT_Error(client, "Invalid Usage: /smsay <player> <message>");
		return Plugin_Handled;
	}

	char message[255], arg1[128], buffer[128], title[128];

	GetCmdArg(1, arg1, sizeof(arg1));
	int target = TTT_Target(arg1, client, true, false, false);

	if (args >= 2)
    {
		// They've included a message!
		GetCmdArg(2, message, sizeof(message));

		for (int i = 3; i <= args; i++)
        {
			GetCmdArg(i, buffer, sizeof(buffer));
			Format(message, sizeof(message), "%s %s", message, buffer);
		}
	}

	Format(title, sizeof(title), "%N: ", client);
	TTT_SendPanelMsg(target, title, message);

	return Plugin_Handled;
}

public Action Command_SCSay(int client, int args)
{
	if (args < 2)
    {
		TTT_Error(client, "Invalid Usage: /scsay <player> <message>");
		return Plugin_Handled;
	}

	char message[255], arg1[128], buffer[128];

	GetCmdArg(1, arg1, sizeof(arg1));
	int target = TTT_Target(arg1, client, true, false, false);

	if (target < 0)
    {
		return Plugin_Handled;
	}

	if (args >= 2)
    {
		// They've included a message!
		GetCmdArg(2, message, sizeof(message));

		for (int i = 3; i <= args; i++)
        {
			GetCmdArg(i, buffer, sizeof(buffer));
			Format(message, sizeof(message), "%s %s", message, buffer);
		}
	}

	PrintCenterText(target, message);
	return Plugin_Handled;
}

public Action Command_Teleport(int client, int args)
{
    if (args < 1)
    {
        TTT_Error(client, "Usage: sm_teleport <target> [player].");
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
    	CPrintToChatAll("{purple}[TTT] {blue}%N {yellow}teleported {blue}%N {yellow}to {blue}%N.", client, target, recipient);
	}
	else
    {
        CPrintToChatAll("{purple}[TTT] {blue}%N {yellow}teleported {blue}%N.", client, target);
    }

    return Plugin_Handled;
}
