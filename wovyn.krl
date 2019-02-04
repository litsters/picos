ruleset wovyn_base {
	meta {
		name "Wovyn Base"
		description <<
A first ruleset for the Wovyn sensor
>>
		author "Sam Litster"
		logging on

	}

	global {
		temperature_threshold = 75
	}

	rule process_heartbeat {
		select when wovyn heartbeat
		pre {
			never_used = event:attrs.klog("attrs")
		}
		if event:attr("genericThing") then
			send_directive("say", { "heartbeat": "hello world" })
		fired {
			raise wovyn event "new_temperature_reading" attributes {
				"temperature" : event:attrs.genericThing.data.temperature[0].temperatureF ,
				"timestamp" : time:now()
			}
		} else {

		}
	}

	rule find_high_temps {
		select when wovyn new_temperature_reading
		pre {
			never_used = event:attrs.klog("attrs")
		}
		if event:attr("temperature") > temperature_threshold then
			send_directive("find", { "find_temps": "found" })
	}
}
