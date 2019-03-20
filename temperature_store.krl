ruleset temperature_store {
	meta {
		name "Temperature Store"
		description <<
A ruleset for tracking temperatures
>>
		author "Sam Litster"
		logging on

		use module io.picolabs.wrangler alias Wrangler
		use module io.picolabs.subscription alias Subscription

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

	rule temperatures_requested {
		select when sensor report_temps where (event:attr("report_id") && event:attr("originator"))
		foreach Subscription:established("Tx_role", "controller") setting (value, key)
			pre {
				report_id = event:attr("report_id").klog("id=")
				originator = event:attr("originator").klog("originator=")
				controller_eci = value{"Tx"}.klog("controller eci = ")
				source = value{"Rx"}.klog("source=")
				host = value{"Tx_host"}.klog("tx_host=")
				temps = temperatures().klog("temps=")
				event = {
					"eci": originator,
					"eid": "report",
					"domain": "sensor",
					"type": "temps_reported",
					"attrs": {
						"report_id": report_id,
						"temps": temps,
						"source": source
					}
				}
			}
			if originator == controller_eci then event:send(event, host)
	}
}
