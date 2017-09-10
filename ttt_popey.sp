#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <colorvariables>
#include <imod>
#include <general>
#include <cstrike>

/* Plugin Info */
#define PLUGIN_NAME 			"Popey's TTT Stuff"
#define PLUGIN_VERSION_M 		"0.0.2"
#define PLUGIN_AUTHOR 			"Popey"
#define PLUGIN_DESCRIPTION		"Some TTT Related Commands."
#define PLUGIN_URL				"https://sinisterheavens.com"

ConVar sm_popey_version = null;
Handle Timers[50];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION_M,
	url = PLUGIN_URL
};

Database db_ttt;
Database db_pa;

public OnPluginStart()
{
	RegisterCvars();
	RegisterCmds();
	HookEvents();
	
	char error[255];
	db_pa = SQL_Connect("player_analytics", false, error, sizeof(error));
	 
	if (db_pa == null)
	{
		PrintToServer("Could not connect: %s", error);
	}
	
	PrintToServer("[TTT Popey] Has Loaded Succcessfully!");
}

public OnPluginEnd()
{
	//end commands here
	PrintToServer("[TTT Popey] Has Unloaded Successfully!");
}

public void RegisterCvars()
{
	sm_popey_version = CreateConVar("sm_popey_version", PLUGIN_VERSION_M, "Popey's TTT Plugin Version")
}

public void RegisterCmds()
{
	//register all commands here
	RegConsoleCmd("sm_staff", Command_Staff, "Lists Online Staff");
	RegConsoleCmd("sm_admins", Command_Staff, "Lists Online Staff");
	RegConsoleCmd("sm_playtime", Command_Playtime, "Reports on a Playtime");
	RegConsoleCmd("sm_rank", Command_Rank, "Rank of your Karma Score");
	RegConsoleCmd("sm_spectator", Command_Spectator, "Move Player to Spec");
	RegConsoleCmd("sm_afk", Command_Spectator, "Move Player to Spec");
	RegConsoleCmd("sm_terrorist", Command_Terrorist, "Move Player to T");
	RegConsoleCmd("sm_ct", Command_Counter_Terrorist, "Move Player to CT");
	RegConsoleCmd("sm_bantimes", Command_BanTimes, "List Common Time Lengths");
	RegAdminCmd("sm_reloadttt", Command_Reload_TTT, ADMFLAG_ROOT,  "Reload the TTT Plugin");
}

public void HookEvents()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_say", OnPlayerMessage);
}

public void OnMapStart()
{
	//commands on map start
}

public Action OnPlayerMessage(Event event, const char[] name, bool dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client < 1)
		return Plugin_Continue;

	char auth[255];
	char text[256];
	char string[1024];
	
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth)) 
	GetEventString(event, "text", text, sizeof(text));
	Format(string, sizeof(string), "%i`&^&`%s`&^&`%s", GetTime(), auth, text);

	char file[1024];
	BuildPath(Path_SM, file, PLATFORM_MAX_PATH, "/logs/chat.txt");
	Handle fileHandle = OpenFile(file, "a");
	WriteFileLine(fileHandle, string);
	CloseHandle(fileHandle);

	return Plugin_Continue;
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	TestArmour();
	Timers[1] = CreateTimer(210.0, BeaconAfterTime);
	return Plugin_Continue;
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	KillTimer(Timers[1]);
	return Plugin_Continue;
}

public Action BeaconAfterTime(Handle timer) {
	CPrintToChatAll("{purple}[Beacon] {yellow}There's only one minute thirty left!");
	ServerCommand("sm_beacon @all");
}

public void TestArmour() {
	for (int i = 1; i <= MaxClients; i++)
	{
	    if (IsValidClient(i)) {
			if (IsPlayerAlive(i)) {
				if (IsCarryingClantag(i)) {
					SetEntProp(i, Prop_Data, "m_ArmorValue", 10, 1);  
				}
			}
	    }
	}  
}

public void BlockCommand() {
	//new String:command[100] = "sm_tp"
	//new flags = GetCommandFlags(command);
	//SetCommandFlags(command, flags|FCVAR_CHEAT)
}

public Action Command_Reload_TTT(int client, int args) {
	CPrintToChatAll("{purple}[Popey TTT] {yellow}Plugin Restarting...")
	ServerCommand("sm plugins reload ttt-popey");
	return Plugin_Handled;
}

stock void PrintToConsoleAll(const char[] format, any:...)
{
    char buffer[1024];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            PrintToConsole(i, "%s", buffer);
        }
    }
}

public GetStaffInArray(int[] mods, int max)
{
	int counted_mods = 0;
	for (int player = 1; player <= MaxClients && counted_mods < max; player++)
	{
		if(IsValidClient(player))
		{
			if(iMod_IsStaff(player))
			{
				mods[counted_mods++] = player;
			}
		}
	}
	return counted_mods;
}

