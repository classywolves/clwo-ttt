#if defined _rdm_db_included
#endinput
#endif
#define _rdm_db_included

#include <generics>

#define CASE_CHOICE_NONE            0
#define CASE_CHOICE_SLAY            1
#define CASE_CHOICE_WARN            2

#define CASE_VERDICT_NONE 			0
#define CASE_VERDICT_INNOCENT 		1
#define CASE_VERDICT_GUILTY 		2

Database rdmDb;
bool rdmConnected;

int currentRound;
int lastDeathIndex;

int lastGunFired[MAXPLAYERS + 1] = { 0, ... };
int currentCase[MAXPLAYERS + 1] = { -1, ... };

public void RdmInit() {
    Database.Connect(RdmCallback, "rdm");
}

public void RdmCallback(Database db, const char[] error, any data) {
    if (db == null) {
        LogError("RdmCallback: %s", error);
        return;
    }

    rdmDb = db;
    rdmConnected = true;

    rdmDb.SetCharset("utf8");
    rdmDb.Query(RdmFetchLastDeathIndex, "SELECT MAX(`death_index`) FROM `deaths`;");
    rdmDb.Query(RdmFetchLastRoundIndex, "SELECT MAX(`round_no`) FROM `deaths`;");
}

public void RdmDeathInsert(int victim, int victimKarma, int attacker, int attackerKarma) {
    if (!rdmConnected) {
        return;
    }

    char query[768];

    char victimName[64];
    char victimId[64];
    int victimRole;
    Player playerVictim = Player(victim);
    playerVictim.Name(victimName);
    playerVictim.Auth(AuthId_Steam2, victimId);
    victimRole = playerVictim.Role;

    char attackerName[64];
    char attackerId[64];
    int attackerRole;
    Player playerAttacker = Player(attacker);
    playerAttacker.Name(attackerName);
    playerAttacker.Auth(AuthId_Steam2, attackerId);
    attackerRole = playerAttacker.Role;

    rdmDb.Format(query, sizeof(query), "INSERT INTO `deaths` (`death_index`, `death_time`, `victim_name`, `victim_id`, `victim_role`, `victim_karma`, `killer_name`, `killer_id`, `killer_role`, `killer_karma`, `last_gun_fire`, `round_no`, `reported_death`) VALUES ('%d', '%d', '%s', '%s', '%d', '%d', '%s', '%s', '%d', '%d', '%d', '%d', '0');",
    ++lastDeathIndex, GetTime(), victimName, victimId, victimRole, victimKarma, attackerName, attackerId, attackerRole, attackerKarma, lastGunFired[victim], currentRound);

    rdmDb.Query(RdmDeathInsertCallback, query);
}

public void RdmDeathInsertCallback(Database db, DBResultSet results, const char[] error, int data) {
    if (results == null) {
        LogError("RdmGetLastDeathsCallback: %s", error);
    }
}

public void RdmGetLastDeathsCallback(Database db, DBResultSet results, const char[] error, int client) {
    if (results == null) {
        LogError("RdmGetLastDeathsCallback: %s", error);
    }

    Menu rdmMenu = new Menu(MenuHandler_RDM);
    rdmMenu.SetTitle("Please select the death you would like to report.");
    while(results.FetchRow()) {
        int deathIndex;
        int roundNumber;
        char name[64];
        char info[8];
        char message[128];

        deathIndex = results.FetchInt(0);
        roundNumber = results.FetchInt(1);
        results.FetchString(2, name, 64);

        IntToString(deathIndex, info , 8);
        Format(message, sizeof(message), "%s (%i rounds ago)", name, currentRound - roundNumber);
        rdmMenu.AddItem(info, message);
    }

    rdmMenu.Display(client, 240);
}

public void RdmReportCallback(Database db, DBResultSet results, const char[] error, int data) {
    if (results == null) {
        LogError("RdmReportCallback: %s", error);
        return;
    }
}

