#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <generics>
#include <ttt_messages>

enum model {
    WPN_PROP,
    WPN_MDL,
    WPN_CHANCE
}

char models[][][] = {
    { "weapon_ak47", "models/weapons/w_rif_ak47_dropped.mdl", "0.10" },
    { "weapon_aug", "models/weapons/w_rif_aug_dropped.mdl", "0.05" },
    { "weapon_awp", "models/weapons/w_snip_awp_dropped.mdl", "0.02" },
    { "weapon_bizon", "models/weapons/w_smg_bizon_dropped.mdl", "0.05" },
    { "weapon_deagle", "models/weapons/w_pist_deagle_dropped.mdl", "0.05" },
    { "weapon_elite", "models/weapons/w_pist_elite_dropped.mdl", "0.05" },
    { "weapon_famas", "models/weapons/w_rif_famas_dropped.mdl", "0.05" },
    { "weapon_fiveseven", "models/weapons/w_pist_fiveseven_dropped.mdl", "0.10" },
    { "weapon_flashbang", "models/weapons/w_eq_flashbang_dropped.mdl", "0.05" },
    { "weapon_g3sg1", "models/weapons/w_snip_g3sg1_dropped.mdl", "0.01" },
    { "weapon_galilar", "models/weapons/w_rif_galilar_dropped.mdl", "0.05" },
    { "weapon_hegrenade", "models/weapons/w_eq_fraggrenade_dropped.mdl", "0.05" },
    { "weapon_incgrenade", "models/weapons/w_eq_incendiarygrenade_dropped.mdl", "0.05" },
    { "weapon_m249", "models/weapons/w_mach_m249_dropped.mdl", "0.02" },
    { "weapon_m4a1", "models/weapons/w_rif_m4a1_dropped.mdl", "0.02" },
    { "weapon_m4a1_silencer", "models/weapons/w_rif_m4a1_s_dropped.mdl", "0.02" },
    { "weapon_mac10", "models/weapons/w_smg_mac10_dropped.mdl", "0.05" },
    { "weapon_mag7", "models/weapons/w_shot_mag7_dropped.mdl", "0.05" },
    { "weapon_mp7", "models/weapons/w_smg_mp7_dropped.mdl", "0.05" },
    { "weapon_mp9", "models/weapons/w_smg_mp9_dropped.mdl", "0.05" },
    { "weapon_negev", "models/weapons/w_mach_negev_dropped.mdl", "0.02" },
    { "weapon_nova", "models/weapons/w_shot_nova_dropped.mdl", "0.05" },
    { "weapon_p250", "models/weapons/w_pist_p250_dropped.mdl", "0.05" },
    { "weapon_p90", "models/weapons/w_smg_p90_dropped.mdl", "0.05" },
    { "weapon_sawedoff", "models/weapons/w_shot_sawedoff_dropped.mdl", "0.05" },
    { "weapon_scar20", "models/weapons/w_snip_scar20_dropped.mdl", "0.01" },
    { "weapon_sg556", "models/weapons/w_rif_sg556_dropped.mdl", "0.05" },
    { "weapon_ssg08", "models/weapons/w_snip_ssg08_dropped.mdl", "0.05" },
    { "weapon_smokegrenade", "models/weapons/w_eq_smokegrenade_dropped.mdl", "0.05" },
    { "weapon_tec9", "models/weapons/w_pist_tec9_dropped.mdl", "0.05" },
    { "weapon_ump45", "models/weapons/w_smg_ump45_dropped.mdl", "0.05" },
    { "weapon_xm1014", "models/weapons/w_shot_xm1014_dropped.mdl", "0.05" }
};

int totalPositions = 0;
float positions[1024][3];

Handle mapPoints;
Handle mapPointsRead;

int g_iGlow;

public OnPluginStart()
{
    RegisterCmds();
    HookEvents();
    InitDBs();
    InitPrecache();
    OnMapStart();

    LoadTranslations("common.phrases");

    PrintToServer("[INF] Loaded succcessfully");
}

public void RegisterCmds()
{
    RegAdminCmd("sm_spawngun", Command_SpawnGun, ADMFLAG_CONVARS, "Spawn a gun!");
    RegAdminCmd("sm_spawnguns", Command_SpawnGuns, ADMFLAG_CONVARS, "Spawn all guns!");
    RegAdminCmd("sm_addloc", Command_AddLoc, ADMFLAG_CONVARS, "Add a position for a gun to spawn!");
    RegAdminCmd("sm_loadlocs", Command_LoadLocs, ADMFLAG_CONVARS, "Load locations for guns to spawn!");
    RegAdminCmd("sm_showlocs", Command_ShowLocs, ADMFLAG_CONVARS, "Show all locations on a map!");
}

