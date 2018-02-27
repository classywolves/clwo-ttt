#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <clientprefs>
#include <cstrike>
#include <sdktools_entinput>
#include <sdktools_functions>
#include <player_methodmap>
//#include <inilo>
//#include <updater>
#include <imod>
#include <ttt>
#include <ttt_shop>

#define PLUGIN_NAME 			"iNilo TTT"
#define PLUGIN_VERSION_M 			"0.0.1"
#define PLUGIN_AUTHOR 			"iNilo.net"
#define PLUGIN_DESCRIPTION		"iNilo TTT"
#define PLUGIN_URL				"http://inilo.net"

#define UPDATE_URL    "https://trclwo.inilo.net/deploy/deploy.php?request="

#define MAX_SPECBAN_TIME 60
Handle g_hSpecBanTime = null;
Handle g_hSpecBanBy = null;
Handle g_hSpecBanByName = null;
Handle g_hSpecBanReason = null;
Handle g_hSpecBanCount = null;
Handle g_hSpecUnBanCount = null;
int g_iClientSettingReasonFor[MAXPLAYERS+1];


public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION_M,
	url = PLUGIN_URL
};



public OnPluginStart()
{
	RegisterCvars();
	RegisterCmds();
	HookEvents();
	PostPluginStart();
	PrintToChatAll(" \x03[\x01%s\x03] \x01>\x04Online\x01<",PLUGIN_NAME);

}
public PostPluginStart()
{


}
public OnPluginEnd()
{
	PrintToChatAll(" \x03[\x01%s\x03] \x01>\x02Offline\x01<",PLUGIN_NAME);
}
public void RegisterCvars()
{
	g_hSpecBanTime = RegClientCookie("SpecBan_Time", "Amount of minutes left on spectator", CookieAccess_Protected);
	g_hSpecBanBy = RegClientCookie("SpecBan_By", "Banned by this user", CookieAccess_Protected);
	g_hSpecBanByName = RegClientCookie("SpecBan_ByName", "Banned by this username", CookieAccess_Protected);
	g_hSpecBanReason = RegClientCookie("SpecBan_Reason", "Banned because of", CookieAccess_Protected);
	g_hSpecBanCount = RegClientCookie("SpecBan_BanCount", "Amount of previous bans", CookieAccess_Protected);
	g_hSpecUnBanCount = RegClientCookie("SpecBan_UnbanCount", "Amount of previous unbans", CookieAccess_Protected);
}
public void RegisterCmds()
{
	#if defined _inilo_included_
	hello();
	#endif
	RegConsoleCmd("MaxClients", Command_MaxClients ,"");
	RegAdminCmd("sm_poop", Command_Poop, ADMFLAG_ROOT, "");
	RegConsoleCmd("sm_t", Command_T,"");
	RegConsoleCmd("sm_traitor", Command_T,"");
	RegConsoleCmd("sm_innocent", Command_T,"");
	RegConsoleCmd("sm_ct", Command_CT,"");
	RegConsoleCmd("sm_detective", Command_CT,"");
	RegConsoleCmd("sm_spec", Command_Spec,"");
	RegConsoleCmd("sm_specbans", Command_SpecBans,"");
	RegAdminCmd("sm_specban", Command_SpecBan, ADMFLAG_BAN, "sm_specban <name or #userid or steamid> [time 0 - 360]");
}
public void HookEvents()
{
	//if (LibraryExists("updater"))
	//{
	//	char self[128];
	//	GetPluginFilename(GetMyHandle(), self, sizeof(self));
	//	ReplaceString(self,sizeof(self),".smx", "",false);
	//	char cUpdateURL[512];
	//	Format(cUpdateURL,sizeof(cUpdateURL),"%s%s",UPDATE_URL,self);
	//	Updater_AddPlugin(UPDATE_URL)
	//}


	HookEvent("player_team", CheckForSpecBanUserEvent);
	HookEvent("player_spawn", CheckForSpecBanUserEvent);
	HookEvent("player_team", CheckForSpecBanUserEvent);
	HookEvent("round_prestart", CheckForSpecBan, EventHookMode_Post);
	HookEvent("round_end", CheckForSpecBan, EventHookMode_Post);
	AddCommandListener(Command_Jointeam, "jointeam");
	//AddCommandListener(Command_Jointeam, "jointeam");	
}

