#pragma semicolon 1

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
#include <smlib/crypt>

/*
* Custom methodmap includes.
*/
#include <player_methodmap>

public Plugin myinfo =
{
    name = "TTT Skills",
    author = "Popey & c0rp3n",
    description = "TTT Upgrades and Skills.",
    version = "0.0.1",
    url = ""
};

int skillPoints[MAXPLAYERS+1][64];

bool websitePayload[MAXPLAYERS + 1];

Handle cookiePlayerExperience = INVALID_HANDLE;
Handle cookiePlayerLevel = INVALID_HANDLE;

Handle experienceTimers[MAXPLAYERS + 1];

int startingInnocents = 0;
int startingNoneTraitors = 0;

char chars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890";

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    RegPluginLibrary("ttt_skills");

    CreateNative("Skills_GetPoints", Native_GetPoints);
    CreateNative("Skills_SetPoints", Native_SetPoints);
    CreateNative("Skills_GetLevel", Native_GetLevel);
    CreateNative("Skills_SetLevel", Native_SetLevel);
    CreateNative("Skills_GetExperience", Native_GetExperience);
    CreateNative("Skills_SetExperience", Native_SetExperience);
}

public OnPluginStart()
{
    CacheFiles();
    RegisterCmds();
    HookEvents();
    InitDBs();

    LoopValidClients(i) OnClientAuthorized(i, "");

    LoadTranslations("common.phrases");

    PrintToServer("[UPG] Loaded succcessfully");
}

public void CacheFiles()
{
    AddFileToDownloadsTable("sound/ttt_clwo/ttt_levelup.mp3");
}

public void RegisterCmds()
{
    RegAdminCmd("sm_experience", Command_DisplayExperience, ADMFLAG_GENERIC);

    RegAdminCmd("sm_setexperience", Command_SetExperience, ADMFLAG_ROOT);
    RegAdminCmd("sm_setlevel", Command_SetLevel, ADMFLAG_ROOT);

    RegAdminCmd("sm_update_info", Command_UpdateInfo, ADMFLAG_ROOT);
    RegAdminCmd("sm_display_upgrades", Command_DisplayUpgrades, ADMFLAG_GENERIC);

    RegConsoleCmd("sm_session", Command_GetSession);
    RegConsoleCmd("sm_populate", Command_Populate, "Populates upgrades");

    RegConsoleCmd("sm_skills", Command_Skills, "Opens the skill menu");
    RegConsoleCmd("sm_skill", Command_Skills, "Opens the skill menu");
    RegConsoleCmd("sm_reset_skills", Command_ResetSkills, "Reset all skills");

    RegConsoleCmd("sm_profile", Command_Profile, "Shows a players profile.");
}

public void HookEvents()
{
    HookEvent("player_death", OnPlayerDeath);
}

public void InitDBs()
{
    databaseTTT = ConnectDatabase("ttt", "ttt");
    // databaseTTT.Query(GenericOnSQLConnectCallback, "CREATE TABLE IF NOT EXISTS `sessions` (`steam_id` varchar(64) PRIMARY KEY NOT NULL, `session_id` int(64) NOT NULL, `skill_hash` int(128), `skill_points` int(11))");
    // databaseTTT.Query(GenericOnSQLConnectCallback, "CREATE TABLE IF NOT EXISTS `upgrades` (`steam_id` varchar(64) PRIMARY KEY NOT NULL, `upgrade1` int(11), `upgrade2` int(11), `upgrade3` int(11), `upgrade4` int(11), `upgrade5` int(11), `upgrade6` int(11), `upgrade7` int(11), `upgrade8` int(11), `upgrade9` int(11), `upgrade10` int(11), `upgrade11` int(11), `upgrade12` int(11), `upgrade13` int(11), `upgrade14` int(11), `upgrade15` int(11), `upgrade16` int(11), `upgrade17` int(11), `upgrade18` int(11), `upgrade19` int(11), `upgrade20` int(11), `upgrade21` int(11), `upgrade22` int(11), `upgrade23` int(11), `upgrade24` int(11), `upgrade25` int(11), `upgrade26` int(11), `upgrade27` int(11), `upgrade28` int(11), `upgrade29` int(11), `upgrade30` int(11), `upgrade31` int(11), `upgrade32` int(11))");

    cookiePlayerExperience = RegClientCookie("player_experience", "Current experience player has.", CookieAccess_Private);
    cookiePlayerLevel = RegClientCookie("player_level", "Current player level.", CookieAccess_Private);
    cookieGoodActions = RegClientCookie("goodActions", "Stores the amount of good kills for a player.", CookieAccess_Protected);
    cookieBadActions = RegClientCookie("badActions", "Stores the amount of bad kills for a player.", CookieAccess_Protected);
}

