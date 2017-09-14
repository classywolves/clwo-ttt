
#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools_functions>
#include <sdktools_trace>
#include <sdktools_engine>
#include <entity>
#include <general>

/* Plugin Info */
#define PLUGIN_NAME 			"LastSeen Logger"
#define PLUGIN_VERSION_M 		"0.0.1"
#define PLUGIN_AUTHOR 			"ScreenMan"
#define PLUGIN_DESCRIPTION		"Logs time you last saw a player."
#define PLUGIN_URL				"http://screenman.pro"

int array_lastseen[MAXPLAYERS + 1][MAXPLAYERS + 1];
float vec_eyes[MAXPLAYERS + 1][3];

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
	CreateTimer(1.0, Timer_UpdateLastSeen, _, TIMER_FLAG_NO_MAPCHANGE);
	PrintToServer("[LSeen] Has Loaded Succcessfully!");
}

public OnPluginEnd() {
	PrintToServer("[LSeen] Has Unloaded Successfully!");
}

public Action Timer_UpdateLastSeen(Handle timer)
{
	
	for (int i = 1; i <= MAXPLAYERS; i++ )
	{
		if (!C_IsValidClient(i)) { continue; }
		GetClientEyeAngles(i, vec_eyes[i]);
	}
  
	return Plugin_Continue;
}

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
	clientLoc[2] += 10;
	// targetLoc[2] += 5;
	TR_TraceRayFilter(clientLoc, targetLoc, MASK_SHOT, RayType_EndPoint, TraceRayDontHitSelf, client);

	return (!TR_DidHit() || TR_GetEntityIndex() == target);
}

bool TraceHeadToHead(int client, int target, float clientLoc[3], float targetLoc[3])
{
	clientLoc[2] += 10;
	targetLoc[2] += 10;
	TR_TraceRayFilter(clientLoc, targetLoc, MASK_SHOT, RayType_EndPoint, TraceRayDontHitSelf, client);

	return (!TR_DidHit() || TR_GetEntityIndex() == target);
}

 public bool TraceRayDontHitSelf(entity, mask, any data)
{
	return ((entity > 0) && (entity <= MaxClients) && (entity != data));
}