public Action CheckForSpecBanUserEvent(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid")); 
	VerifyPlayer(client, true);
}
public Action CheckForSpecBan(Event event, const char[] name, bool dontBroadcast)
{
	for (int x = 1; x <= MaxClients; x++)
	{
		if(!IsValidClient(x))
			continue;
		VerifyPlayer(x, true);
	}
}

public Action VerifyPlayer(int client, bool message)
{
	if(!IsValidClient(client))
		return Plugin_Continue;
	if(!IsClientSpecBanned(client))
		return Plugin_Continue;
	if(GetClientTeam(client) != CS_TEAM_T && GetClientTeam(client) != CS_TEAM_CT)
		return Plugin_Continue;
	//move player to spec.
	ForcePlayerSuicide(client);
	CS_SwitchTeam(client, CS_TEAM_SPECTATOR);
	//ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	if(message)
		ShowBlockedPlayerPanel(client);

	return Plugin_Continue;
}

public Action Command_Jointeam(int client, const char[] command, int argc)
{
	if(!IsValidClient(client))
		return Plugin_Continue;

	VerifyPlayer(client, true);
	//ShowBlockedPlayerPanel(client);
	//CS_SwitchTeam(client,CS_TEAM_T);
	//ChangeClientTeam(client, CS_TEAM_T);
	return Plugin_Continue;
}

public void OnMapStart()
{
	CreateTimer(60.0, Timer_60s, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public Action Timer_60s(Handle timer, Handle hndl)
{
	for (int client = 1; client <= MaxClients; client++)//loop trough all players // I = CLIENT ID
	{
		if(!IsValidClient(client))
			continue;
		if(!IsClientSpecBanned(client))
			continue;
		LowerSpecBan(client, 1);
		PrintToChat(client, " [SM] %i minutes remaining on your spectator ban", GetSpecBanTime(client) -1);
	}
	return Plugin_Continue;	
}

public void LowerSpecBan(int client, int amount)
{
	int current = GetSpecBanTime(client);
	char cTemp[64];
	Format(cTemp, sizeof(cTemp), "%i", current - amount);
	SetClientCookie(client, g_hSpecBanTime, cTemp);
}

public void OnClientPutInServer(int client)
{

}
public void OnClientAuthorized(int client, const char[] auth)
{

}
public void OnClientPostAdminCheck(int client)
{

}
public void OnClientDisconnect(int client) 
{

}
public void LateLoadAll()
{
	for (int client = 1; client <= MaxClients; client++)//loop trough all players // I = CLIENT ID
	{
		if(IsValidClient(client))
		{
			LateLoadClient(client);
		}
	}

}

public void LateLoadClient(int client)
{

}

public Action Command_T(int client, int args)
{
	CS_SwitchTeam(client, CS_TEAM_T);
	return Plugin_Handled;
}
public Action Command_CT(int client, int args)
{
	CS_SwitchTeam(client, CS_TEAM_CT);
	return Plugin_Handled;
}
public Action Command_Spec(int client, int args)
{
	CS_SwitchTeam(client, CS_TEAM_SPECTATOR);
	return Plugin_Handled;
}
public Action Command_SpecBan(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "sm_specban <name or #userid or steam:id> [time 0 - 60] [reason]")
	}
	char arg1[65];
	GetCmdArg(1, arg1, sizeof(arg1));

	char arg2[65];
	GetCmdArg(2, arg2, sizeof(arg2));

	char arg3[65];
	GetCmdArg(3, arg3, sizeof(arg3));

	int value = 0;
	if(args < 2)
	{
		//no time given, put time at 15 min
		value = 15;
	}
	else
	{
		value = StringToInt(arg2);
	}
	
	if(value < 1)
	{
		ReplyToCommand(client, " Bad time parameter, must be between 1 and 60");
		return Plugin_Handled;
	}
	if(value > MAX_SPECBAN_TIME)
	{
		ReplyToCommand(client, " Rounded to the maxtime");
		value = MAX_SPECBAN_TIME;
	}

	if(args < 3)
	{
		//no reason given, launch menu.
		arg3 = "";
	}
	else if(strlen(arg3) > 0)
	{
		//custom reason given - do nothing
	}
	else
	{
		//Invalid reason given - handle this case just in case.
		ReplyToCommand(client, " Bad reason parameter, length must be above 0");
		return Plugin_Handled;
	}


	if (StrContains(arg1, "STEAM_1:", false) == 0) {
		PerformBanAuth(client, arg1, value, arg3)
	} else {
		int target = FindTarget(client, arg1, true, true);
		if (target == -1)
		{
			ReplyToCommand(client, " [SM] Failed to locate target");
			return Plugin_Handled;
		}

		if(IsClientSpecBanned(target))
		{
			ReplyToCommand(client, " [SM] This player is already spectator banned");
			return Plugin_Continue;
		}
		PerformBan(client, target, value, arg3);
		VerifyPlayer(client, true);
		ShowActivity2(client, " [SM] ","Specbanned '%N' for %i minutes", target, value);
		LogAction(client, target, "\"%L\" Specbanned \"%L\" for %i minutes", client, target, value);
	}

	return Plugin_Handled;
}

