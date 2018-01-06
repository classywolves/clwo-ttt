#include <basecomm>
#include <general>
#include <player_methodmap>

public void OnPluginStart() {
	RegAdminCmd("sm_nuke", command_nuke, ADMFLAG_GENERIC);
}

public Action command_nuke(int client, int args) {
	char string_time[128];
	GetCmdArg(1, string_time, sizeof(string_time));
	int time = StringToInt(string_time)

	if (time < 2 || time > 30) {
		time = 10;
	}

	LoopValidClients(i) {
		if (!Player(i).staff) {
			BaseComm_SetClientMute(i, true);
		}
	}

	CPrintToChatAll("{purple}[TTT] {green}You have been muted by {blue}%N {green} for {blue}%d{green} seconds.", client, time);

	CreateTimer(float(time), timer_unnuke);
}

public Action timer_unnuke(Handle timer) {
	LoopValidClients(i) {
		BaseComm_SetClientMute(i, false);
	}

	CPrintToChatAll("{purple}[TTT] {green}Your mute has expired.");
}