public void HookEvents()
{
    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

public void InitDBs()
{
}

public void InitPrecache()
{
    g_iGlow = PrecacheModel("sprites/blueglow1.vmt");

    //for (int i = 0; i < sizeof(models); i++) {
    //  PrecacheModel(models[i][WPN_MDL]);
    //  //AddFileToDownloadsTable(models[i][WPN_MDL]);
    //}
}

public void OnMapStart()
{
    LoadPoints();
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    //SpawnGuns();
}

public Action Command_SpawnGun(int client, int args)
{
    char name[128], mode[128]; // ipos[256];

    float pos[3];
    GetClientEyePosition(client, pos);

    GetCmdArg(1, name, sizeof(name));
    GetCmdArg(2, mode, sizeof(mode));

    //if (args > 2) {
    //  GetCmdArg(3, ipos, sizeof(ipos));

    //  char floatValues[3][128];
    //  ExplodeString(ipos, ";", floatValues, 3, 128);

    //  pos[0] = StringToFloat(floatValues[0]);
    //  pos[1] = StringToFloat(floatValues[1]);
    //  pos[2] = StringToFloat(floatValues[2]);
    //}

    PrintToServer("SpawnGun() - %s %s %f;%f;%f setting ammo", name, mode, pos[0], pos[1], pos[2]);
    SpawnGun(name, pos);

    // name - "prop_physics" / "prop_physics_override"  
    // mode - "models/props_junk/watermelon01.mdl" / "models/weapons/w_rif_ak47_dropped.mdl"

    return Plugin_Handled;
}

public Action Command_SpawnGuns(int client, int args)
{
    SpawnGuns();

    return Plugin_Handled;
}

public Action Command_AddLoc(int client, int args) 
{
    float pos[3];
    GetClientEyePosition(client, pos);

    char msg[255];
    Format(msg, sizeof(msg), "Adding loc at %f;%f;%f", pos[0], pos[1], pos[2]);
    TTT_Message(client, msg);

    AddLoc(pos);

    return Plugin_Handled;
}

public Action Command_LoadLocs(int client, int args)
{
    LoadPoints();

    return Plugin_Handled;
}

public Action Command_ShowLocs(int client, int args)
{
    ShowLootSpawns(client);
}

public void ShowLootSpawns(int client)
{
    TTT_Message(client, "Showing all %i loot spawning locations", totalPositions + 1);
    for (int i = 0; i < totalPositions + 1; i++) 
    {
        TE_SetupGlowSprite(positions[i], g_iGlow, 10.0, 1.0, 235);
        TE_SendToAll();
    }
}

public void LoadPoints()
{
    char map[255], path[PLATFORM_MAX_PATH];

    GetCurrentMap(map, sizeof(map));
    BuildPath(Path_SM, path, sizeof(path), "configs/lootpos/%s.txt", map);

    mapPointsRead = OpenFile(path, "r");
    if (mapPointsRead == null) return;

    char line[512];
    totalPositions = 0;

    PrintToServer("Loading points from file");

    while(!IsEndOfFile(mapPointsRead) && ReadFileLine(mapPointsRead, line, sizeof(line)))
    {
        PrintToServer("Loaded a line: %s", line);

        char floatValues[3][128];
        ExplodeString(line, ";", floatValues, 3, 128);

        PrintToServer("%s %s;%s;%s", line, floatValues[0], floatValues[1], floatValues[2]);

        positions[totalPositions][0] = StringToFloat(floatValues[0]);
        positions[totalPositions][1] = StringToFloat(floatValues[1]);
        positions[totalPositions][2] = StringToFloat(floatValues[2]);

        totalPositions++;
    }

    totalPositions--;

    PrintToServer("Loaded %i lines", totalPositions);

    if (totalPositions < 0) totalPositions = 0;

    mapPointsRead.Close();
}

public void SpawnGuns()
{
    if (totalPositions)
    {
        int total = 100;
        for (int i = 0; i < sizeof(models); i++)
        {
            float chance = StringToFloat(models[i][WPN_CHANCE]);

            for (int j = 0; j < chance * total; j++)
            {
                float pos[3];
                GetPos(pos);

                PrintToServer("SpawnGun() : %s %s %f;%f;%f", models[0][WPN_PROP], models[0][WPN_MDL], pos[0], pos[1], pos[2]);
                //SpawnGun(models[0][WPN_PROP], models[0][WPN_MDL], pos);
                SpawnGun(models[i][WPN_PROP], pos);
            }
        }
    }
}

public int SpawnGun(char[] cWeaponName, float[3] pos)
{
    float angle[3];
    angle[1] = GetRandomFloat(0.0, 360.0);

    int weapon = CreateEntityByName(cWeaponName);
    if(!IsValidEntity(weapon))
        return INVALID_ENT_REFERENCE;

    // KillEntityIn(weapon, 600.0);
    //PrintToChat(client, "You spawned: %s", itemToCreate)
    DispatchSpawn(weapon); 
    TeleportEntity(weapon, pos, angle, NULL_VECTOR);
    return weapon;
}

public void GetPos(float[3] pos)
{
    if (totalPositions)
    {
        int item = GetRandomInt(0, totalPositions - 1);

        PrintToServer("GetPos() %f;%f;%f", positions[item][0], positions[item][1], positions[item][2]);

        pos[0] = positions[item][0];
        pos[1] = positions[item][1];
        pos[2] = positions[item][2];
    }
}

public void AddLoc(float pos[3])
{
    positions[totalPositions][0] = pos[0];
    positions[totalPositions][1] = pos[1];
    positions[totalPositions][2] = pos[2];

    totalPositions++;

    char line[512];
    Format(line, sizeof(line), "%f;%f;%f", pos[0], pos[1], pos[2]);

    TE_SetupGlowSprite(pos, g_iGlow, 10.0, 1.0, 235);
    TE_SendToAll();

    char map[255], path[PLATFORM_MAX_PATH];

    GetCurrentMap(map, sizeof(map));
    BuildPath(Path_SM, path, sizeof(path), "configs/lootpos/%s.txt", map);

    mapPoints = OpenFile(path, "a");
    WriteFileLine(mapPoints, line);
    mapPoints.Close();
} 
