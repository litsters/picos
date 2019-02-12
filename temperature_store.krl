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
	}

	rule collect_threshold_violations {
		select when wovyn threshold_violation
	}

	rule clear_temperatures {
		select when sensor reading_reset
	}
}
