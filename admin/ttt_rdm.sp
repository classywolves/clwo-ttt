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
#include <colorvariables>
#include <ttt>
#include <ttt_messages>
#include <ttt_targeting>

/*
* Database includes.
*/
#include <rdm\db>

public Plugin myinfo = {
    name = "TTT RDM",
    author = "Popey & Corpen",
    description = "TTT Random Death Match manager and handler.",
    version = "0.0.1",
    url = ""
};

int currentlySelectedDeath[MAXPLAYERS + 1] =  { -1, ... };

public OnPluginStart() {
    RegisterCmds();
    HookEvents();
    RdmInit();

    PrintToServer("[RDM] Loaded successfully");
}

public void RegisterCmds() {
    RegConsoleCmd("sm_rdm", Command_RDM, "Shows the RDM report window for all recent killers.");
    RegAdminCmd("sm_cases", Command_CaseCount, ADMFLAG_GENERIC, "Shows the current amount of cases to staff.");
    RegAdminCmd("sm_handle", Command_Handle, ADMFLAG_GENERIC, "Handles the next case or a user inputted case.");
    RegAdminCmd("sm_info", Command_Info, ADMFLAG_GENERIC, "Displays all of the information for a given case.");
    RegAdminCmd("sm_verdict", Command_Verdict, ADMFLAG_GENERIC, "Shows a member of staff the availible verdicts for there current case.");
}

public void HookEvents() {
    HookEvent("weapon_fire", Event_OnWeaponFire, EventHookMode_Post);
}

public void TTT_OnRoundStart(int innocents, int traitors, int detective) {
    currentRound++;
}

public void Event_OnWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    lastGunFired[GetClientOfUserId(event.GetInt("userid"))] = GetTime();
}

public void TTT_OnClientDeath(int victim, int attacker)
{
    int victimKarma = TTT_GetClientKarma(victim);
    int attackerKarma = TTT_GetClientKarma(attacker);

    if (BadKill(TTT_GetClientRole(attacker), TTT_GetClientRole(victim)))
    {
        CPrintToChatAdmins(ADMFLAG_GENERIC, TTT_MESSAGE ... "{default}Bad Action: [{yellow}%N{default}] ({orange}%d{default}) killed [{yellow}%N{default}] ({orange}%d{default})", attacker, attackerKarma, victim, victimKarma);
    }

    RdmDeathInsert(victim, victimKarma, attacker, attackerKarma);
}

public Action Command_CaseCount(int client, int args)
{
    char query[768];
    rdmDb.Format(query, sizeof(query), "SELECT COUNT(*) AS `case_count` FROM `reports` LEFT JOIN `handles` ON `reports`.`death_index` = `handles`.`death_index` WHERE `handles`.`verdict` IS NULL;");
    rdmDb.Query(RdmCaseCountCallback, query, client);

    return Plugin_Handled;
}

public Action Command_Handle(int client, int args) {
    if (currentCase[client] != -1) {
        CPrintToChat(client, TTT_ERROR ... "You cannot handle a new case whilst you still have a case awaiting your verdict.");
        return Plugin_Handled;
    }

    char query[768];
    rdmDb.Format(query, sizeof(query), "SELECT `reports`.`death_index` AS `death_id` FROM `reports` LEFT JOIN `handles` ON `reports`.`death_index` = `handles`.`death_index` WHERE `handles`.`verdict` IS NULL GROUP BY `reports`.`death_index` ORDER BY `reports`.`death_index` ASC LIMIT 1;");
    rdmDb.Query(RdmHandleCallback, query, client);

    return Plugin_Handled;
}

public Action Command_Info(int client, int args)
{
    if (!rdmConnected)
    {
        return Plugin_Handled;
    }

    char query[768];
    rdmDb.Format(query, sizeof(query), "SELECT `deaths`.`death_index`, `deaths`.`death_time`, `deaths`.`victim_name`, `deaths`.`victim_role`, `deaths`.`victim_karma`, `deaths`.`killer_name`, `deaths`.`killer_role`, `deaths`.`killer_karma`, `deaths`.`last_gun_fire`, `deaths`.`round_no` FROM `deaths` WHERE `death_index` = '%d' ORDER BY `deaths`.`death_index` DESC LIMIT 1;", currentCase[client]);
    rdmDb.Query(RdmInfoCallback, query, client);

    return Plugin_Handled;
}

