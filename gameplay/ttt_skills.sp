#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <ttt>
#include <colorvariables>
#include <generics>
#include <mostactive>
#include <ttt_actions>

public Plugin myinfo =
{
    name = "TTT Skills",
    author = "Popey & c0rp3n",
    description = "TTT Upgrades and Skills.",
    version = "1.0.0",
    url = ""
};

Database skillsDb;

int playerSkills[MAXPLAYERS + 1][32];
int playerExperience[MAXPLAYERS + 1];
int playerLevels[MAXPLAYERS + 1];
int playerSkillPoints[MAXPLAYERS + 1];

Handle experienceTimers[MAXPLAYERS + 1];

bool skills[32];
char skillNames[32][100];
char skillDescriptions[32][192];
int skillMaxPoints[32];

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    RegPluginLibrary("ttt_skills");

    CreateNative("Skills_RegisterSkill", Native_RegisterSkill);

    CreateNative("Skills_GetPoints", Native_GetPoints);
    CreateNative("Skills_GetLevel", Native_GetLevel);
    CreateNative("Skills_GetExperience", Native_GetExperience);
    CreateNative("Skills_AddExperience", Native_AddExperience);
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    CacheFiles();
    RegisterCmds();

    HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Post);
    Database.Connect(DbCallback, "skills");

    PrintToServer("[SKL] Loaded succcessfully");
}

public void CacheFiles()
{
    AddFileToDownloadsTable("sound/ttt_clwo/ttt_levelup.mp3");
}

public void RegisterCmds()
{
    RegConsoleCmd("sm_skills", Command_Skills, "Opens the skill menu");
    RegConsoleCmd("sm_skill", Command_Skills, "Opens the skill menu");
    RegConsoleCmd("sm_reset_skills", Command_ResetSkills, "Reset all skills");

    RegConsoleCmd("sm_profile", Command_Profile, "Shows a players profile.");
}

public void DbCallback(Database db, const char[] error, any data) {
    if (db == null) {
        LogError("DbCallback: %s", error);
        return;
    }

    skillsDb = db;

    skillsDb.SetCharset("utf8");
    LoopValidClients(i)
    {
        char steamId[32];
        GetClientAuthId(i, AuthId_Steam2, steamId, 32);

        char query[768];
        skillsDb.Format(query, sizeof(query), "SELECT `level`, `experience`, `points`, `skill_0`, `skill_1`, `skill_2`, `skill_3`, `skill_4`, `skill_5`, `skill_6`, `skill_7`, `skill_8`, `skill_9`, `skill_10`, `skill_11`, `skill_12`, `skill_13`, `skill_14`, `skill_15`, `skill_16`, `skill_17`, `skill_18`, `skill_19`, `skill_20`, `skill_21`, `skill_22`, `skill_23`, `skill_24`, `skill_25`, `skill_26`, `skill_27`, `skill_28`, `skill_29`, `skill_30`, `skill_31` FROM `skills` WHERE `auth_id` REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;", steamId[8]);
        skillsDb.Query(SelectSkillsCallback, query, i);
    }
}

public void OnClientAuthorized(int client, const char[] auth)
{
    experienceTimers[client] = CreateTimer(1800.0, Timer_GiveExperience, client, TIMER_REPEAT);

    char steamId[32];
    GetClientAuthId(client, AuthId_Steam2, steamId, 32);

    char query[768];
    skillsDb.Format(query, sizeof(query), "SELECT `level`, `experience`, `points`, `skill_0`, `skill_1`, `skill_2`, `skill_3`, `skill_4`, `skill_5`, `skill_6`, `skill_7`, `skill_8`, `skill_9`, `skill_10`, `skill_11`, `skill_12`, `skill_13`, `skill_14`, `skill_15`, `skill_16`, `skill_17`, `skill_18`, `skill_19`, `skill_20`, `skill_21`, `skill_22`, `skill_23`, `skill_24`, `skill_25`, `skill_26`, `skill_27`, `skill_28`, `skill_29`, `skill_30`, `skill_31` FROM `skills` WHERE `auth_id` REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;", steamId[8]);
    skillsDb.Query(SelectSkillsCallback, query, client);
}

