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
#include <colorlib>
#include <generics>

/*
 * Custom methodmap includes.
 */
#include <player_methodmap>
#include <round_methodmap>


public OnPluginStart()
{
	RegisterCmds();
	HookEvents();
	InitObjects();
	
	PrintToServer("[TSR] Loaded succcessfully");
}

public void InitObjects() {
}

public void RegisterCmds() {
}

public void HookEvents() {
	//HookEvent("weapon_fire", OnWeaponFire, EventHookMode_Pre);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {
	// Our weapon is not a weapon
	if (!IsValidEntity(weapon)) {
		PrintToServer("invalid weapon");
		return Plugin_Continue;
	}

	char name[64];
	GetEntityClassname(weapon, name, sizeof(name))

	// Our weapon is not a taser.
	PrintToServer("weapon %s", weapon);
	if (strcmp(name, "weapon_taser")) {
		return Plugin_Continue;
	}

	// The time is past 30 seconds
	PrintToServer("After time?");
	if (Round.AfterTime(30)) {
		PrintToServer("Yes");
		return Plugin_Continue;
	}

	Player(client).Msg("{red}Tasers are blocked for the first 30 seconds of a round.");
	buttons &= ~IN_ATTACK

	return Plugin_Changed;
}

public Action OnWeaponFire(Event event, const char[] name, bool dontBroadcast) {
	Player player = Player(GetClientOfUserId(event.GetInt("userid")));

	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));

	// Our weapon is not a taser.
	if (strcmp(weapon, "weapon_taser")) {
		return Plugin_Continue;
	}

	// The time is past 30 seconds
	if (Round.AfterTime(30)) {
		return Plugin_Continue;
	}

	player.Msg("{red}Tasers are blocked for the first 30 seconds of a round.");
	CreateTimer(0.5, ReturnTaser, player.Client);

	return Plugin_Handled;
}

public Action ReturnTaser(Handle timer, any client) {
	Player player = Player(client);

	player.Msg("{green}We have replenished your taser.");
	player.Give("weapon_taser");
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	Round.Start();

	return Plugin_Continue;
}