public Action Command_RDM(int client, int args)
{
    if (!rdmConnected)
    {
        return Plugin_Handled;
    }

    char query[768];
    char auth[64]; GetClientAuthId(client, AuthId_Steam2, auth, 64);

    rdmDb.Format(query, sizeof(query), "SELECT `deaths`.`death_index` as `death_id`, `deaths`.`round_no` as `round_no`, `deaths`.`killer_name` as `killer_name` FROM `deaths` WHERE `victim_id` = '%s' ORDER BY `deaths`.`death_time`  DESC LIMIT 10;", auth);
    rdmDb.Query(RdmGetLastDeathsCallback, query, client);

    return Plugin_Handled;
}

public Action Command_Verdict(int client, int args)
{
    if (currentCase[client] < 0) {
        CPrintToChat(client, TTT_ERROR ... "You do not currently have a case to cast a verdict upon.");
        return Plugin_Handled;
    }

    if (args < 1) {
        Menu verdictMenu = new Menu(MenuHandler_Verdict);
        verdictMenu.AddItem("", "Innocent");
        verdictMenu.AddItem("", "Guilty");
        verdictMenu.Display(client, 240);
    }
    else {
        char response[64];
        GetCmdArg(1, response, 64);

        int verdict = CASE_VERDICT_NONE;
        if (strcmp(response, "innocent", false)) {
            verdict |= CASE_VERDICT_INNOCENT;
        }
        if (strcmp(response, "guilty", false)) {
            verdict |= CASE_VERDICT_GUILTY;
        }

        if (verdict == CASE_VERDICT_INNOCENT || verdict == CASE_VERDICT_GUILTY) {
            char query[768];
            rdmDb.Format(query, sizeof(query), "UPDATE `handles` SET `handles`.`verdict` = '%d' WHERE `death_index` = '%d';", verdict, currentCase[client]);
            rdmDb.Query(RdmVerdictCallback, query, client);
        }
        else {
            CPrintToChat(client, TTT_ERROR ... "Please pass either Innocent or Guilty.");
        }
    }

    return Plugin_Handled;
}

int MenuHandler_RDM(Menu menu, MenuAction action, int client, int data) {
    switch (action) {
        case MenuAction_Select: {
            char info[8];
            menu.GetItem(data, info, 8);
            currentlySelectedDeath[client] = StringToInt(info);

            Menu punishMenu = new Menu(MenuHandler_PunishChoice);
            punishMenu.SetTitle("Would you like you killer to be?");
            punishMenu.AddItem("", "Slain next round");
            punishMenu.AddItem("", "Warned");

            punishMenu.Display(client, 240);
        }
    }
}

int MenuHandler_PunishChoice(Menu menu, MenuAction action, int client, int punishment) {
    switch (action) {
        case MenuAction_Select: {
            char query[768];
            rdmDb.Format(query, sizeof(query), "INSERT INTO `reports` (`death_index`, `punishment`) VALUES ('%d', '%d');", currentlySelectedDeath[client], punishment);
            rdmDb.Query(RdmReportCallback, query, client);
        }
    }
}

int MenuHandler_Verdict(Menu menu, MenuAction action, int client, int choice) {
    switch (action) {
        case MenuAction_Select:
        {
            int verdict;
            if (choice == 0)
            {
                verdict = CASE_VERDICT_INNOCENT;
            }
            else if (choice == 1)
            {
                verdict = CASE_VERDICT_GUILTY;
            }

            char query[768];
            rdmDb.Format(query, sizeof(query), "UPDATE `handles` SET `handles`.`verdict` = '%d' WHERE `death_index` = '%d';", verdict, currentCase[client]);
            rdmDb.Query(RdmVerdictCallback, query, client);
        }
    }
}

public bool BadKill(int attackerRole, int victimRole)
{
    if (attackerRole == victimRole) return true;
    //else if (attackerRole == TTT_TEAM_TRAITOR || victimRole == TTT_TEAM_TRAITOR) return false;
    else if ((attackerRole | victimRole) & TTT_TEAM_TRAITOR) return false;
    else return true;
}

public void TTT_OnRoundEnd(int winner, Handle array)
{
    char query[768];
    rdmDb.Format(query, sizeof(query), "SELECT COUNT(*) AS `case_count` FROM `reports` LEFT JOIN `handles` ON `reports`.`death_index` = `handles`.`death_index` WHERE `handles`.`verdict` IS NULL;");
    rdmDb.Query(RdmCaseCountCallback, query);
}
