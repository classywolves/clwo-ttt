#if defined _ttt_messages_included
#endinput
#endif
#define _ttt_messages_included

#define MAX_MESSAGE_LENGTH 1024
#define MAX_MSAY_LENGTH 255

stock void TTT_Message(int client, const char[] msg, any ...)
{
    char buffer[MAX_MESSAGE_LENGTH];
    char formatted[MAX_MESSAGE_LENGTH];
    VFormat(buffer, MAX_MESSAGE_LENGTH, msg, 3);

    Format(formatted, MAX_MESSAGE_LENGTH, "{purple}[TTT] {yellow}%s", buffer);
    CPrintToChat(client, formatted);
}

stock void TTT_Error(int client, const char[] msg, any ...)
{
    char buffer[MAX_MESSAGE_LENGTH];
    char formatted[MAX_MESSAGE_LENGTH];
    VFormat(buffer, MAX_MESSAGE_LENGTH, msg, 3);

    Format(formatted, MAX_MESSAGE_LENGTH, "{purple}[TTT] {red}%s", buffer);
    CPrintToChat(client, formatted);
}

stock void TTT_SendPanelMsg(int client, char[] title, char[] message) {
    ReplaceString(message, MAX_MSAY_LENGTH, "\\n", "\n");

    Panel panel = new Panel();
    panel.SetTitle(title);
    panel.DrawItem("", ITEMDRAW_SPACER);
    panel.DrawText(message);
    panel.DrawItem("", ITEMDRAW_SPACER);
    panel.CurrentKey = GetMaxPageItems(panel.Style);
    panel.DrawItem("Exit", ITEMDRAW_CONTROL);

    if(IsValidClient(client))
    {
        panel.Send(client, HandlerDoNothing, 10);
    }

    delete panel;
}

stock int HandlerDoNothing(Menu menu, MenuAction action, int param1, int param2) {
	// Do nothing.  It's really exciting.
	return;
}
