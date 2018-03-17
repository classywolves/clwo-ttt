#include <sourcemod>
#include <general>
#include <player_methodmap>
#include <ttt>

/* Plugin TTT addon */ 
#define PLUGIN_NAME       			"TTT Corpen" 
#define PLUGIN_VERSION_M     		"0.0.1" 
#define PLUGIN_AUTHOR       		"Corpen" 
#define PLUGIN_DESCRIPTION    		"Corpen's TTT Area." 
#define PLUGIN_URL        			"" 

#define MAX_MESSAGE_LENGTH			192
 
public Plugin myinfo = { 
  name = PLUGIN_NAME, 
  author = PLUGIN_AUTHOR, 
  description = PLUGIN_DESCRIPTION, 
  version = PLUGIN_VERSION_M, 
  url = PLUGIN_URL 
}; 

public void OnPluginStart()
{
	RegAdminCmd("sm_smsay", CommandSMSay, ADMFLAG_GENERIC, "Targeted MSay.");
	RegAdminCmd("sm_scsay", CommandSCSay, ADMFLAG_GENERIC, "Targeted CSay.");
	RegConsoleCmd("sm_alive", command_alive, "Displays the currently alive / undiscovered players.");
}

public Action CommandSMSay(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_smsay <player> <message>");
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
	
	char text[MAX_MESSAGE_LENGTH];
	GetCmdArg(2, text, sizeof(text));
	
	SendPanelTo(client, target_client, text);
	
	return Plugin_Handled;	
}

void SendPanelTo(int client, int target, char[] message)
{
	char title[100];
	Format(title, 64, "%N:", client);
	
	ReplaceString(message, MAX_MESSAGE_LENGTH, "\\n", "\n");
	
	Panel mSayPanel = new Panel();
	mSayPanel.SetTitle(title);
	mSayPanel.DrawItem("", ITEMDRAW_SPACER);
	mSayPanel.DrawText(message);
	mSayPanel.DrawItem("", ITEMDRAW_SPACER);
	mSayPanel.CurrentKey = GetMaxPageItems(mSayPanel.Style);
	mSayPanel.DrawItem("Exit", ITEMDRAW_CONTROL);

	if(IsValidClient(target))
	{
		mSayPanel.Send(target, HandlerDoNothing, 10);
	}

	delete mSayPanel;
}

public int HandlerDoNothing(Menu menu, MenuAction action, int param1, int param2)
{
	/* Do nothing */
}

public Action CommandSCSay(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_scsay <player> <message>");
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
	
	char text[MAX_MESSAGE_LENGTH];
	GetCmdArg(2, text, sizeof(text));
	
	PrintCenterText(target_client, text);
	
	return Plugin_Handled;	
}

public Action command_alive(int client, int args)
{
	int maxMessageLength = 64 * MAXPLAYERS;
	char[] sepperator = ", ";
	char[] message = "Players Alive: ";
	
	bool isFirst = true;
	LoopValidClients(i)
	{
		if (TTT_GetFoundStatus(i) == false)
		{
			char userName[64];
			Player(i).Name(userName);
			StrCat(message, maxMessageLength, userName);
			
			if (isFirst == false)
			{
				StrCat(message, maxMessageLength, sepperator);
			}
			else
			{
				isFirst = false;
			}
		}
	}
	
	CPrintToChat(client, message);
}
