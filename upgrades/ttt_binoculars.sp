#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <ttt>
#include <ttt_helpers>
#include <player_methodmap>
#include <emitsoundany>

#define upgrade_id 8

int initial_fov[MAXPLAYERS + 1];
int last_time[MAXPLAYERS + 1] = {0, ...};
int zoom_level[MAXPLAYERS + 1] = {0, ...};

public void OnPluginStart() {
	RegConsoleCmd("sm_binoculars", command_binoculars);

	HookEvent("weapon_zoom", on_weapon_zoom);
	HookEvent("player_spawn", on_player_spawn);

	// Prepare the sound file for use.
	AddFileToDownloadsTable("sound/ttt_clwo/ttt_binoculars_activate.mp3");
	AddFileToDownloadsTable("sound/ttt_clwo/ttt_binoculars_deactivate.mp3");
	AddFileToDownloadsTable("sound/ttt_clwo/ttt_binoculars_switch.mp3");
}

public void OnConfigsExecuted()
{
}

public Action command_binoculars(int client, int args) {
	Player player = Player(client);
	if (player.has_upgrade(upgrade_id) <= 3) {
		CPrintToChat(client, "{purple}[TTT] {orchid}You do not have five skill points in this skill.");
		return Plugin_Handled;
	}

	if (!player.alive) {
		CPrintToChat(client, "{purple}[TTT] {orchid}You must be alive to use this skill.");
		return Plugin_Handled;
	}

	zoom_level[client]++;

	if (zoom_level[client] == 1) {
		SetEntProp(client, Prop_Send, "m_iFOV", 40);
		// Play Activation Sound
		ClientCommand(client, "play */ttt_clwo/ttt_binoculars_activate.mp3");
	}
	if (zoom_level[client] == 2) {
		SetEntProp(client, Prop_Send, "m_iFOV", 10);
		// Play Switch Sound
		ClientCommand(client, "play */ttt_clwo/ttt_binoculars_switch.mp3");
	}
	if (zoom_level[client] == 3) {
		SetEntProp(client, Prop_Send, "m_iFOV", 0);
		zoom_level[client] = 0;
		// Play Deactivation Sound
		ClientCommand(client, "play */ttt_clwo/ttt_binoculars_deactivate.mp3");
	}

	return Plugin_Handled;
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
	if (buttons & IN_ATTACK && zoom_level[client] > 0) {
		buttons &= ~IN_ATTACK;
		if (last_time[client] < GetTime() - 1) {
			last_time[client] = GetTime()
			CPrintToChat(client, "{purple}[TTT] {red}You cannot shoot whilst using binoculars!");

		}
	}

	return Plugin_Continue;
}

public Action on_player_spawn(Handle event, const char[] name, bool dont_broadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	initial_fov[client] = GetEntProp(client, Prop_Send, "m_iFOV");
	zoom_level[client] = 0;
}

public Action on_weapon_zoom(Handle event, const char[] name, bool dont_broadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	zoom_level[client] = 0;	
}