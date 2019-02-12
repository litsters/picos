ruleset temperature_store {
	meta {
		name "Wovyn Base"
		description <<
A ruleset for tracking temperatures
>>
		author "Sam Litster"
		logging on
	}

	global {

	}

	rule collect_temperatures {
		select when wovyn new_temperature_reading
		send_directive("collect_temp", {"arrived": "true"})
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
