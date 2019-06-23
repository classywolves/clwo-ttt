#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <ttt>

int gI_Type[MAXPLAYERS + 1];
int gI_Client[MAXPLAYERS + 1];
Handle g_hDb = INVALID_HANDLE;

int gI_PunishmentsRDM[MAXPLAYERS + 1];
int gI_PunishmentsMute[MAXPLAYERS + 1];
int gI_PunishmentsGag[MAXPLAYERS + 1];

char sql_createPunish[] = "CREATE TABLE `Punish` (`auth` VARCHAR(50) NULL DEFAULT NULL, `name` VARCHAR(50) NULL DEFAULT NULL, `reason` VARCHAR(50) NULL DEFAULT NULL, `type` INT(11) NULL DEFAULT NULL, `timestamp` INT(11) NULL DEFAULT NULL)";
char sql_insertPunishment[] = "INSERT INTO Punish (auth, name, reason, type, timestamp, auth_admin, name_admin) VALUES('%s', '%s', '%s', '%i', '%d', '%s', '%s')";

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
	RegAdminCmd("sm_punish", Command_DisplayMenu, ADMFLAG_GENERIC, "Displays the admin menu");
	RegAdminCmd("sm_p", Command_DisplayMenu, ADMFLAG_GENERIC, "Displays the admin menu");
	RegAdminCmd("sm_punishr", Command_PR, ADMFLAG_GENERIC, "Displays the admin menu");
	RegAdminCmd("sm_pr", Command_PR, ADMFLAG_GENERIC, "Displays the admin menu");
	RegAdminCmd("sm_punishm", Command_PM, ADMFLAG_GENERIC, "Displays the admin menu");
	RegAdminCmd("sm_pm", Command_PM, ADMFLAG_GENERIC, "Displays the admin menu");
	RegAdminCmd("sm_punishg", Command_PG, ADMFLAG_GENERIC, "Displays the admin menu");
	RegAdminCmd("sm_pg", Command_PG, ADMFLAG_GENERIC, "Displays the admin menu");
	
	db_setupDatabase();
	LateLoadAll();
}

public void LateLoadAll()
{
	LoopValidClients(i)
	{
		if(!IsClientConnected(i))
				continue;
		
		LoadClientPunishments(GetClientUserId(i));
	}
}

public void OnClientPostAdminCheck(int client)
{
	LoadClientPunishments(GetClientUserId(client));	
}

stock void LoadClientPunishments(int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(TTT_IsClientValid(client) && !IsFakeClient(client))
	{
		char sCommunityID[64];
		
		if(!GetClientAuthId(client, AuthId_SteamID64, sCommunityID, sizeof(sCommunityID)))
		{
			LogError("(LoadClientPunishments) Auth failed: #%d", client);
			return;
		}
		
		char sQuery[2048];
		Format(sQuery, sizeof(sQuery), "select sum(CASE when Type=0 then 1 else 0 end), sum(CASE when Type=1 then 1 else 0 end), sum(CASE when Type=2 then 1 else 0 end) from Punish where auth = %s and active = 1 and timestamp > %i - 259200", sCommunityID, GetTime());
		//
		if(g_hDb != null)
			SQL_TQuery(g_hDb, SQL_OnClientPostAdminCheck, sQuery, userid);
	}
}


public void SQL_OnClientPostAdminCheck(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client || !TTT_IsClientValid(client) || IsFakeClient(client))
		return;
	
	if(hndl == null || strlen(error) > 0)
	{
		LogError("(SQL_OnClientPostAdminCheck) Query failed: %s", error);
		return;
	}
	else
	{
		if (SQL_FetchRow(hndl))
		{
			char sCommunityID[64];
			
			if(!GetClientAuthId(client, AuthId_SteamID64, sCommunityID, sizeof(sCommunityID)))
			{
				LogError("(SQL_OnClientPostAdminCheck) Auth failed: #%d", client);
				return;
			}
				
			int iTemp0 = SQL_FetchInt(hndl, 0);
			int iTemp1 = SQL_FetchInt(hndl, 1);
			int iTemp2 = SQL_FetchInt(hndl, 2);
			
			gI_PunishmentsRDM[client] = iTemp0;
			gI_PunishmentsMute[client] = iTemp1;
			gI_PunishmentsGag[client] = iTemp2;
			
		}
	}
}