public Action Command_SpecBans(int client, int args)
{
	if(client != 0)
	{
		Menu SpecMenu = BuildSpecBansMenu(client);
		SpecMenu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}
public void AskAdminReason(int admin, int target)
{
	if(!IsValidClient(admin))
		return;
	if(!IsValidClient(target))
		return;

	Menu ReasonMenu = BuildResonMenu(admin, target);
	ReasonMenu.Display(admin, MENU_TIME_FOREVER);
	
}

public void OnEntityCreated(int entity, const char[] classname)
{
	//PrintToConsoleiNilo("\t[OnEntityCreated] %s", classname);
	if(StrEqual(classname, "smokegrenade_projectile"))
	{
		KillEntityIn(entity, 20.0);
		CreateTimer(0.1, delay, EntIndexToEntRef(entity)); 
	}
	if(StrEqual(classname, "decoy_projectile"))
	{
		KillEntityIn(entity, 20.0);
		CreateTimer(0.1, delay, EntIndexToEntRef(entity)); 
	}

}


public Action:delay(Handle:timer, any:ref) 
{ 
    new entity = EntRefToEntIndex(ref); 

    if(entity > MaxClients) 
    { 

        SDKHookEx(entity, SDKHook_StartTouch, touch); 
        SDKHookEx(entity, SDKHook_Touch, touch); 
        SDKHookEx(entity, SDKHook_EndTouch, touch); 
    } 
} 

public Action:touch(entity, other) 
{ 
    if(other > MaxClients) 
    { 
        new String:classname[30]; 
        GetEntityClassname(other, classname, sizeof(classname)); 
        if(StrEqual(classname, "func_breakable")) 
        { 
            AcceptEntityInput(entity, "Kill"); 
        } 
    } 
}  

Menu BuildSpecBansMenu(int admin)
{
	bool staff = CheckCommandAccess(admin, "sm_specban", ADMFLAG_BAN);
	/* Create the menu Handle */
	Menu menu = new Menu(BuildSpecBansMenu_Callback);
	if(staff)
	{
		menu.SetTitle("Select a player to unban");
	}
	else
	{
		menu.SetTitle("List of specbans");
	}
	int count;
	for (int search = 1; search <= MaxClients; search++)
	{
		if(!IsValidClient(search))
			continue;
		char name[255];
		char targetid[3];
		GetClientName(search, name, sizeof(name));
		IntToString(search, targetid, sizeof(targetid));
		if(IsClientSpecBanned(search))
		{
			count++;
			Format(name, sizeof(name), "%s [%i min left]", name, GetSpecBanTime(search));
			if(staff)
			{
				menu.AddItem(targetid, name);
			}
			else
			{
				menu.AddItem(targetid, name, ITEMDRAW_DISABLED);
			}
		}
	}
	if(count == 0)
	{
		AddMenuItem(menu, "", "None of the online players have a spectator ban", ITEMDRAW_DISABLED);
	}
	return menu;

}
Menu BuildResonMenu(int admin, int target)
{
	Menu menu = new Menu(ReasonMenu_Callback);
	char cTitle[128];
	Format(cTitle, sizeof(cTitle), "Please select the reason why you specbanned %N", target);
	menu.SetTitle(cTitle);
	g_iClientSettingReasonFor[admin] = target;
	menu.AddItem("#RDM#", "RDM");
	menu.AddItem("#TBAIT#", "Traitor baiting");
	menu.AddItem("#FALSEKOS#", "False KOS");
	menu.AddItem("#GHOST#", "Ghosting");
	menu.AddItem("#PROPBLOCK#", "Prop blocking");
	menu.AddItem("#TROLL#", "Trolling");
	menu.AddItem("#CAMP#", "Camping");
	menu.AddItem("#REVENGERDM#", "Revenge RDM");
	return menu;
}

public void GetSpecBanReason(int client, char cOutput[128], int maxsize)
{
	char cTemp[64];
	GetClientCookie(client, g_hSpecBanReason, cTemp, sizeof(cTemp));
	TranslateReasonToNiceText(cTemp, cOutput, maxsize);
}

public void TranslateReasonToNiceText(const char[] cInput, char cOutput[128], int maxlen)
{
	if(StrEqual(cInput,"#UNKNOWN#"))
	{
		strcopy(cOutput, maxlen, "No reason was given");
		return;
	}
	if(StrEqual(cInput,"#RDM#"))
	{
		strcopy(cOutput, maxlen, "RDM'ing");
		return;
	}
	if(StrEqual(cInput,"#TBAIT#"))
	{
		strcopy(cOutput, maxlen, "Traitor baiting");
		return;
	}
	if(StrEqual(cInput,"#FALSEKOS#"))
	{
		strcopy(cOutput, maxlen, "False K.O.S calling");
		return;
	}
	if(StrEqual(cInput,"#GHOST#"))
	{
		strcopy(cOutput, maxlen, "Ghosting");
		return;
	}
	if(StrEqual(cInput,"#PROPBLOCK#"))
	{
		strcopy(cOutput, maxlen, "Prop blocking");
		return;
	}
	if(StrEqual(cInput,"#TROLL#"))
	{
		strcopy(cOutput, maxlen, "Trolling");
		return;
	}
	if(StrEqual(cInput,"#CAMP#"))
	{
		strcopy(cOutput, maxlen, "Camping");
		return;
	}
	if(StrEqual(cInput,"#REVENGERDM#"))
	{
		strcopy(cOutput, maxlen, "Revenge RDM'ing");
		return;
	}
	strcopy(cOutput, maxlen, cInput);
}


public int BuildSpecBansMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client = param1;
		bool staff = CheckCommandAccess(client, "sm_specban", ADMFLAG_BAN);
		if(staff)
		{
			char info[512];
			menu.GetItem(param2, info, sizeof(info));
			int target = StringToInt(info);
			if(!IsValidClient(target))
				return;
			Menu UnSpecBanMenu = BuildUnSpecBanMenu(client, target);
			if(UnSpecBanMenu != null)
			{
				UnSpecBanMenu.Display(client, MENU_TIME_FOREVER);
			}
		}
 
	}
}
public int ReasonMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client = param1;
		char info[512];
		menu.GetItem(param2, info, sizeof(info));
		int target = g_iClientSettingReasonFor[client];
		if(!IsValidClient(target))
			return;
		SetSpecBanReason(target, info);

		char cTemp[128];
		GetSpecBanReason(target, cTemp, sizeof(cTemp));
		ShowActivity2(client, " [SM] ","Set the reason of '%N' specban to %s", target, cTemp);
		LogAction(client, target, "\"%L\" Set the reason of \"%L\" specban to %s", client, target, cTemp);
	}
}


