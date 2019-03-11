ruleset manager_profile {
	meta {
		name "Manager Profile"
		description <<
A ruleset for sensor manager profiles
>>
		author "Sam Litster"
		logging on

		use module io.picolabs.lesson_keys
    use module io.picolabs.twilio_v2 alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
	}

	global {
		phone_number_from = "+14358506613"

		phone_number_to = function(){
			contact = ent:contact.defaultsTo("+14352419394");
			contact
		}

		message = function(name, temp){
			msg = "Threshold violation from sensor " + sensor + ": " + temp;
			msg
		}
	}

	rule temperature_violation_notification {
		select when manager threshold_violation where (event:attr("temperature")  && event:attr("sensor"))
		pre {
			temp = event:attr("temperature")
			sensor = event:attr("sensor")
			msg = message(sensor, temp)
			contact = phone_number_to()
		}
		twilio:send_sms(contact,
                    phone_number_from,
                    message
                   )
	}
	
}
