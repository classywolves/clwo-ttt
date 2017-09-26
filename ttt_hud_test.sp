#pragma semicolon 1

#include <sourcemod>

public OnPluginStart()
{
    RegConsoleCmd("test", asdf);
}

public Action:asdf(client, args)
{
    new Handle:hHudText = CreateHudSynchronizer();
    SetHudTextParams(0.01, 0.01, 5.0, 255, 128, 0, 255, 2, 0.1, 0.5, 0.5);
    ShowSyncHudText(client, hHudText, "WARNING: Please do not RDM.");
    CloseHandle(hHudText);

    return Plugin_Handled;
}  