public void OnClientAuthorized(int client, const char[] auth)
{
    char string[63], hash[127];
    SessionAndHash(client, string, hash);
    Populate(client);
    experienceTimers[client] = CreateTimer(1800.0, GiveExperience, client, TIMER_REPEAT);
}

public void OnClientDisconnect(int client)
{
    // Reset upgrade points for the client who just disconnected.
    for (int skill = 0; skill < 64; skill++) {
        skillPoints[client][skill] = 0;
    }

    ClearTimer(experienceTimers[client]);
}

public int Native_GetPoints(Handle plugin, int numParams)
{
    if (numParams != 2)
    {
        PrintToServer("Warning, Skills_GetPoints was not called correctly.");
        return -1;
    }

    int client = GetNativeCell(1);
    int skill = GetNativeCell(2);
    return skillPoints[client][skill];
}

public int Native_SetPoints(Handle plugin, int numParams)
{
    if (numParams != 3)
    {
        PrintToServer("Warning, Skills_SetPoints was not called correctly.");
        return;
    }

    int client = GetNativeCell(1);
    int upgrade = GetNativeCell(2);
    int points = GetNativeCell(3);
    skillPoints[client][upgrade] = points;
}

public int Native_GetLevel(Handle plugin, int numParams)
{
    if (numParams != 1)
    {
        PrintToServer("Warning, Skills_GetPoints was not called correctly.");
        return -1;
    }

    int client = GetNativeCell(1);
    return Player(client).GetCookieInt(cookiePlayerLevel, 1);
}

public int Native_SetLevel(Handle plugin, int numParams)
{
    if (numParams != 2)
    {
        PrintToServer("Warning, Skills_SetLevel was not called correctly.");
        return;
    }

    int client = GetNativeCell(1);
    int level = GetNativeCell(2);
    Player(client).SetCookieInt(cookiePlayerLevel, level);
}

public int Native_GetExperience(Handle plugin, int numParams)
{
    if (numParams != 1)
    {
        PrintToServer("Warning, Skills_GetExperience was not called correctly.");
        return -1;
    }

    int client = GetNativeCell(1);
    return Player(client).GetCookieInt(cookiePlayerExperience, 1);
}

public int Native_SetExperience(Handle plugin, int numParams)
{
    if (numParams != 2)
    {
        PrintToServer("Warning, Skills_SetExperience was not called correctly.");
        return;
    }

    int client = GetNativeCell(1);
    int experience = GetNativeCell(2);
    Player(client).SetCookieInt(cookiePlayerExperience, experience);
    CheckLevel(client);
    ShowExperienceBar(client);
}

public void TTT_OnRoundStart(int innocents, int traitors, int detective)
{
    startingInnocents = innocents;
    startingNoneTraitors = innocents + detective;
}

public void TTT_OnRoundEnd(int winner) {
    if (winner == TTT_TEAM_TRAITOR) {
        int undiscovered;
        LoopDeadClients(i) {
            if (!TTT_GetFoundStatus(i)) {
                if (TTT_GetClientRole(i) != TTT_TEAM_TRAITOR)
                {
                    undiscovered++;
                }
            }
        }

        int gainedXP = 40 * (undiscovered / startingNoneTraitors);
        LoopAliveClients(i) {
            if (TTT_GetClientRole(i) == TTT_TEAM_TRAITOR) {
                CPrintToChat(i, "{purple}[TTT] {yellow}You gained %d experience for hiding %d bodies!", gainedXP, undiscovered);
                Player(i).Experience += gainedXP;
            }
        }
    }
    else
    {
        float innocentsAlive = 0.0;
        LoopAliveClients(i)
        {
            if (TTT_GetClientRole(i) == TTT_TEAM_INNOCENT)
            {
                innocentsAlive++;
            }
        }
        int gainedXP = RoundFloat(40.0 * (innocentsAlive / startingInnocents));
        LoopAliveClients(i)
        {
            if (TTT_GetClientRole(i) == TTT_TEAM_DETECTIVE)
            {
                CPrintToChat(i, "{purple}[TTT] {yellow}You gained %d experience for keeping %d players alive!", gainedXP, innocentsAlive);
                Player(i).Experience += gainedXP;
            }
        }
    }
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if (victim == attacker || victim == 0 || attacker == 0)
    return Plugin_Continue;

    Player playerAtacker = Player(attacker);

    int alivePlayers = 0;
    LoopAliveClients(i)
    {
        alivePlayers++;
    }
    if (alivePlayers < 4)
    return Plugin_Continue;

    if (playerAtacker.BadKill(victim))
    {
        playerAtacker.Experience -= 20;
    }
    else
    {
        if (playerAtacker.Traitor)
        {
            playerAtacker.Experience += 10;
        }
        else
        {
            playerAtacker.Experience += 40;
        }
    }

    return Plugin_Continue;
}

