ruleset wovyn_base {
	meta {
		name "Wovyn Base"
		description <<
A first ruleset for the Wovyn sensor
>>
		author "Sam Litster"
		logging on

    use module io.picolabs.lesson_keys
    use module io.picolabs.twilio_v2 alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}

		use module sensor_profile alias profile
	}

	global {
		phone_number_from = "+14358506613"

		message = function(temp){
			msg = "Temperature violation: " + temp;
			msg
		}
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
			temperature_threshold = profile:getThreshold()
			notice = (event:attr("temperature") > temperature_threshold) => "A temperature violation occurred." | "No violation."
			
		}
		send_directive("high_temp", { "threshold": temperature_threshold })
		always {
			raise wovyn event "threshold_violation" attributes event:attrs if event:attr("temperature") > temperature_threshold
		}
	}

	rule threshold_notification {
		select when wovyn threshold_violation
		pre {
			never_used = event:attrs.klog("attrs")
			message = message(event:attr("temperature"))
		}
		twilio:send_sms(profile:getContact(),
                    phone_number_from,
                    message
                   )
	}
}
