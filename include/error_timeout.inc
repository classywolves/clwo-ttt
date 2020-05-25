#if defined _error_timeout_included
	#endinput
#endif
#define _error_timeout_included

int __ET_iLastErrorMessage[MAXPLAYERS + 1];

stock bool ErrorTimeout(int client, int timout = 5)
{
    int errorCurrentTime = GetTime();
    if (errorCurrentTime >= __ET_iLastErrorMessage[client] + timout)
    {
        __ET_iLastErrorMessage[client] = errorCurrentTime;

        return true;
    }

    return false;
}
