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
#include <botmimic>
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
	
	PrintToServer("[TSR] Loaded succcessfully");
}

public void InitObjects() {
}

public void HookEvents() {
}

public void RegisterCmds() {
	RegConsoleCmd("sm_startrecord", Command_StartRecord, "Start Round.");
	RegConsoleCmd("sm_mimicdeath", Command_Death, "Mimic you dying.");
}

public Action Command_StartRecord(int client, int args) {
	RoundRecord(client);
}

public Action Command_Death(int client, int args) {
	Death(client);
}

public void RoundRecord(int client) {
	Player player = Player(client);

	if (!BotMimic_IsPlayerRecording(player.Client)) {
		BotMimic_StartRecording(player.Client, round, player.AccountID);
	}
}

public void Death(int client) {
	if (BotMimic_IsPlayerRecording(player.Client)) {
		
	}	
}