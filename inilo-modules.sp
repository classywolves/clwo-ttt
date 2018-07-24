#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <clientprefs>
#include <cstrike>
#include <sdktools_entinput>
#include <sdktools_functions>
#include <imod>
//#include <main>
//#include <inilo>
//#include <updater>
//#include <logger>
#include <ttt>



/* Plugin Info */
#define PLUGIN_NAME 			"iNilo Modules"
#define PLUGIN_VERSION_M 			"0.0.1"
#define PLUGIN_AUTHOR 			"iNilo.net"
#define PLUGIN_DESCRIPTION		"iNilo - non jb module"
#define PLUGIN_URL				"http://inilo.net"

//#define UPDATE_URL    "https://trclwo.inilo.net/deploy/deploy.php?request="



#include "inilo/inilo_spectate.sp"


public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION_M,
	url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	//setLogSource("iniloModules");

	RegPluginLibrary("iMod");
	CreateNative("iMod_GetUserType", Native_GetUserType);
	CreateNative("iMod_HigherThen", Native_HigherThen);
	CreateNative("iMod_GetUserTypeString", Native_GetUserTypeString);
	CreateNative("iMod_HigherThenString", Native_HigherThenString);
	CreateNative("iMod_IsStaff", Native_IsStaff);
	CreateNative("iMod_IsBroadcast", Native_IsBroadcast);

	return APLRes_Success;
}


	public OnPluginStart()
	{
	RegisterCvars();
	RegisterCmds();
	HookEvents();
	LateLoadAll();
	staff_OnPluginStart();
	spectate_OnPluginStart();

	PostPluginStart();
	PrintToChatAll(" \x03[\x01%s\x03] \x01>\x04Online\x01<",PLUGIN_NAME);

}
public PostPluginStart()
{
	InitWeaponList();

}
public OnPluginEnd()
{
	PrintToChatAll(" \x03[\x01%s\x03] \x01>\x02Offline\x01<",PLUGIN_NAME);
}
public void RegisterCvars()
{

}
public OnLibraryAdded(const char[] name)
{
	/*
	if (StrEqual(name, "updater"))
	{
		char self[128];
		GetPluginFilename(GetMyHandle(), self, sizeof(self));
		ReplaceString(self,sizeof(self),".smx", "",false);
		char cUpdateURL[512];
		Format(cUpdateURL,sizeof(cUpdateURL),"%s%s",UPDATE_URL,self);
		Updater_AddPlugin(cUpdateURL)
	}
	*/
}
public void RegisterCmds()
{
	/*
	#if defined _inilo_included_
	hello();
	#endif
	*/
	RegConsoleCmd("sm_myskin", Command_MySkins,"sm_myskin respawns your current weapons with skins of your own");
	RegConsoleCmd("sm_myskins", Command_MySkins,"sm_myskins respawns your current weapons with skins of your own");
	RegConsoleCmd("sm_onlinestaff", Command_WhoCanReadStaffChat ,"sm_onlinestaff prints a list of powerd-staff. (non informers)");
}
public void HookEvents()
{
	/*
	if (LibraryExists("updater"))
	{
		char self[128];
		GetPluginFilename(GetMyHandle(), self, sizeof(self));
		ReplaceString(self,sizeof(self),".smx", "",false);
		char cUpdateURL[512];
		Format(cUpdateURL,sizeof(cUpdateURL),"%s%s",UPDATE_URL,self);
		Updater_AddPlugin(UPDATE_URL)
	}
	*/
	
}
public void OnMapStart()
{

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

public Action Command_WhoCanReadStaffChat(int client, int args)
{
	//char buffer[1024];
	int[] mods = new int[MaxClients+1];
	int num_mods = GetStaffInArray(mods,MaxClients+1);
	PrintToChat(client," [SM] Check console output");
	PrintToConsole(client,"%i staff online",num_mods);
	PrintToConsole(client,"------------------------------------");
	for (int mod = 0; mod <= num_mods; mod++)
	{
		int send_to = mods[mod];
		if (IsValidClient(send_to))
		{
			PrintToConsole(client,"> %L",send_to);
		}
	}
	PrintToConsole(client,"------------------------------------");
	return Plugin_Handled;
}


int weapon_ak47 = CS_TEAM_T; //t gun
int weapon_aug = CS_TEAM_CT; //ct gun
int weapon_awp = -1;
int weapon_bizon = -1;
int weapon_deagle = -1;
//int  weapon_elite = CS_TEAM_CT;
int weapon_famas = CS_TEAM_CT; //ct gun
int weapon_fiveseven = CS_TEAM_CT; //ct gun
//int  weapon_flashbang = 4;
int weapon_g3sg1 = CS_TEAM_T; //t gun
int weapon_galilar = CS_TEAM_T; //t gun
int weapon_glock = CS_TEAM_T; //t gun
int weapon_hkp2000 = CS_TEAM_CT; //ct gun
int weapon_m249 = -1;
int weapon_m4a1 = CS_TEAM_CT; //ct gun
int weapon_mac10 = CS_TEAM_T; //t gun
int weapon_mag7 = CS_TEAM_CT; //ct gun
//int  weapon_molotov = CS_TEAM_T; //t gun
int weapon_mp7 = -1;
int weapon_mp9 = CS_TEAM_CT; //ct gun
int weapon_negev = -1;
int weapon_nova = -1;
int weapon_p250 = -1;
int weapon_p90 = -1;
int weapon_scar20 = CS_TEAM_CT; //ct gun
int weapon_sg556 = CS_TEAM_T; //t gun
//int  weapon_ssg08 = CS_TEAM_CT;
int weapon_tec9 = CS_TEAM_T; //t gun
int weapon_ump45 = -1;
int weapon_xm1014 = -1;
int weapon_sawedoff = CS_TEAM_T; //t gun



Handle g_WeaponDataBase = null;
//int const weapon_database[]
/*
0 = teamless (as for most of games)
1 = spectators (as for most of games)
2 = terrorists
3 = CT
*/
public void InitWeaponList()
{
	g_WeaponDataBase = CreateTrie();


	SetTrieValue(g_WeaponDataBase, "weapon_ak47"      , weapon_ak47);
	SetTrieValue(g_WeaponDataBase, "weapon_aug"       , weapon_aug);
	SetTrieValue(g_WeaponDataBase, "weapon_awp"       , weapon_awp);
	SetTrieValue(g_WeaponDataBase, "weapon_bizon"     , weapon_bizon);
	SetTrieValue(g_WeaponDataBase, "weapon_deagle"    , weapon_deagle);
	SetTrieValue(g_WeaponDataBase, "weapon_famas"     , weapon_famas);
	SetTrieValue(g_WeaponDataBase, "weapon_fiveseven" , weapon_fiveseven);
	SetTrieValue(g_WeaponDataBase, "weapon_g3sg1"     , weapon_g3sg1);
	SetTrieValue(g_WeaponDataBase, "weapon_galilar"   , weapon_galilar);
	SetTrieValue(g_WeaponDataBase, "weapon_glock"     , weapon_glock);
	SetTrieValue(g_WeaponDataBase, "weapon_hkp2000"   , weapon_hkp2000);
	SetTrieValue(g_WeaponDataBase, "weapon_m249"      , weapon_m249);
	SetTrieValue(g_WeaponDataBase, "weapon_m4a1"      , weapon_m4a1);
	SetTrieValue(g_WeaponDataBase, "weapon_mac10"     , weapon_mac10);
	SetTrieValue(g_WeaponDataBase, "weapon_mag7"      , weapon_mag7);
	SetTrieValue(g_WeaponDataBase, "weapon_mp7"       , weapon_mp7);
	SetTrieValue(g_WeaponDataBase, "weapon_mp9"       , weapon_mp9);
	SetTrieValue(g_WeaponDataBase, "weapon_negev"     , weapon_negev);
	SetTrieValue(g_WeaponDataBase, "weapon_nova"      , weapon_nova);
	SetTrieValue(g_WeaponDataBase, "weapon_p250"      , weapon_p250);
	SetTrieValue(g_WeaponDataBase, "weapon_p90"       , weapon_p90);
	SetTrieValue(g_WeaponDataBase, "weapon_sawedoff"  , weapon_sawedoff);
	SetTrieValue(g_WeaponDataBase, "weapon_scar20"    , weapon_scar20);
	SetTrieValue(g_WeaponDataBase, "weapon_sg556"     , weapon_sg556);
	SetTrieValue(g_WeaponDataBase, "weapon_tec9"      , weapon_tec9);
	SetTrieValue(g_WeaponDataBase, "weapon_ump45"     , weapon_ump45);
	SetTrieValue(g_WeaponDataBase, "weapon_xm1014"    , weapon_xm1014);

}



new g_iLastMyskins[MAXPLAYERS+1] = {-1,...};
public Action Command_MySkins(int client, int args)
{
	//https://github.com/Andersso/SM-WeaponModels/blob/da2b990164562cbb19e9d996f927601a525deee5/README.md#list-of-weapons---csgo
	//^ list and indexes of weapons

	//#553 == classname[weapon_deagle] - index[64] (revolver)
	//#556 == classname[weapon_deagle] - index[1] (deagle)

	if(IsValidPlayer(client))//we checked if he is a valid client
	{ 
		g_iLastMyskins[client] = GetTime();
		int original_team = GetClientTeam(client);
		//PrintToChatAll("original team is = %i",original_team);
		//switch him teams;
		//player_FakeTeamSwitch(client,CS_TEAM_CT);
		char weapon_active_classname[512];
		Client_GetActiveWeaponName(client, weapon_active_classname, sizeof(weapon_active_classname));
		//int weapon_active_index = Client_GetActiveWeapon(client);

		//PrintToChatAll("silencer on %b",silenceron);
		//PrintToChatAll("active weapon == %s",weapon_active_classname);
		int weapon_db[4];
		int weapon_db_ammo[4][2];
		for (int slot = 0; slot < 4; slot++) //load all slot data
		{
			int current_weapon = Client_GetWeaponBySlot(client, slot);
			weapon_db[slot] = current_weapon;
			int primaryammo;
			int secondaryammo;
			//hack warning pistol here:
			if(current_weapon != INVALID_ENT_REFERENCE)
			{
				char buffer[512]; //buffer string
				Entity_GetClassName(current_weapon, buffer, sizeof(buffer));
				lib_GetWeaponAmmo(current_weapon,primaryammo,secondaryammo);
				PrintToConsole(client,"[MySkins] [GET] [%s] %i/%i",buffer,primaryammo,secondaryammo);
				weapon_db_ammo[slot][0] = primaryammo;
				weapon_db_ammo[slot][1] = secondaryammo;
			}
		}
		//got all the needed data, replace the skins now.
		for (int slot = 0; slot < 4; slot++) //load all slot data
		{
			if(weapon_db[slot] != INVALID_ENT_REFERENCE)
			{

				int primaryammo =  weapon_db_ammo[slot][0];
				int secondaryammo =   weapon_db_ammo[slot][1];
				int should_be_team;
				char classname[512]; //buffer string
				Entity_GetClassName(weapon_db[slot],classname, sizeof(classname));
				//got ammo now, delte guns and spawn int one in with identical ammo
				if(primaryammo != -1 && secondaryammo != -1) //both primary and secondary are not -1 so we can replace this weapon
				{ 
					bool silencer = false;
					if(StrEqual(classname,"weapon_m4a1") || StrEqual(classname,"weapon_hkp2000"))//detect silencer
					{ 
						int silenceron = GetEntProp(weapon_db[slot], Prop_Send, "m_bSilencerOn"); 
						int firemode = GetEntProp(weapon_db[slot], Prop_Send, "m_weaponMode");
						if(silenceron && firemode == 1)
						{
							silencer = true;
						}
						else
						{
							silencer = false;
						}
						//PrintToChatAll("silencer = %b || firemode %i",silenceron,firemode);
					}
					Client_RemoveWeapon(client, classname);
					GetTrieValue(g_WeaponDataBase,classname,should_be_team);
					//2 == T == CS_TEAM_T
					//3 == CT == CS_TEAM_CT
					//-1 == ANY
					char buffer[512]; //buffer string
					switch(should_be_team)
					{ 
						case CS_TEAM_T :
						{
							buffer = "T";
							SetEntProp(client, Prop_Data, "m_iTeamNum", CS_TEAM_T);
						}
						case CS_TEAM_CT :
						{
							buffer = "CT";
							SetEntProp(client, Prop_Data, "m_iTeamNum", CS_TEAM_CT);
						}
						default:
						{
							buffer = "ANY";
							SetEntProp(client, Prop_Data, "m_iTeamNum", original_team);
						}
					}
					//PrintToChatAll("we got an index of %d",GetEntProp(weapon_db[slot], Prop_Send, "m_iItemDefinitionIndex"));
					//bug: when a player gets given a p2k, but has USP equiped this spawns instead
					//fix incorrect gun models
					switch (GetEntProp(weapon_db[slot], Prop_Send, "m_iItemDefinitionIndex"))
					{
						case 60: strcopy(classname, sizeof(classname), "weapon_m4a1_silencer");
						case 61: strcopy(classname, sizeof(classname), "weapon_usp_silencer");
						case 63: strcopy(classname, sizeof(classname), "weapon_cz75a");
						case 64: strcopy(classname, sizeof(classname), "weapon_revolver");
					}

					int given_weapon =  GivePlayerItem(client,classname);
					if(StrEqual(classname,"weapon_m4a1_silencer")) //https://forums.alliedmods.net/showthread.php?t=116732
					{
						classname = "weapon_m4a1";
						if(!silencer)
						{
							ReplyToCommand(client, " [SM] You had a unsilenced gun, ignore the graphical glitch ;)");
							int weapon = Client_GetWeaponBySlot(client, slot);
							//PrintToChatAll("forcing silencer");
							SetEntProp(weapon, Prop_Send, "m_bSilencerOn", 0);
							SetEntProp(weapon, Prop_Send, "m_weaponMode", 0);
							//re-equip because bugged model
							//Client_EquipWeapon(client, weapon, true);
						}
					}
					if(StrEqual(classname,"weapon_usp_silencer")) //https://forums.alliedmods.net/showthread.php?t=116732
					{
						classname = "weapon_hkp2000";
						if(!silencer)
						{
							ReplyToCommand(client, " [SM] You had a unsilenced gun, ignore the graphical glitch ;)");
							int weapon = Client_GetWeaponBySlot(client, slot);
							//PrintToChatAll("forcing silencer");
							SetEntProp(weapon, Prop_Send, "m_bSilencerOn", 0);
							SetEntProp(weapon, Prop_Send, "m_weaponMode", 0);
							//re-equip because bugged model not needed, is not primary
						}
					}
					if(StrEqual(classname,"weapon_cz75a"))//https://forums.alliedmods.net/showthread.php?t=116732
					{ 
						classname = "weapon_p250";
					}
					//spawned it in, now change bullets to match old one.
					//https://forums.alliedmods.net/showthread.php?p=2293043
					lib_SetWeaponAmmo(given_weapon,primaryammo,secondaryammo);
					PrintToConsole(client,"[MySkins] [SET] [%s] %i/%i",classname,primaryammo,secondaryammo);
					//lib_SetPrimaryAmmo(given_weapon,primaryammo)
					//lib_SetSecondaryAmmo(given_weapon,secondaryammo)


					//int weapon = Client_GetWeaponBySlot(client, slot);

					//SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
					//SetEntProp(weapon, Prop_Send, "m_iSecondaryReserveAmmoCount", 0);


					//Weapon_SetPrimaryClip(Client_GetWeaponBySlot(client, slot), primaryammo);
					//SetEntProp(weapon_db[slot], Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
					//SetEntProp(weapon_db[slot], Prop_Send, "m_iPrimaryReserveAmmoCount",secondaryammo);
					//Client_SetWeaponPlayerAmmo(client,classname, secondaryammo,-1); //ammo is store in player not on gun
				}
			}
		}
		//set original team back
		SetEntProp(client, Prop_Data, "m_iTeamNum", original_team);
	}
	ReplyToCommand(client, " [SM] Replaced all weapons with your own skins");
	return Plugin_Handled;
}




//--------------- port of staff code.
//--------------- port of staff code.
//--------------- port of staff code.
//--------------- port of staff code.
//--------------- port of staff code.
//--------------- port of staff code.
//--------------- port of staff code.
//--------------- port of staff code.
//--------------- port of staff code.
//--------------- port of staff code.
//--------------- port of staff code.
//--------------- port of staff code.
//--------------- port of staff code.
//--------------- port of staff code.



/* Plugins Defines */
#define MAX_USER_TYPES 12
#define MAX_USER_TYPES_CATEGORIES 8


bool g_bUserTypeStaff[MAX_USER_TYPES+1];//
bool g_bUserTypeBroadcast[MAX_USER_TYPES+1];// if staff is in the broadcast domain



stock char g_sUserTypes[MAX_USER_TYPES][MAX_USER_TYPES_CATEGORIES][64] = 
{
	//"checker command [0]"				,"is staff[1]"	"broadcast"			,"Access Name [2]"	,"Full name [3]"	,"ScoreB name [4]"	,"Chat name [5]" ,"target string"
	{"inilo_staff_checker_normal"			,"0"		,"0"				,"Normal"			,"Normal"			,""					,""			,"pleb"},
	{"inilo_staff_checker_dev"				,"1"		,"1"				,"Developer"		,"Developer"		,"Dev"				,"Dev"		,"dev"},
	{"inilo_staff_checker_informer"			,"1"		,"1"				,"Informer"			,"Informer"			,"+"				,"+"		,"informer"},
	{"inilo_staff_checker_vip"				,"0"		,"0"				,"VIP"				,"VIP"				,"VIP"				,"VIP"		,"vip"},
	{"inilo_staff_checker_vipplus"			,"0"		,"0"				,"VIP Plus"			,"VIP Plus"			,"VIP+"				,"VIP+"		,"vip+"},
	{"inilo_staff_checker_trialmod"			,"1"		,"1"				,"Trial Moderator"	,"Trial Moderator"	,"Trial Mod"		,"T.MOD"	,"tmod"},
	{"inilo_staff_checker_moderator"		,"1"		,"1"				,"Moderator"		,"Moderator"		,"Moderator"		,"M"		,"mod"},
	{"inilo_staff_checker_seniormod"		,"1"		,"1"				,"Senior Moderator"	,"Senior Moderator"	,"Sen. Mod"			,"S.MOD"	,"senmod"},
	{"inilo_staff_checker_guardian"			,"1"		,"1"				,"Guardian"			,"Guardian"			,"Guardian"			,"G"		,"guardian"},
	{"inilo_staff_checker_admin"			,"1"		,"1"				,"Admin"			,"Admin"			,"Admin"			,"A"		,"admin"},
	{"inilo_staff_checker_senioradmin"		,"1"		,"1"				,"Senior Admin"		,"Senior Admin"		,"Sen. Admin"		,"SA"		,"senadmin"},
	{"inilo_staff_checker_senator"			,"1"		,"1"				,"Senator"			,"Senator"			,"Senator"			,"S"		,"senator"},
};

char g_cStaffChatPrefix[] = "\x01[\x09STAFF\x01]";
char g_cStaffConsolePrefix[] = "[STAFF]";



public void staff_OnPluginStart()
{
	Internal_BuildAccessSystem();
	staff_RegisterNatives();
	staff_RegisterCvars();
	staff_RegisterCmds();
	staff_HookEvents();
}

public void staff_RegisterCvars()
{

}
public void staff_RegisterCmds()
{
	RegAdminCmd("sm_access",Command_AccessCheckAll, ADMFLAG_ROOT, "sm_access.");
}
public void staff_HookEvents()
{

}

public void staff_RegisterNatives()
{
	//CreateNative("iNilo_ClientIsStaff", Native_ClientIsStaff);
	//CreateNative("iNilo_True", Native_True);
	//

}


stock bool block_warmup_command(int client)
{
	if(!IsGameTime())
	{
		if(!Internal_Access_HigherThenString(client,"admin",false))
		{
			ReplyToCommand(client, " [SM] You access level is too low to use this command in warmup");
			return true;
		}
	}
	return false;

}


//**************** Natives.

/**
 * Native for checking if client is part of staff
 **/
 /*
public int Native_ClientIsStaff(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	return Internal_Access_ClientIsStaff(client);	
}
*/

/**
 * Native for getting the userntype
 **/
public int Native_True(Handle plugin, int numParams)
{
	return true;
}

/**
 * Native for checking if staff
 **/
public int Native_IsStaff(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	return Internal_Access_IsStaff(client);
}
/**
 * Native for checking if staff
 **/
public int Native_IsBroadcast(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	return Internal_Access_IsBroadcast(client);
}

/**
 * Native for getting the userntype
 **/
public int Native_GetUserType(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	return Internal_Access_GetUserType(client);
}
public int Native_HigherThen(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int level = GetNativeCell(2);
	bool equal = GetNativeCell(3);
	if(!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	return Internal_Access_HigherThen(client,level,equal);
}


/**
 * Native for gettin data out of the usertype array
 **/
public int Native_GetUserTypeString(Handle plugin, int numParams)
{
	//int usertype,int type, char[] output, int maxlen
	int usertype = GetNativeCell(1);
	int type = GetNativeCell(2);
	int maxlen = GetNativeCell(4);
	char[] UserTypeString = new char[maxlen];	
	//get internal stuff.
	Internal_Access_GetUserTypeString(usertype,type,UserTypeString,maxlen);
	return SetNativeString(3,UserTypeString,maxlen);
}
public int Native_HigherThenString(Handle plugin, int numParams)
{
	//int usertype,int type, char[] output, int maxlen
	int client = GetNativeCell(1);

	int len;
	GetNativeStringLength(2, len);

	if (len <= 0)
	{
	  return false;
	}
 
	char[] str = new char[len + 1];
	GetNativeString(2, str, len + 1);
	//get internal stuff.
	bool equal = GetNativeCell(3);
	return Internal_Access_HigherThenString(client,str,equal);
}



/**
 * Builds our own access system.
 */
public void Internal_BuildAccessSystem()
{
	//adebug_tierup("Internal_BuildAccessSystem");
	//register our own commands.
	//install our own access system.
	for(int i = 0; i < MAX_USER_TYPES;i++)
	{
		//Register the command.
		char cCommandDescription[128];
		Format(cCommandDescription,sizeof(cCommandDescription),"Custom access level for %s.",g_sUserTypes[i][USER_TYPE_FULLNAME]);
		RegAdminCmd(g_sUserTypes[i][USER_TYPE_COMMAND], Command_AccessCheck, ADMFLAG_ROOT,cCommandDescription);

		//now add the target filter
		//TargetFilter_Ranks

		char cTargetFilterText[128];
		char cTargetFilterPrintText[128];

		char cTargetFilterText_Inverted[128];
		char cTargetFilterPrintText_Inverted[128];


		//normal
		Format(cTargetFilterText,sizeof(cTargetFilterText),"@%s",g_sUserTypes[i][USER_TYPE_MULTI_TARGET]);
		Format(cTargetFilterPrintText,sizeof(cTargetFilterPrintText),"all %s's",g_sUserTypes[i][USER_TYPE_FULLNAME]);


		//invert
		Format(cTargetFilterText_Inverted,sizeof(cTargetFilterText_Inverted),"@!%s",g_sUserTypes[i][USER_TYPE_MULTI_TARGET]);
		Format(cTargetFilterPrintText_Inverted,sizeof(cTargetFilterPrintText_Inverted),"all non %s's",g_sUserTypes[i][USER_TYPE_FULLNAME]);
	

		//normal
		//AddMultiTargetFilter(cTargetFilterText, TargetFilter_Ranks,cTargetFilterPrintText, false);
		//targets_RegisterTarget(cTargetFilterText, TargetFilter_Ranks,cTargetFilterPrintText, false);
		//invert.
		//AddMultiTargetFilter(cTargetFilterText_Inverted, TargetFilter_Ranks,cTargetFilterPrintText_Inverted, false);
		//targets_RegisterTarget(cTargetFilterText_Inverted, TargetFilter_Ranks,cTargetFilterPrintText_Inverted, false);



		//adebug("Created Admin cmd -> %s",g_sUserTypes[i][0]);

		//build bool list if its staff
		if(StrEqual(g_sUserTypes[i][USER_TYPE_IS_STAFF],"1"))
		{
			g_bUserTypeStaff[i] = true;
			//adebug("part of staff");
		}
		else
		{
			g_bUserTypeStaff[i] = false;
			//adebug("not part of staff");
		}
		
		//build broadcast.
		if(StrEqual(g_sUserTypes[i][USER_TYPE_BROADCAST],"1"))
		{
			g_bUserTypeBroadcast[i] = true;
			//adebug("part of staff");
		}
		else
		{
			g_bUserTypeBroadcast[i] = false;
			//adebug("not part of staff");
		}
		

	}
	//adebug_tierdown("Internal_BuildAccessSystem");
}

/**
 * Command_AccessCheck command to allow own access system
 **/
public Action Command_AccessCheck(int client, int args)
{
	//adebug_tierup("Command_AccessCheck");
	char CommandName[128];
	GetCmdArg(0, CommandName, sizeof(CommandName));
	char UserTypeString[64];
	int usertype = Internal_Access_GetUserType(client);
	Internal_Access_GetUserTypeString(usertype,USER_TYPE_GROUPNAME,UserTypeString,sizeof(UserTypeString));
	ReplyToCommand(client," [SM] Success! Your access level is '%s' and you have access to '%s'. (usertype==%i)",UserTypeString,CommandName,usertype);
	ReplyToCommand(client," [SM] (staf==%b) (broadcast==%b)",Internal_Access_IsStaff(client),Internal_Access_IsBroadcast(client));
	char cChatTag[128];
	ProcessPreTagShort2(client,cChatTag,sizeof(cChatTag));
	ReplyToCommand(client," [SM] (chat tag==%s)",cChatTag);
	//adebug_tierdown("Command_AccessCheck");
	return Plugin_Handled;
}

public Action Command_AccessCheckAll(int client, int args)
{

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			PrintToConsole(client,"[checked] - [%N] - (usertype==%i) (staf==%b) (broadcast==%b)",i,Internal_Access_GetUserType(i),Internal_Access_IsStaff(i),Internal_Access_IsBroadcast(i));
		}
	}

	return Plugin_Handled;
}




