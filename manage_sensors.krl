ruleset manage_sensors {
	meta {
		name "Manage Sensors"
		description <<
A ruleset for managing a collection of sensors
>>
		author "Sam Litster"
		logging on

		shares sensors
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

		sensors = function() {
			senserz = ent:sensors.defaultsTo({});
			senserz
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
										 "profile": defaultProfile(name),
										 "rids": "io.picolabs.lesson_keys;io.picolabs.twilio_v2;temperature_store;wovyn_base;sensor_profile"}
		}
	}

	rule store_new_sensor {
		select when wrangler child_initialized
		pre {
			the_sensor = {"id": event:attr("id"), "eci": event:attr("eci")}
			sensor_name = event:attr("rs_attrs"){"profile"}{"name"}
			profile = event:attr("rs_attrs"){"profile"}
		}
		if sensor_name.klog("found sensor_name")
		then
			event:send(
				{ "eci": the_sensor{"eci"}, "eid": "initialize-sensor",
					"domain": "sensor", "type": "profile_updated",
					"attrs": {"location": profile.location, "name": profile.name, "threshold": profile.threshold, "contact": profile.contact } } )
		fired {
			ent:sensors := ent:sensors.defaultsTo({});
			ent:sensors{[sensor_name]} := the_sensor
		}
	}

	rule sensor_offline {
		select when sensor unneeded_sensor
		pre {
			sensor_name = event:attr("name")
			exists = ent:sensors >< sensor_name
			child_to_delete = picoName(sensor_name)
		}
		if exists then
			send_directive("deleting sensor", {"name": sensor_name})
		fired {
			raise wrangler event "child_deletion"
				attributes {"name": child_to_delete};
			clear ent:sensors{[sensor_name]}
		}
	}

	rule clear_sensors {
		select when sensor empty
		always {
			ent:sensors := {}
		}
	}

}
