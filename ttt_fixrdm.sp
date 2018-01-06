#include <sourcemod>
#include <sdktools>
#include <colorvariables>
#include <ttt>
#include <cstrike>
#include <general>

public OnPluginStart() {
	// Register Commands
	RegAdminCmd("sm_fixrdm", Command_Fix_RDM, ADMFLAG_CONFIG, "Reload /rdm");
	RegAdminCmd("sm_fixskills", Command_Fix_Skills, ADMFLAG_CONFIG, "Reload /skills");
}

public Action Command_Fix_RDM(int client, int args) {
	PrintMsg(client);
	char msg[256];
	Format(msg, sizeof(msg), "{purple}[TTT] {red}%N has restarted the RDM plugin.", client);
	CPrintToStaff(msg);
	ServerCommand("sm plugins reload ttt_rdm; sm plugins load ttt_rdm;");
	return Plugin_Handled;
}

public Action Command_Fix_Skills(int client, int args) {
	PrintMsg(client);
	char msg[256];
	Format(msg, sizeof(msg), "{purple}[TTT] {red}%N has restarted the Skills plugin.", client);
	CPrintToStaff(msg);
	ServerCommand("sm plugins reload ttt_upgrades; sm plugins load ttt_upgrades;");
	return Plugin_Handled;
}

public PrintMsg(int client) {
	CPrintToChat(client, "{purple}[TTT] {yellow}Saving Client_Prefs...");
	CPrintToChat(client, "{purple}[TTT] {yellow}Persisting Settings & CVARs...");
	CPrintToChat(client, "{purple}[TTT] {yellow}Unloading DB...");
	CPrintToChat(client, "{purple}[TTT] {green}DB Unloaded.");
	CPrintToChat(client, "{purple}[TTT] {red}Plugin Unloaded (Error: \"\").");
	CPrintToChat(client, "{purple}[TTT] {green}Plugin Loaded (Error: \"\").");
	CPrintToChat(client, "{purple}[TTT] {green}DB Connected (Error: \"\").");
	CPrintToChat(client, "{purple}[TTT] {green}Client Prefs Finished Caching.");
}