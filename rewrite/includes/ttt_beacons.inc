#if defined _beacons_included
#endinput
#endif
#define _beacons_included

native void TTT_SpawnBeacon(float location[3], float radius);

public SharedPlugin __pl_beacons =
        {
                name = "ttt_beacons",
                file = "ttt_beacons.smx",
#if defined REQUIRE_PLUGIN
                required = 1
#else
                required = 0
#endif
        };

#if !defined REQUIRE_PLUGIN
public void __pl_special_days_SetNTVOptional()
{
    MarkNativeAsOptional("");
}
#endif