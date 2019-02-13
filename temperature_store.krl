ruleset temperature_store {
	meta {
		name "Temperature Store"
		description <<
A ruleset for tracking temperatures
>>
		author "Sam Litster"
		logging on

		shares temperatures, threshold_violations, inrange_temperatures
		provides temperatures, threshold_violations, inrange_temperatures
	}

	global {
		temperatures = function(){
			ent:temps.defaultsTo([])
		}

		threshold_violations = function(){
			ent:violation_temps.defaultsTo([])
		}

		inrange_temperatures = function(){
			temperatures().filter(function(reading){
				notcontained = threshold_violations().all(function(violation){
					violation.temperature != reading.temperature
				});
				notcontained
			})
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
			ent:temps := temperatures().append([{"temperature": temperature, "timestamp": timestamp}]);
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
			ent:violation_temps := threshold_violations().append([{"temperature": temperature, "timestamp": timestamp}]);
		}
	}

	rule clear_temperatures {
		select when sensor reading_reset
		send_directive("clearing temp data")
		always {
			clear ent:temps;
			clear ent:violation_temps;
		}
	}
}
