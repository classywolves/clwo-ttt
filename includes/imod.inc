/** Double-include prevention */
#if defined _imod_included_
  #endinput
#endif
#define _imod_included_


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

native bool iMod_IsStaff(int client);
native bool iMod_IsBroadcast(int client);
native int iMod_HigherThen(int client,int level,bool equal=false);
native bool iMod_HigherThenString(int client,char[] string,bool equal=false);
native int iMod_GetUserType(int client);
native char iMod_GetUserTypeString(int UserType,int type, char[] output, int maxlen);




#include <sdktools>
#include <sdkhooks>
#include <cstrike>
