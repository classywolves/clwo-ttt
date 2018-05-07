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
 #include <player_models>

public Plugin myinfo =
{ 
	name = "TTT Corpen", 
	author = "Corpen", 
	description = "Corpen's TTT Area", 
	version = "0.0.1", 
	url = "" 
};

int ctRandom = 0;
int tRandom = 0;

public OnPluginStart()
{
	RegisterCmds();
	HookEvents();
	InitDBs();

	LoadTranslations("common.phrases");
	
	PrintToServer("[CRP] Loaded succcessfully");
}

public void RegisterCmds() {
	RegConsoleCmd("sm_smsay", Command_SMSay, "Targeted MSay.");
	RegConsoleCmd("sm_scsay", Command_SCSay, "Targeted CSay.");
	//RegConsoleCmd("sm_alive", Command_Alive, "Displays the currently alive / undiscovered players.");
}

public void HookEvents()
{
	
}

public void InitDBs()
{
	
}

public Action TTT_OnRoundStart_Pre()
{
	ctRandom = GetRandomInt(0, MAX_PLAYER_TEAMS - 1);
	tRandom = GetRandomInt(0, MAX_PLAYER_TEAMS - 1);
	
	return Plugin_Continue;
}

public void TTT_OnClientGetRole(int client, int role)
{
	DataPack pack;
	CreateDataTimer(0.05, TimedSetPlayerModel, pack);
	pack.WriteCell(client);
	pack.WriteCell(role);
}

public void OnMapStart()
{
	PreCacheTeamModels();
}

public void PreCacheTeamModels()
{
	for (int i = 0; i < MAX_CT_PLAYER_MODELS_COUNT; i++)
	{
		PrecacheModel(ctPlayerModels[i], true);
	}
	
	for (int i = 0; i < MAX_VIEW_MODELS_COUNT; i++)
	{
		PrecacheModel(ctViewModels[i], true);
	}
	
	for (int i = 0; i < MAX_T_PLAYER_MODELS_COUNT; i++)
	{
		PrecacheModel(tPlayerModels[i], true);
	}
	
	for (int i = 0; i < MAX_VIEW_MODELS_COUNT; i++)
	{
		PrecacheModel(tViewModels[i], true);
	}
}

public Action TimedSetPlayerModel(Handle timer, Handle pack)
{
	int client = ReadPackCell(pack);
	int role = ReadPackCell(pack);
	SetPlayerModel(client, role);
	
	return Plugin_Continue;
}

public void SetPlayerModel(int client, int role)
{
	switch (role)
	{
		case TTT_TEAM_DETECTIVE:
		{
			int index = 0;
			switch (ctRandom)
			{
				case 0:
				{
					index += GetRandomInt(0, 4);
				}
				case 1:
				{
					index = 5 + GetRandomInt(0, 4);
				}
				case 2:
				{
					index = 10 + GetRandomInt(0, 4);
				}
				case 3:
				{
					index = 15 + GetRandomInt(0, 5);
				}
				case 4:
				{
					index = 21 + GetRandomInt(0, 5);
				}
				case 5:
				{
					index = 27 + GetRandomInt(0, 4);
				}
				case 6:
				{
					index = 32 + GetRandomInt(0, 4);
				}
			}
			
			SetEntityModel(client, ctPlayerModels[index]);
			SetPlayerArms(client, ctViewModels[ctRandom]);
		}
		case TTT_TEAM_INNOCENT, TTT_TEAM_TRAITOR:
		{
			SetEntityModel(client, tPlayerModels[(5 * tRandom) + GetRandomInt(0, 4)]);
			SetPlayerArms(client, tViewModels[tRandom]);
		}
	}
}

void SetPlayerArms(int client, char arms_path[PLATFORM_MAX_PATH])
{
	if(!StrEqual(arms_path, ""))
	{
		//Remove player all items and give back them after 0.1 seconds + block weapon pickup
		int weapon_index;
		for (int slot = 0; slot < 7; slot++)
		{
			weapon_index = GetPlayerWeaponSlot(client, slot);
			{
				if(weapon_index != -1) 
				{
					if (IsValidEntity(weapon_index))
					{
						RemovePlayerItem(client, weapon_index);
						
						DataPack pack;
						CreateDataTimer(0.1, GiveBackWeapons, pack);
						pack.WriteCell(client);
						pack.WriteCell(weapon_index);
					}
				}
			}
		}
	
		//Set player arm model
		if(!IsModelPrecached(arms_path))
			PrecacheModel(arms_path);

		SetEntPropString(client, Prop_Send, "m_szArmsModel", arms_path);

	}
}

public Action GiveBackWeapons(Handle tmr, Handle pack)
{
	ResetPack(pack);
	int client = ReadPackCell(pack);
	int weapon_index = ReadPackCell(pack);
	EquipPlayerWeapon(client, weapon_index);
}

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