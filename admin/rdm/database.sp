public void DbCallback_Connect(Database db, const char[] error, any data)
{
    if (db == null)
    {
        PrintToServer("DbCallback_Connect: %s", error);
        return;
    }

    g_database = db;
    g_database.SetCharset("utf8");
    Db_SelectLastDeathIndex();
    g_currentRound = TTT_GetRoundID();
}

public void Db_InsertDeath(int victim, int attacker)
{
    int victimId = GetSteamAccountID(victim);
    int victimRole = TTT_GetClientRole(victim);
    char sVictimRole[10] = "none";
    RoleEnum(sVictimRole, sizeof(sVictimRole), victimRole);

    int attackerId = GetSteamAccountID(attacker);
    int attackerRole = TTT_GetClientRole(attacker);
    char sAttackerRole[10] = "none";
    RoleEnum(sAttackerRole, sizeof(sAttackerRole), attackerRole);

    char query[768];
    Format(
        query, sizeof(query), "INSERT INTO `deaths` (`death_index`, `death_time`, `victim_id`, `victim_role`, `attacker_id`, `attacker_role`, `last_gun_fire`, `round`) VALUES ('%d', '%d', '%d', '%s', '%d', '%s', '%d', '%d');",
        ++g_lastDeathIndex, GetTime(), victimId, sVictimRole, attackerId, sAttackerRole, g_playerData[victim].lastGunFired, g_currentRound);
    g_database.Query(DbCallback_InsertDeath, query);
}

public void DbCallback_InsertDeath(Database db, DBResultSet results, const char[] error, any data)
{
    if (results == null)
    {
        LogError("DbCallback_InsertDeath: %s", error);
        return;
    }
}

public void Db_InsertHandle(int client, int death)
{
    CPrintToChatAdmins(ADMFLAG_GENERIC, TTT_MESSAGE ... "{yellow}%N {default}has taken an RDM case.", client);

    int accountID = GetSteamAccountID(client);

    char query[768];
    Format(query, sizeof(query), "INSERT INTO `handles` (`death_index`, `admin_id`) VALUES ('%d', '%d');", death, accountID);
    g_database.Query(DbCallback_InsertHandle, query, GetClientUserId(client));
}