public void RdmInfoCallback(Database db, DBResultSet results, const char[] error, int client) {
    if (results == null) {
        LogError("RdmInfoCallback: %s", error);
        return;
    }

    if (results.FetchRow()) {
        char accuserName[64]; results.FetchString(2, accuserName, 64);
        char accusedName[64]; results.FetchString(5, accusedName, 64);

        char accuserRole[16];
        switch (results.FetchInt(3)) // Accuser Role
        {
            case TTT_TEAM_INNOCENT:
            {
                Format(accuserRole, 16, "{green}Innocent");
            }
            case TTT_TEAM_TRAITOR:
            {
                Format(accuserRole, 16, "{red}Traitor");
            }
            case TTT_TEAM_DETECTIVE:
            {
                Format(accuserRole, 16, "{blue}Detective");
            }
        }

        char accusedRole[16];
        switch (results.FetchInt(6)) // Accuser Role
        {
            case TTT_TEAM_INNOCENT:
            {
                Format(accusedRole, 16, "{green}Innocent");
            }
            case TTT_TEAM_TRAITOR:
            {
                Format(accusedRole, 16, "{red}Traitor");
            }
            case TTT_TEAM_DETECTIVE:
            {
                Format(accusedRole, 16, "{blue}Detective");
            }
        }

        CPrintToChat(client, "{purple}[TTT] {yellow}Case information for Death: %d(%d rounds ago)", results.FetchInt(0), currentRound - results.FetchInt(9));
        CPrintToChat(client, "{yellow}The accuser had shot last %d seconds before there death.", results.FetchInt(1) - results.FetchInt(8));
        CPrintToChat(client, "{yellow}Accuser: %s(%d) - %s", accuserName, results.FetchInt(4), accuserRole);
        CPrintToChat(client, "{yellow}Accused: %s(%d) - %s", accusedName, results.FetchInt(7), accusedRole);
    }
}

public void RdmHandleCallback(Database db, DBResultSet results, const char[] error, int handler) {
    if (results == null) {
        LogError("RdmHandleCallback: %s", error);
        return;
    }

    if (results.FetchRow())
    {
        int deathId = results.FetchInt(0);

        char query[768], staffName[64], staffSteamId[64];
        Player player = Player(handler);
        player.Name(staffName);
        player.Auth(AuthId_Steam2, staffSteamId);

        DataPack data = new DataPack();
        data.WriteCell(handler);
        data.WriteCell(deathId);

        rdmDb.Format(query, sizeof(query), "INSERT INTO `handles`(`death_index`, `staff_name`, `staff_auth`, `verdict`) VALUES (%d, '%s', '%s', '%d');", deathId, staffName, staffSteamId, 0);
        rdmDb.Query(RdmHandleInsertCallback, query, data);
    }
    else
    {
        Player(handler).Error("There are currently no available cases.");
    }
}

public void RdmHandleInsertCallback(Database db, DBResultSet results, const char[] error, DataPack data) {
    if (results == null) {
        LogError("RdmHandleInsertCallback: %s", error);
    }

    data.Reset();
    int handler = data.ReadCell();
    int deathId = data.ReadCell();

    char query[768];
    rdmDb.Format(query, sizeof(query), "SELECT `deaths`.`death_index` AS `death_id`, `deaths`.`victim_name` AS `victim_name`, `deaths`.`killer_name` AS `killer_name` FROM `deaths` WHERE `deaths`.`death_index` = '%d' LIMIT 1", deathId);
    rdmDb.Query(RdmHandleResponseCallback, query, handler);
}

public void RdmHandleResponseCallback(Database db, DBResultSet results, const char[] error, int handler) {
    if (results == null) {
        LogError("RdmHandleResponseCallback: %s", error);
    }

    if (results.FetchRow())
    {
        int deathId = results.FetchInt(0);
        char accuserName[64]; results.FetchString(1, accuserName, 64);
        char accusedName[64]; results.FetchString(2, accusedName, 64);

        CPrintToChat(handler, "{purple}[TTT] {yellow}You have taken %s's case against %s.", accuserName, accusedName);
        currentCase[handler] = deathId;
    }
}

