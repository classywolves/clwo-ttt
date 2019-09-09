#if defined _error_timeout_included
	#endinput
#endif
#define _error_timeout_included

int g_iLastErrorMessage[MAXPLAYERS + 1];

stock bool ErrorTimeout(int client, int timout)
{
    int errorCurrentTime = GetTime();
    if (errorCurrentTime >= g_iLastErrorMessage[%1] + %3)
    {
        g_iLastErrorMessage[%1] = errorCurrentTime;

        return true;
    }

    return false;
}
