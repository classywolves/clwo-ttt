#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorlib>
#include <generics>
#include <ttt_targeting>

#undef REQUIRE_PLUGIN
#include <clwo_store_credits>
#define REQUIRE_PLUGIN
#include <clwo_store_messages>

#define SKILL_ARRAY_SIZE 16

public Plugin myinfo =
{
    name = "CLWO Store",
    author = "c0rp3n",
    description = "Custom store and credits system for CLWO TTT.",
    version = "0.2.0",
    url = ""
};

bool g_bStoreReady = false;
bool g_bCreditsLoaded = false;

Database g_database = null;

ArrayList g_aStoreSkills = null;

StringMap g_smSkillIndexMap = null;

GlobalForward g_OnRegisterForward = null;
GlobalForward g_OnReadyForward = null;
GlobalForward g_fOnClientSkillsLoaded = null;

ConVar g_cSortItems = null;

enum struct Skill
{
    char id[16];
    char name[64];
    char description[192];
    int price;
    float increase;
    int level;
    int sort;
    Handle plugin;
    Function callback;
}

enum struct PlayerData
{
    bool enabled[SKILL_ARRAY_SIZE];
    int levels[SKILL_ARRAY_SIZE];
    int selectedSkill;
}

PlayerData g_playerData[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    g_OnRegisterForward = new GlobalForward("Store_OnRegister", ET_Ignore);
    g_OnReadyForward = new GlobalForward("Store_OnReady", ET_Ignore);
    g_fOnClientSkillsLoaded = new GlobalForward("Store_OnClientSkillsLoaded", ET_Ignore, Param_Cell);

    CreateNative("Store_IsReady", Native_IsReady);

    CreateNative("Store_RegisterSkill", Native_RegisterSkill);
    CreateNative("Store_UnRegisterSkill", Native_UnRegisterSkill);
    CreateNative("Store_GetSkill", Native_GetSkill);

    RegPluginLibrary("clwo-store");

    return APLRes_Success;
}

public void OnPluginStart()
{
    g_cSortItems = CreateConVar("clwo_store_sort", "1", "Sort shop items? 0 = Disabled. 1 = Enabled (default).", _, true, 0.0, true, 1.0);

    AutoExecConfig(true, "store", "clwo");

    g_aStoreSkills = new ArrayList(sizeof(Skill), 0);

    g_smSkillIndexMap = new StringMap();

    RegConsoleCmd("sm_skills", Command_Skills, "Displays the skills menu to the client.");

    Database.Connect(DbCallback_Connect, "store");

    PrintToServer("[STR] Loaded succcessfully");
}

public void OnAllPluginsLoaded()
{
    g_bCreditsLoaded = Store_CheckCreditsLibraryExists();
}

