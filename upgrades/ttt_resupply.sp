#include <ttt>
#include <ttt_helpers>
#include <player_methodmap>
#include <maths_methodmap>

#define upgrade_id 9
#define max_upgrade 4

// We start by defining an array to hold a timer for each player.
Handle ammo_timers[MAXPLAYERS + 1];

public void OnPluginStart() {
	// When a player dies or when the round ends, we want to destroy all
	// connected timers.
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_death", OnPlayerDeath);
}

// Kill single timer.
public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (ammo_timers[client] != INVALID_HANDLE) {
		KillTimer(ammo_timers[client]);
	}
}

// Kill all alive timers.
public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	LoopClients(client) {
		if (ammo_timers[client] != INVALID_HANDLE) {
			KillTimer(ammo_timers[client]);
		}
	}
}

public void TTT_OnRoundStart(int innocents, int traitors, int detectives) {
	// We loop through each player, assigning them a repeating timer
	// that will regenerate their health.
	LoopAliveClients(client) {
		Player player = Player(client);
		int upgrade_level = Maths().min(player.has_upgrade(upgrade_id), max_upgrade)
		if (upgrade_level) {
			if (ammo_timers[client] != INVALID_HANDLE) { KillTimer(ammo_timers[client]); }
			ammo_timers[client] = CreateTimer(3.0, ammo_regen, client, TIMER_REPEAT);
		}
	}

	return;
}

// This function will regenerate a persons health by one.
// It is called by the timer defined above.
public Action ammo_regen(Handle timer, int client) {
	Player player = Player(client);
	// +1 ammo for all weapons a client has.
}