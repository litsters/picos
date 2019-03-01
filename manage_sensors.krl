ruleset manage_sensors {
	meta {
		name "Manage Sensors"
		description <<
A ruleset for managing a collection of sensors
>>
		author "Sam Litster"
		logging on
	}

	global {
		defaultThreshold = 75
		picoName = function(name) {
			"Sensor " + name + " Pico"
		}
		defaultProfile = function(name) {
			profile = {"name":name, "location":"Wymount", "threshold":defaultThreshold, "contact": "+14352419394"};
			profile
		}
	}

	rule sensor_already_exists {
		select when sensor new_sensor
		pre {
			name = event:attr("name")
			exists = ent:sensors >< name
		}
		if exists then
			send_directive("sensor_ready", {"name": name})
	}

	rule sensor_needed {
		select when sensor new_sensor
		pre {
			name = event:attr("name")
			exists = ent:sensors >< name
		}
		if not exists
		then
			noop()
		fired {
			raise wrangler event "child_creation"
				attributes { "name": picoName(name),
										 "color": "#f442eb",
										 "profile": defaultProfile(name)}
		}
	}

	rule store_new_sensor {
		select when wrangler child_initialized
		pre {
			the_sensor = {"id": event:attr("id"), "eci": event:attr("eci")}
			sensor_name = event:attr("rs_attrs"){"profile"}{"name"}
		}
		if sensor_name.klog("found sensor_name")
		then
			event:send(
				{ "eci": the_sensor{"eci"}, "eid": "install-ruleset",
					"domain": "wrangler", "type": "install_rulesets_requested",
					"attrs": {"rids": "io.picolabs.lesson_keys;io.picolabs.twilio_v2;temperature_store;wovyn_base;sensor_profile"} } )
		fired {
			ent:sections := ent:sections.defaultsTo({});
			ent:sections{[sensor_name]} := the_sensor
		}
	}

	rule on_rules_installed {
		select when wrangler ruleset_added
		pre {
			never_used = event.attrs().klog()
		}
	}
}
