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
 * Custom methodmap includes.
 */
#include <player_methodmap>

public Plugin myinfo =
{ 
	name = "TTT NightVision", 
	author = "Corpen", 
	description = "TTT Night Vision Skill", 
	version = "0.0.1", 
	url = "" 
};

public OnPluginStart()
{
	RegisterCmds();
	
	PrintToServer("[NVS] Loaded succcessfully");
}

public void RegisterCmds()
{
	RegConsoleCmd("sm_nv", Command_NightVision, "Toggles Night Vision for the player.");
}

/*
public void TTT_OnRoundStart(int innocents, int traitors, int detective)
{
	int iFlags = GetCommandFlags("give");
	SetCommandFlags("give", iFlags &~ FCVAR_CHEAT);

	LoopAliveClients(i)
	{
		if (Player(i).Upgrade(Upgrade_Night_Vision, 0, 1))
		{
			ClientCommand(i, "give item_nvgs");
		}
	}
	
	SetCommandFlags(give);
}
*/

public Action Command_NightVision(int client, int args)
{
	Player player = Player(client);
	if (player.Upgrade(Upgrade_Night_Vision, 0, 1))
	{
		if (player.NightVision) 
		{ 
			player.NightVision = false;
			player.Msg("{yellow}NV is deactivated.");
		}
		else 
		{ 
			player.NightVision = true;
			player.Msg("{yellow}NV is activated.");
		} 
	}
}