public void OnLibraryAdded(const char[] name)
{
    if (Store_CheckCreditsLibraryName(name))
    {
        g_bCreditsLoaded = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (Store_CheckCreditsLibraryName(name))
    {
        g_bCreditsLoaded = false;
    }
}

public void OnClientPutInServer(int client)
{
    for (int i = 0; i < SKILL_ARRAY_SIZE; ++i)
    {
        g_playerData[client].enabled[i] = false;
        g_playerData[client].levels[i] = 0;
    }
    g_playerData[client].selectedSkill = -1;
}

public void OnClientPostAdminCheck(int client)
{
    if (g_bStoreReady)
    {
        Db_SelectClientSkills(client);
    }
}

public void OnClientDisconnect(int client)
{
    for (int i = 0; i < SKILL_ARRAY_SIZE; ++i)
    {
        g_playerData[client].enabled[i] = false;
        g_playerData[client].levels[i] = 0;
    }
    g_playerData[client].selectedSkill = -1;
}

////////////////////////////////////////////////////////////////////////////////
// Commands
////////////////////////////////////////////////////////////////////////////////

public Action Command_Skills(int client, int args)
{
    Menu_Skills(client);

    return Plugin_Handled;
}

////////////////////////////////////////////////////////////////////////////////
// Database
////////////////////////////////////////////////////////////////////////////////

public void DbCallback_Connect(Database db, const char[] error, any data)
{
    if (db == null)
    {
        PrintToServer("DbCallback_Connect: %s", error);
        return;
    }

    g_database = db;
    SQL_FastQuery(g_database, "CREATE TABLE IF NOT EXISTS `store_skills` ( `id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `account_id` INT UNSIGNED NOT NULL, `skill_id` VARCHAR(16) NOT NULL, `level` INT UNSIGNED NOT NULL, PRIMARY KEY (`id`), UNIQUE `unique_skill_entry` (`account_id`, `skill_id`) ) ENGINE = InnoDB;");

    Call_StartForward(g_OnRegisterForward);
    Call_Finish();

    g_bStoreReady = true;

    Call_StartForward(g_OnReadyForward);
    Call_Finish();

    PrintToServer(STORE_MESSAGE ... "%d Skills have been registered.", g_aStoreSkills.Length);

    LoopValidClients(i)
    {
        Db_SelectClientSkills(i);
    }
}

void Db_InsertUpdateSkill(int client, int skill, int level)
{
    int accountID = GetSteamAccountID(client, true);

    char skillID[16];
    SkillIndexToID(skill, skillID, sizeof(skillID));

    char query[256];
    Format(query, sizeof(query), "INSERT INTO `store_skills` (`account_id`, `skill_id`, `level`) VALUES ('%d', '%s', '%d') ON DUPLICATE KEY UPDATE `level` = '%d';", accountID, skillID, level, level);
    g_database.Query(DbCallback_InsertUpdateSkill, query, GetClientUserId(client));
}

public void DbCallback_InsertUpdateSkill(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        PrintToServer("DbCallback_InsertUpdateSkill: %s", error);
        return;
    }
}

void Db_UpdateSkillEnabled(int client, const char[] id, bool enabled)
{
    int accountID = GetSteamAccountID(client);

    char query[256];
    Format(query, sizeof(query), "UPDATE `store_skills` SET `enabled` = %s WHERE `account_id` = '%d' AND `skill_id` = '%s';", enabled ? "TRUE" : "FALSE", accountID, id);
    g_database.Query(DbCallback_UpdateSkillEnabled, query, GetClientUserId(client));
}

public void DbCallback_UpdateSkillEnabled(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        PrintToServer("DbCallback_UpdateSkillEnabled: %s", error);
        return;
    }
}

void Db_SelectClientSkills(int client)
{
    int accountID = GetSteamAccountID(client, true);

    char query[256];
    Format(query, sizeof(query), "SELECT `skill_id`, `level`, `enabled` FROM `store_skills` WHERE `account_id` = '%d';", accountID);
    g_database.Query(DbCallback_SelectClientSkills, query, GetClientUserId(client));
}

