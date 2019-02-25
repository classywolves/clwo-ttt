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
#include <ttt_db>

public Plugin myinfo = {
    name = "TTT Player Commands",
    author = "Popey & Corpen",
    description = "General player commands for CLWO TTT.",
    version = "1.0.0",
    url = ""
};

public OnPluginStart() {
    RegisterCmds();
    //HookEvents();
    InitDBs();

    PrintToServer("[PCM] Loaded successfully");
}

public void RegisterCmds() {
    RegConsoleCmd("sm_staff", Command_Staff, "List the all of the staff who are currently online.");
    RegConsoleCmd("sm_admins", Command_Staff, "List the all of the staff who are currently online.");

    RegConsoleCmd("sm_spec", Command_Spectate, "Choose which of the alive players you would like to spectate.");

    RegConsoleCmd("sm_terrorist", Command_Terrorist, "Move Player to T.");
    RegConsoleCmd("sm_ct", Command_CounterTerrorist, "Move Player to CT.");
    RegConsoleCmd("sm_afk", Command_Spectator, "Move Player to Spectator.");

    RegConsoleCmd("sm_rank", Command_Rank, "Displays your current ranking based upon your karma.");
    RegConsoleCmd("sm_playtime", Command_Playtime, "Displays your current total playtime.");

    RegConsoleCmd("sm_give", Command_Give, "Gives the given amount of credits to another player.")
}

public void InitDBs() {
    TTTInit();
}

public Action Command_Staff(int client, int args) {
    int staffCount = 0;
    int staffIndexes[MAXPLAYERS + 1];
    LoopValidClients(i) {
        if (Player(i).Staff) {
            staffIndexes[staffCount++] = i;
        }
    }

    if (staffCount == 0) {
        CPrintToChat(client, "{purple}[w] {darkred}There are no staff online");
    }
    else {
        // PrintToChat(client, "%L", staff);
        // iMod_GetUserTypeString(int UserType,int type, char[] output, int maxlen)
        CPrintToChat(client, "{purple}[Staff] {yellow}There are currently {green}%i {yellow}staff online:", staffCount);

        for (int i = 0; i < staffCount; i++) {
            char rankName[64];
            int rank = GetPlayerRank(staffIndexes[i])
            GetRankName(rank, rankName, USER_RANK_NAME);
            switch (rank) {
                case 0, 1, 3, 4, 5, 6, 8, 9, 10: {
                    CPrintToChat(client, "{purple}[Staff] {darkblue}%N {yellow}is a {green}%s", staffIndexes[i], rankName);
                }
                case 2, 7: {
                    CPrintToChat(client, "{purple}[Staff] {darkblue}%N {yellow}is an {green}%s", staffIndexes[i], rankName);
                }
            }
        }
    }

    return Plugin_Handled;
}

public Action Command_Spectate(int client, int args) {
    Menu menu = new Menu(MenuHandler_Spectate);
    menu.SetTitle("Which player would you like to specate?");
    LoopAliveClients(i) {
        char index[4];
        IntToChar4(i, index);

        char name[64];
        Player(i).Name(name);

        char display[512];
        switch(TTT_GetClientRole(i)) {
			case TTT_TEAM_UNASSIGNED: {
                Format(display, sizeof(display), "%s [%s]", name, "Unassigned");
			}
			case TTT_TEAM_INNOCENT: {
                Format(display, sizeof(display), "%s [%s]", name, "Innocent");
			}
			case TTT_TEAM_TRAITOR: {
                Format(display, sizeof(display), "%s [%s]", name, "Traitor");
			}
			case TTT_TEAM_DETECTIVE: {
                Format(display, sizeof(display), "%s [%s]", name, "Detective");
			}
            default: {
                Format(display, sizeof(display), "%s [%s]", name, "Unassigned");
            }
        }

        menu.AddItem(index, display);
    }

    return Plugin_Handled;
}

public Action Command_Terrorist(int client, int args) {
    Player player = Player(client)
    player.Team = CS_TEAM_T;
    player.Msg("You have been moved to the {team1}T {yellow}side.");

    return Plugin_Handled;
}

public Action Command_Spectator(int client, int args) {
    Player player = Player(client)
    player.Team = CS_TEAM_SPECTATOR;
    player.Msg("You have been moved to {team0}Spectator.");

    return Plugin_Handled;
}

public Action Command_CounterTerrorist(int client, int args) {
    Player player = Player(client)
    player.Team = CS_TEAM_CT;
    player.Msg("You have been moved to the {team2}CT {yellow}side.");

    return Plugin_Handled;
}

public Action Command_Rank(int client, int args)
{
    Player player = Player(client);
    char steamID[64];
    player.Auth(AuthId_SteamID64, steamID);
    TTTGetRank(steamID, GetClientUserId(client));

    return Plugin_Handled;
}

