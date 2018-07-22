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

ConVar matFullbright;

char soundTurnOn[PLATFORM_MAX_PATH] = "ttt_clwo/nightvision/nvon.mp3";

public OnPluginStart()
{
	PreCache();

	GetConVars();
	
	RegisterCmds();
	
	PrintToServer("[NVS] Loaded succcessfully");
}

public void PreCache()
{
	PrecacheSound(soundTurnOn, true);
	
	char buffer[PLATFORM_MAX_PATH];
	Format(buffer, sizeof(buffer),"sound/%s", soundTurnOn);
	AddFileToDownloadsTable(buffer); 
}

public void GetConVars()
{
	matFullbright = FindConVar("mat_fullbright");
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
		int iFlags = matFullbright.Flags;
		matFullbright.Flags = iFlags &~ FCVAR_CHEAT;
		
		if (player.NightVision) 
		{ 
			player.NightVision = false;
			player.Msg("{yellow}NV is deactivated.");
			matFullbright.ReplicateToClient(client, "0");
		}
		else 
		{ 
			player.NightVision = true;
			player.Msg("{yellow}NV is activated.");
			EmitSoundToClient(client, soundTurnOn);
			matFullbright.ReplicateToClient(client, "1");
		}
		
		matFullbright.Flags = iFlags | FCVAR_CHEAT;
	}
	else
	{
		player.Error("You have not yet unlocked the night vision skill.");
	}
}