/*
	media url search by twitch follows of username
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

string GetTitle() {
	return "{$CP0=Twitch$}";
}

string GetVersion() {
	return "1";
}

string GetDesc() {
	return "Twitch";
}

array<dictionary> GetCategorys() {
	array<dictionary> ret;
	
	dictionary item1;
	item1["title"] = "{$CP1251=подписки онлайн$}{$CP0=Your Follows$}";
	item1["Category"] = "most";
	ret.insertLast(item1);
	return ret;
}

array<dictionary> GetChunkOfUsersOnline(string allFollowersNick, string header) {
	array<dictionary> ret;
	// Get channels which is online right now.
	string jsonOfUserOnline = HostUrlGetString("https://api.twitch.tv/kraken/streams?channel=" + allFollowersNick, "", header);

	// HostPrintUTF8(jsonOfYou);
	// HostPrintUTF8(jsonOfNicknames);
	HostPrintUTF8(jsonOfUserOnline);

	// Read json of online channels.
	JsonReader TwitchOnlineReader;
	JsonValue TwitchOnlineRoot;
	if (TwitchOnlineReader.parse(jsonOfUserOnline, TwitchOnlineRoot) && TwitchOnlineRoot.isObject()) {
		JsonValue itemsName = TwitchOnlineRoot["streams"];
		if (itemsName.isArray()) {
			//Set every online channel in list of urls.
			for (int k = 0, lenNames = itemsName.size(); k < lenNames; k++) {
				bool isPlaylist = itemsName[k]["is_playlist"].asBool();
				string viewers = itemsName[k]["viewers"].asString();
				string display_name = itemsName[k]["channel"]["display_name"].asString();
				string login = itemsName[k]["channel"]["name"].asString();
				string title = itemsName[k]["channel"]["status"].asString();
				HostPrintUTF8(login);

				//If channel plays VOD add that string.
				if (isPlaylist) {
					title = "[VOD] " + title;
				}

				title += " (" + viewers + ")";

				dictionary objectOfChannel;
				objectOfChannel["url"] = "https://twitch.tv/" + login;
				objectOfChannel["title"] = title;
				ret.insertLast(objectOfChannel);
			}
		}
	}

	return ret;
}

array<dictionary> GetUrlList(string Category, string Genre, string PathToken, string Query, string PageToken) {
	HostOpenConsole();
	string loginFromFile = HostFileRead(HostFileOpen("Extention\\Media\\UrlList\\TwitchLogin.txt"), 500);
	array<dictionary> ret;
	string api;
	
	string getNameOfID = "https://api.twitch.tv/helix/users?";
	string idOfChannel = "";
	string header = "Client-ID: 1dviqtp3q3aq68tyvj116mezs3zfdml";

	// Get user id of twitch through username.
	string jsonOfYou = HostUrlGetString(getNameOfID + "login=" + loginFromFile, "", header);
	JsonReader TwitchYouReader;
	JsonValue TwitchYouRoot;
	if (TwitchYouReader.parse(jsonOfYou, TwitchYouRoot) && TwitchYouRoot.isObject()) {
		idOfChannel = TwitchYouRoot["data"][0]["id"].asString();
	}

	// Get list of id of channel that user follows.
	// API can get 100 user maximum. 
	// TODO: increase number of channels via cursors, that gives in json.
	api = "https://api.twitch.tv/helix/users/follows?first=100&from_id=" + idOfChannel;
	string json = HostUrlGetString(api, "", header);

	JsonReader TwitchReader;
	JsonValue TwitchRoot;

	if (TwitchReader.parse(json, TwitchRoot) && TwitchRoot.isObject()) {
		JsonValue items = TwitchRoot["data"];
		string parameters = "";

		if (items.isArray()) {
			// Read every ID in list to set them in parameters.
			for (int i = 0, len = items.size(); i < len; i++) {
				JsonValue item = items[i]["to_id"];
				parameters += "id=" + item.asString() + "&";
			}

			// It should be channel1,channel2,channel3...
			string allFollowersNick = "";
			string jsonOfNicknames = HostUrlGetString(getNameOfID + parameters, "", header);

			// Read every nickname and insert them in single string.
			JsonReader TwitchNamesReader;
			JsonValue TwitchNamesRoot;
			if (TwitchNamesReader.parse(jsonOfNicknames, TwitchNamesRoot) && TwitchNamesRoot.isObject()) {
				JsonValue itemsName = TwitchNamesRoot["data"];
				if (itemsName.isArray()) {
					for (int k = 0, lenNames = itemsName.size(); k < lenNames; k++) {
						string login = itemsName[k]["login"].asString();
						allFollowersNick += login + ",";
						// Divide every request by 25 usernames.
						if (k % 25 == 0 || k == lenNames - 1) {
							ret.insertAt(0, GetChunkOfUsersOnline(allFollowersNick, header));
							allFollowersNick = "";
						}
					}
				}
			}

			
		}
	}

	return ret;
}
