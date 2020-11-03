#include <log>

Logger logger;

public OnPluginStart()
{
	logger = Logger();
	logger.name("test");

	logger.Log("A random info message");
	logger.Success("We did good");
	logger.Warn("Watch out!");
	logger.Error("Uh oh...");

	logger.Warn("Huh %s", "test");
}