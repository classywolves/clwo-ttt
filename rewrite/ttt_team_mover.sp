/*
 * Base CS:GO plugin requirements.
 */
#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

/*
 * Custom include files.
 */
#include <colorvariables>
#include <generics>

/*
 * Custom methodmap includes.
 */
#include <player_methodmap>

public OnPluginStart()
{
	RegisterCmds();
	HookEvents();
	InitObjects();
	
	PrintToServer("[TMO] Loaded succcessfully");
}

public void InitObjects() {
}

public void HookEvents() {
}

public void RegisterCmds() {
}

TTT_OnBodyFound(int client, int victim, const char[] deadPlayer) {
	Player player = Player(victim);

	player.Team = CS_TEAM_CT;
}