Menu BuildUnSpecBanMenu(int admin, int target)
{
	Menu menu = new Menu(UnSpecBanMenu_Callback);
	if(!IsValidClient(target))
		return null;

	char name[255];
	GetClientName(target, name, sizeof(name));
	Format(name,sizeof(name),"Info on %s", name);
	menu.SetTitle(name);

	char cTemp[128];
	char cTemp2[128];
	char cDisplay[128];
	GetClientCookie(target, g_hSpecBanBy, cTemp2, sizeof(cTemp2));
	GetClientCookie(target, g_hSpecBanByName, cTemp, sizeof(cTemp));
	Format(cDisplay, sizeof(cDisplay), "By: %s [acc: %i]", cTemp, cTemp2);
	menu.AddItem("", cDisplay, ITEMDRAW_DISABLED);

	
	GetSpecBanReason(target, cTemp, sizeof(cTemp));
	Format(cDisplay, sizeof(cDisplay), "Reason: %s", cTemp);
	menu.AddItem("", cDisplay, ITEMDRAW_DISABLED);


	GetClientCookie(target, g_hSpecBanTime, cTemp, sizeof(cTemp));
	Format(cDisplay, sizeof(cDisplay), "%s minutes remaining", cTemp);
	menu.AddItem("", cDisplay, ITEMDRAW_DISABLED);



	char targetid[3];
	IntToString(target, targetid, sizeof(targetid));

	menu.AddItem(targetid, "Un spec-ban the player");
	menu.AddItem("#CANCEL#", "Leave spec banned");
	return menu;
}



