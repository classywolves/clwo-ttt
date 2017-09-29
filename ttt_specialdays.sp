
#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <colorvariables>
#include <ttt>
#include <cstrike>
#include <general>

/* Plugin Info */
#define PLUGIN_NAME 			"TTT Special Days"
#define PLUGIN_VERSION_M 		"0.0.4"
#define PLUGIN_AUTHOR 			"Popey"
#define PLUGIN_DESCRIPTION		"Special days."
#define PLUGIN_URL				"https://sinisterheavens.com"

bool is_gravity_day = false;
bool is_tp_day = true;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION_M,
	url = PLUGIN_URL
};

public OnPluginStart() {
	// Register CVARS
	// rdm_version = CreateConVar("ldb_version", PLUGIN_VERSION_M, "Leaderboard Plugin Version");
	CreateConVar("url_version", PLUGIN_VERSION_M, "URL Plugin Version");
	
	// Register Commands
	RegAdminCmd("sm_force_day", Command_Force_Day, FCVAR_CHEAT, "Force a gravity day");

	// Register Events
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);

	// Alert Load Success
	PrintToServer("[URL] Has Loaded Succcessfully!");
}

public Action TTT_OnRoundStart_Pre() {
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if (!is_tp_day) { return Plugin_Continue; }
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsValidClient(client)) {
		SetEntityGravity(client, 1.0);
	}

	return Plugin_Continue;
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (is_gravity_day) {
		is_gravity_day = false;
		for (int client = 1; client <= MaxClients; client++) {
			if(IsValidClient(client)) {
				SetEntityGravity(client, 1.0);
			}
		}
	}

	if (is_tp_day) {
		is_tp_day = false;
		for (int client = 1; client <= MaxClients; client++) {
			if(IsValidClient(client)) {
				ClientCommand(client, "firstperson");
			}
		}
	}
}

public Action OnClientCommand(int client, int args)
{
	char cmd[16];
	GetCmdArg(0, cmd, sizeof(cmd));	/* Get command name */
 
 	if (is_tp_day && StrEqual(cmd, "sm_tp")) {
		/* Got the client command! Block it... */
		CPrintToChat(client, "{purple}[SD] {orchid}You cannot disable third person during a special day.");
		return Plugin_Handled;
	}
 
	return Plugin_Continue;
}

public Action Command_Force_Day(int client, int args) {
	Third_Person()
}

public Maybe_Special_Day() {
	int random = GetRandomInt(0, 1000)

	if (random < 10) {
		// Gravity_Day()
	} else if (random < 30) {
		Third_Person();
	}

	// Not a special day.
}

public Gravity_Day() {
	PrintToServer("It's a gravity day!  Setting players gravity.");
	is_gravity_day = true
	CPrintToChatAll("{purple}[SD] {green}It's a gravity day!  Setting all players gravity to {yellow}0.3{green}.")
	for (int client = 1; client <= MaxClients; client++) {
		if(IsValidClient(client)) {
			SetEntityGravity(client, 0.3);
		}
	}
}

public Third_Person() {
	PrintToServer("It's a third person day!");
	is_tp_day = true
	CPrintToChatAll("{purple}[SD] {green}It's a third person day!  Enabled {yellow}thirdperson{green} on all players.")
	for (int client = 1; client <= MaxClients; client++) {
		if(IsValidClient(client)) {
			ClientCommand(client, "thirdperson");
		}
	}
}

public OnPluginEnd() {
	// Alert Unload Success
	PrintToServer("[URL] Has Unloaded Successfully!");
}