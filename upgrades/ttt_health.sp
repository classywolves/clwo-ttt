#include <ttt>
#include <ttt_helpers>
#include <player_methodmap>
#include <maths_methodmap>

#define upgrade_id 1
#define max_upgrade 4

// This is an example plugin layout.  It includes a timer and
// increases health every (10 - 2 * skill_point) seconds.

public void TTT_OnRoundStart(int innocents, int traitors, int detectives) {
	// We loop through each player, assigning them a repeating timer
	// that will regenerate their health.
	LoopAliveClients(client) {
		Player player = Player(client);
		int upgrade_level = Maths().min(player.has_upgrade(upgrade_id), max_upgrade)
		if (upgrade_level) {
			CreateTimer(10.0 - upgrade_level * 2.0, health_regen, client)
		}
	}

	return;
}

// This function will regenerate a persons health by one.
// It is called by the timer defined above.
public Action health_regen(Handle timer, int client) {
	Player player = Player(client);
	if (player.health < 100) {
		player.health++;
	}

	if (player.health > 0 && TTT_IsRoundActive()) {
		int upgrade_level = Maths().min(player.has_upgrade(upgrade_id), max_upgrade);
		CreateTimer(10.0 - upgrade_level * 2.0, health_regen, client);
	}

	return Plugin_Handled;
}