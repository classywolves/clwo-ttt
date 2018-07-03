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
#include <datapack>

/*
 * Custom methodmaps.
 */
#include <player_methodmap>

/*
 * Custom Defines.
 */


public Plugin myinfo =
{ 
	name = "TTT Corpen", 
	author = "Corpen", 
	description = "Corpen's TTT Area", 
	version = "0.0.1", 
	url = "" 
};

public OnPluginStart()
{
	RegisterCmds();
	//HookEvents();
	//InitDBs();

	LoadTranslations("common.phrases");
	
	PrintToServer("[CRP] Loaded succcessfully");
}

public void RegisterCmds() {
	RegConsoleCmd("sm_smsay", Command_SMSay, "Targeted MSay.");
	RegConsoleCmd("sm_scsay", Command_SCSay, "Targeted CSay.");
	//RegConsoleCmd("sm_alive", Command_Alive, "Displays the currently alive / undiscovered players.");
}

/*
public void HookEvents()
{
	
}
*/

/*
public void InitDBs()
{
	
}
*/

public Action Command_SMSay(int client, int args)
{
	Player player = Player(client);

	if (!Player(client).Access("informer", true)) {
		return Plugin_Handled;
	}

	if (args < 2) {
		player.Error("Invalid Usage: /smsay <player> <message>")
		return Plugin_Handled;
	}

	char message[255], arg1[128], buffer[128], title[128];

	GetCmdArg(1, arg1, sizeof(arg1));
	Player target = player.TargetOne(arg1, true)

	if (target.Client == -1) {
		return Plugin_Handled;
	}

	if (args >= 2) {
		// They've included a message!
		GetCmdArg(2, message, sizeof(message));

		for (int i = 3; i <= args; i++) {
			GetCmdArg(i, buffer, sizeof(buffer));
			Format(message, sizeof(message), "%s %s", message, buffer);
		}
	}

	Format(title, sizeof(title), "%N: ", player.Client);
	target.SendPanelMsg(title, message);
	
	return Plugin_Handled;	
}

public Action Command_SCSay(int client, int args)
{
	Player player = Player(client);

	if (!Player(client).Access("informer", true)) {
		return Plugin_Handled;
	}

	if (args < 2) {
		player.Error("Invalid Usage: /scsay <player> <message>")
		return Plugin_Handled;
	}

	char message[255], arg1[128], buffer[128];

	GetCmdArg(1, arg1, sizeof(arg1));
	Player target = player.TargetOne(arg1, true)

	if (target.Client == -1) {
		return Plugin_Handled;
	}

	if (args >= 2) {
		// They've included a message!
		GetCmdArg(2, message, sizeof(message));

		for (int i = 3; i <= args; i++) {
			GetCmdArg(i, buffer, sizeof(buffer));
			Format(message, sizeof(message), "%s %s", message, buffer);
		}
	}

	target.CSay(message);	
	return Plugin_Handled;	
}

public Action Command_Alive(int client, int args) {
	Player player = Player(client);

	char playerNames[MAXPLAYERS][64];
	int unfound = GetUnfoundPlayers(playerNames);

	char message[1024];

	Format(message, sizeof(message), "Players Alive: %s", playerNames[0]);

	for(int i = 1; i < unfound; i++) {
		Format(message, sizeof(message), "%s, %s", message, playerNames[i]);
	}

	player.Msg(message);
}