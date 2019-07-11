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
#include <colorvariables>
#include <sourcecomms>
#include <generics>
#include <ttt_messages>
#include <ttt_targeting>

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
  RegAdminCmd("sm_addhistory", Command_AddHistory, ADMFLAG_CHAT, "Add a message to a players log");
  RegAdminCmd("sm_history", Command_History, ADMFLAG_CHAT, "List a players history");
}

public Action Command_AddHistory(int client, int args) {
	// Usage is "/addhistory <target> <message>"
	if (args < 2) {
		TTT_Usage(client, "sm_addhistory <target> <message>");
		return Plugin_Handled;
	}

	char arg1[128], message[256], buffer[128], auth[64], adminAuth[64], adminName[64];

	GetCmdArg(1, arg1, sizeof(arg1));
	int target = TTT_Target(arg1, client, true, true, false);

	if (target == -1)
    {
		return Plugin_Handled;
	}

	GetCmdArg(2, message, sizeof(message));

	for (int i = 3; i <= args; i++) {
		GetCmdArg(i, buffer, sizeof(buffer));
		Format(message, sizeof(message), "%s %s", message, buffer);
	}

	GetClientAuthId(target, AuthId_Steam2, auth, sizeof(auth));
	GetClientAuthId(client, AuthId_Steam2, adminAuth, sizeof(adminAuth));
	GetClientName(client, adminName, sizeof(adminName));

	HistoryInsert(auth, message, "ADM_NOTE", adminName, adminAuth);

	return Plugin_Handled;
}

public Action Command_History(int client, int args) {
	// Usage is "/history <target> <page>"
	if (args < 1) {
		TTT_Usage(client, "sm_addhistory <target> <page>");
		return Plugin_Handled;
	}

	char arg1[128];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = TTT_Target(arg1, client, true, true, false);

	if (target == -1)
    {
		return Plugin_Handled;
	}

    return Plugin_Handled;
}
