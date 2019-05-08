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
#include <datapack>

/*
* Custom methodmaps.
*/
#include <player_methodmap>

public Plugin myinfo = {
    name = "TTT Staff Commands",
    author = "Popey & c0rp3n",
    description = "General staff commands for CLWO TTT.",
    version = "1.0.0",
    url = ""
};

public OnPluginStart() {
    RegisterCmds();

    PrintToServer("[SCM] Loaded successfully");
}

public void RegisterCmds() {
    RegAdminCmd("sm_bantimes", Command_BanTimes, ADMFLAG_GENERIC, "List Common Time Lengths.");
    RegAdminCmd("sm_forcespec", Command_ForceSpectator, ADMFLAG_GENERIC, "Moves a player to spectator.");
    RegAdminCmd("sm_reloadplugin", Command_ReloadPlugin, ADMFLAG_RCON, "Reloads the passed plugin.");
    RegAdminCmd("sm_slaynr", Command_SlayNextRound, ADMFLAG_SLAY, "Slay a player before roles are assigned for the next round.");
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

public Action Command_ForceSpectator(int client, int args) {
    Player player = Player(client);
    if (args < 1) {
        player.Error("Usage: sm_forcespec <target>.");
        return Plugin_Handled;
    }

    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    Player target = player.TargetOne(buffer, true);
    if (!target.ValidClient) { return Plugin_Handled; }

    target.Team = CS_TEAM_SPECTATOR;
    CPrintToChat(target.Client, "{purple}[TTT] {yellow}You were forced to spectator by %N.", client);

    return Plugin_Handled;
}

public Action Command_ReloadPlugin(int client, int args) {
    Player player = Player(client);
    if (args < 1) {
        player.Error("Usage: sm_reload <plugin>.");
        return Plugin_Handled;
    }

    char plugin[128]
    GetCmdArg(1, plugin, sizeof(plugin));

    char load[1024], reload[1024];
    ServerCommandEx(reload, sizeof(reload), "sm plugins reload %s", plugin);
    PrintToConsole(client, reload);
    ServerCommandEx(load, sizeof(load), "sm plugins load %s", plugin);
    PrintToConsole(client, load);
    CPrintToChat(client, "{purple}[TTT] {yellow}Reloaded {green}%s {yellow}successfully!", plugin);

    return Plugin_Handled;
}

public Action Command_SlayNextRound(int client, int args) {
    Player player = Player(client);
    if (args < 1) {
        player.Error("Invalid Usage: sm_slaynr <target name>");
        return Plugin_Handled;
    }

    char targetName[128];
    GetCmdArg(1, targetName, sizeof(targetName));
    Player playerTarget = player.TargetOne(targetName);

    TTT_AddRoundSlays(playerTarget.Client, 1, false);

    return Plugin_Handled;
}

public Action Command_SMSay(int client, int args)
{
	Player player = Player(client);
	if (args < 2) {
		player.Error("Invalid Usage: /smsay <player> <message>")
		return Plugin_Handled;
	}

	char message[255], arg1[128], buffer[128], title[128];

	GetCmdArg(1, arg1, sizeof(arg1));
	Player target = player.TargetOne(arg1, true)

	if (target.Client == -1) {
		return Plugin_Handled;
	}

	if (args >= 2) {
		// They've included a message!
		GetCmdArg(2, message, sizeof(message));

		for (int i = 3; i <= args; i++) {
			GetCmdArg(i, buffer, sizeof(buffer));
			Format(message, sizeof(message), "%s %s", message, buffer);
		}
	}

	Format(title, sizeof(title), "%N: ", player.Client);
	target.SendPanelMsg(title, message);

	return Plugin_Handled;
}

public Action Command_SCSay(int client, int args)
{
	Player player = Player(client);
	if (args < 2) {
		player.Error("Invalid Usage: /scsay <player> <message>")
		return Plugin_Handled;
	}

	char message[255], arg1[128], buffer[128];

	GetCmdArg(1, arg1, sizeof(arg1));
	Player target = player.TargetOne(arg1, true)

	if (target.Client == -1) {
		return Plugin_Handled;
	}

	if (args >= 2) {
		// They've included a message!
		GetCmdArg(2, message, sizeof(message));

		for (int i = 3; i <= args; i++) {
			GetCmdArg(i, buffer, sizeof(buffer));
			Format(message, sizeof(message), "%s %s", message, buffer);
		}
	}

	target.CSay(message);
	return Plugin_Handled;
}

public Action Command_Teleport(int client, int args) {
    Player player = Player(client);
    if (args < 1) {
        player.Error("Usage: sm_teleport <target> [player].");
        return Plugin_Handled;
    }

    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    Player target = player.TargetOne(buffer, true);
    if (!target.ValidClient) { return Plugin_Handled; }

    float pos[3];
    if (args == 1) {
        if (!player.RayTrace(pos))
        {
            player.Error("Please look at a valid location.");
            return Plugin_Handled;
        }
    }
    else {
        GetCmdArg(2, buffer, MAX_NAME_LENGTH);
        Player recipient = player.TargetOne(buffer, true);
        if (!recipient.ValidClient) { return Plugin_Handled; }

        recipient.Pos(pos);
    }

    target.SetPos(pos);
    CPrintToChatAll("{purple}[TTT] {blue}%N {yellow}teleported {blue}%N.", player.Client, target.Client);

    return Plugin_Handled;
}