public Action Command_Playtime(int client, int args) {
	char auth[255];
	
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth)) 
	
	// CPrintToChat(client, "{purple}[Playtime] {yellow}Playtime of %N ", client);
	char format_query[1024];
	Format(format_query, sizeof(format_query), "SELECT SUM(`duration`) FROM `player_analytics` WHERE auth='%s' LIMIT 50", auth);
	
	DBResultSet query = SQL_Query(db, format_query);

	if (query == null)
	{
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("Failed to query (error: %s)", error);
	} else {
		char timestr[15];
		while (SQL_FetchRow(query))
		{
			SQL_FetchString(query, 0, timestr, sizeof(timestr));
			float time = StringToFloat(timestr);
			float timemin = time / 60;
			int timehour = RoundToFloor(timemin / 60)
			int timeminint = RoundToFloor(timemin)
			while (timeminint > 59) {
				timeminint = timeminint - 60;
			}
			
			CPrintToChatAll("{purple}[Playtime] {yellow}%N has played for %d hours, %d minutes!", client, timehour, timeminint);
		}
		delete query;
	}
	
	delete db;
}

public Action Command_BanTimes(int client, int args) {
	CPrintToChatAll("{purple}[BanTimes] {yellow}The following are some common ban times:");
	CPrintToChatAll("{purple}[BanTimes] {yellow} - 1 hour  --> 60    minutes");
	CPrintToChatAll("{purple}[BanTimes] {yellow} - 1 day   --> 1440  minutes");
	CPrintToChatAll("{purple}[BanTimes] {yellow} - 2 days  --> 2880  minutes");
	CPrintToChatAll("{purple}[BanTimes] {yellow} - 1 week  --> 10080 minutes");
	CPrintToChatAll("{purple}[BanTimes] {yellow} - 1 month --> 40320 minutes");
}

public Action Command_Rank(int client, int args) {
	char error[255];
	Database db = SQL_Connect("ttt", false, error, sizeof(error));
	 
	if (db == null)
	{
		PrintToServer("Could not connect: %s", error);
	}
	
	char auth[255];
	
	GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth)) 
	
	// CPrintToChat(client, "{purple}[Playtime] {yellow}Playtime of %N ", client);
	char format_query[1024];
	Format(format_query, sizeof(format_query), "SELECT karma, FIND_IN_SET( karma, (SELECT GROUP_CONCAT( karma ORDER BY karma DESC ) FROM `ttt` )) AS rank, (select COUNT(*) from `ttt`) as total FROM `ttt` WHERE communityid = '%s' or communityid = (select communityid from `ttt` where karma > (select karma from `ttt` where communityid = '%s') order by karma asc limit 1)", auth, auth);
	
	DBResultSet query = SQL_Query(db, format_query);

	if (query == null)
	{
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("Failed to query (error: %s)", error);
	} else {
		char rank[15];
		char karma[15];
		char total[15];
		char nextKarma[15];
		char nextRank[15];
		bool first = true;
		
		while (SQL_FetchRow(query))
		{
			if (first)
			{
				SQL_FetchString(query, 1, rank, sizeof(rank));
				SQL_FetchString(query, 0, karma, sizeof(karma));
				SQL_FetchString(query, 2, total, sizeof(total));
			}
			else
			{
				SQL_FetchString(query, 0, nextKarma, sizeof(nextKarma));
				SQL_FetchString(query, 1, nextRank, sizeof(nextRank));
			}
			first = false;
		}
		
		if (StringToInt(nextKarma) < StringToInt(karma)) {
			char temp[15];
			temp = karma;
			karma = nextKarma;
			nextKarma = temp;
			char temp2[15];
			temp2 = rank;
			rank = nextRank;
			nextRank = temp2;
		}
		
		int moreKarma;
		moreKarma = StringToInt(nextKarma) - StringToInt(karma)
		
		CPrintToChatAll("{purple}[Playtime] {yellow}%N has %s karma, making him rank %s/%s.  He needs %d more karma to get to rank %s!", client, karma, rank, total, moreKarma, nextRank);
		
		delete query;
	}
	
	delete db;
}

public Action Command_Staff(int client, int args) {
	int[] staff = new int[MaxClients+1];
	int num_staff;
	num_staff = GetStaffInArray(staff, MaxClients+1);
	if (num_staff == 0) {
		CPrintToChat(client, "{purple}[w] {darkred}There are no staff online")
	} else {
		// PrintToChat(client, "%L", staff);
		// iMod_GetUserTypeString(int UserType,int type, char[] output, int maxlen)
		CPrintToChat(client, "{purple}[Staff] {yellow}There are currently {green}%i {yellow}staff online:", num_staff);

		for (int i = 0; i < num_staff; i++) {
			new String:name[200];
			iMod_GetUserTypeString(iMod_GetUserType(staff[i]), USER_TYPE_FULLNAME, name, sizeof(name));
			CPrintToChat(client, "{purple}[Staff] {darkblue}%N {yellow}is a {green}%s", staff[i], name)
		}
	}
	return Plugin_Handled;
}

public Action Command_Spectator(int client, int args) {
	CPrintToChat(client, "{purple}[Move] {yellow}We moved you to spectator.");
	ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	return Plugin_Handled;
}

public Action Command_Terrorist(int client, int args) {
	CPrintToChat(client, "{purple}[Move] {yellow}We moved you to terrorist.");
	ChangeClientTeam(client, CS_TEAM_T);
	return Plugin_Handled;
}

public Action Command_Counter_Terrorist(int client, int args) {
	CPrintToChat(client, "{purple}[Move] {yellow}We moved you to counter-terrorist.");
	ChangeClientTeam(client, CS_TEAM_CT);
	return Plugin_Handled;
}