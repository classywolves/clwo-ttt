#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#include <generics>
#include <ttt_ranks>
#include <colorlib>

int g_iMyParentIs[MAXPLAYERS+1];
bool g_iAmEmpowered[MAXPLAYERS+1];
Handle g_hForwardPackFor[MAXPLAYERS+1];

public void OnPluginStart()
{
    RegisterCmds();

    PostPluginStart();
}

public int RegisterCmds()
{

}

public int PostPluginStart()
{

}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("ttt_informers");

    CreateNative("informers_IHaveAParent", Native_IHaveAParent);
    CreateNative("informers_IAmEmpowered", Native_IAmEmpowered);
    CreateNative("informers_GetMyParent", Native_GetMyParent);
    CreateNative("informers_RemoveMyAdoption", Native_RemoveMyAdoption);
    CreateNative("informers_SetMyParent", Native_SetMyParent);
    CreateNative("informers_RemoveMyParent", Native_RemoveMyParent);
    CreateNative("informers_CanAdopt", Native_CanAdopt);
    CreateNative("informers_ForwardToMyParent", Native_ForwardToMyParent);
    CreateNative("informers_ShowAdoptions", Native_ShowAdoptions);
    return APLRes_Success;
}

public int Native_IHaveAParent(Handle plugin, int numParams)
{
    int informer = GetNativeCell(1);

	if(g_iMyParentIs[informer] != 0)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

public int Native_IAmEmpowered(Handle plugin, int numParams)
{
    int informer = GetNativeCell(1);

	return g_iAmEmpowered[informer];
}

public int Native_GetMyParent(Handle plugin, int numParams)
{
    int informer = GetNativeCell(1);

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

public int Native_RemoveMyAdoption(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
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

    return 0;
}

public int Native_SetMyParent(Handle plugin, int numParams)
{
    int informer, parent;
    bool empower;
	
    informer = GetNativeCell(1);
    parent = GetNativeCell(2);
    empower = view_as<bool>(GetNativeCell(3));

    if(!IsValidClient(informer) && !IsValidClient(parent))
		return 0;
	g_iMyParentIs[informer] = parent;
	g_iAmEmpowered[informer] = empower;
	return 1;
}

public int Native_RemoveMyParent(Handle plugin, int numParams)
{
    int informer = GetNativeCell(1);

	g_iMyParentIs[informer] = 0;
	g_iAmEmpowered[informer] = false;
}

public int Native_CanAdopt(Handle plugin, int numParams)
{
    int informer = GetNativeCell(1);
    int client = GetNativeCell(2);

	AdminId infAdminId = GetUserAdmin(informer);
	AdminId clAdminId = GetUserAdmin(client);
	
	if(GetAdminFlag(infAdminId, Admin_Root, Access_Real))
	{
		return 0;
	}
	if(GetAdminFlag(clAdminId, Admin_Root, Access_Real))
	{
		return 1;
	}	
	if(Ranks_GetClientRank(informer) < RANK_INFORMER)
	{
		return 0;
	}
	if(Ranks_GetClientRank(informer) == RANK_INFORMER || (CheckCommandAccess(client, "access_adoptstaff", ADMFLAG_VOTE, false) && Ranks_GetClientRank(informer) < Ranks_GetClientRank(client)))
	{
		return 1;
	}
	if(informer == -1)
	{
		return 0;
	}
	else
	{
		return 0;
	}
}

public int Native_ForwardToMyParent(Handle plugin, int numParams)
{
    int informer = GetNativeCell(1);
    char cCommand[64], cArgs[128];
    bool empowered, request;  
    GetNativeString(2, cCommand, sizeof(cCommand));
    GetNativeString(3, cArgs, sizeof(cArgs));
    empowered = view_as<bool>(GetNativeCell(4));
    request = view_as<bool>(GetNativeCell(5));

	//DataPack pack = new DataPack();
	//pack.WriteCell(-1); //disconnected player
	//pack.WriteString(steam64); //send steamid64

	if(!IsValidClient(informer))
    {
		return 0;
    }
	//get his partent.
	int admin = g_iMyParentIs[informer];

	if(!IsValidClient(admin))
    {
		return 0;
    }

	char cRefactorCommand[128];
	strcopy(cRefactorCommand, sizeof(cRefactorCommand),cCommand);

	//refab the string.
	if(!request)
	{
		ReplaceString(cRefactorCommand,sizeof(cRefactorCommand),"i", "",false);
	}

	//PrintToConsole(admin,"REQUEST BY ADOPTED INFORMER ='%s'\nargs=%s",cRefactorCommand,cArgs);

	if(!CheckCommandAccess(g_iMyParentIs[informer], cRefactorCommand, ADMFLAG_ROOT, false))
	{
		CPrintToChat(informer, "[SM] Your parent does not have access to that command!");
		return 0;
	}

	if(empowered && !request)
	{
		PrintToChatAll("[SM] %N executed %N \x0eempowered\x01 command (%s %s)",admin,informer, cCommand, cArgs);
		FakeClientCommandEx(admin,"%s %s",cRefactorCommand,cArgs);
		return 1;
	}

	DataPack pack = new DataPack();
	pack.WriteCell(admin);
	pack.WriteCell(informer);
	pack.WriteString(cRefactorCommand);
	pack.WriteString(cArgs);
	//global.
	g_hForwardPackFor[admin] = pack;

	informers_ShowConfirmation(admin);
	return 1;
}

public int Native_ShowAdoptions(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

	Handle menu = CreateMenu(informers_ShowAdoptionsCallback);
	SetMenuTitle(menu, "Showing current adoptions");
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			int parent = g_iMyParentIs[i];
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

public int informers_ShowConfirmation(int client)
{
	DataPack pack = view_as<DataPack>(g_hForwardPackFor[client]);
	pack.Reset();
	int admin = pack.ReadCell();
	int informer = pack.ReadCell();
	char cCommand[128];
	char cArgs[128];
	char cRequest[128];
	pack.ReadString(cCommand, sizeof(cCommand));
	pack.ReadString(cArgs,  sizeof(cArgs));

	Format(cRequest, sizeof(cRequest), "%s %s", cCommand, cArgs);
	ReplaceString(cRequest, sizeof(cRequest), "  ", " ", false);

	if(IsValidClient(admin) && IsValidClient(informer))
	{
		Handle menu = CreateMenu(informers_ShowConfirmationHandler);
		SetMenuTitle(menu, "'%N' forwarded a command to you.\ndo you want to execute it?\n%s",informer,cRequest);
		AddMenuItem(menu, "___YES___", "Yes. (think twice about this)");
		AddMenuItem(menu, "___NO___", "No");
		AddMenuItem(menu, "___UNPARENT___", "No, and unparent.");
		DisplayMenu(menu, admin, MENU_TIME_FOREVER);
	}

    return 0;
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
			PrintToChatAll(" [SM] %N \x0eexecuted\x01 %N's requested command (%s %s)", admin, informer, cCommand, cArgs);	
		}
		else if(StrEqual(info,"___NO___"))
		{
			PrintToChat(informer," [SM] Your parent '%N' \x0edenied\x01 the command.",admin);
			ReplyToCommand(admin," [SM] You denied '%N' forwarded command",informer);	
		}
		else if(StrEqual(info,"___UNPARENT___"))
		{
			g_iMyParentIs[informer] = 0;
	        g_iAmEmpowered[informer] = false;
			CPrintToChatAdmins("sm_handle", "%N was orphaned by %N",informer,admin);
			PrintToChat(informer," [SM] You got \x0eunparented\x01 by '%N' and the command was denied",admin);
			ReplyToCommand(admin," [SM] You unparented '%N' and denied the command",informer);
		}
 
	}
}