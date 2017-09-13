
#undef REQUIRE_PLUGIN
#include <sourcemod>

/* Plugin Info */
#define PLUGIN_NAME 			"LastSeen Logger"
#define PLUGIN_VERSION_M 		"0.0.1"
#define PLUGIN_AUTHOR 			"ScreenMan"
#define PLUGIN_DESCRIPTION		"Logs time you last saw a player."
#define PLUGIN_URL				"http://screenman.pro"

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
	CreateConVar("lastseen_version", PLUGIN_VERSION_M, "LastSeen Plugin Version");
	PrintToServer("[URL] Has Loaded Succcessfully!");
}

public OnPluginEnd() {
	PrintToServer("[URL] Has Unloaded Successfully!");
}