public void TTT_OnBodyFound(int client, int victim, int[] ragdoll, bool silentID) {
    Player(client).Experience += 4;
}

public Action Command_DisplayExperience(int client, int args) {
    Player player = Player(client);

    char target[128] = "@me";
    if (args > 0) {
        GetCmdArg(1, target, sizeof(target));
    }

    Player targetPlayer = player.TargetOne(target);
    if (!targetPlayer.ValidClient) return Plugin_Handled;

    CPrintToChat(client, "{purple}[TTT] {yellow}%N currently has %d experience and is level %d.", targetPlayer.Client, targetPlayer.Experience, 1);

    return Plugin_Handled;
}

public Action Command_DisplayUpgrades(int client, int args) {
    char target[128] = "@me";
    if (args > 0) {
        GetCmdArg(1, target, sizeof(target));
    }

    //CPrintToChat(client, "{purple}[TTT] {orchid}I hate life, seriously, I do.");

    Player targetPlayer;

    targetPlayer = Player(client).TargetOne(target);
    if (!targetPlayer.ValidClient) return Plugin_Handled;

    CPrintToChat(client, "{purple}[TTT] {yellow}Upgrades for {green}%N {yellow}printed in console.", targetPlayer.Client);

    for (int skill = 0; skill < 31; skill++)
    {
        PrintToConsole(client, "Skill %d: %d", skill, targetPlayer.GetSkill(skill));
    }

    return Plugin_Handled;
}

public Action Command_SetExperience(int client, int args) {
    Player player = Player(client);
    if (player.Access(RANK_SENATOR))

    if (args != 2) {
        player.Error("Invalid command usage, expects: /setexperience <target> <experience>");
        return Plugin_Handled;
    }

    char target[128], experienceString[128];
    GetCmdArg(1, target, sizeof(target));
    GetCmdArg(2, experienceString, sizeof(experienceString));

    Player targetPlayer = player.TargetOne(target);
    if (!targetPlayer.ValidClient) return Plugin_Handled;

    int experience = StringToInt(experienceString);

    targetPlayer.Experience = experience;

    CPrintToChat(client, "{purple}[TTT] {yellow}Set experience on %N to %d.", targetPlayer.Client, experience);

    return Plugin_Handled;
}

public Action Command_SetLevel(int client, int args) {
    Player player = Player(client);

    if (args != 2) {
        player.Error("Invalid command usage, expects: /setlevel <target> <level>");
        return Plugin_Handled;
    }

    char target[128], levelString[128];
    GetCmdArg(1, target, sizeof(target));
    GetCmdArg(2, levelString, sizeof(levelString));

    Player targetPlayer = Player(client).TargetOne(target);
    if (!targetPlayer.ValidClient) return Plugin_Handled;

    int level = StringToInt(levelString);
    if (level == 0) level = 0;

    targetPlayer.Level = level;

    CPrintToChat(client, "{purple}[TTT] {yellow}Set experience on %N to %d.", targetPlayer.Client, level);

    return Plugin_Handled;
}

public Action Command_UpdateInfo(int client, int args) {
    if (args != 2) {
        if (client != 0) {
            CPrintToChat(client, "{purple}[TTT] {orchid}Invalid command usage, expects: /update_info <steam64> <hashmap>");
            return Plugin_Handled;
        }
    }

    char target[128], hashmap[255];
    GetCmdArg(1, target, sizeof(target));
    GetCmdArg(2, hashmap, sizeof(hashmap));

    Player targetPlayer = Player(client).TargetOne(target);

    if (!targetPlayer.ValidClient) {
        PrintToServer("Warning, Steam_64 not found for %s", target);
        return Plugin_Handled;
    }

    // Do some fantastic stuff with these two values here...
    PrintToServer("Update Info Called, %s %s %d", target, hashmap, targetPlayer.Client);
    Populate(targetPlayer.Client);

    return Plugin_Handled;
}

public Action Command_GetSession(int client, int args)
{
    Player player = Player(client);

    char session[63], hash[127];
    SessionAndHash(client, session, hash);
    player.Msg("Debug: Session: %s, Hash: %s", session, hash);

    return Plugin_Handled;
}

public Action Command_Populate(int client, int args)
{
    Player player = Player(client);
    Populate(client);
    player.Msg("Debug: Populating your Upgrades");
}

