#include <player_methodmap>

methodmap Mission {
	public Mission(int client) {
		return view_as<Mission>(client);
	}

	public void Name(char name[64]) {
		StrCat(name, sizeof(name), "Example Mission");
	}

	public void Description(char description[512]) {
		StrCat(description, sizeof(description), "An Example Mission Description");
	}


}

methodmap KillMission < Mission {
	public KillMission(int client) {
		return view_as<KillMission>(client);
	}
}

Mission mission;

public void OnPluginStart() {
	mission = KillMission(2);

	char name[64], description[512];

	mission.Name(name);
	mission.Description(description);

	PrintToServer(name);
}

methodmap Mission {
	public Mission(int client) {
		return view_as<Mission>(client);
	}

	public void Name(char name[64]) {
		StrCat(name, sizeof(name), "Example Mission");
	}

	public void Description(char description[512]) {
		StrCat(description, sizeof(description), "An Example Mission Description");
	}

	// Called when the mission is successful, gives rewards.
	public void Success() {
		Player player = Player(that)

	}
}

methodmap KillMission < Mission {
	public KillMission(int client) {
		return view_as<KillMission>(client);
	}
}

Mission mission;

public void OnPluginStart() {
	mission = KillMission(2);

	char name[64], description[512];

	mission.Name(name);
	mission.Description(description);

	PrintToServer(name);
}