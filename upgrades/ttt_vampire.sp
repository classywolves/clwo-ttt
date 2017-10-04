#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <ttt>
#include <ttt_helpers>
#include <player_methodmap>

#define upgrade_id 0

// We also need an array to hold players upgrade levels
int upgrade_levels[MAXPLAYERS + 1];

public void OnPluginStart() {
	// For every client we need to grab their current upgrade level.
	// Populate might not have run yet, but that is fine since that means we
	// are not late loading anyway.
	LoopValidClients(client) OnClientPutInServer(client);
}

public void OnMapStart() {
    sprite_beam = PrecacheModel("materials/sprites/laserbeam.vmt");
    sprite_halo = PrecacheModel("materials/sprites/glow.vmt");
}

// When a client is put in the server, we want to automatically grab their
// upgrade level.
public void OnClientPutInServer(int client) {
	update_upgrade_level(client);
	SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
}

// When the player disconnects from the server, we want to reset their upgrade_level
// back to zero.
public void OnClientDisconnect(int client) {
	upgrade_levels[client] = 0;
}

// We also want to update their skill level when it changes via the .populate()
// function on the player methodmap
public void OnUpgradeChanged(int client, int upgrade) {
	if (upgrade == upgrade_id) update_upgrade_level(client);
}

public void update_upgrade_level(int client) {
	Player player = Player(client);
	upgrade_levels[player.id] = player.has_upgrade(upgrade_id);
}

// This function will regenerate a persons health by a percentage of any damage
//  the player does.
public void Hook_OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3]) {
	if(attacker <= 0 || attacker > MaxClients || victim <= 0 || victim > MaxClients) return;

	if (upgrade_levels[attacker] > 0) {
		Player player_attacker = Player(attacker);

		if(!player_attacker.valid_client) return;

		float health_gain = damage * 0.075 * upgrade_levels[player_attacker.id];

		if (player_attacker.health != player_attacker.max_health) {
			int new_health = RoundFloat(player_attacker.health + health_gain);
			if (new_health > player_attacker.max_health) new_health = player_attacker.max_health;
			player_attacker.health = new_health;

			float fAttackerOrigin[3], fVictimOrigin[3];
			GetClientEyePosition(attacker, fAttackerOrigin);
			GetClientEyePosition(victim, fVictimOrigin);
			fAttackerOrigin[2] -= 10.0;
			fVictimOrigin[2] -= 10.0;

			TE_SetupBeamPoints(fAttackerOrigin, fVictimOrigin, sprite_beam, sprite_halo, 0, 66, 0.2, 1.0, 20.0, 1, 0.0, colour_red, 5);
			TE_SendToAll();

			CPrintToChat(player_attacker.id, "Vampirism!  Set health to %d", new_health);
		}
	}
}