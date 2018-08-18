/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <timers>

/*
 * Custom include files.
 */
#include <ttt>
#include <colorvariables>
#include <generics>

/*
 * Custom methodmaps.
 */
#include <player_methodmap>
#include <ttt_specialDays>

#define KOTH_ROUNDS_MIN 5
#define KOTH_ROUNDS_MAX 10
#define KOTH_HILLS_MAX 16

public Plugin myinfo =
{
    name = "TTT King of the Hill Day",
    author = "c0rp3n",
    description = "TTT Special Day of King of the Hill.",
    version = "1.0.0",
    url = ""
};

bool isDayRunning = false;
int remainingRounds = -1;

int hillCount = 0;
float hills[KOTH_HILLS_MAX][3];

public OnPluginStart()
{
    RegisterCmds();
    
    PrintToServer("[SDB] Loaded successfully");
}

RegisterCmds()
{
    RegConsoleCmd("sm_addhillspawn", Command_AddHillSpawn, "Allows an Admin to place a Hill Spawn Point at where they are looking.");
}

public Action TTT_StartSpecialDay(int specialDay)
{
    if (specialDay != SPECIAL_DAY_KOTH) return Plugin_Continue;
    
    remainingRounds = GetRandomInt(KOTH_ROUNDS_MIN, KOTH_ROUNDS_MAX);
    
    if (!ParseConfig()) { return Plugin_Stop; }
    isDayRunning = true;
    
    return Plugin_Handled;
}

public Action TTT_StopSpecialDay()
{
    if (!isDayRunning) return Plugin_Continue;
    
    
    isDayRunning = false;
    
    return Plugin_Handled;
}

public bool ParseConfig()
{
    KeyValues kv = new KeyValues("TTT_KotH_Hills");
    char config[PLATFORM_MAX_PATH];
    
    char mapName[128];
    GetCurrentMap(mapName, sizeof(mapName));
    BuildPath(Path_SM, config, sizeof(config), "configs/ttt/koth/%s_hills.cfg", mapName);
    if (!FileExists(config)) { return false; }
    
    kv.ImportFromFile(config);
    kv.GotoFirstSubKey();
    
    hillCount = 0;
    do
    {
        kv.GetVector("Location", hills[hillCount++]);
    } while (kv.GotoNextKey());
    
    delete kv;
    
    return true;
}

public bool AddHillConfig(float pos[3])
{
    KeyValues kv = new KeyValues("TTT_KotH_Hills");
    char config[PLATFORM_MAX_PATH];
    
    char mapName[128];
    GetCurrentMap(mapName, sizeof(mapName));
    BuildPath(Path_SM, config, sizeof(config), "configs/ttt/koth/%s_hills.cfg", mapName);
    if (FileExists(config))
    {
        kv.ImportFromFile(config);
        kv.GotoFirstSubKey();
        while (kv.GotoNextKey()) {}
        
        char buffer[2];
        kv.GetSectionName(buffer, 2);
        int lastIndex = StringToInt(buffer);
        if (lastIndex >= KOTH_HILLS_MAX)
        {
            delete kv;
            return false;
        }
    
        IntToString(++lastIndex, buffer, 2);
        kv.JumpToKey(buffer, true);
        kv.SetVector("Location", pos);
    }
    else
    {
        kv.JumpToKey("0", true);
        kv.SetVector("Location", pos);
    }
    
    kv.ExportToFile(config);
    delete kv;
    
    return true;
}

public void TTT_OnRoundStart(int innocents, int traitors, int detective)
{
    if (isDayRunning)
    {
        if (remainingRounds <= 0)
        {
            TTT_StopSpecialDay();
            return;
        }
        
        if (remainingRounds > 1) { CPrintToChatAll("{purple}[TTT] {yellow}For the next {blue}%n {yellow}rounds King of the Hill will be active.", remainingRounds); }
        else { CPrintToChatAll("{purple}[TTT] {yellow}For the next round King of the Hill will be active."); }
        
        remainingRounds--;
    }
}

public Action Command_AddHillSpawn(int client, int args)
{
    Player player = Player(client);
    if (player.Access(RANK_SADMIN, true)) { return Plugin_Handled; }
    
    float pos[3];
    if (!player.RayTrace(pos))
    {
        player.Error("Please look at a valid location.");
    }
    
    if (AddHillConfig(pos)) { CPrintToChat(client, "{purple}[TTT] {yellow}Placed a hill at x: {blue}%f{yellow}, y: {blue}%f{yellow}, z: {blue}%f {yellow}with an index of {blue}%n{yellow}."); }
    else { player.Error("Was unable to add a new hill as you have already reached the max amount for this map.") }
    
    return Plugin_Handled;
}