public void DbCallback_SelectClientSkills(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        PrintToServer("DbCallback_SelectClientSkills: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if (client)
    {
        while (results.FetchRow())
        {
            char id[16];
            results.FetchString(0, id, sizeof(id));

            int level = results.FetchInt(1);
            bool enabled = (results.FetchInt(2) != 0);

            PrintToConsole(client, "[Store] Fetched skill %s level %d (enabled: %s)", id, level, enabled ? "true" : "false");

            int skill = SkillIDToIndex(id);
            if (skill >= 0)
            {
                SetClientSkillEnabled(client, skill, enabled);
                SetClientSkill(client, skill, level);

                if (enabled)
                {
                    Function_OnSkillUpdate(client, skill, level);
                }
            }
        }

        Call_StartForward(g_fOnClientSkillsLoaded);
        Call_PushCell(client);
        Call_Finish();
    }
}

////////////////////////////////////////////////////////////////////////////////
// Menus
////////////////////////////////////////////////////////////////////////////////

/*
void Menu_Store(int client)
{
    Menu mStore = new Menu(MenuHandler_Store);
    mStore.SetTitle("c0rp3n's shady merchant \"friend\"");

    mStore.AddItem("i", "Items");
    mStore.AddItem("s", "Skills");
    mStore.AddItem("u", "Upgrades");

    mStore.Display(client, 240);
}
*/

void Menu_Skills(int client)
{
    Menu mSkills = new Menu(MenuHandler_Skills);
    mSkills.SetTitle("Skills");

    for (int i = 0; i < g_aStoreSkills.Length; i++)
    {
        Skill skill;
        g_aStoreSkills.GetArray(i, skill);

        char message[192];

        int level = GetClientSkill(client, i);
        if (level)
        {
            Format(message, sizeof(message), "%s (Level: %d)", skill.name, level);
        }
        else
        {
            Format(message, sizeof(message), "%s (Not Owned)", skill.name);
        }

        mSkills.AddItem(skill.id, message);
    }

    mSkills.Display(client, 240);
}

void Menu_SkillInfo(int client, int skill)
{
    Panel pSkill = new Panel();

    Skill skillData;
    g_aStoreSkills.GetArray(skill, skillData);

    pSkill.SetTitle(skillData.name);

    int level = GetClientSkill(client, skill);
    static char levelText[64];

    if (level == 0)
    {
        Format(levelText, sizeof(levelText), "Not Owned (Max: %d)\n", skillData.level);
    }
    else if (level < skillData.level)
    {
        Format(levelText, sizeof(levelText), "Current Level: %d (Max: %d)\n", level, skillData.level);
    }
    else
    {
        Format(levelText, sizeof(levelText), "Current Level: %d (Maximum)\n", level);
    }

    int price = 0;
    char priceText[32] = "";
    if (level > 0 && level < skillData.level)
    {
        price = RoundToNearest(float(skillData.price) * Pow(skillData.increase, float(level)));
    }
    else if (level == 0)
    {
        price = skillData.price;
    }

    if (price)
    {
        Format(priceText, sizeof(priceText), "Price: %dcR\n", price);
    }

    char text[192];
    Format(text, sizeof(text), "%s%s\n%s", levelText, skillData.description, priceText);
    pSkill.DrawText(text);

    if (level < skillData.level)
    {
        pSkill.DrawItem("Purchase", ITEMDRAW_CONTROL);
    }
    else
    {
        pSkill.CurrentKey = 2;
    }

    if (level > 0)
    {
        if (GetClientSkillEnabled(client, skill))
        {
            pSkill.DrawItem("Disable", ITEMDRAW_CONTROL);
        }
        else
        {
            pSkill.DrawItem("Enable", ITEMDRAW_CONTROL);
        }
    }

    pSkill.DrawItem("", ITEMDRAW_SPACER);

    pSkill.CurrentKey = 8;
    pSkill.DrawItem("Back", ITEMDRAW_CONTROL);
    pSkill.DrawItem("Exit", ITEMDRAW_CONTROL);

    g_playerData[client].selectedSkill = skill;
    pSkill.Send(client, PanelHandler_SkillInfo, 240);

    delete pSkill;
}

/*
void Menu_SkillRefund(int client, int skill)
{
    Panel pRefund = new Panel();

    Skill skillData;
    g_aStoreSkills.GetArray(skill, skillData);

    static char title[64];
    Format(title, sizeof(title), "Refund: %s", skillData.name);
    pRefund.SetTitle(title);

    pRefund.DrawText("Are you sure you want to refund this skill you will only recieve 80% of the cR you spent.");
}
*/

/*
public int MenuHandler_Store(Menu menu, MenuAction action, int client, int data)
{
    switch (action) 
    {
        case MenuAction_Select:
        {
            char info[2];
            menu.GetItem(data, info, sizeof(info));
            switch (info[0])
            {
                case 'i':
                {

                }
                case 's':
                {
                    Menu_Skills(client);
                }
                case 'u':
                {
                    
                }
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}
*/

public int PanelHandler_SkillInfo(Menu menu, MenuAction action, int client, int choice)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            switch (choice)
            {
                case 1: // Purchase
                {
                    Purchase_Skill(client, g_playerData[client].selectedSkill);
                    Menu_SkillInfo(client, g_playerData[client].selectedSkill);
                }
                case 2:
                {
                    ToggleClientSkillEnabled(client, g_playerData[client].selectedSkill);
                    Menu_SkillInfo(client, g_playerData[client].selectedSkill);
                }
                case 8: // Back
                {
                    Menu_Skills(client);
                }
                case 9: // Exit
                {
                    delete menu;
                }
            }
        }
        case MenuAction_Display :
        {

        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}

