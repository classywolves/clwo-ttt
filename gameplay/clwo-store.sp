#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <generics>
#include <ttt_messages>
#include <ttt_targeting>
#include <clwo-store-messages>

public Plugin myinfo =
{
    name = "CLWO Store",
    author = "c0rp3n",
    description = "Custom store and credits system for CLWO TTT.",
    version = "0.1.0",
    url = ""
};

bool g_bStoreReady = false;

Database g_database = null;

ArrayList g_aStoreItems = null;
ArrayList g_aStoreSkills = null;

StringMap g_smItemIndexMap = null;
StringMap g_smSkillIndexMap = null;

GlobalForward g_OnRegisterForward = null;
GlobalForward g_OnReadyForward = null;
GlobalForward g_OnItemPurchasedForward = null;
GlobalForward g_OnSkillPurchasedForward = null;

ConVar g_cSortItems = null;
ConVar g_cCredits = null;

enum struct Item
{
    char id[16];
    char name[64];
    char description[192];
    int price;
    int maxCount;
    int sort;
}

enum struct Skill
{
    char id[16];
    char name[64];
    char description[192];
    int price;
    float increase;
    int level;
    int sort;
}

enum struct PlayerData
{
    int credits;
    StringMap items;
    StringMap skills;
    int selectedItem;
    int selectedSkill;
}

PlayerData g_playerData[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    g_OnRegisterForward = new GlobalForward("Store_OnRegister", ET_Ignore);
    g_OnReadyForward = new GlobalForward("Store_OnReady", ET_Ignore);
    g_OnItemPurchasedForward = new GlobalForward("Store_OnItemPurchased", ET_Ignore, Param_Cell, Param_String);
    g_OnSkillPurchasedForward = new GlobalForward("Store_OnItemPurchased", ET_Ignore, Param_Cell, Param_String, Param_Cell);

    CreateNative("Store_IsReady", Native_IsReady);

    CreateNative("Store_RegisterItem", Native_RegisterItem);
    CreateNative("Store_RegisterSkill", Native_RegisterSkill);
    CreateNative("Store_UnRegisterItem", Native_UnRegisterItem);
    CreateNative("Store_UnRegisterSkill", Native_UnRegisterSkill);
    CreateNative("Store_GetItem", Native_GetItem);
    CreateNative("Store_GetSkill", Native_GetSkill);
    CreateNative("Store_AddItem", Native_AddItem);

    CreateNative("Store_GetCredits", Native_GetCredits);
    CreateNative("Store_SetCredits", Native_SetCredits);
    CreateNative("Store_AddCredits", Native_AddCredits);

    RegPluginLibrary("clwo-store");

    return APLRes_Success;
}

public OnPluginStart()
{
    g_cSortItems = CreateConVar("clwo_store_sort", "1", "Sort shop items? 0 = Disabled. 1 = Enabled (default).", _, true, 0.0, true, 1.0);
    g_cCredits = CreateConVar("clwo_store_credits", "0", "The amount of credits a player should start with.");

    g_aStoreItems = new ArrayList(sizeof(Item), 0);
    g_aStoreSkills = new ArrayList(sizeof(Skill), 0);

    g_smItemIndexMap = new StringMap();
    g_smSkillIndexMap = new StringMap();

    HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Post);

    RegConsoleCmd("sm_cr", Command_Credits, "Displays the clients credits (cR).");
    RegConsoleCmd("sm_givecr", Command_GiveCredits, "Give a set amount of credits to a client (cR).");
    RegAdminCmd("sm_setcr", Command_SetCredits, ADMFLAG_CHEATS, "Set a clients credits (cR).");

    RegConsoleCmd("sm_skills", Command_Skills, "Displays the skills menu to the client.");
    RegConsoleCmd("sm_store", Command_Store, "Displays the store to the client.");

    AutoExecConfig(true, "store", "clwo");

    Database.Connect(DbCallback_Connect, "store");

    PrintToServer("[STR] Loaded succcessfully");
}

public void OnClientPutInServer(int client)
{
    g_playerData[client].credits = -1;
    g_playerData[client].items = new StringMap();
    g_playerData[client].skills = new StringMap();
    g_playerData[client].selectedItem = -1;
    g_playerData[client].selectedSkill = -1;

    Db_SelectClientCredits(client);
    Db_SelectClientItems(client);
    Db_SelectClientSkills(client);
}

