ruleset manage_sensors {
	meta {
		name "Manage Sensors"
		description <<
A ruleset for managing a collection of sensors
>>
		author "Sam Litster"
		logging on

		use module io.picolabs.wrangler alias Wrangler
		use module io.picolabs.subscription alias Subscription

		shares sensors, collect_temperatures, all_reports
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

		collect_temperatures = function(){
			collected_temps = Subscription:established("Tx_role", "sensor").map(function(value,key){
				
				eci = value{"Tx"}.klog("tx=");
				host = value{"Tx_host"}.klog("host=");
				temps = Wrangler:skyQuery(eci, "temperature_store", "temperatures", {}, host);
				temps
			});

			collected_temps
		}

		all_reports = function(){
			reports = ent:reports.defaultsTo({});
			reports
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
			wellknown = Wrangler:skyQuery(event:attr("eci"), "wovyn_base", "wellKnown", {}).klog("wellknown = ");
		}
		if sensor_name.klog("found sensor_name")
		then
			event:send(
				{ "eci": the_sensor{"eci"}, "eid": "initialize-sensor",
					"domain": "sensor", "type": "profile_updated",
					"attrs": {"location": profile.location, "name": profile.name, "threshold": profile.threshold, "contact": profile.contact } } )
		fired {
			ent:sensors := ent:sensors.defaultsTo({});
			ent:sensors{[sensor_name]} := the_sensor;

			raise wrangler event "subscription" attributes 
				{
					"name": sensor_name,
					"Rx_role": "controller",
					"Tx_role": "sensor",
					"channel_type": "subscription",
					"wellKnown_Tx": wellknown,
					"Tx_host": "http://localhost:8080"
				}
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

	rule introduce_sensor {
		select when sensor introduction where (event:attr("wellknown") && event:attr("host") && event:attr("name"))
		pre {
			wellknown = event:attr("wellknown")
			name = event:attr("name")
			host = event:attr("host")
		}
		send_directive("introducing sensor")
		always {
			raise wrangler event "subscription" attributes 
				{
					"name": name,
					"Rx_role": "controller",
					"Tx_role": "sensor",
					"channel_type": "subscription",
					"wellKnown_Tx": wellknown,
					"Tx_host": host
				}
		}
	}

	rule report_requested {
		select when manager new_report
		foreach Subscription:established("Tx_role", "sensor") setting (value, key)
			pre {
				report_id = ent:report_counter.defaultsTo(0)
				channel = value{"Rx"}.klog("channel=")
				target_eci = value{"Tx"}.klog("tx=")
				host = value{"Tx_host"}.klog("host=")
				sensor_count = Subscription:established("Tx_role", "sensor").keys().length()
				event = {
					"eci": target_eci,
					"eid": "report",
					"domain": "sensor",
					"type": "report_temps",
					"attrs": {
						"report_id": report_id,
						"originator": channel
					}
				}
			}
			event:send(event, host)
			fired {
				ent:report_counter := ent:report_counter.defaultsTo(0) + 1 on final;
				ent:reports := all_reports().put(report_id, {"sensor_count": sensor_count, "num_reported": 0, "reports":{}}) on final;
			}
	}

	rule temps_reported {
		select when sensor temps_reported where (event:attr("report_id") && event:attr("temps") && event:attr("source"))
		pre {
			id = event:attr("report_id")
			num_reported = ent:reports{id}{"num_reported"} + 1
			reports = ent:reports{id}{"reports"}.put(event:attr("source"), event:attr("temps"))
			sensor_count = ent:reports{id}{"sensor_count"}
		}
		send_directive("updating report " + event:attr("report_id"))
		always {
			ent:reports := all_reports().put(event:attr("report_id"), {"sensor_count": sensor_count, "num_reported": num_reported, "reports": reports});
		}
	}

	rule clear_reports {
		select when manager clear_reports
		send_directive("clearing reports")
		always {
			ent:report_counter := 0;
			ent:reports := {};
		}
	}

}
