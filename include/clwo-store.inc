#if defined _clwo_store_included
	#endinput
#endif
#define _clwo_store_included

public SharedPlugin __pl_clwo_store =
{
	name = "clwo-store",
	file = "clwo-store.smx",
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
    MarkNativeAsOptional("Store_UpdateItem");
    MarkNativeAsOptional("Store_UnRegisterItem");
    MarkNativeAsOptional("Store_GetItem");
    MarkNativeAsOptional("Store_AddItem");

    MarkNativeAsOptional("Store_GetCredits");
    MarkNativeAsOptional("Store_SetCredits");
    MarkNativeAsOptional("Store_AddCredits");
}
#endif

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
 * Called when an item is purchased in the menu. Return Plugin_Stop
 * to prevent the purchase and stop any credit deductions.
 *
 * @param client            The client who purchased the item.
 * @param itemshort         The item index.
 */
forward void Store_OnItemPurchased(int client, char[] id);

/*
 * Called when an item is purchased in the menu. Return Plugin_Stop
 * to prevent the purchase and stop any credit deductions.
 *
 * @param client            The client who purchased the item.
 * @param itemshort         The item index.
 */
forward void Store_OnSkillPurchased(int client, char[] id, int level);

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
 * @param maxCount          The optional max count a client may have of the item. (Default: 0 - No limit)
 * @param sort              The priority in Sorting. Buy menu is sorted from high to low. (Default: 0)
 *
 * @return                  The items unique integer id for this session.
 */
native void Store_RegisterItem(char[] id, char[] name, char[] description, int price, int maxCount = 0, int sort = 0);

/*
 * Registers a skill to the store.
 *
 * @param id                The short-tag identifier of the skill (must be unique).
 * @param name              The name of the skill.
 * @param description       The information about the skill.
 * @param price             The price of the skill.
 * @param step              The increase in price per level. (0.0 - No change)
 * @param level             The optional max level of this skill. (Default: 1, 0 - No limit)
 * @param sort              The priority in Sorting. Buy menu is sorted from high to low. (Default: 0)
 *
 * @return                  The items unique integer id for this session.
 */
native void Store_RegisterSkill(char[] id, char[] name, char[] description, int price, float step, int level = 1, int sort = 0);

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

/*
 * Gets the clients total credits.
 *
 * @param client            The client to be checked.
 *
 * @return                  The clients credit count.
 */
native int Store_GetCredits(int client);

/*
 * Gets the clients total credits.
 *
 * @param client            The client to be checked.
 * @param credits           The amount the clients credits should be set too.
 *
 * @return                  The clients credit count.
 */
native int Store_SetCredits(int client, int credits);

/*
 * Gets the clients total credits.
 *
 * @param client            The client to be checked.
 * @param credits           The amount of credits to be added to the clients total credits.
 *
 * @return                  The clients credit count.
 */
native int Store_AddCredits(int client, int credits);
