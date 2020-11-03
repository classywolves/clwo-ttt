#if defined _mission_included
	#endinput
#endif
#define _mission_included

/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <generics>

/*
 * Custom methodmaps.
 */
#include <player_methodmap>

#define that view_as<int>(this)

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
		Player player = Player(that);
		player.Msg("You completed this mission!");
		// player.experience += 50;
	}

	// Check whether this client has completed this mission
	public bool Check() {
		return true;
	}

	// Get the progress of this mission as a percentage.
	public float Progress() {
		return 0.54534;
	}
}