public Action Command_Playtime(int client, int args)
{
    Player player = Player(client);
    char steamID[64];
    player.Auth(AuthId_SteamID64, steamID);
    TTTGetPlaytime(steamID, GetClientUserId(client));

    return Plugin_Handled;
}

public Action Commnand_Give(int client, int args) {
    Player player = Player(client);
    if (args < 2) {
        player.Error("Usage: sm_give <target> <credits>.");
        return Plugin_Handled;
    }

    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    Player target = player.TargetOne(buffer, true);
    if (!target.ValidClient) { return Plugin_Handled; }

    GetCmdArg(2, buffer, MAX_NAME_LENGTH);
    int credits = StringToInt(buffer);
    if (credits < 1 || credits > player.Credits) {
        CPrintToChat(client, "{purple}[TTT] {red}You have an insufficient amount of credits to give {blue}%N {green}%i {yellow}credits.", targer.Client, credits);
    }

    return Plugin_Handled;
}

public Action MenuHandler_Spectate(Menu menu, MenuAction action, int client, int data) {
    switch (action) {
        case MenuAction_Select: {
            char indexChars[4];
            menu.GetItem(data, indexChars, 4);
            int index = Char4ToInt(indexChars);
            if (Player(index).ValidClient) {
                Player(client).Msg("You started specating {blue}%N", target);
                Player.Spectate(index);
            }
        }
    }

    return Plugin_Handled;
}

public void TTTGetRank(char auth[64], int userID) {
    if (tttConnected == false) return;

    char query[768];
    tttDb.Format(query, sizeof(query), "SET @playerKarma = (SELECT `karma` FROM `ttt` WHERE `communityid`='%s'); SELECT @playerKarma AS `karma`, (SELECT `karma` FROM `ttt` WHERE `karma` > @playerKarma ORDER BY `karma` ASC LIMIT 1) AS `nextKarma`, (SELECT COUNT(*) FROM `ttt` WHERE `karma` >= @playerKarma) AS `rank`, (SELECT COUNT(*) FROM `ttt`) AS `playerCount`;", auth);
    tttDb.Query(TTTKarmaRankCallback, query, userID);
}

public void TTTKarmaRankCallback(Database db, DBResultSet results, const char[] error, any userID) {
    if (results == null) {
        LogError("TTTKarmaRankCallback: %s", error);
        return;
    }

    if (results.FieldCount < 4) { return; }

    int client = GetClientOfUserId(userID);

    results.FetchRow();
    if (results.FetchInt(1) == 0)
    {
        int karma = results.FetchInt(0);
        int rank = results.FetchInt(2);
        int playerCount = results.FetchInt(3);

        CPrintToChatAll("{purple[TTT] {blue}%N {yellow}has {green}%d {yellow}karma making them rank {green}%d/%d.", client, karma, rank, playerCount);
    }
    else {
        int karma = results.FetchInt(0);
        int nextKarma = results.FetchInt(1);
        int rank = results.FetchInt(2);
        int nextRank = rank - 1;
        int playerCount = results.FetchInt(3);

        CPrintToChatAll("{purple[TTT] {blue}%N {yellow}has {green}%d {yellow}karma making them rank {green}%d/%d. {yellow}They need {green}%d {yellow}more karma to get to rank {green}%s!", client, karma, rank, playerCount, nextKarma, nextRank);
    }
}

public void TTTGetPlaytime(char auth[64], int userID) {
    if (tttConnected == false) return;

    char query[768];
    tttDb.Format(query, sizeof(query), "SELECT SUM(`duration`) FROM `player_analytics` WHERE `auth`='%s';", auth);
    tttDb.Query(TTTKarmaRankCallback, query, userID);
}

public void TTTPlaytimeCallback(Database db, DBResultSet results, const char[] error, any userID) {
    if (results == null) {
        LogError("TTTPlaytimeCallback: %s", error);
        return;
    }

    int client = GetClientOfUserId(userID);

    results.FetchRow();
    int playTime = results.FetchInt(0);
    int minutes, hours, days;
    while (playTime >= 86400)
    {
        playTime -= 86400;
        days++;
    }
    while (playTime >= 3600)
    {
        playTime -= 3600;
        hours++;
    }
    while (playTime >= 60)
    {
        playTime -= 60;
        minutes++;
    }
    if (days > 0) { CPrintToChatAll("{purple}[TTT] {blue}%N {yellow}has played for {green}%i {yellow}days and {green}%i {yellow}hours.", client, days, hours); }
    else if (hours > 0) { CPrintToChatAll("{purple}[TTT] {blue}%N {yellow}has played for {green}%i {yellow}hours.", client, hours); }
    else { CPrintToChatAll("{purple}[TTT] {blue}%N {yellow}has played for {green}%i {yellow}minutes.", client, minutes); }
}