public int UnSpecBanMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		int client = param1;
		char info[512];
		menu.GetItem(param2, info, sizeof(info));
		int target = StringToInt(info);
		if(IsValidClient(target))
		{
			if(PerformUnban(client, target))
			{
				ShowActivity2(client, " [SM] ","Unspecbanned '%N'", target);
				LogAction(client, target, "\"%L\" Unspecbanned \"%L\"", client, target);
			}
		}
		
 
	}
}

public bool PerformUnban(int client, int target)
{
	SetClientCookie(target, g_hSpecBanTime, "0");

	char cValue[8];
	char cTemp[8];
	GetClientCookie(client, g_hSpecUnBanCount, cValue, sizeof(cValue));
	Format(cTemp, sizeof(cTemp), "%i", StringToInt(cValue) + 1);
	SetClientCookie(target, g_hSpecUnBanCount, cTemp);

	return true;
}

public PerformBanAuth(int client, char[] authID, int time, char[] reason) {
	char cTemp[64];
	Format(cTemp, sizeof(cTemp), "%i", time);
	SetAuthIdCookie(authID, g_hSpecBanTime, cTemp);

	Format(cTemp, sizeof(cTemp), "%i", GetSteamAccountID(client));
	SetAuthIdCookie(authID, g_hSpecBanBy, cTemp);

	Format(cTemp, sizeof(cTemp), "%N", client);
	SetAuthIdCookie(authID, g_hSpecBanByName, cTemp);

	if(strlen(reason) > 0)
	{
		//received custom reason
		Format(cTemp, sizeof(cTemp), "%s" ,reason);
		SetAuthIdCookie(authID, g_hSpecBanReason, cTemp);
	}
	else
	{
		Format(cTemp, sizeof(cTemp), "%s" ,"#UNKNOWN#");
		SetAuthIdCookie(authID, g_hSpecBanReason, cTemp);
	}
	
	// Currently there is no GetAuthIdCookie and I know of no workaround.
	/*
	char cValue[8];
	GetAuthIdCookie(authID, g_hSpecBanCount, cValue, sizeof(cValue));
	Format(cTemp, sizeof(cTemp), "%i", StringToInt(cValue) + 1);
	SetAuthIdCookie(authID, g_hSpecBanCount, cTemp);
	*/
	
	/*
	if(strlen(reason) > 0)
	{
		//request the admin for a reason.
		AskAdminReason(client, authID);
	}
	*/
}

public bool PerformBan(int client, int target, int time, char[] reason)
{
	char cTemp[64];
	Format(cTemp, sizeof(cTemp), "%i", time);
	SetClientCookie(target, g_hSpecBanTime, cTemp);

	Format(cTemp, sizeof(cTemp), "%i", GetSteamAccountID(client));
	SetClientCookie(target, g_hSpecBanBy, cTemp);

	Format(cTemp, sizeof(cTemp), "%N", client);
	SetClientCookie(target, g_hSpecBanByName, cTemp);

	if(strlen(reason) > 0)
	{
		//received custom reason
		Format(cTemp, sizeof(cTemp), "%s" ,reason);
		SetClientCookie(target, g_hSpecBanReason, cTemp);
	}
	else
	{
		Format(cTemp, sizeof(cTemp), "%s" ,"#UNKNOWN#");
		SetClientCookie(target, g_hSpecBanReason, cTemp);
	}
	
	char cValue[8];
	GetClientCookie(target, g_hSpecBanCount, cValue, sizeof(cValue));
	Format(cTemp, sizeof(cTemp), "%i", StringToInt(cValue) + 1);
	SetClientCookie(target, g_hSpecBanCount, cTemp);
	
	if(strlen(reason) > 0)
	{
		//request the admin for a reason.
		AskAdminReason(client, target);
	}
}

