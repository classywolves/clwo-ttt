#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#include <ttt_shop>
#include <ttt>
#include <config_loader>
#include <multicolors>

#define SHORT_NAME "poisonsmoke"

#define PLUGIN_NAME TTT_PLUGIN_NAME ... " - Items: Poisonous Smoke"

int g_iTPrice = 0;
int g_iDPrice = 0;

int g_iTPrio = 0;
int g_iDPrio = 0;

int g_iTCount = 0;
int g_iTPCount[MAXPLAYERS + 1] =  { 0, ... };

int g_iDCount = 0;
int g_iDPCount[MAXPLAYERS + 1] =  { 0, ... };

bool g_bHasPoisonSmoke[MAXPLAYERS + 1] =  { false, ... };


char g_sConfigFile[PLATFORM_MAX_PATH] = "";
char g_sPluginTag[PLATFORM_MAX_PATH] = "";
char g_sLongName[64];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = TTT_PLUGIN_AUTHOR,
	description = TTT_PLUGIN_DESCRIPTION,
	version = TTT_PLUGIN_VERSION,
	url = TTT_PLUGIN_URL
};

public void OnPluginStart()
{
	TTT_IsGameCSGO();

	LoadTranslations("ttt.phrases");

	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/ttt/config.cfg");
	Config_Setup("TTT", g_sConfigFile);

	Config_LoadString("ttt_plugin_tag", "{orchid}[{green}T{darkred}T{blue}T{orchid}]{lightgreen} %T", "The prefix used in all plugin messages (DO NOT DELETE '%T')", g_sPluginTag, sizeof(g_sPluginTag));

	Config_Done();


	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/ttt/poison_smoke.cfg");

	Config_Setup("TTT-Poisonous-Smoke", g_sConfigFile);

	Config_LoadString("ps_name", "Poisonous  Smoke", "The name of the Poisonous Smoke in the Shop", g_sLongName, sizeof(g_sLongName));

	g_iTPrice = Config_LoadInt("ps_traitor_price", 300, "The amount of credits for poisonous smoke costs as traitor. 0 to disable.");
	g_iDPrice = Config_LoadInt("ps_detective_price", 0, "The amount of credits for poisonous smoke costs as detective. 0 to disable.");

	g_iTPrio = Config_LoadInt("ps_traitor_sort_prio", 0, "The sorting priority of the poisonous smoke (Traitor) in the shop menu.");
	g_iDPrio = Config_LoadInt("ps_detective_sort_prio", 0, "The sorting priority of the poisonous smoke (Detective) in the shop menu.");

	g_iTCount = Config_LoadInt("ps_traitor_count", 3, "The amount of usages for poisonous smokes per round as traitor. 0 to disable.");
	g_iDCount = Config_LoadInt("ps_detective_count", 0, "The amount of usages for poisonous smokes per round as detective. 0 to disable.");

	Config_Done();

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("smokegrenade_detonate", Event_SmokeDetonate, EventHookMode_Pre);
}

public void OnClientDisconnect(int client)
{
	ResetPoisonSmokeCount(client);
}

// Hook before smoke detonates
public Action Event_SmokeDetonate(Event event, const char[] name, bool dontBroadcast)
{
	// Get who threw the smoke grenade.
	int client = GetClientOfUserId(event.GetInt("userid"));

	// Ensure that the player is valid before continuing.
	if (TTT_IsClientValid(client))
	{
		// Retrieve entity to be able to modify its values later.
		int entity = event.GetInt("entityid");

		if (!g_bHasPoisonSmoke[client])
		{
			return Plugin_Continue;
		}
		float fSmokeValue = GetEntPropFloat(entity, Prop_Data, "m_DmgRadius", 0);
		PrintToServer("[INFO] Smoke Default Value: %f", fSmokeValue);
		SetEntPropFloat(entity, Prop_Data, "m_DmgRadius", fSmokeValue + 200.0); 


		g_bHasPoisonSmoke[client] = false;

		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (TTT_IsClientValid(client))
	{
		ResetPoisonSmokeCount(client);
	}
}

public void OnAllPluginsLoaded()
{
	TTT_RegisterCustomItem(SHORT_NAME, g_sLongName, g_iTPrice, TTT_TEAM_TRAITOR, g_iTPrio);
	TTT_RegisterCustomItem(SHORT_NAME, g_sLongName, g_iDPrice, TTT_TEAM_DETECTIVE, g_iDPrio);
}

public Action TTT_OnItemPurchased(int client, const char[] itemshort, bool count)
{
	if (TTT_IsClientValid(client) && IsPlayerAlive(client))
	{
		if (StrEqual(itemshort, SHORT_NAME, false))
		{
			int role = TTT_GetClientRole(client);

			if (role == TTT_TEAM_TRAITOR && g_iTPCount[client] >= g_iTCount)
			{
				CPrintToChat(client, g_sPluginTag, "Bought All", client, g_sLongName, g_iTCount);
				return Plugin_Stop;
			}
			else if (role == TTT_TEAM_DETECTIVE && g_iDPCount[client] >= g_iDCount)
			{
				CPrintToChat(client, g_sPluginTag, "Bought All", client, g_sLongName, g_iDCount);
				return Plugin_Stop;
			}

			GivePlayerItem(client, "weapon_decoy");

			g_bHasPoisonSmoke[client] = true;

			if (count)
			{
				if (role == TTT_TEAM_TRAITOR)
				{
					g_iTPCount[client]++;
				}
				else if (role == TTT_TEAM_DETECTIVE)
				{
					g_iDPCount[client]++;
				}
			}
		}
	}
	return Plugin_Continue;
}

void ResetPoisonSmokeCount(int client)
{
	g_iTPCount[client] = 0;
	g_iDPCount[client] = 0;

	g_bHasPoisonSmoke[client] = false;
}
