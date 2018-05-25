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

UserMsg g_FadeUserMsgId;

Handle bloodLustTimers[MAXPLAYERS+1];

char traitorOverlay[PLATFORM_MAX_PATH] = "darkness/ttt/overlayTraitor";
char traitorBloodLustOverlay[PLATFORM_MAX_PATH] = "corpen/ttt/overlayTraitorBloodLust";

float bloodLustStartTime = 45.0;
float bloodLustFinalTime = 30.0;

public OnPluginStart()
{
	g_FadeUserMsgId = GetUserMessageId("Fade");

	PreCache();
	HookEvents();
	
	LoadTranslations("common.phrases");
	
	PrintToServer("[BLM] Loaded succcessfully");
}

public void HookEvents() {
	HookEvent("player_death", OnPlayerDeath);
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

public void TTT_OnRoundStart(int innocents, int traitors)
{
	LoopClients(i) {
		Player player = Player(i)

		if (player.Traitor) {
			bloodLustTimers[i] = CreateTimer(bloodLustStartTime, BloodLustStart, i);
		}
		else
		{
			ClearTimer(bloodLustTimers[i]);
		}
	}
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attackerClient = GetClientOfUserId(GetEventInt(event, "attacker"));

	Player victim = Player(client)
	Player attacker = Player(attackerClient)

	if (attacker.Traitor) {
		ClearTimer(bloodLustTimers[attacker.Client]);
		
		BloodLustReset(attacker.Client);
		bloodLustTimers[attacker.Client] = CreateTimer(bloodLustStartTime, BloodLustStart, attacker.Client);
	}
	else
	{
		ClearTimer(bloodLustTimers[attacker.Client]);
	}
	
	ClearTimer(bloodLustTimers[victim.Client]);

	return Plugin_Continue;
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
	if (Player(client).Traitor) {
		ClearTimer(bloodLustTimers[attacker.Client]);
		
		return Plugin_Continue;
	}

	CPrintToChat(client, "{purple}[TTT] {red}You are longing for blood!  Best kill again soon, else there may be consequences.");
	//ShowOverlayToClient(client, traitorBloodLustOverlay);
	BloodLustScreenColor(client);
	ClearTimer(bloodLustTimers[client]);
	bloodLustTimers[client] = CreateTimer(bloodLustFinalTime, BloodLustFinal, client);
}

public Action BloodLustFinal(Handle timer, int client)
{
	if (Player(client).Traitor) {
		ClearTimer(bloodLustTimers[attacker.Client]);
		
		return Plugin_Continue;
	}

	CPrintToChat(client, "{purple}[TTT] {red}You have gone without blood for too long; you are now revealed to the players around you.");
	SetEntityRenderColor(client, 255, 0, 0, 255);
	ClearTimer(bloodLustTimers[client]);
}

public void BloodLustReset(int client)
{
	SetEntityRenderColor(client, 255, 255, 255, 255);
	//ShowOverlayToClient(client, traitorOverlay);
	ClearScreenColor(client);
}

public void BloodLustScreenColor(int client)
{
	int color[4] = { 255, 0, 0 , 63 };
	SetScreenColor(client, color);
}

public void ClearScreenColor(int client)
{
	int color[4] = { 0, 0, 0 , 0 };
	SetScreenColor(client, color);
}

public void SetScreenColor(int client, int color[4])
{
	Player player = Player(client);
	if (!player.ValidClient || !player.Traitor)
	{
		ClearTimer(bloodLustTimers[client]);

		return;
	}
	
	int clients[2];
	clients[0] = client;	
	
	int duration = 255;
	int holdtime = 255;
	int flags = 0x0002;

	Handle message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(message, "duration", duration);
		PbSetInt(message, "hold_time", holdtime);
		PbSetInt(message, "flags", flags);
		PbSetColor(message, "clr", color);
	}
	else
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, holdtime);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
	}
	
	EndMessage();
}
