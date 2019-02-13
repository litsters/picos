ruleset temperature_store {
	meta {
		name "Wovyn Base"
		description <<
A ruleset for tracking temperatures
>>
		author "Sam Litster"
		logging on

		shares temperatures
	}

	global {
		temperatures = function(){
			ent:temps.defaultsTo([])
		}
	}

	rule collect_temperatures {
		select when wovyn new_temperature_reading
		pre {
			never_used = event:attrs.klog("attrs")
			temperature = event:attr("temperature")
			timestamp = event:attr("timestamp")
		}
		send_directive("collecting temperature")
		always {
			ent:temps := temperatures().append([temperature]);
			ent:temps.klog();
			ent:times := ent:times.defaultsTo([]).append([timestamp]);
		}
	}

	rule collect_threshold_violations {
		select when wovyn threshold_violation
		send_directive("collect_viol", {"arrived": "true"})
	}

	rule clear_temperatures {
		select when sensor reading_reset
		send_directive("clear_temp", {"arrived": "true"})
	}
}
