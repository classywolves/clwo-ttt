/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <colorvariables>
#include <sourcecomms>
#include <generics>
#include <commands_helper>

/*
 * Custom methodmaps
 */
#include <player_methodmap>

/*
 * Custom databases
 */
#include <history_db>


public Plugin myinfo =
{
	name = "TTT History",
	author = "Popey",
	description = "TTT Player history system.",
	version = "1.0.0",
	url = ""
};

public OnPluginStart() {
	RegisterCmds();
	InitDBs();

	PrintToServer("[HIS] Loaded successfully");
}

public InitDBs() {
	HistoryInit();
}

// == History is table:
// SteamID, Timestamp, Message, MsgType AdminID, AdminName

public void RegisterCmds() {
  RegConsoleCmd("sm_addhistory", Command_AddHistory, "Add a message to a players log");
  RegConsoleCmd("sm_history", Command_History, "List a players history")
}

public Action Command_AddHistory(int client, int args) {
	// Usage is "/addhistory <target> <message>"
	Player player = Player(client);

	// Player is not tmod or above AND is not an active informer.
	if (!player.Informer && player.Staff) {
		player.Error("You do not have access to this command!");
		return Plugin_Handled;
	}

	if (args < 2) {
		player.Error("Invalid Usage: /addhistory <target> <message>")
		return Plugin_Handled;
	}

	char arg1[128], message[256], buffer[128], auth[64], adminAuth[64], adminName[64];

	GetCmdArg(1, arg1, sizeof(arg1));
	Player target = player.TargetOne(arg1, true);

	if (target.Client == -1) {
		return Plugin_Handled;
	}

	GetCmdArg(2, message, sizeof(message));

	for (int i = 3; i <= args; i++) {
		GetCmdArg(i, buffer, sizeof(buffer));
		Format(message, sizeof(message), "%s %s", message, buffer);
	}

	target.Auth(AuthId_Steam2, auth);
	player.Auth(AuthId_Steam2, adminAuth);
	player.Name(adminName);

	HistoryInsert(auth, message, "ADM_NOTE", adminName, adminAuth);

	return Plugin_Handled;
}

public Action Command_History(int client, int args) {
	// Usage is "/history <target> <page>"
	Player player = Player(client);

	// Player is not tmod or above AND is not an active informer.
	if (!player.Informer && player.Staff) {
		player.Error("You do not have access to this command!");
		return Plugin_Handled;
	}

	if (args < 1) {
		player.Error("Invalid Usage: /addhistory <target> <page>")
		return Plugin_Handled;
	}

	char arg1[128]
	
	GetCmdArg(1, arg1, sizeof(arg1));
	Player target = player.TargetOne(arg1, true);

	if (target.Client == -1) {
		return Plugin_Handled;
	}
}
