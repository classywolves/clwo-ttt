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
	LateLoadAll();
	
	PrintToServer("[TSR] Loaded succcessfully");
}

public void InitObjects() {
}

public void HookEvents() {
}

public void RegisterCmds() {
	RegAdminCmd("sm_testinvis", Command_TestInvis, ADMFLAG_ROOT, "Test invisibility")
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

// Block players from shooting if they're not allowed to shoot.
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {
	if (buttons & IN_ATTACK) {
		Player attacker = Player(client);
		if (!attacker.CanShoot) {
			buttons &= ~IN_ATTACK;
		}
	}

	return Plugin_Continue;
}

public Action OnTraceAttack(int iVictim, int &iAttacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup) {
	if (IsWorldDamage(iAttacker, damagetype)) {
		return Plugin_Continue;
	}

	Player attacker = Player(iAttacker);
	Player victim = Player(iVictim);

	if (victim.Invulnerable) {
		// This player cannot take damage.
		damage = 0.0;
		return Plugin_Changed;
	}

	char weapon[64];
	attacker.Weapon(weapon);

	if (StrContains(weapon, "taser", false) != -1) {
		if (victim.Traitor) {
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
		player.Invisible = true;
		player.Invulnerable = true;
		player.CanShoot = false;
		CreateTimer(2.5 * level, DisableInvisibility, player.Client);
	}
}

public Action DisableInvisibility(Handle time, any client) {
	Player player = Player(client);

	player.Msg("{yellow}Your invisibility has worn off!");
	player.Invisible = false;
	player.Invulnerable = false;
	player.CanShoot = true;
}