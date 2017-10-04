#include <ttt>
#include <ttt_helpers>
#include <player_methodmap>

#define upgrade_id 1

// This is an example plugin layout.  It includes a timer and
// increases health every (10 - 2 * skill_point) seconds.

// We start by defining an array to hold a timer for each player.
Handle health_timers[MAXPLAYERS + 1];

// We also need an array to hold players upgrade levels
int upgrade_levels[MAXPLAYERS + 1];

public void OnPluginStart() {
	// Hook the on round start event, we need this to start a timer
	// to incremement players health.
	// HookEvent("round_start", OnRoundStart);

	// When a player dies or when the round ends, we want to destroy all
	// connected timers.
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_death", OnPlayerDeath);

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

// Kill single timer.
public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (upgrade_levels[client] && health_timers[client] != INVALID_HANDLE) {
		KillTimer(health_timers[client]);
	}
}

// Kill all alive timers.
public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	LoopClients(client) {
		if (upgrade_levels[client] && health_timers[client] != INVALID_HANDLE) {
			KillTimer(health_timers[client]);
		}
	}
}

public void TTT_OnRoundStart(int innocents, int traitors, int detectives) {
	// We loop through each player, assigning them a repeating timer
	// that will regenerate their health.
	LoopAliveClients(client) {
		if (upgrade_levels[client]) {
			health_timers[client] = CreateTimer(10.0 - upgrade_levels[client] * 2.0, health_regen, client, TIMER_REPEAT);
		}
	}

	return;
}

public void update_upgrade_level(int client) {
	Player player = Player(client);
	upgrade_levels[player.id] = player.has_upgrade(upgrade_id);
}

// This function will regenerate a persons health by one.
// It is called by the timer defined above.
public Action health_regen(Handle timer, int client) {
	Player player = Player(client);
	if (player.health < 100) {
		player.health++;
	}
}