public void DbCallback_InsertHandle(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        LogError("DbCallback_InsertHandle: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    Db_SelectCaseBaseInfo(client);
}

public void Db_InsertReport(int client, int death, CaseChoice punishment)
{
    char sPunishment[5] = "none";
    if (punishment == CaseChoice_Slay)
    {
        sPunishment = "slay";
    }
    else if (punishment == CaseChoice_Warn)
    {
        sPunishment = "warn";
    }

    char query[768];
    Format(query, sizeof(query), "INSERT INTO `reports` (`death_index`, `punishment`) VALUES ('%d', '%s');", g_playerData[client].currentDeath, sPunishment);
    g_database.Query(DbCallback_InsertReport, query, GetClientUserId(client));
}

public void DbCallback_InsertReport(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        LogError("DbCallback_InsertReport: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    CPrintToChat(client, TTT_MESSAGE ... "Thanks for submitting a case, a staff member shall be in contact shortly.");

    CPrintToChatAdmins(ADMFLAG_GENERIC, TTT_MESSAGE ... "{yellow}%N {default}opened a new RDM case.", client);

    Db_SelectCaseCount();
}

public void Db_SelectLastDeathIndex()
{
    g_database.Query(DbCallback_SelectLastDeathIndex, "SELECT MAX(`death_index`) FROM `deaths`;");
}

public void DbCallback_SelectLastDeathIndex(Database db, DBResultSet results, const char[] error, any data)
{
    if (results == null)
    {
        PrintToServer("DbCallback_SelectLastDeathIndex: %s", error);
        return;
    }

    if (results.FetchRow())
    {
        g_lastDeathIndex = results.FetchInt(0);
    }
    else
    {
        g_lastDeathIndex = 0;
    }
}

public void Db_SelectCaseCount()
{
    char query[768];
    Format(query, sizeof(query), "SELECT COUNT(*) AS `case_count` FROM `open_cases`;");
    g_database.Query(DbCallback_SelectCaseCount, query);
}

public void DbCallback_SelectCaseCount(Database db, DBResultSet results, const char[] error, any data)
{
    if (results == null)
    {
        LogError("DbCallback_SelectCaseCount: %s", error);
        return;
    }

    if (results.FetchRow())
    {
        int caseCount = results.FetchInt(0);
        if (caseCount < 1)
        {
            CPrintToChatAdmins(ADMFLAG_GENERIC, TTT_MESSAGE ... "There are currently no unhandled cases.");
        }
        else if (caseCount < 2)
        {
            CPrintToChatAdmins(ADMFLAG_GENERIC, TTT_MESSAGE ... "There is now {orange}%d {default}unhandled case.", caseCount);
        }
        else
        {
            CPrintToChatAdmins(ADMFLAG_GENERIC, TTT_MESSAGE ... "There are now {orange}%d {default}unhandled cases.", caseCount);
        }
    }
}

public void Db_SelectNextCase(int client)
{
    char query[128];
    Format(query, sizeof(query), "SELECT `death_index` FROM `open_cases` ORDER BY `death_index` ASC LIMIT 1;");
    g_database.Query(DbCallback_SelectNextCase, query, GetClientUserId(client));
}

public void DbCallback_SelectNextCase(Database db, DBResultSet results, const char[] error, int userid) {
    if (results == null)
    {
        LogError("DbCallback_SelectNextCase: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if (results.FetchRow())
    {
        int death = results.FetchInt(0);
        Db_InsertHandle(client, death);
        g_playerData[client].currentCase = death;
        Db_SelectInfo(client)
    }
    else
    {
        CPrintToChat(client, TTT_ERROR ... "There are currently no available cases.");
    }
}

public void Db_SelectClientDeaths(int client)
{
    int accountID = GetSteamAccountID(client);

    char query[768];
    Format(query, sizeof(query), "SELECT `death_index`, `attacker_name`, `round` FROM `death_info` WHERE `victim_id` = '%d' ORDER BY `death_time`  DESC LIMIT 10;", accountID);
    g_database.Query(DbCallback_SelectClientDeaths, query, GetClientUserId(client));
}

public void DbCallback_SelectClientDeaths(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        LogError("DbCallback_SelectClientDeaths: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    Menu rdmMenu = new Menu(MenuHandler_RDM);
    rdmMenu.SetTitle("Please select the death you would like to report.");
    while(results.FetchRow())
    {
        int death;
        int roundNumber;
        char name[64];
        char info[8];
        char message[192];

        death = results.FetchInt(0);
        results.FetchString(1, name, sizeof(name));
        roundNumber = results.FetchInt(2);

        IntToString(death, info , 8);
        Format(message, sizeof(message), "%s (%i rounds ago)", name, g_currentRound - roundNumber);
        rdmMenu.AddItem(info, message);
    }

    rdmMenu.Display(client, 240);
}

public void Db_SelectCaseBaseInfo(int client)
{
    char query[768];
    Format(query, sizeof(query), "SELECT `death_index`, `victim_name`, `attacker_name` FROM `case_info` WHERE `death_index` = '%d';", g_playerData[client].currentCase);
    g_database.Query(DbCallback_SelectCaseBaseInfo, query, GetClientUserId(client));
}

public void DbCallback_SelectCaseBaseInfo(Database db, DBResultSet results, const char[] error, int userid) {
    if (results == null)
    {
        LogError("DbCallback_SelectCaseBaseInfo: %s", error);
        return;
    }

    if (results.FetchRow())
    {
        int client = GetClientOfUserId(userid);
        int death = results.FetchInt(0);
        char victimName[64]; results.FetchString(1, victimName, sizeof(victimName));
        char attackerName[64]; results.FetchString(2, attackerName, sizeof(attackerName));

        CPrintToChat(client, TTT_MESSAGE ... "You have taken case {orange}#%d: {yellow}%s's {default}accusing {yellow}%s of RDM.", death, victimName, attackerName);
    }
}

public void Db_SelectInfo(int client)
{
    char query[768];
    Format(query, sizeof(query), "SELECT `death_index`, `death_time`, `victim_name`, `victim_role`+0, `victim_karma`, `attacker_name`, `attacker_role`+0, `attacker_karma`, `last_gun_fire`, `round` FROM `case_info` WHERE `death_index` = '%d';", g_playerData[client].currentCase);
    g_database.Query(DbCallback_SelectInfo, query, GetClientUserId(client));
}

public void DbCallback_SelectInfo(Database db, DBResultSet results, const char[] error, int userid) {
    if (results == null)
    {
        LogError("DbCallback_SelectInfo: %s", error);
        return;
    }

    if (results.FetchRow())
    {
        int client = GetClientOfUserId(userid);

        int death = results.FetchInt(0);
        int time = results.FetchInt(1);
        char victimName[64]; results.FetchString(2, victimName, sizeof(victimName));
        Role victimRole = view_as<Role>(results.FetchInt(3));
        int victimKarma = results.FetchInt(4);
        char attackerName[64]; results.FetchString(5, attackerName, sizeof(attackerName));
        Role attackerRole = view_as<Role>(results.FetchInt(6));
        int attackerKarma = results.FetchInt(7);
        int lastshot = results.FetchInt(8);
        int round = results.FetchInt(9);

        char sVictimRole[16];
        RoleString(sVictimRole, sizeof(sVictimRole), victimRole);

        char sAttackerRole[16];
        RoleString(sAttackerRole, sizeof(sAttackerRole), attackerRole);

        CPrintToChat(client, TTT_MESSAGE ... "Case information for Death: {orange}%d{default}({orange}%d {default}rounds ago)", death, g_currentRound - round);
        CPrintToChat(client, TTT_MESSAGE ... "The victim had shot last {orange}%d {default}seconds before there death.", time - lastshot);
        CPrintToChat(client, TTT_MESSAGE ... "Accuser: {yellow}%s{default}({orange}%d{default}) - %s", victimName, victimKarma, sVictimRole);
        CPrintToChat(client, TTT_MESSAGE ... "Accused: {yellow}%s{default}({orange}%d{default}) - %s", attackerName, attackerKarma, sAttackerRole);
    }
}

public void Db_SelectVerdictInfo(int client, int death)
{
    char query[256];
    Format(query, sizeof(query), "SELECT `death_index`, `victim_id`, `victim_name`, `attacker_id`, `attacker_name`, `punishment`+0, `verdict`+0 FROM `case_info` WHERE `death_index` = '%d';", death);
    g_database.Query(DbCallback_SelectVerdictInfo, query, GetClientUserId(client));
}

public void DbCallback_SelectVerdictInfo(Database db, DBResultSet results, const char[] error, int userid) {
    if (results == null)
    {
        LogError("DbCallback_SelectVerdictInfo: %s", error);
        return;
    }

    if (results.FetchRow())
    {
        int client = GetClientOfUserId(userid);

        int death = results.FetchInt(0);
        int victimID = results.FetchInt(1);
        char victimName[64]; results.FetchString(2, victimName, sizeof(victimName));
        int attackerID = results.FetchInt(3);
        char attackerName[64]; results.FetchString(4, attackerName, sizeof(attackerName));
        CaseChoice punishment = view_as<CaseChoice>(results.FetchInt(5));
        CaseVerdict verdict = view_as<CaseVerdict>(results.FetchInt(6));

        int victim = GetClientOfAccountID(victimID);
        int attacker = GetClientOfAccountID(attackerID);

        if (verdict == CaseVerdict_Innocent)
        {
            if (IsValidClient(victim))
            {
                CPrintToChat(victim, TTT_MESSAGE ... "{yellow}%N {default}has handled your case against {yellow}%s {default}and has concluded them to be {green}innocent{default}, if you have any questions please message staff using an @ before your message or /chat.", client, attackerName);
            }
            if (IsValidClient(attacker))
            {
                CPrintToChat(attacker, TTT_MESSAGE ... "{yellow}%N {default}has found you {green}innocent {default}in your defense against {yellow}%s{default}, have a nice day.", client, victimName);
            }
            CPrintToChat(client, TTT_MESSAGE ... "You have concluded the defendant {green}innocent {default}for case {orange}%d", death);
        }
        else if (verdict == CaseVerdict_Guilty)
        {
            if (IsValidClient(victim))
            {
                CPrintToChat(victim, TTT_MESSAGE ... "{yellow}%N {default}has handled your case against {yellow}%s {defalt}and has concluded them to be {red}guilty{default}. Thanks for your report.", client, attackerName);
            }
            if (IsValidClient(attacker))
            {
                if (punishment == CaseChoice_Slay)
                {
                    CPrintToChat(attacker, TTT_MESSAGE ... "You are being slayed next round by {yellow}%N {default}for killing {yellow}%s{default}. If you have any questions about this please message staff by using an @ before your message.", client, victimName);
                    TTT_AddRoundSlays(attacker, 1, false);
                }
                else if (punishment == CaseChoice_Warn)
                {
                    CPrintToChat(attacker, TTT_MESSAGE ... "You have been found guilty of RDM by {yellow}%N {default}for killing {yellow}%s {default}further action may be taken. If you have any questions about this please message staff by using an @ before your message or /chat.", client, victimName);
                }
            }
            CPrintToChat(client, TTT_MESSAGE ... "You have concluded the defendant {red}guilty {default}for case {orange}%d.", death);
        }
    }
}

public void Db_UpdateVerdict(int client, int death, CaseVerdict verdict)
{
    char sVerdict[9] = "none";
    if (verdict == CaseVerdict_Innocent)
    {
        sVerdict = "innocent";
    }
    else if (verdict == CaseVerdict_Guilty)
    {
        sVerdict = "guilty";
    }

    char query[768];
    Format(query, sizeof(query), "UPDATE `handles` SET `handles`.`verdict` = '%s' WHERE `death_index` = '%d';", sVerdict, death);
    g_database.Query(DbCallback_UpdateVerdict, query, GetClientUserId(client));
}

public void DbCallback_UpdateVerdict(Database db, DBResultSet results, const char[] error, int userid) {
    if (results == null)
    {
        LogError("DbCallback_UpdateVerdict: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    Db_SelectVerdictInfo(client, g_playerData[client].currentCase);

    g_playerData[client].currentCase = -1;
}