public void OnClientDisconnect(int client)
{
    g_playerData[client].credits = -1;
    g_playerData[client].items.Clear();
    g_playerData[client].skills.Clear();
    g_playerData[client].selectedItem = -1;
    g_playerData[client].selectedSkill = -1;

    delete g_playerData[client].items;
    delete g_playerData[client].skills;
}

public Action Command_Credits(int client, int args)
{
    CPrintToChat(client, STORE_MESSAGE ... "{yellow}%N {default}has {orange}%dcR.", client, g_playerData[client].credits);

    return Plugin_Handled;
}

public Action Command_GiveCredits(int client, int args)
{
    if (args < 2)
    {
        CPrintToChat(client, TTT_USAGE ... "sm_givecr <#userid|name> <amount>");
        return Plugin_Handled;
    }

    char buffer[32];
    int target;
    int amount;

    GetCmdArg(1, buffer, sizeof(buffer));
    target = TTT_Target(buffer, client, true, false, false);
    if (target < 1)
    {
        return Plugin_Handled;
    }

    GetCmdArg(2, buffer, sizeof(buffer));
    amount = StringToInt(buffer);

    if (amount > g_playerData[client].credits)
    {
        CPrintToChat(client, STORE_MESSAGE ... "you do not have enough cR to give {orange}%d {default}to {yellow}%N.", amount, target);
        return Plugin_Handled;
    }

    CPrintToChatAll(STORE_MESSAGE ... "{yellow}%N {default}has given {yellow}%N {orange}%dcR.", client, target, amount);
    g_playerData[target].credits += amount;

    return Plugin_Handled;
}

public Action Command_SetCredits(int client, int args)
{
    if (args < 2)
    {
        CPrintToChat(client, TTT_USAGE ... "sm_setcr <#userid|name> <amount>");
        return Plugin_Handled;
    }

    char buffer[32];
    int target;
    int amount;

    GetCmdArg(1, buffer, sizeof(buffer));
    target = TTT_Target(buffer, client, true, false, false);
    if (target < 1)
    {
        return Plugin_Handled;
    }

    GetCmdArg(2, buffer, sizeof(buffer));
    amount = StringToInt(buffer);

    CPrintToChatAll(STORE_MESSAGE ... "{yellow}%N {default}has set {yellow}%N {orange}%dcR.", client, target, amount);
    g_playerData[target].credits = amount;

    return Plugin_Handled;
}

public Action Command_Skills(int client, int args)
{
    Menu_Skills(client);

    return Plugin_Handled;
}

public Action Command_Store(int client, int args)
{
    Menu_Store(client);

    return Plugin_Handled;
}

public void Db_InsertClientCredits(int client)
{
    int accountId = GetSteamAccountID(client, true);

    char query[89];
    Format(query, sizeof(query), "INSERT INTO `store_players` (`account_id`, `credits`) VALUES ('%d', '%d');", accountId, g_playerData[client].credits);
    g_database.Query(DbCallback_InsertClientCredits, query, GetClientUserId(client));
}

public void Db_InsertUpdateSkill(int client, int skill, int level)
{
    int accountId = GetSteamAccountID(client, true);

    Skill skillData;
    g_aStoreSkills.GetArray(skill, skillData);

    char query[256];
    Format(query, sizeof(query), "INSERT INTO `store_skills` (`account_id`, `skill_id`, `level`) VALUES ('%d', '%s', '%d') ON DUPLICATE KEY UPDATE `level` = '%d';", accountId, skillData.id, level, level);
    g_database.Query(DbCallback_InsertUpdateSkill, query, GetClientUserId(client));
}

public void Db_SelectClientCredits(int client)
{
    int accountId = GetSteamAccountID(client, true);

    char query[128];
    Format(query, sizeof(query), "SELECT `credits` FROM `store_players` WHERE `account_id` = '%d';", accountId);
    g_database.Query(DbCallback_SelectClientCredits, query, GetClientUserId(client));
}

public void Db_SelectClientItems(int client)
{
    int accountId = GetSteamAccountID(client, true);

    char query[128];
    Format(query, sizeof(query), "SELECT `item_id`, `quantity` FROM `store_items` WHERE `account_id` = '%d';", accountId);
    g_database.Query(DbCallback_SelectClientItems, query, GetClientUserId(client));
}

