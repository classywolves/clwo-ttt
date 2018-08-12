/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <ttt>
#include <colorvariables>
#include <generics>

/*
 * Custom methodmaps.
 */
#include <player_methodmap>

/*
 * Custom Defines.
 */

public Plugin myinfo =
{ 
	name = "TTT Helper", 
	author = "Corpen", 
	description = "Corpen's TTT Helper", 
	version = "0.0.1", 
	url = "" 
};

public OnPluginStart()
{
	RegisterCmds();
	HookEvents();
	InitDBs();

	LoadTranslations("common.phrases");
	
	PrintToServer("[HLP] Loaded succcessfully");
}

public void RegisterCmds() {
	RegConsoleCmd("sm_hmsg", Command_HMsg, "/msg Helper.");
	RegConsoleCmd("sm_hr", Command_HR, "/r Helper.");
}

public void HookEvents()
{
	
}

public void InitDBs()
{
	
}

public Action Command_HMsg(int client, int args)
{
	Player player = Player(client);
	
	/*
	if (args > 1)
	{
		if (player.Access(RANK_INFORMER, true))
		{
			player.Error("Invalid Usage: /hmsg <player>");
		}
		else
		{
			player.Error("Invalid Usage: /hmsg");
		}
		return Plugin_Handled;
	}
	*/

	Player target;
	
	if (args == 1)
	{
		if (!player.Access(RANK_INFORMER, true))
		{
			player.Error("You do not have access to target players with this command!");
			return Plugin_Handled;
		}
	
		char targetString[128];

		GetCmdArg(1, targetString, sizeof(targetString));
		target = player.TargetOne(targetString, true)

		if (target.Client == -1) {
			return Plugin_Handled;
		}
	}
	else
	{
		target = player;
	}
	
	CPrintToChat(target.Client, "{purple}[MSG] {yellow}To send a private message to another player.");
	CPrintToChat(target.Client, "{purple}[MSG] {yellow}/msg <Player> <Message>");
	CPrintToChat(target.Client, "{purple}[MSG] {yellow}Player: The name of the player you would like to target.");
	CPrintToChat(target.Client, "{purple}[MSG] {yellow}Message: The message to send this will be all the of the text after the Player.");
	
	return Plugin_Handled;	
}

public Action Command_HR(int client, int args)
{
	Player player = Player(client);
	
	/*
	if (args > 1)
	{
		if (player.Access(RANK_INFORMER, true))
		{
			player.Error("Invalid Usage: /hr <player>");
		}
		else
		{
			player.Error("Invalid Usage: /hr");
		}
		return Plugin_Handled;
	}
	*/

	Player target;
	
	if (args == 1)
	{
		if (!player.Access(RANK_INFORMER, true))
		{
			player.Error("You do not have access to target players with this command!");
			return Plugin_Handled;
		}
	
		char targetString[128];

		GetCmdArg(1, targetString, sizeof(targetString));
		target = player.TargetOne(targetString, true)

		if (target.Client == -1) {
			return Plugin_Handled;
		}
	}
	else
	{
		target = player;
	}
	
	CPrintToChat(target.Client, "{purple}[MSG] {yellow}To reply to the last person who sent you a private message.");
	CPrintToChat(target.Client, "{purple}[MSG] {yellow}/r <Message>");
	CPrintToChat(target.Client, "{purple}[MSG] {yellow}Message: The message to send this will be all the of the text entered.");

	return Plugin_Handled;	
}