public void RdmVerdictCallback(Database db, DBResultSet results, const char[] error, int handler) {
    if (results == null) {
        LogError("RdmHandleResponseCallback: %s", error);
    }

    char query[768];
    rdmDb.Format(query, sizeof(query), "SELECT `deaths`.`victim_name`, `deaths`.`victim_id`, `deaths`.`killer_name`, `deaths`.`killer_id`, `reports`.`punishment`, `handles`.`verdict` FROM `deaths` LEFT JOIN `reports` ON `deaths`.`death_index` = `reports`.`death_index` LEFT JOIN `handles` ON `deaths`.`death_index` = `handles`.`death_index` WHERE `deaths`.`death_index` = '1' LIMIT 1;", currentCase[handler]);
    rdmDb.Query(RdmHandleResponseCallback, query, handler);
}

public void RdmVerdictResponseCallback(Database db, DBResultSet results, const char[] error, int handler) {
    if (results == null) {
        LogError("RdmVerdictResponseCallback: %s", error);
    }

    if (results.FetchRow())
    {
        char accuserName[64]; results.FetchString(0, accuserName, 64);
        char accuserAuth[128]; results.FetchString(1, accuserAuth, 128);
        char accusedName[64]; results.FetchString(2, accusedName, 64);
        char accusedAuth[128]; results.FetchString(3, accusedAuth, 128);
        int punishment = results.FetchInt(4);
        int verdict = results.FetchInt(5);

        Player accuser = Player(0).TargetOne(accuserAuth);
        Player accused = Player(0).TargetOne(accusedAuth);

        if (verdict == CASE_VERDICT_INNOCENT) {
            if (accuser.ValidClient) {
                accuser.Msg("%N has handled your case against %s and has concluded them to be innocent if you have any questions please message staff using an @ before your message.", handler, accusedName);
            }
            if (accused.ValidClient) {
                accused.Msg("%N has found you innocent in your defense against %s have a nice day.", handler, accuserName);
            }
            Player(handler).Msg("You have concluded the defendant innocent for case %d.");
        }
        else if (verdict == CASE_VERDICT_GUILTY) {
            if (accuser.ValidClient) {
                accuser.Msg("%N has handled your case against %s and has concluded them to be guilty. Thanks for your report.", handler, accusedName);
            }
            if (punishment == CASE_CHOICE_SLAY) {
                if (accused.Client) {
                    accused.Msg("You are being slayed next round by %N for killing %s. If you have any questions about this please message staff by using an @ before your message.", handler, accuserName);
                    TTT_AddRoundSlays(accused.Client, 1, false);
                }
            }
            else if (punishment == CASE_CHOICE_WARN) {
                if (accused) {
                    accused.Msg("You have been found guilty of RDM by %N for killing %s further action may be taken. If you have any questions about this please message staff by using an @ before your message in team chat.", handler, accuserName);
                }
            }
            Player(handler).Msg("You have concluded the defendant guilty for case %d.");
        }
        currentCase[handler] = -1;
    }
}

public void RdmFetchLastDeathIndex(Database db, DBResultSet results, const char[] error, any data) {
    if (results == null) {
        LogError("RdmFetchLastDeathIndex: %s", error);
    }

    if (results.FetchRow()) {
        lastDeathIndex = results.FetchInt(0);
    }
    else {
        lastDeathIndex = 0;
    }
}

public void RdmFetchLastRoundIndex(Database db, DBResultSet results, const char[] error, any data) {
    if (results == null) {
        LogError("RdmFetchLastRoundIndex: %s", error);
    }

    if (results.FetchRow()) {
        currentRound = results.FetchInt(0);
    }
    else {
        currentRound = 0;
    }
}
