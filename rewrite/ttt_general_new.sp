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
#include <helpers>

/*
 * Database includes.
 */
#include <msg_db>

public OnPluginStart()
{
	RegisterCmds();
	HookEvents();
	InitDBs();
	
	PrintToServer("[GEN] Loaded succcessfully");
}

public void InitDBs() {
	MsgInit();
}

public void RegisterCmds() {
	//RegConsoleCmd("sm_staff", Command_Staff, "List online staff members");
	//RegConsoleCmd("sm_admins", Command_Staff, "List online staff members");
}

public void HookEvents() {
	HookEvent("player_say", OnPlayerMessage);
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	return Plugin_Continue;
}

public Action OnPlayerMessage(Event event, const char[] eventName, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client < 1)
		return Plugin_Continue;

	char name[64], auth[64], text[256];

	Player player = Player(client);
	player.Auth(AuthId_Steam2, auth);
	player.Name(name);

	GetEventString(event, "text", text, sizeof(text));

	PrintToServer("Received message");

	MsgInsert(name, auth, text);

	return Plugin_Continue;
}

public Action Command_Staff(int client, int args) {
	int staff[32];
	int staffCount = GetStaffArray(staff);

	if (staffCount == 0) {
		CPrintToChat(client, "{purple}[TTT] {orchid}There are currently %i staff online.", staffCount);
		return Plugin_Handled;
	}

	CPrintToChat(client, "{purple}[TTT] {yellow}There are currently {green}%d {yellow}staff online:", staffCount);

	for (int i = 0; i < staffCount; i++) {
		char rankName[64];

		Player player = Player(staff[i]);
		player.RankName(rankName);

		CPrintToChat(client, "{purple}[TTT] {blue}%N is a {green}%s", staff[i], rankName);
	}

	return Plugin_Handled;
}