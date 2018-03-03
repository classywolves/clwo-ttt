#include <sourcemod>

/* Plugin TTT addon */ 
#define PLUGIN_NAME       "TTT Corpen" 
#define PLUGIN_VERSION_M     "0.0.1" 
#define PLUGIN_AUTHOR       "Corpen" 
#define PLUGIN_DESCRIPTION    "Corpen's TTT Area." 
#define PLUGIN_URL        "" 
 
public Plugin myinfo = { 
  name = PLUGIN_NAME, 
  author = PLUGIN_AUTHOR, 
  description = PLUGIN_DESCRIPTION, 
  version = PLUGIN_VERSION_M, 
  url = PLUGIN_URL 
}; 

public void OnPluginStart()
{
	RegAdminCmd("sm_ssay", command_ssay, ADMFLAG_GENERIC);
}

public Action command_ssay(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_csay <player> <message>");
		return Plugin_Handled;
	}
	
	char target_string[128];
	GetCmdArg(1, target_string, sizeof(target_string));
	
	// Ensure target exists 
	int target_client = FindTarget(client, target_string, true, false);
	if (target_client == -1) {
		CPrintToChat(client, "{purple}[SSay] {orchid}Target not found.");
		return Plugin_Handled;
	}
	
	char text[192];
	GetCmdArg(2, text, sizeof(text));
	
	PrintCenterText(target_client, text);
	
	//LogAction(client, -1, "\"%L\" triggered sm_csay (text %s)", client, text);
	
	return Plugin_Handled;	
}
