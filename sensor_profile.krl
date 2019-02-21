ruleset sensor_profile {
	meta {
		name "Sensor Profile"
		description <<
A ruleset for managing the sensor profile
>>
		author "Sam Litster"
		logging on

		shares getProfile, getThreshold
		provides getThreshold
	}

	global {
		getProfile = function(){
			profile = ent:profile.defaultsTo({"location": "Wymount", "name": "Sam", "threshold": 65, "contact": "+14352419394"});
			profile
		}

		getThreshold = function(){
			threshold = getProfile().get("threshold");
			threshold
		}
	}

	rule profile_updated {
		select when sensor profile_updated where (event:attr("location") && event:attr("name"))
		pre {
			location = event:attr("location")
			name = event:attr("name")
			threshold = (event:attr("threshold")) => event:attr("threshold").as("Number") | getProfile().get("threshold")
			contact = (event:attr("contact")) => event:attr("contact") | getProfile().get("contact")
		}
		send_directive("profile updated")
		always {
			ent:profile := getProfile().put(["location"], location);
			ent:profile := getProfile().put(["name"], name);
			ent:profile := getProfile().put(["threshold"], threshold);
			ent:profile := getProfile().put(["contact"], contact);
		}
	}
}
