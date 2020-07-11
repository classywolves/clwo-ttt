#if defined _big_brother_included
    #endinput
#endif
#define _big_brother_included

native void BigBrother_LogMessage(int sender, int reciever, char[] message);

public SharedPlugin __pl_big_brother =
{
	name = "big_brother",
	file = "big_brother.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_big_brother_SetNTVOptional()
{
    MarkNativeAsOptional("BigBrother_LogMessage");
}
#endif
