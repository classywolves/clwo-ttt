
#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <colorvariables>
//#include <imod>
#include <ttt>
#include <cstrike>
#include <general>

/* Plugin Info */
#define PLUGIN_NAME 			"TTT Profile"
#define PLUGIN_VERSION_M 		"0.0.4"
#define PLUGIN_AUTHOR 			"Popey"
#define PLUGIN_DESCRIPTION		"Shows a TTT profile page."
#define PLUGIN_URL				"https://sinisterheavens.com"

// ConVar rdm_version = null;
Database db_ttt;
Database db_player_analytics;

typedef NativeCall = function int (Handle plugin, int numParams);

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
	LoadTranslations("common.phrases");
	
	// Connect to Database
	char error[255];
	db_ttt = SQL_Connect("ttt", true, error, sizeof(error));
	if (db_ttt == null) { PrintToServer("[PRF] Could not connect to TTT db: %s", error); }
	else { PrintToServer("[PRF] Connected to TTT DB"); } 
	
	db_player_analytics = SQL_Connect("player_analytics", true, error, sizeof(error));
	if (db_player_analytics == null) { PrintToServer("[PRF] Could not connect to Player Analytics db: %s", error); }
	else { PrintToServer("[PRF] Connected to Player Analytics DB"); } 
	
	// Register CVARS
	// rdm_version = CreateConVar("ldb_version", PLUGIN_VERSION_M, "Leaderboard Plugin Version");
	CreateConVar("prf_version", PLUGIN_VERSION_M, "Profile Plugin Version");
	
	// Register Commands
	RegConsoleCmd("sm_profile", Command_Profile, "Open the Profile");
	
	// Alert Load Success
	PrintToServer("[PRF] Has Loaded Succcessfully!");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("TTT_ProfilePage", Native_TTT_ProfilePage);
    return APLRes_Success;
}

public int Native_TTT_ProfilePage(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	char str[32];
	int len;
	GetNativeStringLength(2, len);
	GetNativeString(2, str, len + 1);
	GetNativeString(2, str, sizeof(str));
	PrintProfile(client, str);
}

public PrintProfile(int client, char[] steamid) {
	CPrintToChat(client, "Some random text");
}

public Action Command_Profile(int client, int args) {
	char arg[255];
	GetCmdArg(1, arg, sizeof(arg));
	int target = FindTarget(client, arg);
	if (target == -1) {
		return Plugin_Continue;
	}
	char auth[64];
	GetClientAuthId(target, AuthId_Steam2, auth, sizeof(auth), true);
	PrintProfile(client, auth);
}

public OnPluginEnd()
{
	// Alert Unload Success
	PrintToServer("[LDB] Has Unloaded Successfully!");
}