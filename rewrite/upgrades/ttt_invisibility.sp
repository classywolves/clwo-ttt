/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <colorvariables>
#include <helpers>

/*
 * Custom methodmap includes.
 */
#include <player_methodmap>

public OnPluginStart()
{
	RegisterCmds();
	HookEvents();
	InitObjects();
	LateLoadAll();
	
	PrintToServer("[TSR] Loaded succcessfully");
}

public void InitObjects() {
}

public void RegisterCmds() {
	RegAdminCmd("sm_testinvis", Command_TestInvis, ADMFLAG_ROOT, "Test invisibility")
}

public void HookEvents() {
	//HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
}

public void OnClientPutInServer(int client) {
	HookClient(client);
}

public void LateLoadAll() {
	LoopValidClients(client) {
		LateLoadClient(client);
	}
}

public void LateLoadClient(int client) {
	HookClient(client);
}

public void HookClient(int client) {
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public Action OnTraceAttack(int iVictim, int &iAttacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup) {
	if (IsWorldDamage(iAttacker, damagetype)) {
		return Plugin_Continue;
	}

	Player attacker = Player(iAttacker);
	Player victim = Player(iVictim);

	char weapon[64];
	attacker.Weapon(weapon);

	//PrintToServer("%N shot %N with %s", iAttacker, iVictim, weapon);

	if (StrContains(weapon, "taser", false) != -1) {
		//PrintToServer("That string ^ contains the phrase taser.");
		if (!victim.Traitor) { PrintToServer("Someone tased an inno, %N", iVictim); }
		if (victim.Traitor) {
			//PrintToServer("And this person was a traitor");
			ActivateInvisibility(victim.Client);
		}
	}

	return Plugin_Continue;
}

public Action Command_TestInvis(int client, int args) {
	ActivateInvisibility(client);
}

public Action ActivateInvisibility(int client) {
	Player player = Player(client)

	int level = player.Upgrade(Upgrade_Invisibility, 0, 3);

	if (level && player.Traitor) {
		player.Msg("{yellow}Your invisibility has activated!");
		SetEntityRenderMode(player.Client, RENDER_NONE);
		CreateTimer(2.5 * level, DisableInvisibility, player.Client);
	}
}

public Action DisableInvisibility(Handle time, any client) {
	Player player = Player(client);

	player.Msg("{yellow}Your invisibility has worn off!");
	SetEntityRenderMode(player.Client, RENDER_NORMAL);
}