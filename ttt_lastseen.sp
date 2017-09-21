
#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools_functions>
#include <sdktools_trace>
#include <sdktools_engine>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <entity>
#include <ttt>
#include <general>

/* Plugin Info */
#define PLUGIN_NAME 			"LastSeen Logger"
#define PLUGIN_VERSION_M 		"0.0.1"
#define PLUGIN_AUTHOR 			"ScreenMan"
#define PLUGIN_DESCRIPTION		"Logs time you last saw a player."
#define PLUGIN_URL				"http://screenman.pro"

//int array_lastseen[MAXPLAYERS + 1][MAXPLAYERS + 1];
//float vec_eyes[MAXPLAYERS + 1][3];
int round_time = 0;
// Integer for prechache index
int g_iSprite = -1;

ConVar g_hCvar_OffsetHead;
int g_Shadow_OffsetHead;

ConVar g_hCvar_OffsetFeet;
int g_Shadow_OffsetFeet;

/*
TODO:
 - Add a function to check if visible in FOV of 90, from client's view angles.
 - Save last seen times to an dynamic array. ADT_Array
*/



public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION_M,
	url = PLUGIN_URL
};

public OnPluginStart()
{
	CreateConVar("lastseen_version", PLUGIN_VERSION_M, "LastSeen Plugin Version");
	RegConsoleCmd("sm_visible", Command_Visible, "Prints all players that are visible");
	
	g_hCvar_OffsetHead = CreateConVar("lseen_offset_head", "10", "Sets the offset.");
	g_hCvar_OffsetFeet = CreateConVar("lseen_offset_feet", "10", "Sets the offset.");
	
	g_Shadow_OffsetHead = g_hCvar_OffsetHead.IntValue;
	g_Shadow_OffsetFeet = g_hCvar_OffsetFeet.IntValue;
	
	HookConVarChange(g_hCvar_OffsetHead, CvarChanged);
	HookConVarChange(g_hCvar_OffsetFeet, CvarChanged);
	
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	CreateTimer(1.0, Timer_1, _, TIMER_REPEAT);
	
	// CreateTimer(1.0, Timer_UpdateLastSeen, _, TIMER_FLAG_NO_MAPCHANGE);
	PrintToServer("[LSeen] Has Loaded Succcessfully!");
}

public void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hCvar_OffsetHead)
	{
		g_Shadow_OffsetHead = StringToInt(newValue);
	}
	else if (convar == g_hCvar_OffsetFeet)
	{
		g_Shadow_OffsetFeet = StringToInt(newValue);
	}
}

public OnPluginEnd() {
	PrintToServer("[LSeen] Has Unloaded Successfully!");
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	round_time = 0;
	return Plugin_Continue;
}

public void OnMapStart()
{
	g_iSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public Action Timer_1(Handle timer) {
	if (TTT_IsRoundActive()) {
		round_time++;
	}
}

/*
public Action Timer_UpdateLastSeen(Handle timer)
{
	
	for (int i = 1; i <= MAXPLAYERS; i++ )
	{
		if (!C_IsValidClient(i)) { continue; }
		GetClientEyeAngles(i, vec_eyes[i]);
	}
  
	return Plugin_Continue;
}
*/

public Action Command_Visible(int client, int args) {
	if (args != 0) {
		return Plugin_Handled;
	}
	
	for (int i = 1; i <= MAXPLAYERS; i++ )
	{
		if (i == client) { continue; }
		if (!C_IsValidClient(i)) { continue; }
		
		float myOrigin[3]; 
		GetClientEyePosition(client, myOrigin);
		
		float targetOrigin[3];
		GetClientEyePosition(i, targetOrigin);
		

		if (TraceHeadToHead(client, i, myOrigin, targetOrigin))
		{
			PrintToConsole(client, "Visible Client Head: %N", i);
		}
		else if (TraceHeadToFeet(client, i, myOrigin, targetOrigin))
		{
			PrintToConsole(client, "Visible Client Feet: %N", i);
		}
		
	}
	return Plugin_Handled;
}

bool C_IsValidClient(int client,bool allowconsole=false) {
	if(client == 0 && allowconsole) { return true; }
	if(client <= 0) { return false; }
	if(client > MaxClients) { return false; }
	if (!IsClientConnected(client)) { return false; } 
	if(!IsClientInGame(client)) { return false; }
	return true;
}

bool TraceHeadToFeet(int client, int target, float clientLoc[3], float targetLoc[3])
{
	clientLoc[2] += g_Shadow_OffsetHead;
	int color[4] =  { 255, 0, 0, 255 };
	// targetLoc[2] += 5;
	TR_TraceRayFilter(clientLoc, targetLoc, MASK_SHOT, RayType_EndPoint, TraceRayDontHitSelf, client);
	TE_SetupBeamPoints(clientLoc, targetLoc, g_iSprite, 0, 0, 0, 5.0, 3.0, 3.0, 10, 0.0, color, 0);
	TE_SendToAll();
	
	return (!TR_DidHit() || TR_GetEntityIndex() == target);
}

bool TraceHeadToHead(int client, int target, float clientLoc[3], float targetLoc[3])
{
	clientLoc[2] += g_Shadow_OffsetHead;
	targetLoc[2] += g_Shadow_OffsetFeet;
	int color[4] =  { 0, 255, 0, 255 };
	TR_TraceRayFilter(clientLoc, targetLoc, MASK_SHOT, RayType_EndPoint, TraceRayDontHitSelf, client);
	TE_SetupBeamPoints(clientLoc, targetLoc, g_iSprite, 0, 0, 0, 5.0, 3.0, 3.0, 10, 0.0, color, 0);
	TE_SendToAll();
	
	return (!TR_DidHit() || TR_GetEntityIndex() == target);
}

 public bool TraceRayDontHitSelf(entity, mask, any data)
{
	return ((entity > 0) && (entity <= MaxClients) && (entity != data));
}