public void Db_SelectClientSkills(int client)
{
    int accountId = GetSteamAccountID(client, true);

    char query[128];
    Format(query, sizeof(query), "SELECT `skill_id`, `level` FROM `store_skills` WHERE `account_id` = '%d';", accountId);
    g_database.Query(DbCallback_SelectClientSkills, query, GetClientUserId(client));
}

public void Db_UpdateClientCredits(int client)
{
    if (g_playerData[client].credits < 0)
    {
        return;
    }

    int accountId = GetSteamAccountID(client, true);

    char query[89];
    Format(query, sizeof(query), "UPDATE `store_players` SET `credits` = '%d' WHERE `account_id` = '%d';", g_playerData[client].credits, accountId);
    g_database.Query(DbCallback_UpdateClientCredits, query, GetClientUserId(client));
}

public void DbCallback_Connect(Database db, const char[] error, any data)
{
    if (db == null)
    {
        PrintToServer("DbCallback_Connect: %s", error);
        return;
    }

    g_database = db;
    SQL_FastQuery(g_database, "CREATE TABLE IF NOT EXISTS `store_players` (`account_id` INT UNSIGNED NOT NULL, `credits` INT UNSIGNED NOT NULL, PRIMARY KEY (`account_id`)) ENGINE = InnoDB;");
    SQL_FastQuery(g_database, "CREATE TABLE IF NOT EXISTS `store_items` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `account_id` INT UNSIGNED NOT NULL, `item_id` VARCHAR(16) NOT NULL, `quantity` INT UNSIGNED NOT NULL, PRIMARY KEY (`id`), UNIQUE `unique_item_entry` (`account_id`, `item_id`)) ENGINE = InnoDB;");
    SQL_FastQuery(g_database, "CREATE TABLE IF NOT EXISTS `store_skills` ( `id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `account_id` INT UNSIGNED NOT NULL, `skill_id` VARCHAR(16) NOT NULL, `level` INT UNSIGNED NOT NULL, PRIMARY KEY (`id`), UNIQUE `unique_skill_entry` (`account_id`, `skill_id`) ) ENGINE = InnoDB;");

    LoopValidClients(i)
    {
        OnClientPutInServer(i);
    }

    Call_StartForward(g_OnRegisterForward);
    Call_Finish();

    g_bStoreReady = true;
    Call_StartForward(g_OnReadyForward);
    Call_Finish();

    PrintToServer(STORE_MESSAGE ... "%d Items have been registered.", g_aStoreItems.Length + g_aStoreSkills.Length);
}

public void DbCallback_InsertClientCredits(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        PrintToServer("DbCallback_InsertClientCredits: %s", error);
        return;
    }
}

public void DbCallback_InsertUpdateSkill(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        PrintToServer("DbCallback_InsertUpdateSkill: %s", error);
        return;
    }
}

