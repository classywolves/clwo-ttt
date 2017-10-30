/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <colorvariables>
#include <helpers>

public OnPluginStart()
{
	RegisterCmds();
	HookEvents();
	
	PrintToServer("[GEN] Loaded succcessfully");
}

public void RegisterCmds() {
	RegConsoleCmd("sm_staff2", Command_Staff, "List online staff members");
}

public void HookEvents() {
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	return Plugin_Continue;
}

public Action Command_Staff(int client, int args) {
	int staff[32];
	int staff_count = GetStaffArray(staff);

	if (!staff_count) {
		CPrintToChat(client, "{purple}[TTT] {orchid}There are currently no staff online.");
		return Plugin_Handled;
	}

	CPrintToChat(client, "{purple}[TTT] {yellow}There are currently {green}%d {yellow}staff online:");

	for (int i = 0; i < StaffCount; i++) {
		char RankName = 
		Player player = Player(i)
		CPrintToChat(client, "{purple}[TTT] {blue}%N is a {green}%s", )
	}
}