#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#include <generics>
#include <ttt_ranks>
#include <ttt_messages>
#include <colorvariables>
#include <sourcecomms>

int g_iMyParentIs[MAXPLAYERS+1];
bool g_iAmEmpowered[MAXPLAYERS+1];
Handle g_hForwardPackFor[MAXPLAYERS+1];
ConVar cv_info_var_online_staff;

public void OnPluginStart()
{
	informers_RegisterCvars();
	informers_RegisterCmds();
	informers_HookEvents();
  	//post
  	informers_PostPluginStart();
}

public void informers_PostPluginStart()
{
	//PrintToChatAll(" \x03[\x01%s\x03] \x01>\x06 online ✔\x01<","Informer powers");
}
public void informers_RegisterCvars()
{
	cv_info_var_online_staff = CreateConVar("Staff_online", "#unknown#", "" );
	//cv_info_var_online_staff = CreateConVar("Staff_online", "#unknown#", "",FCVAR_NOTIFY );
}
public void informers_HookEvents()
{

}
public void informers_RegisterCmds()
{
 	RegAdminCmd("sm_islay", Command_InformerSlay, ADMFLAG_GENERIC, "sm_islay <target>");
	RegAdminCmd("sm_imute", Command_InformerMute, ADMFLAG_GENERIC, "sm_imute <target> <time> <reason>");
	RegAdminCmd("sm_igag", Command_InformerMute, ADMFLAG_GENERIC, "sm_igag <target> <time> <reason>");
 	RegAdminCmd("sm_itest", Command_InformerTest, ADMFLAG_SLAY, "sm_islay <target>");
 	RegAdminCmd("sm_adopt", Command_InformerAdopt, ADMFLAG_SLAY, "sm_adopt <player>");
 	RegAdminCmd("sm_empower", Command_InformerEmpower, ADMFLAG_SLAY, "sm_empower <player>");
 	RegConsoleCmd("sm_adoptions", Command_InformerAdoptions,"sm_adoptions");
 	RegAdminCmd("sm_orphan", Command_InformerOrphan, ADMFLAG_SLAY, "sm_orphan");
}

public void informers_OnClientDisconnect(client)
{
	informers_RemoveMyParent(client);
	//check if parent dc'd.
	informers_RemoveMyAdoption(client);
}
public Action Command_InformerAdoptions(int client, int args)
{
	if(IsValidClient(client))
	{
		informers_ShowAdoptions(client);
		return Plugin_Handled; 
	}
	return Plugin_Handled; 
}