public int MenuHandler_Skills(Menu menu, MenuAction action, int client, int data)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[16];
            menu.GetItem(data, info, sizeof(info));
            int skill = SkillIDToIndex(info);
            Menu_SkillInfo(client, skill);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
// Natives
////////////////////////////////////////////////////////////////////////////////

public int Native_IsReady(Handle plugin, int numParams)
{
    return g_bStoreReady;
}

public int Native_RegisterSkill(Handle plugin, int numParams)
{
    Skill skill;
    GetNativeString(1, skill.id, sizeof(skill.id));
    GetNativeString(2, skill.name, sizeof(skill.name));
    GetNativeString(3, skill.description, sizeof(skill.description));
    skill.price = GetNativeCell(4);
    skill.increase = GetNativeCell(5);
    skill.level = GetNativeCell(6);
    skill.plugin = plugin;
    skill.callback = GetNativeCell(7);
    skill.sort = GetNativeCell(8);

    int index = -1;
    for (int i = 0; i < g_aStoreSkills.Length; i++)
    {
        Skill temp;
        g_aStoreSkills.GetArray(i, temp);
        if (StrEqual(temp.id, skill.id, true))
        {
            PrintToServer(STORE_ERROR ... "Skill %s already registered.", temp.id);
            index = i;
            break;
        }
    }

    if (index >= 0) // should allow skills to reload without invalidating
    {
        LogMessage("Updated skill %s with a index of %d.", skill.id, index);
        g_smSkillIndexMap.SetValue(skill.id, index);
        g_aStoreSkills.SetArray(index, skill);
    }
    else
    {
        LogMessage("Pushed skill %s with a index of %d.", skill.id, g_aStoreSkills.Length);
        g_smSkillIndexMap.SetValue(skill.id, g_aStoreSkills.Length);
        g_aStoreSkills.PushArray(skill);
    }
    

    if (g_cSortItems.BoolValue)
    {
        SortADTArrayCustom(g_aStoreSkills, Sort_Skills);
        UpdateSkillMap();
    }

    LogMessage(STORE_MESSAGE ... "Registered skill %s (%s), price: %d, level: %d - %s", skill.name, skill.id, skill.price, skill.level, skill.description);

    if (g_bStoreReady)
    {
        LateLoadSkill();
        LogMessage(STORE_MESSAGE ... "Late loaded skill %s (%s)", skill.name, skill.id);
    }

    return 0;
}

public int Native_UnRegisterSkill(Handle plugin, int numParams)
{
    char id[16];
    GetNativeString(1, id, sizeof(id));

    int index = SkillIDToIndex(id);
    if (index)
    {
        PrintToServer(STORE_ERROR ... "Skill %s is not currently registered.", id);
        return false;
    }

    g_aStoreSkills.Erase(index);
    UpdateSkillMap();

    return true;
}

public int Native_GetSkill(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    char id[16];
    GetNativeString(2, id, sizeof(id));

    int skill = SkillIDToIndex(id);
    int level = GetClientSkill(client, skill);

    return level;
}

