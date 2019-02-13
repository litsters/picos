ruleset temperature_store {
	meta {
		name "Wovyn Base"
		description <<
A ruleset for tracking temperatures
>>
		author "Sam Litster"
		logging on

		shares temperatures, threshold_violations
	}

	global {
		temperatures = function(){
			ent:temps.defaultsTo([])
		}

		timestamps = function(){
			ent:times.defaultsTo([])
		}

		threshold_violations = function(){
			ent:violation_temps.defaultsTo([])
		}

		violation_times = function(){
			ent:violation_times.defaultsTo([])
		}
	}

	rule collect_temperatures {
		select when wovyn new_temperature_reading
		pre {
			temperature = event:attr("temperature")
			timestamp = event:attr("timestamp")
		}
		send_directive("collecting temperature")
		always {
			ent:temps := temperatures().append([temperature]);
			ent:times := timestamps().append([timestamp]);
		}
	}

	rule collect_threshold_violations {
		select when wovyn threshold_violation
		pre {
			temperature = event:attr("temperature")
			timestamp = event:attr("timestamp")
		}
		send_directive("collecting threshold violation")
		always {
			ent:violation_temps := threshold_violations().append([{"temperature": temperature}]);
			ent:violation_temps.klog();
			ent:violation_times := violation_times().append([timestamp]);
		}
	}

	rule clear_temperatures {
		select when sensor reading_reset
		send_directive("clear_temp", {"arrived": "true"})
	}
}
