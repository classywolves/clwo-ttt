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

int lastChange[MAXPLAYERS + 1];

public OnPluginStart()
{
	RegisterCmds();
	HookEvents();
	InitDBs();
	
	PrintToServer("[ATN] Loaded succcessfully");
}

public void RegisterCmds() {
}

public void HookEvents() {
	HookEvent("player_changename", OnChangeName, EventHookMode_PostNoCopy);
}

public void InitDBs() {
}

public Action OnChangeName(Event event, const char[] name, bool dontBroadcast) {
	char oldName[64], newName[64];

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client) {
		return Plugin_Continue;
	}

	int now = GetTime()
	if (now - lastChange[client] <= 2) {
		return Plugin_Continue;
	}

	lastChange[client] = now;

	Player player = Player(client);

	event.GetString("oldname", oldName, sizeof(oldName));
	event.GetString("newname", newName, sizeof(newName));

	if (!StrEqual(oldName, newName) && player.Alive) {
		player.Error("Sorry, you are not allowed to change your name whilst alive.");
		player.SetName(oldName);

		return Plugin_Stop;
	}

	return Plugin_Continue;
}