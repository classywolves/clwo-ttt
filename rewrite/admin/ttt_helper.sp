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

	if (!Player(client).Access("informer", true)) {
		return Plugin_Handled;
	}
	
	if (args < 1) {
		player.Error("Invalid Usage: /hmsg <player>");
		return Plugin_Handled;
	}

	char targetString[128];

	GetCmdArg(1, targetString, sizeof(targetString));
	Player target = player.TargetOne(targetString, true)

	if (target.Client == -1) {
		return Plugin_Handled;
	}
	
	CPrintToChat(client, "{purple}[MSG] {yellow}To send a private message to another player.");
	CPrintToChat(client, "{purple}[MSG] {yellow}/msg <Player> <Message>");
	CPrintToChat(client, "{purple}[MSG] {yellow}Player: The name of the player you would like to target.");
	CPrintToChat(client, "{purple}[MSG] {yellow}Message: The message to send this will be all the of the text after the Player.");
	
	return Plugin_Handled;	
}

public Action Command_HR(int client, int args)
{
	Player player = Player(client);

	if (!Player(client).Access("informer", true)) {
		return Plugin_Handled;
	}
	
	if (args < 1) {
		player.Error("Invalid Usage: /hr <player>");
		return Plugin_Handled;
	}

	char targetString[128];

	GetCmdArg(1, targetString, sizeof(targetString));
	Player target = player.TargetOne(targetString, true)

	if (target.Client == -1) {
		return Plugin_Handled;
	}
	
	CPrintToChat(client, "{purple}[MSG] {yellow}To reply to the last person who sent you a private message.");
	CPrintToChat(client, "{purple}[MSG] {yellow}/r <Message>");
	CPrintToChat(client, "{purple}[MSG] {yellow}Message: The message to send this will be all the of the text entered.");

	return Plugin_Handled;	
}
