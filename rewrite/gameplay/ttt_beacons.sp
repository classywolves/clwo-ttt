/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <ttt>
#include <colorvariables>
#include <generics>
#include <datapack>
#include <sdktools_tempents_stocks>

/*
 * Custom methodmaps.
 */
#include <player_methodmap>
#include <ttt_beacons>

/*
 * Custom Defines.
 */


public Plugin myinfo =
{
    name = "TTT Beacon",
    author = "iNilo & Corpen",
    description = "Adds a new type of beacon that can be placed around the map.",
    version = "1.0.0",
    url = ""
};

int beamSprite = -1;

public OnPluginStart()
{
    RegisterCmds();
    //HookEvents();
    //InitDBs();
    
    PrintToServer("[BCN] Loaded successfully");
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    RegPluginLibrary("ttt_beacons");
    
    CreateNative("TTT_SpawnBeacon", Native_SpawnBeacon);
    
    return APLRes_Success;
}

public void RegisterCmds() {
    RegConsoleCmd("sm_spawnbeacon", Command_SpawnBeacon, "Spawns a beacon.");
}

public void OnMapStart() {
    PreCache();
}

public void PreCache()
{
    beamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public int Native_SpawnBeacon(Handle plugin, int numParams)
{
    return;
}

public Action Command_SpawnBeacon(int client, int args)
{
    Player player = Player(client);
    if (player.Access(RANK_SADMIN, true)) { return Plugin_Handled; }
    
    float pos[3];
    if (!player.RayTrace(pos))
    {
        player.Error("Please look at a valid location.");
    }
    
    int color[4] = {255, 255, 255, 255};
    CreateBeacon(pos, 5.0, color);
    
    return Plugin_Handled;
}

public void CreateBeacon(float location[3], float radius, int color[4])
{
    color[3] = 15;
    
    float delay = 0.0;
    float life = 0.1; // 0.1;
    float width = 1.0;
    
    float visualLocation[3];
    visualLocation = location;
    for(int x = 0; x < 2; x++)
    {
        TE_SetupBeamRingPoint(visualLocation, radius * 2.0, (radius * 2.0 ) + 0.1, beamSprite, 0, 0, 0, life, width, 0.0, color, -1, 0);
        TE_SendToAll();
        visualLocation[2] += 46.0;
    }
}
