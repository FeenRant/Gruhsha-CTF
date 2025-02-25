#include "ChatCommandManager.as"
#include "PickingCommands.as"

//command register order is not important
//actual order in help command is based on the order of commands in ChatCommands.cfg
void RegisterGruhshaChatCommands(ChatCommandManager@ manager)
{
	//gruhsha commands
	manager.RegisterCommand(SpecAllCommand());
	manager.RegisterCommand(AppointCommand());
	manager.RegisterCommand(DemoteCommand());
	manager.RegisterCommand(PickPlayerCommand());
	manager.RegisterCommand(ApproveTeamsCommand());
}
