#if defined _progress_bar_include
  #endinput
#endif
#define _progress_bar_include

#define PROGRESS_BAR_FULL   "▰"
#define PROGRESS_BAR_EMPTY  "▱"
#define PROGRESS_BAR_U8_SIZE 3

enum ProgressBar_Type
{
    ProgressBar_Increment,
    ProgressBar_Decrement
}

enum struct __PB_PlayerBarData
{
    char message[192];
    int start;
    int offset;
}

__PB_PlayerBarData __PB_playerBarData[MAXPLAYERS + 1];

stock void ProgressBar_Create(int client, char[] name, float time, ProgressBar_Type type)
{
    char bar[80];
    ProgressBar_Init(bar, sizeof(bar), 20, 20);

    __PB_playerBarData[client].start = strlen(name) + 1;
    __PB_playerBarData[client].offset = __PB_playerBarData[client].start + (20 * PROGRESS_BAR_U8_SIZE);
    Format(__PB_playerBarData[client].message, 192, "%s: %s", name, bar);
    PrintCenterText(client, __PB_playerBarData[client].message);
    CreateTimer(time / 20.0, Timer_ProgressBarDecrement, GetClientUserId(client));
}

stock void ProgressBar_Init(char[] buffer, int maxsize, int progress, int length = 20)
{
    for (int i = 0; i < progress; i++)
    {
        StrCat(buffer, maxsize, PROGRESS_BAR_FULL);
    }

    for (int i = 0; i < length - progress; i++)
    {
        StrCat(buffer, maxsize, PROGRESS_BAR_EMPTY);
    }
}

stock Action Timer_ProgressBarDecrement(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (IsValidClient(client))
    {
        if (__PB_playerBarData[client].offset > __PB_playerBarData[client].start + PROGRESS_BAR_U8_SIZE)
        {
            __PB_playerBarData[client].message[__PB_playerBarData[client].offset] -= 1;
            PrintCenterText(client, __PB_playerBarData[client].message);

            __PB_playerBarData[client].offset -= PROGRESS_BAR_U8_SIZE;

            return Plugin_Continue;
        }
    }

    return Plugin_Stop;
}