////////////////////////////////////////////////////////////////////////////////
// Forwards
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////

void Function_OnSkillUpdate(int client, int skill, int level)
{
    Skill sd;
    g_aStoreSkills.GetArray(skill, sd);

    Call_StartFunction(sd.plugin, sd.callback);
    Call_PushCell(client);
    Call_PushCell(level);
    Call_Finish();
}

////////////////////////////////////////////////////////////////////////////////
// Stocks
////////////////////////////////////////////////////////////////////////////////

public int Sort_Skills(int i, int j, Handle array, Handle hndl)
{
    static Skill skill1;
    static Skill skill2;

    g_aStoreSkills.GetArray(i, skill1);
    g_aStoreSkills.GetArray(j, skill2);

    if (skill1.sort < skill2.sort)
    {
        return -1;
    }
    else if (skill1.sort > skill2.sort)
    {
        return 1;
    }

    return 0;
}

int SkillIDToIndex(char[] id)
{
    int index = -1;
    g_smSkillIndexMap.GetValue(id, index);

    return index;
}

void SkillIndexToID(int skill, char[] id, int length)
{
    Skill sd;
    g_aStoreSkills.GetArray(skill, sd);

    strcopy(id, length, sd.id);
}

bool Purchase_Skill(int client, int skill)
{
    if (!g_bCreditsLoaded)
    {
        return false;
    }

    Skill skillData;
    g_aStoreSkills.GetArray(skill, skillData);

    int level = GetClientSkill(client, skill);

    LogMessage("client %d purchase skill: %s (level: %d) - skill_index: %d, plugin: %d", client, skillData.name, level + 1, skill, skillData.plugin);

    int cr = Store_GetClientCredits(client);
    int price = RoundToNearest(float(skillData.price) * Pow(skillData.increase, float(level)));
    if (cr >= price)
    {
        ++level;

        if (level > skillData.level)
        {
            return false;
        }

        bool enabled = GetClientSkillEnabled(client, skill);
        Function_OnSkillUpdate(client, skill, enabled ? level : 0);

        cr = Store_SubClientCredits(client, price);
        SetClientSkill(client, skill, level);
        Db_InsertUpdateSkill(client, skill, level);

        Menu_SkillInfo(client, skill);

        CPrintToChat(client, STORE_MESSAGE ... "You just purchased {yellow}%s {default}for {orange}%dcR {default}(remaining credits {orange}%dcR{default}).", skillData.name, price, cr);

        return true;
    }

    return false;
}

void UpdateSkillMap()
{
    g_smSkillIndexMap.Clear();

    Skill sd;
    for (int i = 0; i < g_aStoreSkills.Length; ++i)
    {
        g_aStoreSkills.GetArray(i, sd);
        g_smSkillIndexMap.SetValue(sd.id, i);
    }
}

void LateLoadSkill()
{
    LoopValidClients(i)
    {
        OnClientPutInServer(i);
        OnClientPostAdminCheck(i);
    }
}

bool GetClientSkillEnabled(int client, int skill)
{
    return g_playerData[client].enabled[skill];
}

bool SetClientSkillEnabled(int client, int skill, bool enabled)
{
    return g_playerData[client].enabled[skill] = enabled;
}

int GetClientSkill(int client, int skill)
{
    return g_playerData[client].levels[skill];
}

int SetClientSkill(int client, int skill, int level)
{
    return g_playerData[client].levels[skill] = level;
}

void ToggleClientSkillEnabled(int client, int skill)
{
    char id[16];
    SkillIndexToID(skill, id, sizeof(id));

    int level = GetClientSkill(client, skill);

    bool enabled = !GetClientSkillEnabled(client, skill);
    SetClientSkillEnabled(client, skill, enabled);

    Function_OnSkillUpdate(client, skill, enabled ? level : 0);

    Db_UpdateSkillEnabled(client, id, enabled);
}