public void OnClientDisconnect(int client)
{
    // Reset upgrade points for the client who just disconnected.
    for (int skill = 0; skill < 32; skill++)
    {
        playerSkills[client][skill] = 0;
    }

    ClearTimer(experienceTimers[client]);
}

public Action Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    LoopValidClients(i)
    {
        char steamId[32];
        GetClientAuthId(i, AuthId_Steam2, steamId, 32);

        char query[768];
        skillsDb.Format(
            query, sizeof(query), "UPDATE `skills` SET `level` = '%d', `experience` = '%d', `points` = '%d', `skill_0` = '%d', `skill_1` = '%d', `skill_2` = '%d', `skill_3` = '%d', `skill_4` = '%d', `skill_5` = '%d', `skill_6` = '%d', `skill_7` = '%d', `skill_8` = '%d', `skill_9` = '%d', `skill_10` = '%d', `skill_11` = '%d', `skill_12` = '%d', `skill_13` = '%d', `skill_14` = '%d', `skill_15` = '%d', `skill_16` = '%d', `skill_17` = '%d', `skill_18` = '%d', `skill_19` = '%d', `skill_20` = '%d', `skill_21` = '%d', `skill_22` = '%d', `skill_23` = '%d', `skill_24` = '%d', `skill_25` = '%d', `skill_26` = '%d', `skill_27` = '%d', `skill_28` = '%d', `skill_29` = '%d', `skill_30` = '%d', `skill_31` = '%d' WHERE `auth_id` REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;",
            playerLevels[i], playerExperience[i], playerSkillPoints[i],
            playerSkills[i][0], playerSkills[i][1], playerSkills[i][2], playerSkills[i][3], playerSkills[i][4],
            playerSkills[i][5], playerSkills[i][6], playerSkills[i][7], playerSkills[i][8], playerSkills[i][9],
            playerSkills[i][10], playerSkills[i][11], playerSkills[i][12], playerSkills[i][13], playerSkills[i][14],
            playerSkills[i][15], playerSkills[i][16], playerSkills[i][17], playerSkills[i][18], playerSkills[i][19],
            playerSkills[i][20], playerSkills[i][21], playerSkills[i][22], playerSkills[i][23], playerSkills[i][24],
            playerSkills[i][25], playerSkills[i][26], playerSkills[i][27], playerSkills[i][28], playerSkills[i][29],
            playerSkills[i][30], playerSkills[i][31],
            steamId[8]
        );
        skillsDb.Query(UpdateSkillsCallback, query);
    }
}

public void TTT_OnBodyFound(int client, int victim, const char[] deadPlayer, bool silentID)
{
    playerExperience[client] += 4;
    CheckLevel(client);
}

public Action Timer_GiveExperience(Handle timer, int client)
{
    if (!IsValidClient(client))
    {
        return Plugin_Stop;
    }

    int experience = 50;
    int team = GetClientTeam(client);

    if (team == CS_TEAM_T || team == CS_TEAM_CT) {
        experience = 100;
    }


    CPrintToChat(client, "{purple}[TTT] {yellow}Thanks for playing, you've gained {green}%d {yellow}experience!", experience);
    playerExperience[client] += experience;
    CheckLevel(client);

    return Plugin_Continue;
}

