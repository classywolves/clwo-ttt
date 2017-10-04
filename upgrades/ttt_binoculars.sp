#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <ttt>
#include <ttt_helpers>
#include <player_methodmap>

#define upgrade_id 4

int initial_fov[MAXPLAYERS + 1];
int zoom_level[MAXPLAYERS + 1];

public void OnPluginStart() {
	RegConsoleCmd("sm_binoculars", command_binoculars);

	HookEvent("weapon_zoom", on_weapon_zoom);
	HookEvent("player_spawn", on_player_spawn);
}

public Action command_binoculars(int client, int args) {
	Player player = Player(client);
	if (player.has_upgrade(upgrade_id) < 1) {
		CPrintToChat(client, "{purple}[TTT] {orchid}You do not have a skill point in this skill.");
		return Plugin_Handled;
	}

	if (!player.alive) {
		CPrintToChat(client, "{purple}[TTT] {orchid}You must be alive to use this skill.");
		return Plugin_Handled;
	}

	zoom_level[client]++;
	if (zoom_level[client] > 2) zoom_level[client] = 0;

	SetEntProp(client, Prop_Send, "m_iFOV", initial_fov[client] + (15.0 * zoom_level[client]));

	return Plugin_Handled;
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