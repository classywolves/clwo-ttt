/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <colorvariables>
#include <generics>

/*
 * Database includes.
 */
#include <rdm_db>

public OnPluginStart()
{
	RegisterCmds();
	HookEvents();
	InitDBs();
	
	PrintToServer("[GEN] Loaded succcessfully");
}

public void RegisterCmds() {
}

public void HookEvents() {
}

public void InitDBs() {
	RdmInit();
}