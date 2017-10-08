#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <ttt>
#include <ttt_helpers>
#include <player_methodmap>
#include <maths_methodmap>

#define upgrade_id 18
#define max_level 4

public void OnMapStart() {
    sprite_beam = PrecacheModel("materials/sprites/laserbeam.vmt");
    sprite_halo = PrecacheModel("materials/sprites/glow.vmt");
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
}

// This function will regenerate a persons health by a percentage of any damage
//  the player does.
public void Hook_OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3]) {
	if(attacker <= 0 || attacker > MaxClients || victim <= 0 || victim > MaxClients) return;

	Player player_attacker = Player(attacker);
	if (player_attacker.has_upgrade(upgrade_id) > 0) {
		int upgrade_level = Maths().min(player_attacker.has_upgrade(upgrade_id), max_level);

		if(!player_attacker.valid_client) return;

		float health_gain = damage * 0.075 * upgrade_level;

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