public db_setupDatabase()
{
	char szError[255];
	g_hDb = SQL_Connect("sourcebans", false, szError, 255);
        
	if(g_hDb == INVALID_HANDLE)
	{
		SetFailState("[Punish] Unable to connect to database (%s)",szError);
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

public Action Command_PM(int client, int args)
{
	if(!IsClientConnected(client))
		return Plugin_Handled;
	
	if (!TTT_IsClientValid(client))
		return Plugin_Handled;
	
	gI_Type[client] = 1;
	
	if (args < 1)
	{	
		DisplayTargets(client);	
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	int target = FindTarget(client, arg1, true, true);
	if (target == -1) 
	{
		return Plugin_Handled;
	}
	if (IsClientInGame(target))
	{
		gI_Client[client] = GetClientUserId(target);
		DisplayReasons(client);
	}
	if (!IsClientInGame(target)) ReplyToCommand(client, "[SM] %t", "Target is not in game");
	
	
	return Plugin_Continue;
}

public Action Command_PR(int client, int args)
{
	if(!IsClientConnected(client))
		return Plugin_Handled;
	
	if (!TTT_IsClientValid(client))
		return Plugin_Handled;
	
	gI_Type[client] = 0;
	
	if (args < 1)
	{	
		DisplayTargets(client);	
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	int target = FindTarget(client, arg1, true, true);
	if (target == -1) 
	{
		return Plugin_Handled;
	}
	if (IsClientInGame(target))
	{
		gI_Client[client] = GetClientUserId(target);
		DisplayReasons(client);
	}
	if (!IsClientInGame(target)) ReplyToCommand(client, "[SM] %t", "Target is not in game");
	
	
	return Plugin_Continue;
}

public Action Command_PG(int client, int args)
{
	if(!IsClientConnected(client))
		return Plugin_Handled;
	
	if (!TTT_IsClientValid(client))
		return Plugin_Handled;
	
	gI_Type[client] = 2;
	
	if (args < 1)
	{	
		DisplayTargets(client);	
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	int target = FindTarget(client, arg1, true, true);
	if (target == -1) 
	{
		return Plugin_Handled;
	}
	if (IsClientInGame(target))
	{
		gI_Client[client] = GetClientUserId(target);
		DisplayReasons(client);
	}
	if (!IsClientInGame(target)) ReplyToCommand(client, "[SM] %t", "Target is not in game");
	
	
	return Plugin_Continue;
}

public Action Command_DisplayMenu(int client, int args)
{
	Menu menu = new Menu(MenuHandler1);
	
	menu.SetTitle("Select Type of Punishment!");
	
	menu.AddItem("0", "RDM");
	menu.AddItem("1", "Mute");
	menu.AddItem("2", "Gag");
	
	menu.Display(client, 20);
 
	return Plugin_Handled;
}

public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		gI_Type[param1] = StringToInt(info);
		
		//PrintToChat(param1, "You selected item: %i", gI_Type[param1]);
		
		DisplayTargets(param1);
		
	}
	
	return 0;
}

public void DisplayTargets(int client)
{
	Menu menu2 = new Menu(MenuHandler2);
	
	menu2.SetTitle("Select a target!");
	
	char name[MAX_NAME_LENGTH], Sid[24];
	int Iid;
	LoopValidClients(i)
	{
		if(!IsClientConnected(i) || IsFakeClient(i))
			continue;
			
		GetClientName(i, name, sizeof(name));
		Iid = GetClientUserId(i);
		IntToString(Iid, Sid, 4);
		menu2.AddItem(Sid, name);
	}
		
	menu2.Display(client, 20);

}

public int MenuHandler2(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		
		gI_Client[param1] = StringToInt(info);
		
		//PrintToChat(param1, "You selected item: %i", gI_Client[param1]);
		DisplayReasons(param1);
	}
	return 0;
}

public void DisplayReasons(int client)
{
	Menu menu = new Menu(MenuHandler3);
	char szName[50];
	
	int target = GetClientOfUserId(gI_Client[client]);
	GetClientName(target, szName, sizeof(szName));
	
	menu.SetTitle("Select a Reason! Punishing %s", szName);
	
	if(gI_Type[client] == 0)
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

public int MenuHandler3(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{	
		
		char info[255];
		menu.GetItem(param2, info, sizeof(info));
		
		PunishDem(param1, info);
	}
	return 0;
}

public void PunishDem(int client, char reason[255])
{
	
	char szQuery[255];
	char szSteamId[50];
	char szName[50];
	char szSteamId2[50];
	char szName2[50];
	int target;
	
	switch(gI_Type[client])
	{
		case 0:
		{
			target = GetClientOfUserId(gI_Client[client]);
			
			if(gI_PunishmentsRDM[target] == 0)
				FakeClientCommand(client, "sm_slay #%i", gI_Client[client]);
			else if(gI_PunishmentsRDM[target] == 1)
			{
				FakeClientCommand(client, "sm_kick #%i 'You have RDMed 2x over the past 3 days!'", gI_Client[client]);
			}
			else if(gI_PunishmentsRDM[target] == 2)
			{
				FakeClientCommand(client, "sm_rdm #%i 15 %s", gI_Client[client], reason);
			}
			else
			{
				
				float pow = Pow(2.0, float(gI_PunishmentsRDM[target] - 2));
				int time = 15 * RoundFloat(pow);
				
				FakeClientCommand(client, "sm_rdm #%i %i %s", gI_Client[client], time, reason);
			}
			
			
			GetClientAuthId(target, AuthId_SteamID64, szSteamId, sizeof(szSteamId));
			GetClientName(target, szName, sizeof(szName));
			
			GetClientAuthId(client, AuthId_SteamID64, szSteamId2, sizeof(szSteamId2));
			GetClientName(client, szName2, sizeof(szName2));
			
			//PrintToChatAll("%i", gI_PunishmentsMute[client]);
			
			gI_PunishmentsRDM[target]++;
			
			Format(szQuery, 512, sql_insertPunishment, szSteamId, szName, reason, gI_Type[client], GetTime(), szSteamId2, szName2);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, DBPrio_Low);
		}
		case 1:
		{
			target = GetClientOfUserId(gI_Client[client]);
			
			if(gI_PunishmentsMute[target] == 0)
				FakeClientCommand(client, "sm_mute #%i 15 %s", gI_Client[client], reason);
			else 
			{
				
				float pow = Pow(2.0, float(gI_PunishmentsMute[target]));
				int time = 15 * RoundFloat(pow);
				
				FakeClientCommand(client, "sm_mute #%i %i %s", gI_Client[client], time, reason);
			}
			
			
			GetClientAuthId(target, AuthId_SteamID64, szSteamId, sizeof(szSteamId));
			GetClientName(target, szName, sizeof(szName));
			
			GetClientAuthId(client, AuthId_SteamID64, szSteamId2, sizeof(szSteamId2));
			GetClientName(client, szName2, sizeof(szName2));
			
			//PrintToChatAll("%i", gI_PunishmentsMute[client]);
			
			gI_PunishmentsMute[target]++;
			
			Format(szQuery, 512, sql_insertPunishment, szSteamId, szName, reason, gI_Type[client], GetTime(), szSteamId2, szName2);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, DBPrio_Low);
			
		}
		case 2:
		{
			target = GetClientOfUserId(gI_Client[client]);
			
			if(gI_PunishmentsGag[target] == 0)
				FakeClientCommand(client, "sm_gag #%i 15 %s", gI_Client[client], reason);
			else 
			{
				
				float pow = Pow(2.0, float(gI_PunishmentsGag[target]));
				int time = 15 * RoundFloat(pow);
				
				FakeClientCommand(client, "sm_gag #%i %i %s", gI_Client[client], time, reason);
			}
			
			
			GetClientAuthId(target, AuthId_SteamID64, szSteamId, sizeof(szSteamId));
			GetClientName(target, szName, sizeof(szName));
			
			GetClientAuthId(client, AuthId_SteamID64, szSteamId2, sizeof(szSteamId2));
			GetClientName(client, szName2, sizeof(szName2));
			
			//PrintToChatAll("%i", gI_PunishmentsGag[client]);
			
			gI_PunishmentsGag[target]++;
			
			Format(szQuery, 512, sql_insertPunishment, szSteamId, szName, reason, gI_Type[client], GetTime(), szSteamId2, szName2);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, DBPrio_Low);
		}
	}
	
}

public SQL_CheckCallback(Handle owner, Handle hndl, const char error[], any data)
{
}