public void informers_RoundFreezeEnd()
{
	if(!GetActiveStaffCount())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				if(Ranks_GetClientRank(i) == RANK_INFORMER)
				{
					PrintToChat(i," [SM] There is \x0eno staff online \x01");
					PrintToChat(i," [SM] You can now use \x0e!islay \x01-\x0e !imute\x01 - \x0e!igag \x01 - \x0e!itp \x01");
				}
			}
		}
		CPrintToChatAdmins(ADMFLAG_GENERIC, "Informer commands enabled");
	}

}
public Action Command_InformerAdopt(int client, int args)
{
	/*
	ReplyToCommand(client," [SM] Due abuse, I disabled this feature (you can thank valario and bob ross)" );
	return Plugin_Handled;
	*/
	if(fc(client))return Plugin_Handled;
	if (args < 1)
	{
		
		new Handle:menu = CreateMenu(teamban_Command_InformerAdoptCallback);
		SetMenuTitle(menu, "What informer do you want to adopt");
		int count;
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				if(Ranks_GetClientRank(i) == RANK_INFORMER)
				{
					char name[32];
					char targetid[3];
					GetClientName(i, name, sizeof(name));
					char stringformenu[255];
					IntToString(i, targetid, sizeof(targetid));
					if(informers_IHaveAParent(i))
					{
						Format(stringformenu,sizeof(stringformenu),"%s (adopted by %N)",name,informers_GetMyParent(i));						
					}
					else
					{
						Format(stringformenu,sizeof(stringformenu),"%s",name);
					}
					AddMenuItem(menu, targetid, stringformenu,informers_IHaveAParent(i) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
					count++;
				}
			}
		}
		if(count == 0)
		{
			AddMenuItem(menu, "","No informers online",ITEMDRAW_DISABLED);
		}
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	int target = FindTarget(client,arg,true,true);
	if(target != -1 && Ranks_GetClientRank(target) == RANK_INFORMER)
	{
		if(informers_IHaveAParent(target))
		{
			ReplyToCommand(client," [SM] This informer is already adopted by '%N'",informers_GetMyParent(target));
			return Plugin_Handled;
		}
		if(informers_GetMyParent(target) == client)
		{
			ReplyToCommand(client," [SM] You already adopted this informer");
			return Plugin_Handled;
		}
		//Open for adoption.
		if(informers_SetMyParent(target,client))
		{
			ReplyToCommand(client," [SM] You adopted '%N'",target);
			PrintToChat(client," [SM] You \x0eadopted\x01 '%N'.",target);
			PrintToChat(target," [SM] You got \x0eadopted\x01 by '%N'.",client);
			PrintToChat(target," [SM] You can now use \x0e!islay \x01-\x0e !imute\x01 - \x0e!igag \x01 - \x0e!itp \x01");
			PrintToChat(target," [SM] You can become an orphan again by using \x0e!orphan",client);
			CPrintToChatAdmins(ADMFLAG_GENERIC, " %N adopted %N",client,target);
			return Plugin_Handled;
		}
		ReplyToCommand(client," [SM] Something went wrong while trying to adopt this informer");
		return Plugin_Handled;
	
	}
	else
	{
		ReplyToCommand(client," [SM] Something went wrong while trying to adopt this informer");
		return Plugin_Handled;
	}

}
public Action Command_InformerEmpower(int client, int args)
{
	/*
	ReplyToCommand(client," [SM] Due abuse, I disabled this feature (you can thank valario and bob ross)" );
	return Plugin_Handled;
	*/
	if(fc(client))return Plugin_Handled;
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	int target = FindTarget(client,arg,true,true);
	if(target != -1)
	{
		//Open for adoption.
		if(informers_SetMyParent(target,client,true))
		{
			ReplyToCommand(client," [SM] You empowered '%N'",target);
			PrintToChat(client," [SM] You \x0eempowered\x01 '%N'.",target);
			PrintToChat(target," [SM] You got \x0eempowered\x01 by '%N'.",client);
			PrintToChat(target,"[SM] You can now use \x0e!islay \x01-\x0e !imute\x01 - \x0e!igag \x01 - \x0e!itp \x01");
			PrintToChat(target," [SM] You can become an orphan again by using \x0e!orphan",client);
			CPrintToChatAdmins(ADMFLAG_GENERIC, " %N empowered %N",client,target);
			return Plugin_Handled;
		}
		ReplyToCommand(client," [SM] Something went wrong while trying to empowered this informer");
		return Plugin_Handled;
	
	}
	else
	{
		ReplyToCommand(client," [SM] Something went wrong while trying to empowered this informer");
		return Plugin_Handled;
	}

}