public void SetSpecBanReason(int target, const char[] cReason)
{
	SetClientCookie(target, g_hSpecBanReason, cReason);
}
/*

g_hSpecBanReason
*/

bool IsClientSpecBanned(int client)
{
	if(GetSpecBanTime(client) > 0 || GetSpecBanTime(client) == -1)
	{
		return true;
	}
	else
	{
		return false;
	}
}
int GetSpecBanTime(int client)
{
	if(!AreClientCookiesCached(client))
		return -1;
	char cValue[8];
	GetClientCookie(client, g_hSpecBanTime, cValue, sizeof(cValue));
	return StringToInt(cValue);
}

public Action Command_MaxClients(int client, int args)
{
	ReplyToCommand(client, "MaxClients == %i", MaxClients);
}

public Action Command_Poop(int client, int args)
{
	char arg1[65];
	GetCmdArg(1, arg1, sizeof(arg1));
	if(StrEqual(arg1,"traitor"))
	{
		if(IsValidPlayer(client))
		{
			TTT_SetClientRole(client,TTT_TEAM_TRAITOR);
			PrintToChat(client,"OK");
		}
		
	}
	if(StrEqual(arg1,"credits"))
	{
		if(IsValidPlayer(client))
		{
			int current = TTT_GetClientCredits(client);
			current += 50;
			TTT_AddClientCredits(client,current);
			PrintToChat(client,"OK credits");
		}
		
	}
	if(StrEqual(arg1,"respawn"))
	{
		if(IsValidClient(client))
		{
			CS_RespawnPlayer(client);
		}
		
	}
	if(StrEqual(arg1,"debug"))
	{
		PrintToChat(client,"working on spy");
		for (int i = 1; i <= MaxClients; i++)//loop trough all players // I = CLIENT ID
		{
			if(IsValidClient(i))
			{
				int role = TTT_GetClientRole(i);
				if(role == TTT_TEAM_TRAITOR)
				{
					PrintToChat(client,"%N is a traitor",i);
				}
			}
		}
	}
}
public void ShowBlockedPlayerPanel(int client)
{
	if(!IsValidClient(client))
		return;
	Panel panel = null;
	panel = BuildBlockedPlayerPanel(client);
	if(panel != null && GetSpecBanTime(client) != 0)
	{
		panel.Send(client, Panel_Handler, MENU_TIME_FOREVER);
	}
	delete panel;

}

public Panel_Handler(Handle panel, MenuAction action, param1, param2)
{
        // regardless of what the MenuAction is, do nothing
}

Panel BuildBlockedPlayerPanel(int client)
{
	if(!IsValidClient(client))
		return null;

	char cTemp[128];
	char cTemp2[128];
	char cDisplay[128];

	Panel panel = new Panel();
	if(GetSpecBanTime(client) == -1)
	{
		panel.SetTitle("We are still downloading your spectator ban information\nPlease wait a bit\nThanks!");
	}
	else
	{
		panel.SetTitle("You have been spectator banned by");

		GetClientCookie(client, g_hSpecBanBy, cTemp2, sizeof(cTemp2));
		GetClientCookie(client, g_hSpecBanByName, cTemp, sizeof(cTemp));
		Format(cDisplay, sizeof(cDisplay), "%s [acc: %i]", cTemp, cTemp2);
		panel.DrawText(cDisplay);

		panel.DrawText("Reason:");
		GetSpecBanReason(client, cTemp, sizeof(cTemp));
		panel.DrawText(cTemp);

		GetClientCookie(client, g_hSpecBanTime, cTemp, sizeof(cTemp));
		Format(cDisplay, sizeof(cDisplay), "%s remaining minutes on spectator", cTemp);
		panel.DrawText(cDisplay);
	}


	//menu.AddItem("___CLOSE___","Close");
	panel.DrawItem("Close.");
	return panel;
}