public void DbCallback_SelectClientCredits(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        PrintToServer("DbCallback_SelectClientCredits: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if (IsValidClient(client))
    {
        if (results.FetchRow())
        {
            g_playerData[client].credits = results.FetchInt(0);
        }
        else
        {
            g_playerData[client].credits = g_cCredits.IntValue;
            Db_InsertClientCredits(client);
        }
    }
}

public void DbCallback_SelectClientItems(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        PrintToServer("DbCallback_SelectClientItems: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if (IsValidClient(client))
    {
        while (results.FetchRow())
        {
            char id[16];
            results.FetchString(0, id, sizeof(id));

            int amount = results.FetchInt(1);

            g_playerData[client].items.SetValue(id, amount);
        }
    }
}

public void DbCallback_SelectClientSkills(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        PrintToServer("DbCallback_SelectClientSkills: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if (IsValidClient(client))
    {
        while (results.FetchRow())
        {
            char id[16];
            results.FetchString(0, id, sizeof(id));

            int level = results.FetchInt(1);

            g_playerData[client].skills.SetValue(id, level);
        }
    }
}

public void DbCallback_UpdateClientCredits(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        PrintToServer("DbCallback_UpdateClientCredits: %s", error);
    }
}

public Action Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    LoopValidClients(i)
    {
        Db_UpdateClientCredits(i);
    }
}

public void Menu_Store(int client)
{
    Menu mStore = new Menu(MenuHandler_Store);
    mStore.SetTitle("c0rp3n's shady merchant \"friend\"");

    mStore.AddItem("i", "Items");
    mStore.AddItem("s", "Skills");
    mStore.AddItem("u", "Upgrades");

    mStore.Display(client, 240);
}

public void Menu_Skills(int client)
{
    Menu mSkills = new Menu(MenuHandler_Skills);
    mSkills.SetTitle("Skills");

    for (int i = 0; i < g_aStoreSkills.Length; i++)
    {
        Skill skill;
        g_aStoreSkills.GetArray(i, skill);

        char info[4];
        char message[192];

        IntToString(i, info, sizeof(info));

        int level = -1;
        if (g_playerData[client].skills.GetValue(skill.id, level))
        {
            Format(message, sizeof(message), "%s (Level: %d)", skill.name, level);
        }
        else
        {
            Format(message, sizeof(message), "%s (Not Owned)", skill.name);
        }
        
        mSkills.AddItem(info, message);
    }

    mSkills.Display(client, 240);
}

public void Menu_SkillInfo(int client, int skill)
{
    Panel pSkill = new Panel();

    Skill skillData;
    g_aStoreSkills.GetArray(skill, skillData);

    pSkill.SetTitle(skillData.name);

    int level = -1;
    char levelText[32] = "";
    if (g_playerData[client].skills.GetValue(skillData.id, level))
    {
        Format(levelText, sizeof(levelText), "Current Level: %d\n", level);
        pSkill.DrawText(levelText);
    }
    else
    {
        level = 0;
    }

    int price = -1;
    char priceText[32] = "";
    if (level)
    {
        price = RoundToNearest(float(skillData.price) * Pow(skillData.increase, float(level)));
    }
    else
    {
        price = skillData.price;
    }
    Format(priceText, sizeof(priceText), "Price: %dcR\n", price);

    char text[192];
    Format(text, sizeof(text), "%s%s\n%s", levelText, skillData.description, priceText);
    pSkill.DrawText(text);

    pSkill.DrawItem("Purchase", ITEMDRAW_CONTROL);

    pSkill.DrawItem("", ITEMDRAW_SPACER);

    pSkill.CurrentKey = 8;
    pSkill.DrawItem("Back", ITEMDRAW_CONTROL);
    pSkill.DrawItem("Exit", ITEMDRAW_CONTROL);

    g_playerData[client].selectedSkill = skill;
    pSkill.Send(client, PanelHandler_SkillInfo, 240);

    delete pSkill;
}

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
            char info[4];
            menu.GetItem(data, info, sizeof(info));
            int skill = StringToInt(info, sizeof(info));
            Menu_SkillInfo(client, skill);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}

public int Native_IsReady(Handle plugin, int numParams)
{
    return g_bStoreReady;
}

public int Native_RegisterItem(Handle plugin, int numParams)
{
    Item item;
    GetNativeString(1, item.id, sizeof(item.id));
    GetNativeString(2, item.name, sizeof(item.name));
    GetNativeString(3, item.description, sizeof(item.description));
    item.price = GetNativeCell(4);
    item.maxCount = GetNativeCell(5);
    item.sort = GetNativeCell(6);

    for (int i = 0; i < g_aStoreItems.Length; i++)
    {
        Item temp;
        g_aStoreItems.GetArray(i, temp);
        if (StrEqual(temp.id, item.id, false))
        {
            PrintToServer(STORE_ERROR ... "Item %s already registered.", item.id);
            return -1;
        }
    }

    g_smItemIndexMap.SetValue(item.id, g_aStoreItems.Length);
    g_aStoreItems.PushArray(item);

    if (g_cSortItems.BoolValue)
    {
        SortADTArrayCustom(g_aStoreItems, Sort_Items);
    }

    return 0;
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
    skill.sort = GetNativeCell(7);

    for (int i = 0; i < g_aStoreSkills.Length; i++)
    {
        Skill temp;
        g_aStoreSkills.GetArray(i, temp);
        if (StrEqual(temp.id, skill.id, true))
        {
            PrintToServer(STORE_ERROR ... "Skill %s already registered.", temp.id);
            return -1;
        }
    }

    g_smSkillIndexMap.SetValue(skill.id, g_aStoreSkills.Length);
    g_aStoreSkills.PushArray(skill);

    if (g_cSortItems.BoolValue)
    {
        SortADTArrayCustom(g_aStoreSkills, Sort_Skills);
    }

    LogMessage(STORE_MESSAGE ... "Registered skill %s (%s), price: %d, level: %d - %s", skill.name, skill.id, skill.price, skill.level, skill.description);

    return 0;
}

