#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <colorvariables>
#include <ttt>
#include <cstrike>
#include <general>
#include <logger>

/* Plugin Info */
#define PLUGIN_NAME 			"TTT Bonuses"
#define PLUGIN_VERSION_M 		"0.0.4"
#define PLUGIN_AUTHOR 			"Popey"
#define PLUGIN_DESCRIPTION		"Special days."
#define PLUGIN_URL				"https://sinisterheavens.com"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION_M,
	url = PLUGIN_URL
};

public OnPluginStart() {
	setLogSource("bonuses");

	// Register CVARS
	// rdm_version = CreateConVar("ldb_version", PLUGIN_VERSION_M, "Leaderboard Plugin Version");
	CreateConVar("ttt_bonuses", PLUGIN_VERSION_M, "TTT Plugin Version");
	
	// Register Commands
	RegAdminCmd("sm_force_day", Command_Force_Day, FCVAR_CHEAT, "Force a gravity day");

	// Register Events
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);

	// Alert Load Success
	log(Success, "[URL] Has Loaded Succcessfully!");
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

public OnPluginEnd() {
	// Alert Unload Success
	log(Success, ("[URL] Has Unloaded Successfully!");
}