public Action Command_Skills(int client, int args)
{
    DisplaySkillsPage(client);

    return Plugin_Handled;
}

public Action Command_ResetSkills(int client, int args) {
    ResetSkills(client);

    return Plugin_Handled;
}

public Action GiveExperience(Handle timer, int client)
{
    Player player = Player(client);
    if (!player.ValidClient)
    {
        return Plugin_Stop;
    }

    int experience = 50;
    int team = player.Team;

    if (team == CS_TEAM_T || team == CS_TEAM_CT) {
        experience = 100;
    }


    player.Msg("Thanks for playing, you've gained %d experience!", experience);

    player.Experience += experience;

    PrintToConsole(client, "Welcome to the server!");

    return Plugin_Continue;
}

public Action Command_Profile(int client, int args)
{
    // We still need to get colours sorted out.
    Player player = Player(client);
    int goodActions = player.GoodActions;
    int badActions = player.BadActions;
    char expBar[80];
    GetExperienceBar(client, expBar);

    int goodActionPercentage = RoundFloat(float(goodActions * 100) / float(goodActions + badActions));
    // Fix for azure's report where having a 0 in the total actions will cause a very large negative percentage.
    if (goodActions + badActions < 1) { goodActionPercentage = 50; }
    char goodActionColour[32] = "{GREEN}";

    // We have nine lines to work with...
    CPrintToChat(client, "┏━━━━━━━━━━━━━ {GREEN}%.24N {DEFAULT}━━━━━━━━━━━━━━", client);
    CPrintToChat(client, "┃ Playtime: %d hours", RoundFloat(float(player.Playtime) / 3600));
    CPrintToChat(client, "┃ Karma: %d ({GREEN}+%d{DEFAULT}, {RED}-%d{DEFAULT}, %s%d%s)", player.Karma, goodActions, badActions, goodActionColour, goodActionPercentage, "%%");
    CPrintToChat(client, "┃ Level: %d (%d / %d | %d%s)", player.Level, player.Experience, player.LevelUpExperience, RoundToFloor((float(player.Experience) / float(player.LevelUpExperience - player.Experience)) * 100.0), "%%");
    CPrintToChat(client, "┃ EXP: %s", expBar);
    // CPrintToChat(client, "┃ ");
    // CPrintToChat(client, "┃ ");
    // CPrintToChat(client, "┃ ");
    CPrintToChat(client, "┗━━━━━━━━━━━━━ {GREEN}%.24N {DEFAULT}━━━━━━━━━━━━━━", client);

    return Plugin_Handled;
}

public void Populate(int client) {
    char steamId[64];
    Player player = Player(client);
    player.Auth(AuthId_SteamID64, steamId);
    DBStatement playerSkillPointsStatement = PrepareStatement(databaseTTT, "SELECT * FROM `skills` WHERE steam_id=? LIMIT 1");
    SQL_BindParamString(playerSkillPointsStatement, 0, steamId, false);
    if (!SQL_Execute(playerSkillPointsStatement)) { PrintToServer("User Skills grab failed."); return; }
    if (SQL_FetchRow(playerSkillPointsStatement)) {
        int points;
        for (int skill = 1; skill < 32; skill++) {
            points = SQL_FetchInt(playerSkillPointsStatement, skill);
            player.SetSkill(skill, points);
        }
    }
    return;
}

public void SessionAndHash(int client, char session[63], char hash[127]) {
    char steamId[64];
    Player player = Player(client);
    player.Auth(AuthId_SteamID64, steamId);
    DBStatement statement = PrepareStatement(databaseTTT, "SELECT * FROM `sessions` WHERE steam_id=?");
    SQL_BindParamString(statement, 0, steamId, false);
    if (!SQL_Execute(statement)) { PrintToServer("Session Search SQL Execute Failed..."); return; }

    if (SQL_FetchRow(statement))
    {
        // A row was found!  Return the session.
        SQL_FetchString(statement, 1, session, sizeof(session));
        SQL_FetchString(statement, 2, hash, sizeof(hash));
    }
    else
    {
        // A row was not found.  Generate the session and insert it into the DB.
        char newSession[62];
        GenerateSession(newSession);
        DBStatement insertStatement = PrepareStatement(databaseTTT, "INSERT INTO `sessions` (steam_id, session_id, skill_hash, skill_points) VALUES (?, ?, \"\", ?);");
        SQL_BindParamString(insertStatement, 0, steamId, false);
        SQL_BindParamString(insertStatement, 1, newSession, false);
        SQL_BindParamInt(insertStatement, 2, player.Level, false);
        if (!SQL_Execute(insertStatement)) { PrintToServer("Session Set SQL Execute Failed..."); return; }
    }

    return;
}

