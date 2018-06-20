/*
	media url search by youtube

*/

//	string GetTitle() 													-> get title for UI
//	string GetVersion													-> get version for manage
//	string GetDesc()													-> get detail information
//	string GetLoginTitle()												-> get title for login dialog
//	string GetLoginDesc()												-> get desc for login dialog
//	string ServerCheck(string User, string Pass) 						-> server check
//	string ServerLogin(string User, string Pass) 						-> login
//	void ServerLogout() 												-> logout
//	array<dictionary> GetCategorys()									-> get category list
//	array<dictionary> GetUrlList(string Category, string Genre, string PathToken, string Query, string PageToken)	-> get url list for Category

string GetTitle()
{
return "{$CP949=유튜브$}{$CP0=Twitch$}";
}

string GetVersion()
{
	return "1";
}

string GetDesc()
{
	return "https://www.youtube.com/";
}

array<dictionary> GetCategorys()
{
	array<dictionary> ret;
	
	dictionary item1;
	item1["title"] = "{$CP949=가장 인기 많은 영상$}{$CP0=Your Follows$}{$CP950=觀看次數最多/最少$}";
	item1["Category"] = "most";
	ret.insertLast(item1);
	
	dictionary item2;
	item2["title"] = "{$CP949=검색$}{$CP0=search$}{$CP950=搜尋$}";
	item2["type"] = "search";
	item2["Category"] = "search";
	ret.insertLast(item2);
	
	return ret;
}

array<dictionary> GetUrlList(string Category, string Genre, string PathToken, string Query, string PageToken)
{
	string loginFromFile = HostFileRead(HostFileOpen("Extention\\Media\\PlayParse\\TwitchLogin.txt"), 500);
	array<dictionary> ret;
	string api;
	
	if (Category == "search") api = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=50&type=video&q=" + HostUrlEncode(Query);
	else
	{
		string ctry = HostIso3166CtryName();
		
		api = "https://www.googleapis.com/youtube/v3/videos?part=snippet&chart=mostPopular&maxResults=50&regionCode=" + ctry;
	}
	if (!PageToken.empty())
	{
		api = api + "&pageToken=" + PageToken;
		PageToken = "";
	}	

	string getNameOfID = "https://api.twitch.tv/helix/users?";
	string idOfChannel = "";
	string header = "Client-ID: 1dviqtp3q3aq68tyvj116mezs3zfdml";

	string jsonOfYou = HostUrlGetString(getNameOfID + "login=" + loginFromFile, "", header);
	// HostPrintUTF8(jsonOfUser);

	JsonReader TwitchYouReader;
	JsonValue TwitchYouRoot;

	if (TwitchYouReader.parse(jsonOfYou, TwitchYouRoot) && TwitchYouRoot.isObject()) {
		idOfChannel = TwitchYouRoot["data"][0]["id"].asString();
	}

	
	api = "https://api.twitch.tv/helix/users/follows?first=100&from_id=" + idOfChannel;
	
	HostOpenConsole();

	string json = HostUrlGetString(api, "", header);
	// HostPrintUTF8(json);

	JsonReader TwitchReader;
	JsonValue TwitchRoot;

	string allFollowersNick = "";


	if (TwitchReader.parse(json, TwitchRoot) && TwitchRoot.isObject()) {
		JsonValue items = TwitchRoot["data"];

		string str = "";

		if (items.isArray()) {
			for (int i = 0, len = items.size(); i < len; i++) {
				JsonValue item = items[i]["to_id"];
				str += "id=" + item.asString() + "&";

				// JsonReader TwitchNameReader;
				// JsonValue TwitchNameRoot;

				// string jsonOfUser = HostUrlGetString(getNameOfID + item.asString(), "", header);
				// HostPrintUTF8(jsonOfUser);
				// if (TwitchNameReader.parse(jsonOfUser, TwitchNameRoot) && TwitchNameRoot.isObject()) {
				// 	JsonValue itemName = TwitchRoot["data"][0]["login"];
				// 	HostPrintUTF8(itemName.asString());
				// }

			}

			string jsonOfUser = HostUrlGetString(getNameOfID + str, "", header);
			// HostPrintUTF8(jsonOfUser);

			JsonReader TwitchNameReader;
			JsonValue TwitchNameRoot;

			if (TwitchNameReader.parse(jsonOfUser, TwitchNameRoot) && TwitchNameRoot.isObject()) {
				JsonValue itemsName = TwitchNameRoot["data"];
				// HostPrintUTF8(itemsName.asString());
				if (itemsName.isArray()) {
					for (int k = 0, lenNames = itemsName.size(); k < lenNames; k++) {
						string login = itemsName[k]["login"].asString();
						// HostPrintUTF8(login);

						allFollowersNick += login + ",";

						// dictionary heh;
						// heh["url"] = "https://twitch.tv/" + login;
						// heh["title"] = login;
						// ret.insertLast(heh);
					}
				}
			}

			string jsonOfUserOnline = HostUrlGetString("https://api.twitch.tv/kraken/streams?channel=" + allFollowersNick, "", header);
			// HostPrintUTF8(jsonOfUser);

			JsonReader TwitchOnlineReader;
			JsonValue TwitchOnlineRoot;

			if (TwitchOnlineReader.parse(jsonOfUserOnline, TwitchOnlineRoot) && TwitchOnlineRoot.isObject()) {
				JsonValue itemsName = TwitchOnlineRoot["streams"];
				// HostPrintUTF8(itemsName.asString());
				if (itemsName.isArray()) {
					for (int k = 0, lenNames = itemsName.size(); k < lenNames; k++) {
						bool isPlaylist = itemsName[k]["is_playlist"].asBool();
						string display_name = itemsName[k]["channel"]["display_name"].asString();
						string login = itemsName[k]["channel"]["name"].asString();
						string title = itemsName[k]["channel"]["status"].asString();
						HostPrintUTF8(login);

						if (isPlaylist) {
							title += "[VOD] ";
						}

						dictionary heh;
						heh["url"] = "https://twitch.tv/" + login;
						heh["title"] = title;
						ret.insertLast(heh);
					}
				}
			}
		}
		// HostPrintUTF8(TwitchRoot["total"].asString());
	}

	return ret;
}