public void SelectSkillsCallback(Database db, DBResultSet results, const char[] error, int client)
{
    if (results == null) {
        LogError("FetchSkillsCallback: %s", error);
        return;
    }

    if (results.FetchRow())
    {
        playerLevels[client] = results.FetchInt(0);
        playerExperience[client] = results.FetchInt(1);
        playerSkillPoints[client] = results.FetchInt(2);

        for (int i = 0; i < 32; i++)
        {
            playerSkills[client][3] = results.FetchInt(3 + i);
        }
    }
    else
    {
        playerLevels[client] = 0;
        playerExperience[client] = 0;
        playerSkillPoints[client] = 0;
        for (int i = 0; i < 32; i++)
        {
            playerSkills[client][i] = 0;
        }

        char steamId[32];
        GetClientAuthId(client, AuthId_Steam2, steamId, 32);

        char query[768];
        skillsDb.Format(query, sizeof(query), "INSERT INTO `skills` (`id`, `auth_id`, `level`, `experience`, `points`, `skill_0`, `skill_1`, `skill_2`, `skill_3`, `skill_4`, `skill_5`, `skill_6`, `skill_7`, `skill_8`, `skill_9`, `skill_10`, `skill_11`, `skill_12`, `skill_13`, `skill_14`, `skill_15`, `skill_16`, `skill_17`, `skill_18`, `skill_19`, `skill_20`, `skill_21`, `skill_22`, `skill_23`, `skill_24`, `skill_25`, `skill_26`, `skill_27`, `skill_28`, `skill_29`, `skill_30`, `skill_31`) VALUES (NULL, '%s', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0');", steamId);
        skillsDb.Query(InsertSkillsCallback, query);
    }
}

public void InsertSkillsCallback(Database db, DBResultSet results, const char[] error, int client)
{
    if (results == null) {
        LogError("InsertSkillsCallback: %s", error);
        return;
    }
}

public void UpdateSkillsCallback(Database db, DBResultSet results, const char[] error, int client)
{
    if (results == null) {
        LogError("UpdateSkillsCallback: %s", error);
        return;
    }
}

public Action Command_Skills(int client, int args)
{
    SkillsPanel(client);

    return Plugin_Handled;
}

public Action Command_ResetSkills(int client, int args)
{
    playerSkillPoints[client] = playerLevels[client] - 1;
    for (int i = 0; i < 32; i++)
    {
        playerSkills[client][i] = 0;
    }

    return Plugin_Handled;
}

public Action Command_Profile(int client, int args)
{
    int goodActions = Actions_GetGoodActions(client);
    int badActions = Actions_GetBadActions(client);
    int goodActionPercentage = RoundFloat(float(goodActions * 100) / float(goodActions + badActions));
    if (goodActions + badActions < 1) { goodActionPercentage = 50; }

    int levelUpExperience = LevelUpExperience(playerLevels[client]);

    char expBar[80];
    GetExperienceBar(client, expBar);

    CPrintToChat(client, "┏━━━━━━━━━━━━━ {GREEN}%.24N {DEFAULT}━━━━━━━━━━━━━━", client);
    CPrintToChat(client, "┃ Playtime: %d hours", RoundFloat(float(MostActive_GetPlayTimeTotal(client)) / 3600));
    CPrintToChat(client, "┃ Karma: %d ({GREEN}+%d{DEFAULT}, {RED}-%d{DEFAULT}, %d%%)", TTT_GetClientKarma(client), goodActions, badActions, goodActionPercentage);
    CPrintToChat(client, "┃ Level: %d (%d / %d | %d%%)", playerLevels[client], playerExperience[client], levelUpExperience, RoundToFloor((float(playerExperience[client]) / float(levelUpExperience - playerExperience[client])) * 100.0));
    CPrintToChat(client, "┃ EXP: %s", expBar);
    // CPrintToChat(client, "┃ ");
    // CPrintToChat(client, "┃ ");
    // CPrintToChat(client, "┃ ");
    CPrintToChat(client, "┗━━━━━━━━━━━━━ {GREEN}%.24N {DEFAULT}━━━━━━━━━━━━━━", client);

    return Plugin_Handled;
}

public void CheckLevel(int client)
{
    if (playerExperience[client] > LevelUpExperience(playerLevels[client]))
    {
        playerLevels[client]++;
        playerSkillPoints[client]++;
        CPrintToChat(client, "{purple}[TTT] {yellow}Congratulations!  You've leveled up to lvl {green}%d!", playerLevels[client]);
        ClientCommand(client, "play */ttt_clwo/ttt_levelup.mp3");
    }
}

