#include <player_methodmap>
#include <general>

char maps[][] = {
	"ttt_skate_v2",
	"ttt_desperados_sg_v1"
}

public void OnPluginStart() {
	// Start a timer to run every 3 minutes.
	CreateTimer(180.0, Timer_Check_Map, _, TIMER_REPEAT);
	RegAdminCmd("sm_force_rtv", command_force_rtv, ADMFLAG_GENERIC);
}

public Action Timer_Check_Map(Handle timer) {
	if (Is_Overloaded()) {
		CPrintToStaff("{purple}[TTT] {orchid}Warning, player count exceeds recommendation for this map.  Considering forcing the RTV with /force_rtv")
	}
}

public bool Is_Overloaded() {
	char map_name[255];
	GetCurrentMap(map_name, sizeof(map_name))

	for (int i = 0; i < sizeof(maps); i++) {
		if (StrEqual(maps[i], map_name)) {
			if (GetClientCount() > 16) {
				return true;
			}
		}
	}

	return false;
}

public Action command_force_rtv(int client, int args) {
	if (!Is_Overloaded()) {
		CPrintToChat(client, "{purple}[TTT] {orchid}This map is not overloaded, you are not permitted to force an RTV.");
		return Plugin_Handled;
	}

	CPrintToChatAll("{purple}[TTT] {yellow}This map has been RTV'd by %N!", client);
	ServerCommand("mce_forcertv");
	
	return Plugin_Handled;
}