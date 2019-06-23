#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <ttt>
#include <generics>
#include <ttt_targeting>

int g_clientPunishType[MAXPLAYERS + 1];
int g_clientTarget[MAXPLAYERS + 1];
Handle g_hDb = INVALID_HANDLE;

int g_punishmentsRDM[MAXPLAYERS + 1];
int g_punishmentsMute[MAXPLAYERS + 1];
int g_punishmentsGag[MAXPLAYERS + 1];

char sql_createPunish[] = "CREATE TABLE IF NOT EXISTS `ttt_db`.`punish` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `auth_id` VARCHAR(32) NOT NULL, `name` VARCHAR(64) NOT NULL, `time` INT(11) NOT NULL, `reason` VARCHAR(128) NOT NULL, `type` INT(11) NOT NULL, `auth_admin` VARCHAR(32) NOT NULL, `name_admin` VARCHAR(32) NOT NULL, PRIMARY KEY (`id`), UNIQUE `authtime_index` (`auth_id`, `time`))";
char sql_insertPunishment[] = "INSERT INTO `punish` (`id`, `auth_id`, `name`, `time`, `reason`, `type`, `auth_admin`, `name_admin`) VALUES (NULL, '%s', '%s', '%d', '%s', '%i', '%s', '%s');";
char sql_sumPunishments[] = "SELECT SUM (CASE WHEN `type` = 0 THEN 1 ELSE 0 END), SUM (CASE WHEN `type` = 1 THEN 1 ELSE 0 END), SUM (CASE WHEN `type` = 1 THEN 1 ELSE 0 END) FROM `punish` WHERE `auth_id` REGEXP '^STEAM_[0-9]:%s$' AND `time` > '%i' - '259200';";

public Plugin myinfo = 
{
    name = "TTT Punish Plugin",
    author = "c0rp3n",
    description = "Automation of punishments",
    version = "1.0.0",
    url = ""
};

public void OnPluginStart()
{
    RegAdminCmd("sm_punish", Command_PunishMenu, ADMFLAG_SLAY, "Displays the punish menu");
    RegAdminCmd("sm_p", Command_PunishMenu, ADMFLAG_SLAY, "Displays the punish menu");
    RegAdminCmd("sm_punishr", Command_PunishRdm, ADMFLAG_SLAY, "Displays the admin menu");
    RegAdminCmd("sm_pr", Command_PunishRdm, ADMFLAG_SLAY, "Displays the admin menu");
    RegAdminCmd("sm_punishm", Command_PunishMute, ADMFLAG_SLAY, "Displays the admin menu");
    RegAdminCmd("sm_pm", Command_PunishMute, ADMFLAG_SLAY, "Displays the admin menu");
    RegAdminCmd("sm_punishg", Command_PunishGag, ADMFLAG_SLAY, "Displays the admin menu");
    RegAdminCmd("sm_pg", Command_PunishGag, ADMFLAG_SLAY, "Displays the admin menu");
    
    db_setupDatabase();
    
    LoopValidClients(i)
    {
        LoadClientPunishments(i);
    }
}

public void OnClientPostAdminCheck(int client)
{
    LoadClientPunishments(client);	
}

stock void LoadClientPunishments(int client)
{
    char steamId[32];
    if(!GetClientAuthId(i, AuthId_Steam2, steamId, 32))
    {
        LogError("(SQL_OnClientPostAdminCheck) Auth failed: #%d", client);
        return;
    }
    
    char query[512];
    Format(query, sizeof(query), sql_sumPunishments, steamId[8], GetTime());
    if(g_hDb != null)
    {
        SQL_TQuery(g_hDb, SQL_OnClientPostAdminCheck, query, GetClientUserId(client));
    }
}


