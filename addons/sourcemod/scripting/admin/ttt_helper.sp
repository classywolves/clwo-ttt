#pragma semicolon 1

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
#include <colorlib>
#include <generics>
#include <ttt_messages>
#include <ttt_targeting>


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

	LoadTranslations("common.phrases");

	PrintToServer("[HLP] Loaded succcessfully");
}

public void RegisterCmds()
{
	RegConsoleCmd("sm_hmsg", Command_HMsg, "sm_hmsg <#userid|name> - Shows a help message for sm_msg to a player");
	RegConsoleCmd("sm_hr", Command_HR, "sm_hr <#userid|name> - Shows a help message for sm_r to a player");
}

public Action Command_HMsg(int client, int args)
{
	int target;
	if (args > 1)
	{
		if (!(GetUserFlagBits(client) & ADMFLAG_GENERIC == ADMFLAG_GENERIC))
		{
			CPrintToChat(client, TTT_ERROR ... "You do not have access to target players with this command!");
			return Plugin_Handled;
		}

		char targetString[128];

		GetCmdArg(1, targetString, sizeof(targetString));
		target = TTT_Target(targetString, client);

		if (target == -1)
		{
			return Plugin_Handled;
		}
	}
	else
	{
		target = client;
	}

	CPrintToChat(target, TTT_MESSAGE ... "To send a private message to another player.");
	CPrintToChat(target, TTT_MESSAGE ... "/msg <#userid|name> <message>");
	CPrintToChat(target, TTT_MESSAGE ... "#userid|name: The user ID after a # found in status or the name of the player you would like to message.");
	CPrintToChat(target, TTT_MESSAGE ... "Message: The message to send, this will be all the of the text after the the user ID or name.");

	return Plugin_Handled;
}

public Action Command_HR(int client, int args)
{
	int target;
	if (args > 1)
	{
		if (!(GetUserFlagBits(client) & ADMFLAG_GENERIC == ADMFLAG_GENERIC))
		{
			CPrintToChat(client, TTT_ERROR ... "You do not have access to target players with this command!");
			return Plugin_Handled;
		}

		char targetString[128];

		GetCmdArg(1, targetString, sizeof(targetString));
		target = TTT_Target(targetString, client, true, true, false);

		if (target == -1)
		{
			return Plugin_Handled;
		}
	}
	else
	{
		target = client;
	}

	CPrintToChat(target, TTT_MESSAGE ... "To reply to the last person who sent you a private message.");
	CPrintToChat(target, TTT_MESSAGE ... "/r <message>");
	CPrintToChat(target, TTT_MESSAGE ... "Message: The message to send this will be all the of the text entered.");

	return Plugin_Handled;
}
