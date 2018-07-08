/*
	GoodGame media parse
*/	

//	string GetTitle() 									-> get title for UI
//	string GetVersion									-> get version for manage
//	string GetDesc()									-> get detail information
//	string GetLoginTitle()								-> get title for login dialog
//	string GetLoginDesc()								-> get desc for login dialog
//	string ServerCheck(string User, string Pass) 		-> server check
//	string ServerLogin(string User, string Pass) 		-> login
//	void ServerLogout() 								-> logout
// 	bool PlayitemCheck(const string &in)				-> check playitem
//	array<dictionary> PlayitemParse(const string &in)	-> parse playitem
// 	bool PlaylistCheck(const string &in)				-> check playlist
//	array<dictionary> PlaylistParse(const string &in)	-> parse playlist

string GetTitle() {
	return "GoodGame";
}

string GetVersion() {
	return "1";
}

string GetDesc() {
	return "https://goodgame.ru/";
}

class QualityListItem {
	string url;
	string quality;
	string qualityDetail;
	string resolution;
	string bitrate;
	string format;
	int itag = 0;
	double fps = 0.0;
	int type3D = 0; // 1:sbs, 2:t&b
	bool is360 = false;

	dictionary toDictionary() {
		dictionary ret;
		
		ret["url"] = url;
		ret["quality"] = quality;
		ret["qualityDetail"] = qualityDetail;
		ret["resolution"] = resolution;
		ret["bitrate"] = bitrate;
		ret["format"] = format;
		ret["itag"] = itag;
		ret["fps"] = fps;
		ret["type3D"] = type3D;
		ret["is360"] = is360;
		return ret;
	}	
};

bool PlayitemCheck(const string &in path) {
	if (path.find("://goodgame.ru/channel") >= 0) {
		return true;
	}
	return false;
}

string PlayitemParse(const string &in path, dictionary &MetaData, array<dictionary> &QualityList) {
	// HostOpenConsole();

	//Some vars for quality adding.
	array<string> qualities = {"", "_720", "_480", "_240"};
	array<string> qualitiesStr = {"Source", "720p", "480p", "240p"};
	string oldApi = "http://hls.goodgame.ru/hls/";
	string newApi = "https://cdnnow.goodgame.ru/hls/";
	bool isOldApi = false;

	string nickname = HostRegExpParse(path, "https://goodgame.ru/channel/([-a-zA-Z0-9_]+)");
	HostPrintUTF8(nickname);

	string statusApi = "https://goodgame.ru/api/getchannelstatus?fmt=json&id=" + nickname;
	HostPrintUTF8(statusApi);
	string jsonStatus = HostUrlGetString(statusApi, "", "");

	string titleChannel;
	string channelId;
	string playerSrc;
	string isPremium = "";

	//Some tricks to remove useless root node.
	jsonStatus.replace("}}", "}");
	jsonStatus = jsonStatus.substr(jsonStatus.find(":{") + 1, 10000);
	// HostPrintUTF8(jsonStatus);

	JsonReader ChannelReader;
	JsonValue ChannelRoot;
	if (ChannelReader.parse(jsonStatus, ChannelRoot) && ChannelRoot.isObject()) {

		titleChannel = ChannelRoot["title"].asString();
		playerSrc = ChannelRoot["embed"].asString();
		isPremium = ChannelRoot["premium"].asString();
		channelId = HostRegExpParse(playerSrc, "player\\?([-a-zA-Z0-9_]+)");
		
		HostPrintUTF8(playerSrc);
		HostPrintUTF8(channelId);
	}

	HostPrintUTF8(titleChannel);
	// string m3u8Api = "http://hls.goodgame.ru/hls/" + channelId + ".m3u8";
	string m3u8Api = newApi + channelId + ".m3u8";
	HostPrintUTF8(m3u8Api);
	MetaData["title"] = titleChannel;
	MetaData["content"] = titleChannel;

		
	//Add 4 + 4 qualitites. 
	//New API is pretty fast, but for some reasons is laggy.
	//Old API is pretty slow, but works well. Dunno.
	if (@QualityList !is null) {
		for (int k = 0; k < 4; k++) {
			string currentApi = newApi;
			string currentQuality = qualities[k];
			QualityListItem qualityItem;
			qualityItem.itag = k;
			qualityItem.quality = qualitiesStr[k];
			qualityItem.qualityDetail = qualitiesStr[k];
			if (isOldApi) {
				currentApi = oldApi;
				qualityItem.itag = k + 4;
				qualityItem.qualityDetail += " old API";
			}
			qualityItem.url = currentApi + channelId + currentQuality + ".m3u8";
			QualityList.insertLast(qualityItem.toDictionary());

			//If the channel is not premium, the quality selection is not available.
			//So leave only the source quality of the old API.
			if (isPremium != "true") {
				if (isOldApi) {
					return m3u8Api;
				} else {
					k = -1;
					isOldApi = true;
				}
			}
			///////////

			if (k >= 3 && !isOldApi) {
				k = -1;
				isOldApi = true;
			}
		}
	}

	return m3u8Api;
}