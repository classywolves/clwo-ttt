#if defined _kill_mission_included
  #endinput
#endif
#define _kill_mission_included

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
#include <mission>

/*
 * Custom methodmaps.
 */
#include <player_methodmap>

#define that view_as<int>(this)

methodmap KillMission < Mission {
  public KillMission(int client) {
    return view_as<KillMission>(client);
  }

  public void Name(char name[64]) {
    StrCat(name, sizeof(name), "Murderer");
  }

  public void Description(char description[512]) {
    StrCat(description, sizeof(description), "Kill 20 innocents as a traitor");
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