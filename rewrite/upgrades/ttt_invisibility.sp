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
	if (buttons & IN_ATTACK || buttons & IN_ATTACK2) {
		Player attacker = Player(client);
		if (attacker.BlockShoot) {
			if (!attacker.ErrorTimeout(2)) {
				attacker.Msg("{red}You are not allowed to shoot whilst invulnerable!");
			}
			buttons &= ~IN_ATTACK;
			buttons &= ~IN_ATTACK2;
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

		for (float i = 0.0; i < 2.5 * level; i += 0.1) {
			DataPack pack;
			CreateTimer(i, InvisibilityCountdown, pack);
			pack.WriteCell(player.Client);
			pack.WriteFloat(i / (2.5 * level));
		}
	}
}

public Action InvisibilityCountdown(Handle timer, Handle pack) {
	ResetPack(pack);

	int client = ReadPackCell(pack);
	float percent = ReadPackFloat(pack);

	Player player = Player(client);

	char bar[80], progress[255];
	GetProgressBar(percent, bar);
	Format(progress, sizeof(progress), "Remaining Invisibility: [%s]", bar)

	Handle hHudText = CreateHudSynchronizer();
	SetHudTextParams(0.01, 0.01, 5.0, 255, 128, 0, 255, 0, 0.0, 0.0, 0.0);
	ShowSyncHudText(player.Client, hHudText, progress);
	CloseHandle(hHudText);
}

public void GetProgressBar(float percent, char bar[80]) {
	int bars = 40;
	int squares = RoundFloat(bars * percent);

	for (int i = 0; i < bars; i++) {
		if (i <= squares) {
			StrCat(bar, bars, "▰");
		} else {
			StrCat(bar, bars, "▱");
		}
	}
}

public Action DisableInvisibility(Handle time, any client) {
	Player player = Player(client);

	player.Msg("{yellow}Your invisibility has worn off!");
	player.Invisible = false;
	player.Invulnerable = false;
	player.BlockShoot = false;
}