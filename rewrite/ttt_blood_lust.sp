/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <timers>

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

public Plugin myinfo =
{ 
	name = "TTT Blood Lust",
	author = "Corpen", 
	description = "TTT Bloodlust Traitor anti delaying mechanism.", 
	version = "0.0.1", 
	url = "" 
};

Handle bloodLustTimers[MAXPLAYERS+1];

char traitorOverlay[PLATFORM_MAX_PATH] = "darkness/ttt/overlayTraitor";
char traitorBloodLustOverlay[PLATFORM_MAX_PATH] = "corpen/ttt/overlayTraitorBloodLust";

float bloodLustStartTime = 45.0;
float bloodLustFinalTime = 30.0;

public OnPluginStart()
{
	PreCache();
	
	LoadTranslations("common.phrases");
	
	PrintToServer("[BLM] Loaded succcessfully");
}

public void OnAllPluginsLoaded()
{
	if (!LibraryExists("ttt_overlay"))
	{
		char sBuffer[PLATFORM_MAX_PATH];
	
		Format(sBuffer, sizeof(sBuffer), "materials/%s.vmt", traitorOverlay);
		AddFileToDownloadsTable(sBuffer);
		Format(sBuffer, sizeof(sBuffer), "materials/%s.vtf", traitorOverlay);
		AddFileToDownloadsTable(sBuffer);
		PrecacheDecal(traitorOverlay, true);
	}
}

public void PreCache()
{
	char sBuffer[PLATFORM_MAX_PATH];
	
	Format(sBuffer, sizeof(sBuffer), "materials/%s.vmt", traitorBloodLustOverlay);
	AddFileToDownloadsTable(sBuffer);
	Format(sBuffer, sizeof(sBuffer), "materials/%s.vtf", traitorBloodLustOverlay);
	AddFileToDownloadsTable(sBuffer);
	PrecacheDecal(traitorBloodLustOverlay, true);
}

public void TTT_OnClientGetRole(int client, int role)
{
	if (role == TTT_TEAM_TRAITOR)
	{
		bloodLustTimers[client] = CreateTimer(bloodLustStartTime, BloodLustStart, client);
	}
}

public void TTT_OnClientDeath(int victim, int attacker)
{
	if (TTT_GetClientRole(attacker) == TTT_TEAM_TRAITOR)
	{
		ClearTimer(bloodLustTimers[attacker]);
		
		BloodLustReset(attacker);
		bloodLustTimers[attacker] = CreateTimer(bloodLustStartTime, BloodLustStart, attacker);
	}
	
	if (TTT_GetClientRole(victim) == TTT_TEAM_TRAITOR)
	{
		ClearTimer(bloodLustTimers[victim]);
	}
}

public void TTT_OnRoundEnd(int winner)
{
	LoopValidClients(i)
	{
		ClearTimer(bloodLustTimers[i]);
	}
}

public Action BloodLustStart(Handle timer, int client)
{
	CPrintToChat(client, "{purple}[TTT] {red}You are longing for blood!  Best kill again soon, else there may be consequences.");
	ShowOverlayToClient(client, traitorBloodLustOverlay);
	ClearTimer(bloodLustTimers[client]);
	bloodLustTimers[client] = CreateTimer(bloodLustFinalTime, BloodLustFinal, client);
}

public Action BloodLustFinal(Handle timer, int client)
{
	CPrintToChat(client, "{purple}[TTT] {red}You have gone without blood for too long; you are now revealed to the players around you.");
	SetEntityRenderColor(client, 255, 0, 0, 255);
	ClearTimer(bloodLustTimers[client]);
}

public void BloodLustReset(int client)
{
	SetEntityRenderColor(client, 255, 255, 255, 255);
	ShowOverlayToClient(client, traitorOverlay);
}
