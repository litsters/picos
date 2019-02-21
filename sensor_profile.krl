ruleset sensor_profile {
	meta {
		name "Sensor Profile"
		description <<
A ruleset for managing the sensor profile
>>
		author "Sam Litster"
		logging on

		shares getProfile
	}

	global {
		getProfile = function(){
			profile = ent:profile.defaultsTo({"location": "Wymount", "name": "Sam", "threshold": 65, "contact": "+14352419394"});
			profile
		}
	}

	rule profile_updated {
		select when sensor profile_updated where (event:attr("location") && event:attr("name"))
		pre {
			never_used = event:attrs.klog("attrs")
			location = event:attr("location")
			name = event:attr("name")
			threshold = (event:attr("threshold")) => event:attr("threshold") | getProfile().get("threshold")
			contact = (event:attr("contact")) => event:attr("contact") | getProfile.get("contact")
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
