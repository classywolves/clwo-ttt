/** Double-include prevention */
#if defined _imod_included_
  #endinput
#endif
#define _imod_included_

#if !defined _main_included_
#define MAIN_PLUGIN_NAME "main"
#endif



public SharedPlugin __pl_imod = 
{
	name = "iMod",
	file = "inilo-modules.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_imod_SetNTVOptional()
{
	MarkNativeAsOptional("iMod_GetUserType");
	MarkNativeAsOptional("iMod_HigherThen");
	MarkNativeAsOptional("iMod_GetUserTypeString");
	MarkNativeAsOptional("iMod_HigherThenString");
	MarkNativeAsOptional("iMod_IsStaff");
	MarkNativeAsOptional("iMod_IsBroadcast");
}
#endif



#define USER_TYPE_COMMAND  0
#define USER_TYPE_IS_STAFF  1
#define USER_TYPE_BROADCAST  2
#define USER_TYPE_GROUPNAME  3
#define USER_TYPE_FULLNAME  4
#define USER_TYPE_SCORENAME 5
#define USER_TYPE_CHATNAME  6
#define USER_TYPE_MULTI_TARGET 7


native int iMod_GetUserType(int client);
native int iMod_HigherThen(int client,int level,bool equal=false);
native char iMod_GetUserTypeString(int UserType, int type, char[] output, int maxlen);
native bool iMod_HigherThenString(int client,char[] string,bool equal=false);
native bool iMod_IsStaff(int client);
native bool iMod_IsBroadcast(int client);

/**
 * This function will check if we have a valid player (alive)
 **/
stock bool IsValidPlayer(int client)//ingmae and not bot and alive
{ 
	if(!IsValidClient(client))
		return false;

	if(!IsPlayerAlive(client))
		return false;

	if(GetClientTeam(client) == CS_TEAM_SPECTATOR)
		return false;

	if(GetClientTeam(client) == CS_TEAM_NONE)
		return false;

	return true;
}

/**
 * This function will check if we have a valid player
 **/
stock bool IsValidClient(int client,bool allowconsole=false)
{
		if(client == 0 && allowconsole)
		{
			return true;
		}
		if(client <= 0)
		{
			return false;
		}
		if(client > MaxClients)
		{
			return false;
		}
		if (!IsClientConnected(client)) 
		{ 
			return false; 
		} 
		if(!IsClientInGame(client))
		{
			return false;
		}
		if(IsFakeClient(client))
		{
			return false;
		}
		return true;
}



stock GetStaffInArray(int[] mods, int max)
{
	bool iNiloOnline = (GetFeatureStatus(FeatureType_Native, "iNilo_IsStaff") == FeatureStatus_Available);
	#if defined _imod_included_
	bool iModOnline = (GetFeatureStatus(FeatureType_Native, "iMod_IsStaff") == FeatureStatus_Available);
	#endif
	/*
	if(iNiloOnline)
	{
		PrintToServer("iNiloOnline");
	}
	if(iModOnline)
	{
		PrintToServer("iModOnline");
	}
	*/
	int counted_mods = 0;
	for (int player = 1; player <= MaxClients && counted_mods < max; player++)
	{
		if(IsValidClient(player))
		{
			#if defined _imod_included_
			if(iModOnline)
			{
				if(iMod_IsStaff(player))
				{
					mods[counted_mods++] = player;
				}
			}
			#endif
		}
	}
	return counted_mods;
}


/*
 * Gets the primary clip count of a weapon.
 * 
 * @param weapon		Weapon Entity.
 * @return				Primary Clip count.
 */
stock int lib_GetPrimaryAmmo(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iClip1");
}
/*
 * Sets the primary ammo count of a weapon.
 * 
 * @param weapon		Weapon Entity.
 * @param value			Clip Count value.
 */
stock void lib_SetPrimaryAmmo(int weapon, int ammo)
{
	SetEntProp(weapon, Prop_Data, "m_iClip1", ammo);
}
/*
 * Gets the secondary clip count of a weapon.
 * 
 * @param weapon		Weapon Entity.
 * @return				Primary Clip count.
 */
stock int lib_GetSecondaryAmmo(int weapon)
{
	return 	GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
}
/*
 * Sets the secondary ammo count of a weapon.
 * 
 * @param weapon		Weapon Entity.
 * @param value			Clip Count value.
 */
stock void lib_SetSecondaryAmmo(int weapon,int ammo)
{
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
}
/*
 * Sets the primarty and secondary ammo count of a weapon.
 * 
 * @param weapon		Weapon Entity.
 * @param value			Primary ammo Count value.
 * @param value			Primary ammo Count value.
 */
stock void lib_SetWeaponAmmo(int weapon,int primaryammo,int secondaryammo)
{
	lib_SetPrimaryAmmo(weapon, primaryammo);
	lib_SetSecondaryAmmo(weapon, secondaryammo);
}
/*
 * Gets the primary and secondary clip count of a weapon.
 * 
 * @param weapon 					Weapon Entity.
 * @param primaryammo				Primary Clip count.
 * @param secondaryammo				Secondary Clip count.
 */
stock void lib_GetWeaponAmmo(int weapon,int &primaryammo,int &secondaryammo)
{
	primaryammo = lib_GetPrimaryAmmo(weapon);
	secondaryammo = lib_GetSecondaryAmmo(weapon);
}


stock ProcessPreTagShortTTT(int client, char[] output, int maxlen)
{

	if(!IsValidClient(client))
		return;
	//PrintToConsole(client, "iNiloOnline === %b", iNiloOnline);
	//FORMAT ALL THE THINGS
	Format(output, maxlen, "");
	//check for clwo & id not -1
	int usertype;
	char cChatTag[128];
	//check if we are compiling for popey

	usertype = iMod_GetUserType(client);
	iMod_GetUserTypeString(usertype, USER_TYPE_CHATNAME, cChatTag, sizeof(cChatTag));

	//Finally, dont give the non representing staff a chat tag.
	if(IsCarryingClantag(client) && usertype != 0)
	{
		Format(output,maxlen,"\x01[\x05%s\x01]\x01",cChatTag);
	}
}

stock bool IsCarryingClantag(int client)
{
	if(client == 0) //console fix
		return true;
	char cCl_clanid[64];
	if(IsValidClient(client))
	{
		GetClientInfo(client, "cl_clanid",cCl_clanid, sizeof(cCl_clanid));
	}
	if(StrEqual(cCl_clanid,"5157979"))//5157979 == clwo.eu
	{
		return true;
	}
	else
	{
		return false;
	}
}


stock ProcessTeam(client, String:output[], maxlen)
{
	if(IsValidClient(client))
	{
		//CS_TEAM_SPECTATOR 1	
		//CS_TEAM_T 2
		//CS_TEAM_CT 3	
		switch(GetClientTeam(client))
		{
			case 1:
			{
				Format(output,maxlen,"\x01(\x08S\x01)");
			}
			case 2:
			{
				Format(output,maxlen,"\x01(\x08T\x01)");
			}
			case 3:
			{
				Format(output,maxlen,"\x01(\x08CT\x01)");
			}
		}

	}
}

stock bool GetTournamentWinnerPrefix(int client, char[] output, int maxlen)
{
	//check if the fucker is valid
	if(!IsValidClient(client))
		return false;
	int i = GetSteamAccountID(client, true);
	if(i == 0)
		return false;
	if(i == 195243016 || i == 55040409 || i == 78926158 || i == 48251305 || i == 225746833)
	{
		Format(output, maxlen ,"\x01[\x10♛\x01]");
		return true;
	}
	if(i == 0 || i == 0) //still to be determined
	{
		Format(output, maxlen ,"\x01[\x10♛\x01]");
		return true;
	}
	if(i == 97555452)
	{
		Format(output, maxlen ,"\x01[\x10♛\x01]");
		return true;
	}
	/*
	if(i == 87875559)
	{
		Format(output, maxlen ,"\x01[\x10✪\x01]");
		return true;
	}
	*/
	return false;
}
stock bool GetMeetupPrefix(int client, char[] output, int maxlen)
{
	//inilo 48251305
	//gibby 87875559
	//popey 78926158
	//bowl 101727860
	//junior 402721018
	//anne 382436527
	//square 93443020
	//sharc 110640948
	//teamkiller 73564887
	//broseidon 183371024
	//rickerd 302873455
	//duckator 343383657
	//trip 205427855
	//jj 146173163

	//check if the fucker is valid
	if(!IsValidClient(client))
		return false;
	int i = GetSteamAccountID(client, true);
	if(i == 0)
		return false;
	if(i == 48251305 || i == 87875559 || i == 78926158 || i == 101727860 || i == 402721018 || i == 382436527 || i == 93443020 || i == 110640948 || i == 73564887 || i == 183371024 || i == 302873455 || i == 343383657 || i == 205427855 || i == 146173163)
	{
		Format(output, maxlen ,"\x01[\x10✪\x01]");
		return true;
	}
	return false;
}
stock bool GetBigPussyTag(int client, char[] output, int maxlen)
{
	//junior 402721018
	//check if the fucker is valid
	if(!IsValidClient(client))
		return false;
	int i = GetSteamAccountID(client, true);
	if(i == 0)
		return false;
	if(i == 402721018)
	{
		Format(output, maxlen ,"\x01[\x0ePeppernoob\x01]");
		return true;
	}
	return false;
}


stock ProcessPreTagShort2(int client, char[] output, int maxlen)
{

	//this shit it like magic, its a dragon that appears out of fucking thin air.
	//First off check if we are compiling against inilo or popeys plugins, to call internal API's from
	bool iNiloOnline = (GetFeatureStatus(FeatureType_Native, "iNilo_IsStaff") == FeatureStatus_Available);
	#if defined _imod_included_
	bool iModOnline = (GetFeatureStatus(FeatureType_Native, "iMod_IsStaff") == FeatureStatus_Available);
	#endif
	//check if the fucker is valid
	if(!IsValidClient(client))
		return;
	//PrintToConsole(client, "iNiloOnline === %b", iNiloOnline);
	//FORMAT ALL THE THINGS
	Format(output, maxlen, "");
	//check for clwo & id not -1
	int usertype;
	char cChatTag[128];
	if(iNiloOnline)
	{
		#if defined _main_included_
		//Hey! iNilo seems to be online, call the internal API
		usertype = iNilo_GetUserType(client);
		//6 == chat tag for chat
		iNilo_GetUserTypeString(usertype, 6, cChatTag, sizeof(cChatTag));
		#endif
	}
	//check if we are compiling for popey
	#if defined _imod_included_
	if(iModOnline)
	{
		PrintToConsole(client, "using iMod_GetUserTypeString");
		//use popeys internal API to retrieve chat tags
		usertype = iMod_GetUserType(client);
		iMod_GetUserTypeString(usertype, USER_TYPE_CHATNAME, cChatTag, sizeof(cChatTag));
		
	}
	#endif
	//Finally, dont give the non representing staff a chat tag.
	if(IsCarryingClantag(client) && usertype != 0)
	{
		Format(output,maxlen,"\x01[\x05%s\x01]\x01",cChatTag);
	}
}


stock ProcessPreTagShort2Backup(client, String:output[], maxlen)
{
	if(IsValidClient(client))
	{
		Format(output,maxlen,"");
		//check for clwo & id not -1
		int usertype;
		if(IsCarryingClantag(client))
		{
			AdminId id = GetUserAdmin(client);
			if(id != INVALID_ADMIN_ID)
			{
				if(GetAdminFlag(id,Admin_Chat))
				{
					strcopy(output,maxlen,"\x01[\x05STAFF\x01]");
				}
			}
		}

	}
}


//https://forums.alliedmods.net/showthread.php?t=261376
stock KillEntityIn(iEnt, float flSeconds)
{
	////https://forums.alliedmods.net/showthread.php?t=261376
	char szAddOutput[32];
	Format(szAddOutput, sizeof(szAddOutput), "OnUser1 !self,Kill,,%0.2f,1", flSeconds);
	SetVariantString(szAddOutput);
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}
