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
#include <generics>

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

	MsgInsert(name, auth, text);

	return Plugin_Continue;
}