public void DisplayUrl(int client, char url[512], bool display) {
    char web_url[512];
    Crypt_Base64Encode(url, web_url, sizeof(web_url));

    char buffer[512];
    if (websitePayload[client]) {
        Format(buffer, sizeof(buffer), "http://clwo.inilo.net/webredirect/payload/direct.php?website=%s", web_url);
        }
    else {
        Format(buffer, sizeof(buffer), "http://clwo.eu/webredirect/payload/direct.php?website=%s", web_url);
    }

    websitePayload[client] = !websitePayload[client];

    ShowMOTDPanel(client, "Displaying Page...", buffer, MOTDPANEL_TYPE_URL);
    if (display) {
        CPrintToChat(client, "{purple}[URL] {yellow}Loading {green}%s", url);
    }
}

    public void DisplaySkillsPage(int client) {
        char url[512], session[63], hash[127];
        SessionAndHash(client, session, hash);
        Format(url, sizeof(url), "http://ttt.clwo.eu:3000/#^%s^%s", hash, session);
        DisplayUrl(client, url, true);
        PrintToConsole(client, "Opening: %s", url);
    }

    public void ResetSkills(int client) {
        char auth[64], query[255];
        Player(client).Auth(AuthId_SteamID64, auth);
        FormatEx(query, sizeof(query), "DELETE FROM `sessions` WHERE `steam_id`=\"%s\"", auth);
        PrintToServer("Running query: %s", query);
        SQL_FastQuery(databaseTTT, query);
    }

    public void CheckLevel(int client)
    {
        Player player = view_as<Player>(client);
        if (player.Experience > player.LevelUpExperience)
        {
            player.Experience -= player.LevelUpExperience;
            int newLevel = player.Level + 1;
            player.Level = newLevel;
            CPrintToChat(client, "{purple}[TTT] {green}Congratulations!  You've leveled up to level %d", newLevel);

            char msg[255];
            Format(msg, sizeof(msg), "You are now lvl %i.", newLevel);

            Panel lvlPanel = new Panel();
            lvlPanel.SetTitle("Level Up!");
            lvlPanel.DrawItem("", ITEMDRAW_SPACER);
            lvlPanel.DrawText(msg);
            lvlPanel.DrawText("You have gained a skill point to use in /skills.");
            lvlPanel.DrawItem("", ITEMDRAW_SPACER);
            lvlPanel.CurrentKey = GetMaxPageItems(lvlPanel.Style);
            lvlPanel.DrawItem("Exit", ITEMDRAW_CONTROL);

            lvlPanel.Send(client, HandlerDoNothing, 10);

            ClientCommand(client, "play */ttt_clwo/ttt_levelup.mp3");

            char auth[64], query[255];
            player.Auth(AuthId_SteamID64, auth);
            FormatEx(query, sizeof(query), "UPDATE `sessions` SET `skill_points` = %d WHERE `steam_id` = \"%s\"", newLevel, auth);
            PrintToServer("Running query: %s", query);
            if (!SQL_FastQuery(databaseTTT, query))
            {
                char error[255];
                SQL_GetError(databaseTTT, error, sizeof(error));
                PrintToServer("Failed to query (error: %s)", error);
            }
        }
    }

    public void ShowExperienceBar(int client)
    {
        char unicodeBar[80];
        char introduction[100] = "Exp: ";
        GetExperienceBar(client, unicodeBar);
        StrCat(introduction, sizeof(introduction), unicodeBar);
        Handle hHudText = CreateHudSynchronizer();
        SetHudTextParams(0.01, 0.01, 5.0, 255, 128, 0, 255, 0, 0.0, 0.0, 0.0);
        ShowSyncHudText(client, hHudText, introduction);
        CloseHandle(hHudText);
    }

    public void GetExperienceBar(int client, char unicodeBar[80])
    {
        Player player = Player(client);

        const int barSize = 80;
        const int numBars = 20;

        float levelUpPercentage = float(player.Experience) / float(player.LevelUpExperience);
        int colouredSquares = RoundFloat(numBars * levelUpPercentage);

        for (int i = 0; i < numBars; i++) {
            if (i <= colouredSquares) {
                StrCat(unicodeBar, barSize, "▰");
            }
            else {
                StrCat(unicodeBar, barSize, "▱");
            }
        }
    }

    public void GenerateSession(char newSession[62]) {
        int randomIndex;
        for (int i = 0; i < 60; i++) {
            randomIndex = GetRandomInt(0, 61);
            Format(newSession, sizeof(newSession), "%s%c", newSession, chars[randomIndex]);
        }
    }