public void SQL_OnClientPostAdminCheck(Handle owner, Handle hndl, const char[] error, any userid)
{
    int client = GetClientOfUserId(userid);
    
    if(IsValidClient(client))
    {
        if(hndl == null || strlen(error) > 0)
        {
            LogError("(SQL_OnClientPostAdminCheck) Query failed: %s", error);
            return;
        }
        else
        {
            if (SQL_FetchRow(hndl))
            {
                g_punishmentsRDM[client] = SQL_FetchInt(hndl, 0);
                g_punishmentsMute[client] = SQL_FetchInt(hndl, 1);
                g_punishmentsGag[client] = SQL_FetchInt(hndl, 2);
            }
        }
    }
}


public db_setupDatabase()
{
    char szError[255];
    g_hDb = SQL_Connect("sourcebans", false, szError, 255);
        
    if(g_hDb == INVALID_HANDLE)
    {
        SetFailState("[Punish] Unable to connect to database (%s)", szError);
        return;
    }
        
    char szIdent[8];
    SQL_ReadDriver(g_hDb, szIdent, 8);
        
    SQL_FastQuery(g_hDb,"SET NAMES  'utf8'");
    db_createTables();
}

public db_createTables()
{
    SQL_LockDatabase(g_hDb);        
    SQL_FastQuery(g_hDb, sql_createPunish);
    SQL_UnlockDatabase(g_hDb);
}

public Action Command_PunishMute(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;
    
    g_clientPunishType[client] = 1;
    
    if (args < 1)
    {	
        DisplayTargets(client);	
        return Plugin_Handled;
    }
    
    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, false, false);
    if (IsValidClient(target))
    {
        g_clientTarget[client] = GetClientUserId(target);
        DisplayReasons(client);
    }
    else
    {
        ReplyToCommand(client, "[SM] %t", "Target is not in game");
    }
    
    return Plugin_Continue;
}

public Action Command_PunishRdm(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;
    
    g_clientPunishType[client] = 0;
    
    if (args < 1)
    {	
        DisplayTargets(client);	
        return Plugin_Handled;
    }
    
    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, false, false);
    if (IsValidClient(target))
    {
        g_clientTarget[client] = GetClientUserId(target);
        DisplayReasons(client);
    }
    else
    {
        ReplyToCommand(client, "[SM] %t", "Target is not in game");
    }
    
    
    return Plugin_Continue;
}

public Action Command_PunishGag(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;
    
    g_clientPunishType[client] = 2;
    
    if (args < 1)
    {	
        DisplayTargets(client);	
        return Plugin_Handled;
    }
    
    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, false, false);
    if (IsValidClient(target))
    {
        g_clientTarget[client] = GetClientUserId(target);
        DisplayReasons(client);
    }
    else
    {
        ReplyToCommand(client, "[SM] %t", "Target is not in game");
    }
    
    return Plugin_Continue;
}

public Action Command_PunishMenu(int client, int args)
{
    Menu menu = new Menu(MenuHandler_Punish);
    
    menu.SetTitle("Select Type of Punishment!");
    
    menu.AddItem("0", "RDM");
    menu.AddItem("1", "Mute");
    menu.AddItem("2", "Gag");
    
    menu.Display(client, 20);
 
    return Plugin_Handled;
}

public int MenuHandler_Punish(Menu menu, MenuAction action, int param1, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        g_clientPunishType[param1] = StringToInt(info);
        
        //PrintToChat(param1, "You selected item: %i", g_clientPunishType[param1]);
        
        DisplayTargets(param1);
    }
    
    return 0;
}

public void DisplayTargets(int client)
{
    Menu menu2 = new Menu(MenuHandler2);
    
    menu2.SetTitle("Select a target!");
    
    char name[MAX_NAME_LENGTH], userid[4];
    LoopValidClients(i)
    {
        GetClientName(i, name, sizeof(name));
        IntToString(userid, GetClientUserId(i), 4);
        menu2.AddItem(userid, name);
    }
        
    menu2.Display(client, 20);

}

public int MenuHandler_Targets(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        
        g_clientTarget[param1] = StringToInt(info);
        
        DisplayReasons(param1);
    }
    return 0;
}

