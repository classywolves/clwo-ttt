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
#include <ttt>
#include <colorvariables>
#include <generics>

/*
 * Custom methodmap includes.
 */
#include <player_methodmap>

public Plugin myinfo =
{ 
	name = "TTT Flash", 
	author = "Corpen", 
	description = "TTT Flash on Taze", 
	version = "0.0.1", 
	url = "" 
};

public OnPluginStart()
{
	RegisterCmds();
	HookEvents();
	InitObjects();
	LateLoadAll();
	
	PrintToServer("[FLH] Loaded succcessfully");
}

public void InitObjects() {
}

public void HookEvents() {
}

public void RegisterCmds() {
	
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
	if (IsWorldDamage(iAttacker, damagetype))
	{
		return Plugin_Continue;
	}

	Player attacker = Player(iAttacker);
	Player victim = Player(iVictim);

	if (!victim.Traitor || attacker.Traitor)
	{
		return Plugin_Continue;
	}
	
	char weapon[64];
	attacker.Weapon(weapon);

	
	if (victim.Upgrade(Upgrade_Flash, 0, 1))
	{
		if (StrContains(weapon, "taser", false) != -1)
		{
			int color[4] = {255, 255, 255, 255};
			int duration = 480;
			int holdTime = 480;
			int flags = 0x0001;
			
			attacker.SetScreenColor(color, duration, holdTime, flags);
		}
	}

	return Plugin_Continue;
}