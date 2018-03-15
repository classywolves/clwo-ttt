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
	RegConsoleCmd("sm_testinvis", Command_TestInvis, "Test invisibility");
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
		if (attacker.BlockShoot) {
			if (!attacker.ErrorTimeout(2)) {
				attacker.Msg("{red}You are not allowed to shoot whilst invulnerable!");
			}
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
		if (!attacker.ErrorTimeout(2)) {
			attacker.Msg("{red}This person is invulnerable!");
		}

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
	Player player = Player(client);


	if (!player.Access("senadmin", true)) {
		return Plugin_Handled;
	}

	ActivateInvisibility(player.Client);

	return Plugin_Handled;
}

public Action ActivateInvisibility(int client) {
	Player player = Player(client)

	int level = player.Upgrade(Upgrade_Invisibility, 0, 3);

	if (level && player.Traitor) {
		player.Msg("{yellow}Your invisibility has activated!");
		player.Invisible = true;
		player.Invulnerable = true;
		player.BlockShoot = true;
		CreateTimer(2.5 * level, DisableInvisibility, player.Client);
	}
}

public Action DisableInvisibility(Handle time, any client) {
	Player player = Player(client);

	player.Msg("{yellow}Your invisibility has worn off!");
	player.Invisible = false;
	player.Invulnerable = false;
	player.BlockShoot = false;
}