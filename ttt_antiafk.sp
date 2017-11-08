#define MAX_BUTTONS 25

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <ttt>
#include <colorvariables>

int button_held[MAXPLAYERS + 1];
int held_count[MAXPLAYERS + 1];

public void OnClientDisconnect(int client) {
	button_held[client] = 0;
	held_count[client] = 0;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {
	for (int i = 0; i < MAX_BUTTONS; i++) {
		int button = (1 << i);
		if ((buttons & button) && (button & IN_RIGHT || button & IN_LEFT)) {
			// Activating +right or +left
			held_count[client] += 1;
			if (held_count[client] % 50 == 0) {
				CPrintToChat(client, "{purple}[TTT] {orchid}Please do not use +left or +right.")
			}
			if (held_count[client] % 500 == 0) {
				ForcePlayerSuicide(client);
				TTT_SetFoundStatus(client, true);
			}
		} else if ((button_held[client] & button)) {
			// Released +right or +left
			held_count[client] = 0;
		}
	}

	button_held[client] = buttons;
	buttons &= ~IN_LEFT
	buttons &= ~IN_RIGHT

	return Plugin_Changed;
}