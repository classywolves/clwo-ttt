
#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <colorvariables>
//#include <imod>
#include <ttt>
#include <cstrike>

/* User Type */
#define USER_TYPE_COMMAND      0
#define USER_TYPE_IS_STAFF     1
#define USER_TYPE_BROADCAST    2
#define USER_TYPE_GROUPNAME    3
#define USER_TYPE_FULLNAME     4
#define USER_TYPE_SCORENAME    5
#define USER_TYPE_CHATNAME     6
#define USER_TYPE_MULTI_TARGET 7

#define INNOCENT 1
#define TRAITOR 2
#define DETECTIVE 3

/* Plugin Info */
#define PLUGIN_NAME 			"SMPatch"
#define PLUGIN_VERSION_M 		"0.0.2"
#define PLUGIN_AUTHOR 			"ColdMeekly"
#define PLUGIN_DESCRIPTION		"Adds in missing functionality to sourcemod."
#define PLUGIN_URL				"http://screenman.pro/"

// ConVar smp_version = null;
EngineVersion g_Game;
typedef NativeCall = function int (Handle plugin, int numParams);

/*
include_me.inc

native void Steam64ToSteamID(char[] steam64, char[] output);
*/
public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION_M,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	// smp_version = CreateConVar("smp_version", PLUGIN_VERSION_M, "SourceMod Patch Version");
	CreateConVar("smp_version", PLUGIN_VERSION_M, "SourceMod Patch Version");
	
	// Alert Load Success
	PrintToServer("[SMPatch] Has Loaded Succcessfully!");
}

public OnPluginEnd()
{
	// Alert Unload Success
	PrintToServer("[SMPatch] Has Unloaded Successfully!");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Steam64ToSteamID", Native_Steam64ToSteamID);
	return APLRes_Success;
}

/**
 * returns a subset of a string between one index and another, or through the end of the string.
 * @param {String} input_string 
 * @param {Number} start_pos
 * @param {Number} result
 * @param {Number} len
 **/
stock substr(char[] input_string, int start_pos, char[] result, int len=-1)
{
    if (len == -1)
    {
        strcopy(result, 255, input_string[start_pos]);
    }
    
    else
    {
        strcopy(result, len, input_string[start_pos]);
    }

}

stock bool IsEven(num)
{
    return (num & 1) == 0;
}

stock bool IsOdd(num)
{
    return (num & 1) == 1;
}  



public int Native_Steam64ToSteamID(Handle plugin, int numParams)
{
	/* Retrieve the first parameter we receive */
	int len;
	GetNativeStringLength(1, len);
	
	/* Validate the string */
	if (len <= 0)
	{
		return;
	}
	
	/* Process the string */
	char[] steam64 = new char[len + 1];											// Allocate enough space for the string
	GetNativeString(1, steam64, len + 1);										// Assign argument 1 to steam64 as a string
	
	char cutdown_steamid[18];													// Create a buffer for substr
	substr(steam64, 8, cutdown_steamid);										// Cut out the repetitve numbers
	
	int cutdown2_int = StringToInt(cutdown_steamid) - 960265728;				// Convert the string to Int and Subtract the "Magic" number
	
	if (cutdown2_int < 0){cutdown2_int = cutdown2_int + 1000000000;} 			// Make use of the negative space to make up for lack of space
																				// The output is Steam32

	int a = 1;
	if (IsEven(cutdown2_int)){a = 0;}											// A = 1 if Output = Odd | A = 0 if Output = Even
	
	int steam2 = (cutdown2_int - a) / 2;										// Calculate the SteamID Z value
	
	
	char output_steamid[32];											
	Format(output_steamid, sizeof(output_steamid), "STEAM_0:%d:%d", a, steam2); // STEAM_X:Y:Z, where X = 0, Y = A, Z = Output
	
	SetNativeString(2, output_steamid, sizeof(output_steamid)+1, false);		// Return by reference
}