ruleset sensor_profile {
	meta {
		name "Sensor Profile"
		description <<
A ruleset for managing the sensor profile
>>
		author "Sam Litster"
		logging on
	}

	global {

	}

	rule profile_updated {
		select when sensor profile_updated where (event:attr("location") && event:attr("name"))
		pre {
			never_used = event:attrs.klog("attrs")
		}
		send_directive("profile updated")
	}
}