public void DisplayReasons(int client)
{
    Menu menu = new Menu(MenuHandler3);
    char name[50];
    
    int target = GetClientOfUserId(g_clientTarget[client]);
    GetClientName(target, name, sizeof(name));
    
    menu.SetTitle("Select a Reason! Punishing %s", name);
    
    if(g_clientPunishType[client] == 0)
    {
        menu.AddItem("RDM", "I have selected the correct person");
    } 
    else
    {
        menu.AddItem("Spamming", "Spamming");
        menu.AddItem("English Only", "English Only");
        menu.AddItem("Obscene language", "Obscene language");
        menu.AddItem("Insulting players", "Insulting players");
        menu.AddItem("Admin Disrespect", "Admin Disrespect");
        menu.AddItem("Advertising", "Advertising");
        menu.AddItem("Music in Voice", "Music in Voice");
        menu.AddItem("Other", "Other (Tell SM)");
    }
    
    menu.Display(client, 20);

}

public int MenuHandler_Reasons(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char reason[255];
        menu.GetItem(param2, reason, sizeof(reason));
        
        PunishDem(param1, reason);
    }

    return 0;
}

public void PunishDem(int client, char reason[255])
{
    
    char query[255];
    char steamId[50];
    char name[50];
    char staffSteamId[50];
    char staffName[50];
    int target = GetClientOfUserId(g_clientTarget[client]);
    
    switch(g_clientPunishType[client])
    {
        case 0:
        {
            if(g_punishmentsRDM[target] == 0)
            {
                FakeClientCommand(client, "sm_slay #%i", g_clientTarget[client]);
            }
            else if(g_punishmentsRDM[target] == 1)
            {
                FakeClientCommand(client, "sm_kick #%i 'You have RDMed 2x over the past 3 days!'", g_clientTarget[client]);
            }
            else if(g_punishmentsRDM[target] == 2)
            {
                FakeClientCommand(client, "sm_rdm #%i 15 %s", g_clientTarget[client], reason);
            }
            else
            {
                
                float pow = Pow(2.0, float(g_punishmentsRDM[target] - 2));
                int time = 15 * RoundFloat(pow);
                
                FakeClientCommand(client, "sm_rdm #%i %i %s", g_clientTarget[client], time, reason);
            }
            
            g_punishmentsRDM[target]++;
        }
        case 1:
        {
            if(g_punishmentsMute[target] == 0)
            {
                FakeClientCommand(client, "sm_mute #%i 15 %s", g_clientTarget[client], reason);
            }
            else 
            {
                float pow = Pow(2.0, float(g_punishmentsMute[target]));
                int time = 15 * RoundFloat(pow);
                
                FakeClientCommand(client, "sm_mute #%i %i %s", g_clientTarget[client], time, reason);
            }
            
            g_punishmentsMute[target]++;
            
        }
        case 2:
        {
            if(g_punishmentsGag[target] == 0)
                FakeClientCommand(client, "sm_gag #%i 15 %s", g_clientTarget[client], reason);
            else 
            {
                
                float pow = Pow(2.0, float(g_punishmentsGag[target]));
                int time = 15 * RoundFloat(pow);
                
                FakeClientCommand(client, "sm_gag #%i %i %s", g_clientTarget[client], time, reason);
            }

            g_punishmentsGag[target]++;
        }
    }
    
    GetClientAuthId(target, AuthId_SteamID2, steamId, sizeof(steamId));
    GetClientName(target, name, sizeof(name));
    
    GetClientAuthId(client, AuthId_SteamID2, staffSteamId, sizeof(staffSteamId));
    GetClientName(client, staffName, sizeof(staffName));
    
    Format(query, 512, sql_insertPunishment, steamId, name, GetTime(), reason, g_clientPunishType[client], staffSteamId, staffName);
    SQL_TQuery(g_hDb, SQL_CheckCallback, query, DBPrio_Low);
}

public SQL_CheckCallback(Handle owner, Handle hndl, const char error[], any data)
{
}