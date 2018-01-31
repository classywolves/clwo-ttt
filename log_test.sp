#include <logger>

public void OnPluginStart() {
	test();
}

public void test() {
	setLogSource("logtest");

	log(Info, -1, "Hello!");
	log(Success, -1, "Hi %s", "Bob");
	log(Warn, 5, "how odd?");
	log(Error, -1, ":)");
}