public int Native_UnRegisterItem(Handle plugin, int numParams)
{
    char id[16];
    GetNativeString(1, id, sizeof(id));

    int index = -1;
    if (g_smItemIndexMap.GetValue(id, index))
    {
        PrintToServer(STORE_ERROR ... "Item %s is not currently registered.", id);
        return false;
    }

    g_aStoreItems.Erase(index);
    g_smItemIndexMap.Remove(id);

    return true;
}

public int Native_UnRegisterSkill(Handle plugin, int numParams)
{
    char id[16];
    GetNativeString(1, id, sizeof(id));

    int index = -1;
    if (g_smSkillIndexMap.GetValue(id, index))
    {
        PrintToServer(STORE_ERROR ... "Skill %s is not currently registered.", id);
        return false;
    }

    g_aStoreSkills.Erase(index);
    g_smSkillIndexMap.Remove(id);

    return true;
}

public int Native_GetItem(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    char id[16];
    GetNativeString(2, id, sizeof(id));

    int count = -1;
    if (g_playerData[client].items.GetValue(id, count))
    {
        PrintToServer(STORE_ERROR ... "Item %s is not currently registered.", id);
        return 0;
    }

    return count;
}

public int Native_GetSkill(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    char id[16];
    GetNativeString(2, id, sizeof(id));

    int level = -1;
    if (g_playerData[client].skills.GetValue(id, level))
    {
        PrintToServer(STORE_ERROR ... "Skill %s is not currently registered.", id);
        return 0;
    }

    return level;
}

public int Native_AddItem(Handle plugin, int numParams)
{
    return -1;
}

public int Native_GetCredits(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    return g_playerData[client].credits;
}

public int Native_SetCredits(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int amount = GetNativeCell(2);

    g_playerData[client].credits = amount;

    return g_playerData[client].credits;
}

public int Native_AddCredits(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int amount = GetNativeCell(2);

    g_playerData[client].credits += amount;

    return g_playerData[client].credits;
}

public int Sort_Items(int i, int j, Handle array, Handle hndl)
{
    Item item1;
    Item item2;

    g_aStoreItems.GetArray(i, item1);
    g_aStoreItems.GetArray(j, item2);

    if (item1.sort < item2.sort)
    {
        return -1;
    }
    else if (item1.sort > item2.sort)
    {
        g_smItemIndexMap.SetValue(item1.id, j);
        g_smItemIndexMap.SetValue(item2.id, i);
        return 1;
    }

    return 0;
}

public int Sort_Skills(int i, int j, Handle array, Handle hndl)
{
    Skill skill1;
    Skill skill2;

    g_aStoreSkills.GetArray(i, skill1);
    g_aStoreSkills.GetArray(j, skill2);

    if (skill1.sort < skill2.sort)
    {
        return -1;
    }
    else if (skill1.sort > skill2.sort)
    {
        g_smSkillIndexMap.SetValue(skill1.id, j);
        g_smSkillIndexMap.SetValue(skill2.id, i);
        return 1;
    }

    return 0;
}

public void Purchase_Skill(int client, int skill)
{
    Skill skillData;
    g_aStoreSkills.GetArray(skill, skillData);

    int level = 0;
    g_playerData[client].skills.GetValue(skillData.id, level);

    int price = RoundToNearest(float(skillData.price) * Pow(skillData.increase, float(level)));
    if (g_playerData[client].credits >= price)
    {
        level++;
        g_playerData[client].credits -= price;

        g_playerData[client].skills.SetValue(skillData.id, level);
        Db_InsertUpdateSkill(client, skill, level);

        Menu_SkillInfo(client, skill);

        Call_StartForward(g_OnSkillPurchasedForward);
        Call_PushCell(client);
        Call_PushString(skillData.id);
        Call_PushCell(level);
        Call_Finish();

        CPrintToChat(client, STORE_MESSAGE ... "You just purchased {yellow}%s {default}for {orange}%d.", skillData.name, price);
    }
}
