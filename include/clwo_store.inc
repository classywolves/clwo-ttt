#if defined _clwo_store_included
    #endinput
#endif
#define _clwo_store_included

/*
 * Called when an item is purchased in the menu. Return Plugin_Stop
 * to prevent the purchase and stop any credit deductions.
 *
 * @param client        The Client who purchased the item.
 * @param count         The amount bought.
 */
typedef Store_ItemPurchaseCallback = function Action (int client, int count);

/*
 * Called when a skill is purchased in the menu. Return Plugin_Stop
 * to prevent the purchase and stop any credit deductions.
 *
 * @param client        The Client who purchased the item.
 * @param count         The Level of the Skill.
 */
typedef Store_SkillPurchaseCallback = function Action (int client, int level);

/*
 * Called when the store is ready to register items.
 * Allows for the plugin to be reloaded.
 */
forward void Store_OnRegister();

/*
 * Called when the store has registered all items.
 */
forward void Store_OnReady();

/*
 * Checkes for whether the store is ready yet.
 *
 * @return                  Whether the store is ready yet.
 */
native bool Store_IsReady();

/*
 * Registers an item to the store.
 *
 * @param id                The short-tag identifier of the item (must be unique).
 * @param name              The name of the item.
 * @param price             The price of the item.
 * @param callback          The function to call when this item is purchased.
 * @param maxCount          The optional max count a client may have of the item. (Default: 0 - No limit)
 * @param sort              The priority in Sorting. Buy menu is sorted from high to low. (Default: 0)
 *
 * @return                  The items unique integer id for this session.
 */
native void Store_RegisterItem(char[] id, char[] name, char[] description, int price, Store_ItemPurchaseCallback callback, int maxCount = 0, int sort = 0);

/*
 * Registers a skill to the store.
 *
 * @param id                The short-tag identifier of the skill (must be unique).
 * @param name              The name of the skill.
 * @param description       The information about the skill.
 * @param price             The price of the skill.
 * @param step              The increase in price per level. (0.0 - No change)
 * @param level             The optional max level of this skill. (Default: 1, 0 - No limit)
 * @param callback          The function to call when this skill is purchased.
 * @param sort              The priority in Sorting. Buy menu is sorted from high to low. (Default: 0)
 *
 * @return                  The items unique integer id for this session.
 */
native void Store_RegisterSkill(char[] id, char[] name, char[] description, int price, float step, int level, Store_SkillPurchaseCallback callback, int sort = 0);

/*
 * Un registers an item from the store.
 *
 * @param id                The short-tag identifier of the item.
 *
 * @return                  Whether the item was succesfully removed.
 */
native bool Store_UnRegisterItem(char[] id);

/*
 * Un registers an item from the store.
 *
 * @param id                The short-tag identifier of the item.
 *
 * @return                  Whether the item was succesfully removed.
 */
native bool Store_UnRegisterSkill(char[] id);

/*
 * Gets an the amount of this item owned by the client.
 *
 * @param client            The client to be checked.
 * @param id                The items unique integer id for this session.
 *
 * @return                  The count the user has of this item.
 */
native int Store_GetItem(int client, char[] id);

/*
 * Gets the level of this skill for the given client.
 *
 * @param client            The client to be checked.
 * @param id                The skills unique id.
 *
 * @return                  The count the user has of this item.
 */
native int Store_GetSkill(int client, char[] id);

/*
 * Adds the specified amount of this item to the clients inventory.
 *
 * @param client            The client to be checked.
 * @param id                The items unique integer id for this session.
 * @param amount            The amount to be added.
 *
 * @return                  The count the user has of this item.
 */
native int Store_AddItem(int client, char[] id, int amount);

stock bool Store_CheckLibraryExists()
{
    return LibraryExists("clwo-store");
}

stock bool Store_CheckLibraryName(const char[] name)
{
    return strcmp(name, "clwo-store", true) == 0;
}

public SharedPlugin __pl_clwo_store =
{
    name = "clwo-store",
    file = "clwo_store.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_clwo_store_SetNTVOptional()
{
    MarkNativeAsOptional("Store_IsReady");

    MarkNativeAsOptional("Store_RegisterItem");
    MarkNativeAsOptional("Store_RegisterSkill");
    MarkNativeAsOptional("Store_UnRegisterItem");
    MarkNativeAsOptional("Store_UnRegisterSkill");
    MarkNativeAsOptional("Store_GetItem");
    MarkNativeAsOptional("Store_GetSkill");
    MarkNativeAsOptional("Store_AddItem");
}
#endif