//This is called after selecting a name.
public int teamban_Command_InformerAdoptCallback(Menu menu, MenuAction action,int param1,int param2)
{
	/* If an option was selected, tell the client about the item. */
	new client = param1;
	if (action == MenuAction_Select)
	{
		char info[512];
		bool found = menu.GetItem(param2, info, sizeof(info));
		//PrintToChat(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

		int target = StringToInt(info); //disconnected player
		if(informers_SetMyParent(target,client,false))
		{
			ReplyToCommand(client," [SM] You adopted '%N'",target);
			PrintToChat(client," [SM] You \x0eadopted\x01 '%N'.",target);
			PrintToChat(target," [SM] You got \x0eadopted\x01 by '%N'.",client);
			PrintToChat(target," [SM] You can now use \x0e!islay \x01-\x0e !imute\x01 - \x0e!igag \x01 - \x0e!itp \x01");
			PrintToChat(target," [SM] You can become an orphan again by using \x0e!orphan",client);
			CPrintToChatAdmins(ADMFLAG_GENERIC, " %N adopted %N",client,target);
			return;
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public Action Command_InformerOrphan(int client, int args)
{
	if(fc(client))return Plugin_Handled;
	switch(Ranks_GetClientRank(client))
	{
		case RANK_INFORMER:
			{
				if(informers_IHaveAParent(client))
				{
					informers_RemoveMyParent(client);
					ReplyToCommand(client," [SM] We \x0eremoved\x01 your \x0eparent\x01, you are now an orphan again");
					CPrintToChatAdmins(ADMFLAG_GENERIC, " %N's removed his partent",client);
					return Plugin_Handled;
				}
				else
				{
					ReplyToCommand(client," [SM] You don't have a parent");
					return Plugin_Handled;	
				}
			}
		default:
			{
				informers_RemoveMyAdoption(client);
				PrintToChat(client," [SM] You removed all your \x0eadoptions\x01.");
				ReplyToCommand(client," [SM] You removed all your adoptions");
				CPrintToChatAdmins(ADMFLAG_GENERIC, " %N's adoptions got removed",client);
				return Plugin_Handled;	
			}
	}
				
}

//Check if I have a parent.
public bool informers_IHaveAParent(int informer)
{
	if(informers_GetMyParent(informer) != 0)
	{
		return true;
	}
	else
	{
		return false;
	}
}
public bool informers_IAmEmpowered(int informer)
{
	return g_iAmEmpowered[informer];
}
public int informers_GetMyParent(int informer)
{
	int parent = g_iMyParentIs[informer];
	if(IsValidClient(parent))
	{
		return parent;
	}
	else
	{
		return 0;
	}
}
public int informers_RemoveMyAdoption(int client)
{
	g_iAmEmpowered[client] = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(g_iMyParentIs[i] == client)
		{
			g_iMyParentIs[i] = 0;
			if(IsValidClient(i))
			{
				PrintToChat(i," [SM] The staff member that \x0eadopted\x01 you \x0eorphanned you\x01.");
			}
		}
	}
}

stock bool informers_SetMyParent(int informer,int parent,bool empower=false)
{
	if(!IsValidClient(informer) && !IsValidClient(parent))
		return false;
	g_iMyParentIs[informer] = parent;
	g_iAmEmpowered[informer] = empower;
	return true;
}

public void informers_RemoveMyParent(int informer)
{
	g_iMyParentIs[informer] = 0;
	g_iAmEmpowered[informer] = false;
}

public Action Command_InformerSlay(int client, int args)
{
	if(fc(client))return Plugin_Handled;
	if (args < 1)
	{
		ReplyToCommand(client, " [SM] Usage: sm_islay <target>");
		return Plugin_Handled;
	}
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	int target = FindTarget(client,arg,true,true);
	if(target != -1)
	{
		if(GetActiveStaffCount() > 0)//there is staff online
		{
			if(informers_IHaveAParent(client))
			{
				//i have a parent
				//forward to the parent.
				char cCommand[512];
				char cArgs[512];
				GetCmdArg(0, cCommand, sizeof(cCommand));
				GetCmdArgString(cArgs,sizeof(cArgs));
				if(informers_ForwardToMyParent(client,cCommand,cArgs,informers_IAmEmpowered(client)))
				{
					ReplyToCommand(client, " [SM] Request send to your parent");
				}
				else
				{
					ReplyToCommand(client, " [SM] Something went wrong while sending the command to your parent.");
				}
				return Plugin_Handled;
			}	
			else
			{
				//i dont have a parent.
				ReplyToCommand(client, " [SM] You are not adopted and there is higher staff online. (you cannot use your informer powers)");
				return Plugin_Handled;
			}
		}
		else //no staff online
		{
			ShowActivity2(client, " [SM] ", "slayed '%N'",target);
			LogAction(client, target, "\"%L\" slayed \"%L\"", client, target);
			ForcePlayerSuicide(target);
		}
	}
	return Plugin_Handled;
}

public Action Command_InformerMute(int client, int args)
{
	if(fc(client))return Plugin_Handled;
	if (args < 2)
	{
		ReplyToCommand(client, " [SM] Usage: sm_imute <target> <time> <reason>");
		return Plugin_Handled;
	}
	char arg1[65], arg2[65], reason[256], buffer[65];

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	int time = StringToInt(arg2);
	if(time > 30)
	{
		CPrintToChat(client, TTT_ERROR... "Time is too long, lowered to 30 minutes");
		time = 30;
	}
	int target = FindTarget(client,arg1,true,true);

	GetCmdArg(3, reason, sizeof(reason));
	for (int i = 4; i <= args; i++)
    {
        GetCmdArg(i, buffer, sizeof(buffer));
        Format(reason, sizeof(reason), "%s %s", reason, buffer);
    }

	if(target != -1)
	{
		if(GetActiveStaffCount() > 0)//there is staff online
		{
			if(informers_IHaveAParent(client))
			{
				//i have a parent
				//forward to the parent.
				char cCommand[512];
				char cArgs[512];
				GetCmdArg(0, cCommand, sizeof(cCommand));
				GetCmdArgString(cArgs,sizeof(cArgs));
				if(informers_ForwardToMyParent(client,cCommand,cArgs,informers_IAmEmpowered(client)))
				{
					ReplyToCommand(client, " [SM] Request send to your parent");
				}
				else
				{
					ReplyToCommand(client, " [SM] Something went wrong while sending the command to your parent.");
				}
				return Plugin_Handled;
			}	
			else
			{
				//i dont have a parent.
				ReplyToCommand(client, " [SM] You are not adopted and there is higher staff online. (you cannot use your informer powers)");
				return Plugin_Handled;
			}
		}
		else //no staff online
		{
			ShowActivity2(client, " [SM] ", "muted '%N' for %i minutes, because: %s",target, time, reason);
			SourceComms_SetClientMute(target, true, time, true, reason);
		}
	}
	return Plugin_Handled;
}

public Action Command_InformerGag(int client, int args)
{
	if(fc(client))return Plugin_Handled;
	if (args < 2)
	{
		ReplyToCommand(client, " [SM] Usage: sm_igag <target> <time> <reason>");
		return Plugin_Handled;
	}
	char arg1[65], arg2[65], reason[256], buffer[65];

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	int time = StringToInt(arg2);
	if(time > 30)
	{
		CPrintToChat(client, TTT_ERROR... "Time is too long, lowered to 30 minutes");
		time = 30;
	}
	int target = FindTarget(client,arg1,true,true);

	GetCmdArg(3, reason, sizeof(reason));
	for (int i = 4; i <= args; i++)
    {
        GetCmdArg(i, buffer, sizeof(buffer));
        Format(reason, sizeof(reason), "%s %s", reason, buffer);
    }
	
	if(target != -1)
	{
		if(GetActiveStaffCount() > 0)//there is staff online
		{
			if(informers_IHaveAParent(client))
			{
				//i have a parent
				//forward to the parent.
				char cCommand[512];
				char cArgs[512];
				GetCmdArg(0, cCommand, sizeof(cCommand));
				GetCmdArgString(cArgs,sizeof(cArgs));
				if(informers_ForwardToMyParent(client,cCommand,cArgs,informers_IAmEmpowered(client)))
				{
					ReplyToCommand(client, " [SM] Request send to your parent");
				}
				else
				{
					ReplyToCommand(client, " [SM] Something went wrong while sending the command to your parent.");
				}
				return Plugin_Handled;
			}	
			else
			{
				//i dont have a parent.
				ReplyToCommand(client, " [SM] You are not adopted and there is higher staff online. (you cannot use your informer powers)");
				return Plugin_Handled;
			}
		}
		else //no staff online
		{
			ShowActivity2(client, " [SM] ", "gagged '%N' for %i minutes, because: %s",target, time, reason);
			SourceComms_SetClientGag(target, true, time, true, reason);
		}
	}
	return Plugin_Handled;
}

public Action Command_InformerTest(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, " [SM] Usage: sm_islay <target>");
		return Plugin_Handled;
	}
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	if(informers_IHaveAParent(client))
	{
		//i have a parent
		//forward to the parent.
		char cCommand[512];
		char cArgs[512];
		GetCmdArg(0, cCommand, sizeof(cCommand));
		GetCmdArgString(cArgs,sizeof(cArgs));
		if(informers_ForwardToMyParent(client,cCommand,cArgs,informers_IAmEmpowered(client)))
		{
			ReplyToCommand(client, " [SM] Request send to your parent");
		}
		else
		{
			ReplyToCommand(client, " [SM] Something went wrong while sending the command to your parent.");
		}
		return Plugin_Handled;
	}	

	return Plugin_Handled;
}

