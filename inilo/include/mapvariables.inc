/** Double-include prevention */
#if defined _mapvariablesincluded_
  #endinput
#endif
#define _mapvariables_included_


public SharedPlugin __pl_mapvariables = 
{
	name = "mapvariables",
	file = "inilo-mapvariables.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_mapvariables_SetNTVOptional()
{
	MarkNativeAsOptional("MapVariablesAvailable");
	MarkNativeAsOptional("MapVariablesFetched");

	MarkNativeAsOptional("RefetchMapVariables");

	MarkNativeAsOptional("DeleteMapVariable");

	MarkNativeAsOptional("GetMapVariableString");
	MarkNativeAsOptional("GetMapVariableInt");
	MarkNativeAsOptional("GetMapVariableFloat");

	MarkNativeAsOptional("SetMapVariableString");
	MarkNativeAsOptional("SetMapVariableInt");
	MarkNativeAsOptional("SetMapVariableFloat");

}
#endif


#define MAPVARIABLE_NOT_AVAILABLE -1

#define MAPVARIABLES_KEY_MAXSIZE 64
#define MAPVARIABLES_VALUE_MAXSIZE 255


native void RefetchMapVariables();


forward void OnMapVariablesFetched();



/**
 * Checks if this map has mapvariables
 *
 */
native bool MapVariablesAvailable();
native bool MapVariablesFetched();


/**
 * Gets the value for the mapvariable as string
 *
 */
native int GetMapVariableString(char[] sKey, char[] sValueBuffer, int iLength);

native int DeleteMapVariable(char[] sKey);



/**
 * Gets the value for the mapvariable as integer
 *
 */
native int GetMapVariableInt(char[] sKey, int &iValue);

/**
 * Get the value for the mapvariable as float
 *
 */
native int GetMapVariableFloat(char[] sKey, float &fValue);

native int SetMapVariableString(char[] sKey, char[] sValue);

native int SetMapVariableInt(char[] sKey, int iValue);

native int SetMapVariableFloat(char[] sKey, float fValue);