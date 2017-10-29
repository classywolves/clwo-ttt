#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <ttt>
#include <ttt_helpers>
#include <player_methodmap>

#define upgrade_id 2

// We also need an array to hold players upgrade levels
int upgrade_levels[MAXPLAYERS + 1];

public void OnPluginStart() {
	// For every client we need to grab their current upgrade level.
	// Populate might not have run yet, but that is fine since that means we
	// are not late loading anyway.
	LoopValidClients(client) OnClientPutInServer(client);
}

// When a client is put in the server, we want to automatically grab their
// upgrade level.
public void OnClientPutInServer(int client) {
	update_upgrade_level(client);
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

public void TTT_OnRoundStart(int innocents, int traitors, int detectives) {
	LoopAliveClients(client) {
		Player player = Player(client);
		if (player.role == DETECTIVE && upgrade_levels[client]) {
			if (player.has_weapon("weapon_taser")) {
				
			}
		}
	}

	return;
}