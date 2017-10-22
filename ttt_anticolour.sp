#include <chat-processor>

char Colors[][] = {"\x02", "\x04", "\x03", "\x03", "\x03", "\x05", "\x06", "\x07", "\x03", "\x08", "\x09", "\x10", "\x0A", "\x0B", "\x0C", "\x0D", "\x0E", "\x0F"};

public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
	for (int i = 0; i < sizeof(Colors); i++)
		ReplaceString(message, MAXLENGTH_MESSAGE, Colors[i], "", false);

	Format(message, MAXLENGTH_MESSAGE, "%s{default}", message);

	return Plugin_Changed;
}