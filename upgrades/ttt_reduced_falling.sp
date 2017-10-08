#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <ttt>
#include <ttt_helpers>
#include <player_methodmap>
#include <maths_methodmap>

#define upgrade_id 6
#define max_level 4

public void OnPluginStart() {
	LoopValidClients(client) {
		OnClientPutInServer(client);
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, const float damageForce[3], const float damagePosition[3], int damagecustom) {
	// We only care for fall damage here.
	if (!(damagetype & DMG_FALL)) {
		return Plugin_Continue;
	}

	Player player = Player(victim)
	int upgrade_level = Maths().min(player.has_upgrade(upgrade_id), max_level);

	if (upgrade_level <= 0) {
		return Plugin_Continue;
	}

	float reduce_percent = 0.2 * float(upgrade_level);

	if (reduce_percent >= 1.0) {
		return Plugin_Handled;
	}

	float old_damage = damage;
	damage -= damage * reduce_percent;

	CPrintToChat(player.id, "{purple}[TTT] {yellow}Feather falling reduced your damage from %.0f to %.0f.", old_damage, damage);
	return Plugin_Changed;
}