public int LevelUpExperience(int level)
{
    if (level - 1 > 0)
    {
        return RoundToFloor(600 * Pow(2.0, (float(level - 1) / 4.0)));
    }

    return 600;
}

public void GetExperienceBar(int client, char unicodeBar[80])
{
    const int barSize = 80;
    const int numBars = 20;

    float levelUpPercentage = float(playerLevels[client]) / float(LevelUpExperience(playerLevels[client]));
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

public void SkillsPanel(int client)
{
    Menu skillsMenu = new Menu(MenuHandler_Skills);
    skillsMenu.SetTitle("Skills");
    for (int i = 0; i < 32; i++)
    {
        if (skills[i])
        {
            char info[8];
            char message[192];
            IntToString(i, info, 8);
            Format(message, 192, "%s (Rank: %d)", skillNames[i], playerSkills[client][i]);
            skillsMenu.AddItem(info, message);
        }
    }
}

public void SkillInfoPanel(int client, int skill)
{
    Panel infoPanel = new Panel();
    infoPanel.SetTitle(skillNames[skill]);
    infoPanel.DrawItem("", ITEMDRAW_SPACER);

    char currentStats[100];
    Format(currentStats, 100, "Rank: %d/%d", playerSkills[client][skill], skillMaxPoints[skill]);
    infoPanel.DrawText(currentStats);
    infoPanel.DrawText(skillDescriptions[skill]);
    infoPanel.DrawItem("", ITEMDRAW_SPACER);
    infoPanel.CurrentKey = GetMaxPageItems(infoPanel.Style);
    if (playerSkillPoints[client] > 0)
    {
        if (playerSkills[client][skill] > 0)
        {
            infoPanel.DrawItem("Upgrade", ITEMDRAW_CONTROL);
        }
        else
        {
            infoPanel.DrawItem("Unlock", ITEMDRAW_CONTROL);
        }

        infoPanel.DrawItem("No", ITEMDRAW_CONTROL);
    }
    else
    {
        infoPanel.DrawItem("Back", ITEMDRAW_CONTROL);
        infoPanel.DrawItem("Exit", ITEMDRAW_CONTROL);
    }

    infoPanel.Send(client, MenuHandler_SkillInfo, 240);
    delete infoPanel;
}

public int MenuHandler_Skills(Menu menu, MenuAction action, int client, int item)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            SkillInfoPanel(client, item);
        }
    }
}

public int MenuHandler_SkillInfo(Menu menu, MenuAction action, int client, int item)
{
    switch (action)
    {
        case MenuAction_Select:
        {

        }
    }
}

public int Native_RegisterSkill(Handle plugin, int numParams)
{
    if (numParams != 4)
    {
        PrintToServer("Warning, Skills_RegisterSkill was not called correctly.");
        return;
    }

    int skill = GetNativeCell(1);
    skills[skill] = true;
    GetNativeString(2, skillNames[skill], 100);
    GetNativeString(3, skillDescriptions[skill], 192);
    skillMaxPoints[skill] = GetNativeCell(4);
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
    return playerSkills[client][skill];
}

public int Native_GetLevel(Handle plugin, int numParams)
{
    if (numParams != 1)
    {
        PrintToServer("Warning, Skills_GetPoints was not called correctly.");
        return -1;
    }

    int client = GetNativeCell(1);
    return playerLevels[client];
}

public int Native_GetExperience(Handle plugin, int numParams)
{
    if (numParams != 1)
    {
        PrintToServer("Warning, Skills_GetExperience was not called correctly.");
        return -1;
    }

    int client = GetNativeCell(1);
    return playerExperience[client];
}

public int Native_AddExperience(Handle plugin, int numParams)
{
    if (numParams != 2)
    {
        PrintToServer("Warning, Native_AddExperience was not called correctly.");
        return;
    }

    int client = GetNativeCell(1);
    int experience = GetNativeCell(2);
    playerExperience[client] = playerExperience[client] + experience;
    CheckLevel(client);
}
