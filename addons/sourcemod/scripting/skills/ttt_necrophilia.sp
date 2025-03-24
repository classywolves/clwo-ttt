#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <ttt>
#include <colorlib>
#include <smlib/effects>
#include <generics>
#include <ttt_skills>

#include <math_methodmap>

#define NECROPHILIA_MAX_LEVEL 2

public Plugin myinfo =
{
    name = "TTT Necrophilia",
    author = "Popey & c0rp3n",
    description = "TTT Necrophilia Skill",
    version = "1.0.0",
    url = ""
};

char soundBury[PLATFORM_MAX_PATH] = "ttt_clwo/ttt_necrophilia_bury.mp3";

public OnPluginStart()
{
    PreCache();

    LoadTranslations("common.phrases");

    PrintToServer("[BNO] Loaded successfully");
}

public OnAllPluginsLoaded()
{
    Skills_RegisterSkill(Skill_Necrophilia, "Necrophilia", "The player gains some armour from each body they search.", NECROPHILIA_MAX_LEVEL);
}

public void PreCache()
{
    PrecacheSound(soundBury, true);

    char buffer[PLATFORM_MAX_PATH];
    Format(buffer, sizeof(buffer),"sound/%s", soundBury);
    AddFileToDownloadsTable(buffer);
}

public Action TTT_OnBodyChecked(int client, int[] iRagdollC)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    int upgradeLevel = Skills_GetSkill(client, Skill_Necrophilia, 0, NECROPHILIA_MAX_LEVEL);
    if (upgradeLevel < NECROPHILIA_MAX_LEVEL)
    {
        return Plugin_Continue;
    }

    int armour = GetEntProp(client, Prop_Data, "m_ArmorValue");
    if (armour >= 100)
    {
        return Plugin_Continue;
    }

    if (StrEqual(iRagdollC[Weaponused], "Necrophilia", false))
    {
        return Plugin_Continue;
    }

    // Set the Weaponused state, used to prevent duplicate uses.
    Format(iRagdollC[Weaponused], MAX_NAME_LENGTH, "Necrophilia");
    // Write data to the DataPack.
    DataPack data = CreateDataPack();
    // Delay the time to harvest a body.
    CreateDataTimer(2.0, NecrophiliaTimer, data);
    data.WriteCell(client);
    data.WriteCell(upgradeLevel);
    data.WriteCell(armour);
    data.WriteCell(iRagdollC[Ent]);
    data.Reset();

    return Plugin_Continue;
}

public Action NecrophiliaTimer(Handle timer, DataPack data)
{
    int client = data.ReadCell();
    int upgradeLevel = data.ReadCell();
    int armour = data.ReadCell();
    int ragdollEnt = data.ReadCell();

    // Fetch the position of the ragdoll.
    float position[3];
    GetEntPropVector(ragdollEnt, Prop_Send, "m_vecOrigin", position);

    // Play a sound for the dissolving effect
    EmitAmbientSound(soundBury, position, ragdollEnt, 200);

    // Allow entity to fall through the floor.
    SetEntProp(ragdollEnt, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER);
    SetEntProp(ragdollEnt, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
    SetEntProp(ragdollEnt, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);

    // Begin the dissolve process for the ragdoll.
    Effect_DissolveEntity(ragdollEnt, DISSOLVE_ELECTRICAL, -1);

    // Calculate the random armour amount. And then adds it limiting too 100.
    int randomArmour = (GetRandomInt(10, 40) * upgradeLevel) / 4;
    int newArmor = armour + randomArmour;
    if (newArmor > 100)
    {
        SetEntProp(client, Prop_Data, "m_ArmorValue", 100, 1);
    }
    else
    {
        SetEntProp(client, Prop_Data, "m_ArmorValue", newArmor, 1);
    }

    CPrintToChat(client, "{purple}[TTT] {yellow}You've gained {blue}%d {yellow}armour from Necrophilia!", randomArmour);

    return Plugin_Continue;
}
