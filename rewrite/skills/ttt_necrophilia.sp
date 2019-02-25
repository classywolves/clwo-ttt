#pragma semicolon 1

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

/*
 * Custom methodmap includes.
 */
#include <math_methodmap>
#include <player_methodmap>

#define NECROPHILIA_MAX_LEVEL 2

char soundBury[PLATFORM_MAX_PATH] = "ttt_clwo/ttt_necrophilia_bury.mp3";

public Plugin myinfo =
{
    name = "TTT Necrophilia",
    author = "Popey & c0rp3n",
    description = "TTT Necrophilia Skill",
    version = "0.0.1",
    url = ""
};

public OnPluginStart()
{
    PreCache();
    //RegisterCmds();
    //HookEvents();
    //InitDBs();

    LoadTranslations("common.phrases");

    PrintToServer("[BNO] Loaded successfully");
}

public void PreCache()
{
    PrecacheSound(soundBury, true);

    char buffer[PLATFORM_MAX_PATH];
    Format(buffer, sizeof(buffer),"sound/%s", soundBury);
    AddFileToDownloadsTable(buffer);
}

/*
public void RegisterCmds()
{

}
*/

/*
public void HookEvents()
{

}
*/

/*
public void InitDBs()
{

}
*/

public Action TTT_OnBodyChecked(int client, int[] iRagdollC)
{
    Player player = Player(client);
    if (!player.ValidClient)
    return Plugin_Continue;

    int upgradeLevel = player.Skill(Skill_Necrophilia, 0, NECROPHILIA_MAX_LEVEL);
    if (upgradeLevel < NECROPHILIA_MAX_LEVEL)
    return Plugin_Continue;

    int armour = player.Armour;
    if (armour >= 100)
    return Plugin_Continue;

    if (StrEqual(iRagdollC[Weaponused], "Necrophilia", false))
    return Plugin_Continue;

    // Set the Weaponused state, used to prevent duplicate uses.
    Format(iRagdollC[Weaponused], MAX_NAME_LENGTH, "Necrophilia");
    // Write data to the DataPack.
    DataPack data = CreateDataPack();
    data.WriteCell(client);
    data.WriteCell(upgradeLevel);
    data.WriteCell(armour);
    data.WriteCell(iRagdollC[Ent]);
    data.Reset();
    // Delay the time to harvest a body.
    CreateTimer(2.0, NecrophiliaTimer, data);

    return Plugin_Continue;
}

public Action NecrophiliaTimer(Handle timer, DataPack data) {
    Player player = Player(data.ReadCell());
    int upgradeLevel = data.ReadCell();
    int armour = data.ReadCell();
    int ragdollEnt = data.ReadCell();

    // Fetch the position of the ragdoll.
    float position[3];
    GetEntPropVector(ragdollEnt, Prop_Send, "m_vecOrigin", position);

    // Play a sound for the dissolving effect
    EmitAmbientSound(soundBury, position, ragdollEnt, 200);

    // Allow entity to fall through the floor.
    SetEntProp(ragdollEnt, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID|FSOLID_TRIGGER);
    SetEntProp(ragdollEnt, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
    SetEntProp(ragdollEnt, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);

    // Begin the dissolve process for the ragdoll.
    Effect_DissolveEntity(ragdollEnt, DISSOLVE_ELECTRICAL, -1);

    // Calculate the random armour amount. And then adds it limiting too 100.
    int randomArmour = Math().Min((GetRandomInt(40, 60) * upgradeLevel) / GetClientCount(true), 15);
    player.Armour = Math().Min(armour + randomArmour, 100);

    player.Msg("You've gained {blue}%n {yellow}armour from Necrophilia!", randomArmour);

    return Plugin_Continue;
}
