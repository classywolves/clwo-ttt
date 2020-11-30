#if defined _ext_cookies_included
    #endinput
#endif
#define _ext_cookies_included

/*
 * Called when an item is purchased in the menu. Return Plugin_Stop
 * to prevent the purchase and stop any credit deductions.
 *
 * @param cookie        The Cookie Identifier.
 * @param steamID       The Steam ID of the fetched cookie value.
 * @param value         The value as a string.
 */
typedef ExtCookies_GetCookieCallback = function void (int cookieID, const char[] steamID, const char[] value);

/*
 * Gets the id of a cookie in the database.
 *
 * @param cookie            The name of the cookie.
 *
 * @return                  The id of the cookie.
 */
native int ExtCookies_GetCookieID(const char[] cookie);

/*
 * Un registers an item from the store.
 *
 * @param cookieID          The index of the cookie from ExtCookies_GetCookieIndex.
 * @param steamID           The short-tag identifier of the item.
 * @param callback          The function to call when the cookie has been fetched.
 *
 */
native void ExtCookies_GetCookieBySteamID(int cookieID, const char[] steamID, ExtCookies_GetCookieCallback callback);

/*
 * Un registers an item from the store.
 *
 * @param cookieID          The index of the cookie from ExtCookies_GetCookieIndex.
 * @param steamID           The short-tag identifier of the item.
 *
 */
native void ExtCookies_SetCookieBySteamID(int cookieID, const char[] steamID, const char[] value);

public SharedPlugin __pl_ext_cookies =
{
    name = "ext_cookies",
    file = "ext_cookies.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_ext_cookies_SetNTVOptional()
{
    MarkNativeAsOptional("ExtCookies_GetCookieID");
    MarkNativeAsOptional("ExtCookies_SetCookieBySteamID");
}
#endif