stock bool informers_ForwardToMyParent(int informer,char[] cCommand,char[] cArgs,bool empowered = false)
{

	//DataPack pack = new DataPack();
	//pack.WriteCell(-1); //disconnected player
	//pack.WriteString(steam64); //send steamid64

	if(!IsValidClient(informer))
		return false;

	//get his partent.
	int admin = informers_GetMyParent(informer);

	if(!IsValidClient(admin))
		return false;

	//refab the string.
	char cRefactorCommand[128];
	strcopy(cRefactorCommand, sizeof(cRefactorCommand),cCommand);
	ReplaceString(cRefactorCommand,sizeof(cRefactorCommand),"i", "",false);
	//PrintToConsole(admin,"REQUEST BY ADOPTED INFORMER ='%s'\nargs=%s",cRefactorCommand,cArgs);


	if(empowered)
	{
		PrintToChatAll("[info] %N executed %N \x09empowered command",admin,informer);
		FakeClientCommandEx(admin,"%s %s",cRefactorCommand,cArgs);
		return true;
	}

	DataPack pack = new DataPack();
	pack.WriteCell(admin);
	pack.WriteCell(informer);
	pack.WriteString(cRefactorCommand);
	pack.WriteString(cArgs);
	//global.
	g_hForwardPackFor[admin] = pack;

	informers_ShowConfirmation(admin);
	return true;
}
public void informers_ShowAdoptions(int client)
{
	Handle menu = CreateMenu(informers_ShowAdoptionsCallback);
	SetMenuTitle(menu, "Showing current adoptions");
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			int parent = informers_GetMyParent(i);
			if(IsValidClient(parent))
			{
				char buffer[255];
				Format(buffer,sizeof(buffer),"%N is adopted by %N",i,parent);
				AddMenuItem(menu, "",buffer,ITEMDRAW_DISABLED);
				count++;
			}
		}
	}
	if(count == 0)
	{
		AddMenuItem(menu, "","No informers adopted",ITEMDRAW_DISABLED);
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public int informers_ShowAdoptionsCallback(Menu menu, MenuAction action, int param1, int param2)
{
	
}


public void informers_ShowConfirmation(int client)
{
	DataPack pack = view_as<DataPack>(g_hForwardPackFor[client]);
	pack.Reset();
	int admin = pack.ReadCell();
	int informer = pack.ReadCell();
	char cCommand[128];
	char cArgs[128];
	pack.ReadString(cCommand, sizeof(cCommand));
	pack.ReadString(cArgs,  sizeof(cArgs));

	if(IsValidClient(admin) && IsValidClient(informer))
	{
		Handle menu = CreateMenu(informers_ShowConfirmationHandler);
		SetMenuTitle(menu, "'%N' forwarded a command to you.\ndo you want to execute it?\n%s %s",informer,cCommand,cArgs);
		AddMenuItem(menu, "___YES___", "Yes. (think twice about this)");
		AddMenuItem(menu, "___NO___", "No");
		AddMenuItem(menu, "___UNPARENT___", "No, and unparent.");
		DisplayMenu(menu, admin, MENU_TIME_FOREVER);
	}
}

public int informers_ShowConfirmationHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client = param1;
		char info[512];
		bool found = menu.GetItem(param2, info, sizeof(info));
		//PrintToChat(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

		DataPack pack = view_as<DataPack>(g_hForwardPackFor[client]);
		pack.Reset();
		int admin = pack.ReadCell();
		int informer = pack.ReadCell();
		char cCommand[128];
		char cArgs[128];
		pack.ReadString(cCommand, sizeof(cCommand));
		pack.ReadString(cArgs,  sizeof(cArgs));


		if(!IsValidClient(admin) && !IsValidClient(informer))
			return;
			
		if(StrEqual(info,"___YES___"))
		{
			PrintToConsole(admin,"EXECUTING->%s %s",cCommand,cArgs);
			FakeClientCommandEx(admin,"%s %s",cCommand,cArgs);
			PrintToChat(informer," [SM] Your parent '%N' \x0eexecuted\x01 the command",admin);
			PrintToChat(admin," [SM] You executed '%N''s command",informer);	
		}
		else if(StrEqual(info,"___NO___"))
		{
			PrintToChat(informer," [SM] Your parent '%N' \x0edenied\x01 the command.",admin);
			PrintToChat(admin," [SM] You denied '%N' forwarded command",informer);	
		}
		else if(StrEqual(info,"___UNPARENT___"))
		{
			informers_RemoveMyParent(informer);
			CPrintToChatAdmins(ADMFLAG_GENERIC, "%N was orphaned by %N",informer,admin);
			PrintToChat(informer," [SM] You got \x0eunparented\x01 by '%N' and the command was denied",admin);
			PrintToChat(admin," [SM] You unparented '%N' and denied the command",informer);
		}
 
	}
}
