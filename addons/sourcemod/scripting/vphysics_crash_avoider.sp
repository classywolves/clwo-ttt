/*
 * VPhysics Crash Avoider by c0rp3n
 *
 * Changelogs:
 * v0.1.0 Initial plugin checks whether players are too close before they die 
 *        and attempts to seperate them.
 *
 * v0.2.0 Correct bounds check to be && not ||, fixed not using the abs value
 *        when calulating the distance to move the player.
 *
 * v0.3.0 Move to using a array instead of an ArrayList to avoid unwanted 
 *        allocations should reduce any negligible performance impacts also 
 *        reduces the amount of iterations by updating the start index at the
 *        start of each frame.
 *
 * v0.4.0 Use SDKHook_OnTakeDamageAlivePost instead of SDKHook_OnTakeDamageAlive
 *        as this stops the hook being fired multiple times and damage
 *        calculation has still not been performed.
 *
 * v1.0.0 Release, slightly altered push distance based on testing, double death
 *        buffer size incase of respawns, though this should rarely happen.
 *
 * v1.1.0 Use VPhysics to attemp to avert crashes where a alive player is inside
 *        of a dying player causing a crash.
 *
 * v1.1.1 Up N_FRAMES to 2, increase player range to 64u to hopefully avoid
 *        crashes when a player is walking into a ragdoll.
 *
 * v1.2.0 Move clients away from nearby alive clients, as well as recent death
 *        locations.
 *        Also add support for if players are too closely stacked that the angle
 *        between them would be the same.
 *
 * v1.2.1 Disable client physics disabling to try and avoid client crashes.
 *
 * v1.2.2 Add extra logging to look into client crashes.
 *
 * v1.2.3 Reduce move distance from 32 + (32 - dist) -> 32 - dist.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

#define FLOAT_PI_2 1.5707963267948966192313216916398
//#define FLOAT_PI 3.1415926535897932384626433832795
#define FLOAT_PI_PI_2 4.7123889803846898576939650749193
#define FLOAT_2PI 6.283185307179586476925286766559

public Plugin myinfo =
{
    name = "VPhysics Crash Avoider",
    author = "c0rp3n",
    description = "",
    version = "1.2.2",
    url = ""
};

int m_vecOrigin;

enum struct DeathInfo
{
    float time;
    float pos[2];
}

int g_iDeathCount = 0;
int g_iDeathTimeIndex = 0;
DeathInfo g_deaths[MAXPLAYERS * 2];

int g_iDeathAngleIndex = 0;
float g_fDeathAngles[4] = { FLOAT_PI_2, FLOAT_PI, FLOAT_PI_PI_2, FLOAT_2PI };

public void OnPluginStart()
{
    m_vecOrigin = FindSendPropInfo("CBaseEntity", "m_vecOrigin");

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamageAlive);
}

public void OnClientDisconnent(int client)
{
    SDKUnhook(client, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamageAlive);
}

public void OnGameFrame()
{
    UpdateDeathTimeIndex();
}

////////////////////////////////////////////////////////////////////////////////
// Events
////////////////////////////////////////////////////////////////////////////////

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_iDeathCount = 0;
    g_iDeathTimeIndex = 0;
}

////////////////////////////////////////////////////////////////////////////////
// Hooks
////////////////////////////////////////////////////////////////////////////////

public void Hook_OnTakeDamageAlive(int victim, int attacker, int inflictor, float damage, int damagetype)
{
    if (float(GetClientHealth(victim)) - damage <= 0.0)
    {
        static float pos[3];
        GetEntDataVector(victim, m_vecOrigin, pos);

        // d* differce along the axis
        // ad* absolute difference
        float dx, dy, adx, ady;
        for (int i = g_iDeathTimeIndex; i < g_iDeathCount; ++i)
        {
            // using manhattan distance here as it is good enough for detection.
            dx = g_deaths[i].pos[0] - pos[0];
            dy = g_deaths[i].pos[1] - pos[1];
            adx = FloatAbs(dx);
            ady = FloatAbs(dy);
            if (adx <= 32.0 && ady <= 32.0)
            {
                float theta = GetAngleOfLine(dx, dy, adx, ady);
                // calculate the distance required to make sure the players are
                // no longer stacked
                float dist = 32.0 - Max(adx, ady);

                // move the victim by the distance in the direction of theta
                pos[0] += dist * Cosine(theta);
                pos[1] += dist * Sine(theta);
                SetEntDataVector(victim, m_vecOrigin, pos, true);

                LogMessage("moved client #%d away from death #%d by %fu (%frad)", victim, i, dist, theta);

                break;
            }
        }

        static float npos[3];
        for (int i = 1; i < MaxClients; ++i)
        {
            if (i != victim && IsClientInGame(i) && IsPlayerAlive(i))
            {
                // get the clients position and then perform the same 
                // distance checks as before.
                GetEntDataVector(i, m_vecOrigin, npos);
                dx = npos[0] - pos[0];
                dy = npos[1] - pos[1];
                adx = FloatAbs(dx);
                ady = FloatAbs(dy);
                if (adx <= 64.0 && ady <= 64.0)
                {
                    float theta = GetAngleOfLine(dx, dy, adx, ady);
                    // calculate the distance required to make sure the players
                    // are no longer stacked
                    float dist = 32.0 - Max(adx, ady);

                    // move the victim by the distance in the direction of theta
                    pos[0] += dist * Cosine(theta);
                    pos[1] += dist * Sine(theta);
                    SetEntDataVector(victim, m_vecOrigin, pos, true);

                    int userid = GetClientUserId(i);
                    LogMessage("moved client #%d (#%d) away from client #%d by %fu (%frad)", victim, userid, i, dist, theta);
                }
            }
        }

        PushDeath(pos);
    }
}

////////////////////////////////////////////////////////////////////////////////
// Stocks
////////////////////////////////////////////////////////////////////////////////

float Max(float x, float y)
{
    return x > y ? x : y;
}

/*
 * Update the death angle index so that it is wrapped when all angles are used.
 */
void UpdateDeathAngleIndex()
{
    ++g_iDeathAngleIndex;
    if (g_iDeathAngleIndex >= sizeof(g_fDeathAngles))
    {
        g_iDeathAngleIndex = 0;
    }
}

/*
 * Updates the death time index, this is skip checking against old deaths before
 * a player dies; old deaths are deaths that occured a second earlier atm.
 */
void UpdateDeathTimeIndex()
{
    float time = GetGameTime();
    while (g_iDeathTimeIndex < g_iDeathCount && g_deaths[g_iDeathTimeIndex].time <= time - 1.0)
    {
        ++g_iDeathTimeIndex;
    }
}

/*
 * Get the angle to move a client along, if the angle is neglible we choose, a
 * "random" vector to move along.
 */
float GetAngleOfLine(float dx, float dy, float adx, float ady)
{
    // calculate the angle from the death location to the victim
    float theta = 0.0;
    if (adx > 8.0 || ady > 8.0)
    {
        theta = ArcTangent2(dx, dy);
    }
    else
    {
        theta = g_fDeathAngles[g_iDeathAngleIndex];
        UpdateDeathAngleIndex();
    }
}

/*
 * Adds a new death to the end of the deaths array.
 */
void PushDeath(float[] pos)
{
    g_deaths[g_iDeathCount].time = GetGameTime();
    g_deaths[g_iDeathCount].pos[0] = pos[0];
    g_deaths[g_iDeathCount].pos[1] = pos[1];
    ++g_iDeathCount;
}
