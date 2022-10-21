#include <sourcemod>
#include <sdktools>
#include <shop>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[Shop] Welcome Announcements", 
	author = "LuqS", 
	description = "", 
	version = "1.0.0.0", 
	url = "https://steamcommunity.com/id/luqsgood || Discord: LuqS#6505"
}

public void OnPluginStart()
{
	if (Shop_IsStarted())
	{
		Shop_Started();
	}
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

public void Shop_Started()
{
	CategoryId category_id = Shop_RegisterCategory("welcome_announcements", "Welcome Announcements", "");
	
	// Load KeyValues Config
	KeyValues kv = CreateKeyValues("WelcomeAnnouncements");
	
	// Find the Config
	char sFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "configs/shop/welcome_announcements.cfg");
	
	// Open file and go directly to the settings, if something doesn't work don't continue.
	if (!kv.ImportFromFile(sFilePath) || !kv.GotoFirstSubKey())
	{
		SetFailState("Couldn't load plugin config.");
	}
	
	char name[64], description[64], sound_path[PLATFORM_MAX_PATH], message[128];
	// Parse Icons one by one.
	do
	{
		// Shop data
		kv.GetSectionName(name, sizeof(name));
		kv.GetString("description", description, sizeof(description));
		
		// Item data
		kv.GetString("sound_path", sound_path, sizeof(sound_path));
		kv.GetString("message", message, sizeof(message));
		
		// Precache and download sound
		if (sound_path[0])
		{
			AddFileToDownloadsTable(sound_path);
		}
		
		if (Shop_StartItem(category_id, name))
		{
			Shop_SetInfo(name, description, kv.GetNum("price"), kv.GetNum("sell_price"), Item_Togglable, 0, kv.GetNum("price_gold"), kv.GetNum("sell_price_gold"));
			
			// Custom info
			Shop_SetCustomInfoString("sound_path", sound_path);
			Shop_SetCustomInfoString("message", message);
			
			Shop_SetCallbacks(.use_toggle = OnItemToggle, .preview = OnItemPreview);
			Shop_EndItem();
		}
		
	} while (kv.GotoNextKey());
	
	// Don't leak handles.
	kv.Close();
}

public ShopAction OnItemToggle(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
	//PrintToServer("OnItemToggle: client: %N, category_id: %d, category: %s, item_id: %d, item: %s, isOn: %d, elapsed: %d", client, category_id, category, item_id, item, isOn, elapsed);
	
	// If already equiped, just unequip.
	if (isOn)
	{
		return Shop_UseOff;
	}

	if (!GetClientTeam(client))
	{
		char sound_path[PLATFORM_MAX_PATH], message[128];
	
		// Get data
		Shop_GetItemCustomInfoString(item_id, "sound_path", sound_path, sizeof(sound_path));
		Shop_GetItemCustomInfoString(item_id, "message", message, sizeof(message));
		
		if (sound_path[0])
		{
			for (int current_client = 1; current_client <= MaxClients; current_client++)
			{
				if (IsClientConnected(current_client))
				{
					ClientCommand(current_client, "play %s", sound_path[6]);
				}
			}
		}
		
		if (message[0])
		{
			ShowPanel2(-1, 1, message, client);
		}
	}
	
	Shop_ToggleClientCategoryOff(client, category_id);

	return Shop_UseOn;
}

public void OnItemPreview(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item)
{
	char sound_path[PLATFORM_MAX_PATH], message[128];
	
	// Get data
	Shop_GetItemCustomInfoString(item_id, "sound_path", sound_path, sizeof(sound_path));
	Shop_GetItemCustomInfoString(item_id, "message", message, sizeof(message));
	
	// Preview
	if (sound_path[0])
	{
		ClientCommand(client, "play %s", sound_path[6]);
	}
	
	if (message[0])
	{
		ShowPanel2(client, 1, message, client);
	}
}

void ShowPanel2(int client, int duration, const char[] format, any...)
{
	static char formatted_message[1024];
	VFormat(formatted_message, sizeof(formatted_message), format, 4);
	
	Event show_survival_respawn_status = CreateEvent("show_survival_respawn_status");
	if (show_survival_respawn_status == null)
	{
		return;
	}
	
	show_survival_respawn_status.SetString("loc_token", formatted_message);
	show_survival_respawn_status.SetInt("duration", duration);
	show_survival_respawn_status.SetInt("userid", -1);
	
	if (0 < client <= MaxClients)
	{
		show_survival_respawn_status.FireToClient(client);
		show_survival_respawn_status.Cancel();
	}
	else
	{
		show_survival_respawn_status.Fire();
	}
} 