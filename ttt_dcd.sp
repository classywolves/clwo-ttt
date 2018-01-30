#include <sourcemod>
#include <adminmenu>
#include <sdktools>

#define ENTRIES 32

char player_names[ENTRIES][64];
char player_auths[ENTRIES][64];
bool player_isset[ENTRIES];
int  player_times[ENTRIES];
int  current_pos = 0;

public OnPluginStart() {
	HookEvent("player_disconnect", OnPlayerDisconnect);
	RegConsoleCmd("sm_dcd", Command_DCD, "Log last 32 disconnected players");

}

public Action OnPlayerDisconnect(Handle event, char[] name, bool dont_broadcast) {
	char steam_id[64];
	GetEventString(event, "networkid", steam_id, sizeof(steam_id));

	if (!StrContains(steam_id, "STEAM_1:", false)) {
		// LOG LOG LOG
		LogToFile("log_ttt_dcd.txt", "[Curent_Pos %d] [player_names[cp-1] %s]",current_pos, player_names[current_pos - 1]);
		// LOG LOG LOG
		if (!player_isset[0] || 
			(strcmp(steam_id, player_names[current_pos - 1], false) &&
			 GetTime() != player_times[current_pos - 1] )) {

			// It's a real SteamID.
			player_auths[current_pos] = steam_id;
			GetEventString(event, "name", player_names[current_pos], sizeof(player_names[]));
			player_times[current_pos] = GetTime();
			player_isset[current_pos] = true;

			current_pos++;
			if (current_pos >= ENTRIES - 1) current_pos = 0;
		}
	}

	return Plugin_Continue;
}

public Action Command_DCD(int client, int args) {
	for (int i = current_pos - 1; i >= 0; --i) {
		Log_Position(client, i);
	}

	for (int i = ENTRIES - 1; i > current_pos; --i) {
		Log_Position(client, i);
	}

	return Plugin_Handled;
}

public Log_Position(int client, int pos) {
	if (player_isset[pos]) {
		int delta = GetTime() - player_times[pos];
		PrintToConsole(client, "%s [%s] %dm:%ds", player_names[pos], player_auths[pos], delta / 60, delta % 60);
	}
}