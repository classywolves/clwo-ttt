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
#include <colorvariables>
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

public void RegisterCmds() {
	RegConsoleCmd("sm_hmsg", Command_HMsg, "/msg Helper.");
	RegConsoleCmd("sm_hr", Command_HR, "/r Helper.");
}

public Action Command_HMsg(int client, int args)
{
	int target;
	if (args > 1)
	{
		if (!(GetUserFlagBits(client) & ADMFLAG_GENERIC == ADMFLAG_GENERIC))
		{
			TTT_Error(client, "You do not have access to target players with this command!");
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

	TTT_Message(target, "To send a private message to another player.");
	TTT_Message(target, "/msg <#userid|name> <message>");
	TTT_Message(target, "#userid|name: The user ID after a # found in status or the name of the player you would like to message.");
	TTT_Message(target, "Message: The message to send, this will be all the of the text after the the user ID or name.");

	return Plugin_Handled;
}

public Action Command_HR(int client, int args)
{
	int target;
	if (args > 1)
	{
		if (!(GetUserFlagBits(client) & ADMFLAG_GENERIC == ADMFLAG_GENERIC))
		{
			TTT_Error(client, "You do not have access to target players with this command!");
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

	TTT_Message(target, "To reply to the last person who sent you a private message.");
	TTT_Message(target, "/r <message>");
	TTT_Message(target, "Message: The message to send this will be all the of the text entered.");

	return Plugin_Handled;
}