/**
 * Gets the usertype and fills the string with a more common name 
 * @param usertype what usertype you want to get filled
 * @param type what string you want 0 = checker, 1 = full, 2 = Scoreboard , 3 = Chat
 **/

stock char Internal_Access_GetUserTypeString(int usertype,int type, char[] output, int maxlen)
{
	//adebug_tierup("Internal_Access_GetUserTypeString");	
	strcopy(output,maxlen,g_sUserTypes[usertype][type]);
	//adebug("usertype '%i' for selector '%i' contains '%s'",usertype,type,output);
	//adebug_tierdown("Internal_Access_GetUserTypeString");	
}

stock bool Internal_Access_HigherThen(int client,int level,bool equal)
{
	if(equal)
	{
		if(Internal_Access_GetUserType(client) >= level)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else
	{
		if(Internal_Access_GetUserType(client) > level)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
}
public bool Internal_Access_HigherThenString(int client,const char[] string,bool equal)
{
	//USER_TYPE_MULTI_TARGET
	return Internal_Access_HigherThen(client,Internal_Access_GetUserTypeOfTargetString(string),equal);
}


/**
 * Gets the usertype
 * @param the client you want to check.
 * @return the usertype -1 on faillure
 **/
 
stock int Internal_Access_GetUserType(int client)
{
	if(!IsValidClient(client))
		return 0;
	if(GetUserAdmin(client) == INVALID_ADMIN_ID)
		return 0;

	for(int i = MAX_USER_TYPES - 1; i >= 0 ;i--)
	{
		if(CheckCommandAccess(client,g_sUserTypes[i][USER_TYPE_COMMAND],ADMFLAG_SLAY))
		{
			return i;
		}
	}
	return 0;
}

 
stock int Internal_Access_GetUserTypeOfTargetString(const char[] targetstring)
{
	//replace the !
	char cLookupString[128];
	strcopy(cLookupString,sizeof(cLookupString),targetstring);
	ReplaceString(cLookupString,sizeof(cLookupString),"!","");
	ReplaceString(cLookupString,sizeof(cLookupString),"@","");
	for(int i = 0; i < MAX_USER_TYPES ;i++)
	{
		//log(Info, "g_sUserTypes[i][USER_TYPE_MULTI_TARGET] == %s || LOOKING FOR==%s",g_sUserTypes[i][USER_TYPE_MULTI_TARGET],cLookupString);
		if(StrEqual(g_sUserTypes[i][USER_TYPE_MULTI_TARGET],cLookupString))
		{
			return i;
		}
	}
	return 0;
}


/**
 * Gets if this player is staff.
 *
 **/
 
stock bool Internal_Access_IsStaff(int client)
{
	if(!IsValidClient(client))
		return false;

	if(GetUserAdmin(client) == INVALID_ADMIN_ID)
		return false;
	//so its an admin, lets check the staff parameter.
	//grab the usertype.
	int usertype = Internal_Access_GetUserType(client);
	return g_bUserTypeStaff[usertype];
}
/**
 * Gets if this player is staff.
 *
 **/
 
stock bool Internal_Access_IsBroadcast(int client)
{
	if(!IsValidClient(client))
		return false;

	if(GetUserAdmin(client) == INVALID_ADMIN_ID)
		return false;
	//so its an admin, lets check the staff parameter.
	//grab the usertype.
	int usertype = Internal_Access_GetUserType(client);
	return g_bUserTypeBroadcast[usertype];
}


/**
 * Check if the client is part of the staff
 * @param the client you want to check.
 **/
stock bool Internal_Access_ClientIsStaff(int client)
{
	//adebug_tierup("Internal_Access_ClientIsStaff");	
	bool isStaff = Internal_Access_UserTypeIsStaff(Internal_Access_GetUserType(client));
	//adebug(" checked '%L' for staff and the result is = '%b'",client,isStaff);
	//adebug_tierdown("Internal_Access_ClientIsStaff");	
	return isStaff;
}

/**
 * Check if usertype is part of the staff
 * @param the client you want to check.
 **/
stock bool Internal_Access_UserTypeIsStaff(int UserType)
{
	//adebug_tierup("Internal_Access_UserTypeIsStaff");	
	if(UserType > MAX_USER_TYPES || UserType < 0)
	{
		ThrowError("Internal_Access_UserTypeIsStaff got a usertype out of the array");
	}
	bool isStaff = g_bUserTypeStaff[UserType];
	//adebug("usertype '%i' -> staff = '%b'",UserType,isStaff);
	//adebug_tierdown("Internal_Access_UserTypeIsStaff");	
	return isStaff;
}



