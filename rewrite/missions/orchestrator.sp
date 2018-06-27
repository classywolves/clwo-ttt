#include <player_methodmap>
#include <mission>

/*
 * List of included missions.  If you are adding it to here, you are likely also
 * going to want to add it to "SelectMission"
 */
#include <killmission>

#define TOTAL_MISSIONS 1

Mission playerMissions[MAXPLAYERS + 1][3];

public void OnPluginStart() {

}

public Mission SelectMission(int client) {
	// I am a terrible person, you cannot seem to put types into an array so hard coding it.
	int chosen = GetRandomInt(0, TOTAL_MISSIONS - 1);

	if (chosen == 0) return KillMission(client);

	// Should never be reached.
	return KillMission(client);
}

public void GeneratePlayerMissions(int client) {
	for (int i = 0; i < 3; i++) {
		playerMissions[client][i] = SelectMission(client);
	}
}

public void OnRoundStart() {
  LoopValidClients(i) {
    Player player = Player(i)

  }

  
}