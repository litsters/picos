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

	}

	rule process_heartbeat {
		select when wovyn heartbeat
		pre {
			never_used = event:attrs.klog("attrs")
		}
		send_directive("say", { "heartbeat": "hello world" })
	}
}
