ruleset gossip {
	meta {
		name "Gossip"
		description <<
A ruleset for gossiping
>>
		author "Sam Litster"
		logging on
	}

	global {
		getHeartbeatFrequency = function(){
			ent:frequency.defaultsTo(0)
		}

		getIndex = function(){
			ent:index.defaultsTo(-1)
		}
	}

	rule start_gossip {
		select when gossip start where event:attr("frequency")
		pre {
			frequency = event:attr("frequency").klog("frequency=")
		}
		if frequency > 0 then
			send_directive("starting gossip")
		fired {
			schedule gossip event "heartbeat" at time:add(time:now(), {"seconds": frequency});
			ent:frequency := frequency;
		}
	}

	rule process_heartbeat {
		select when gossip heartbeat
		pre {
			frequency = getHeartbeatFrequency()
		}
		if frequency > 0 then
			send_directive("processing gossip heartbeat")
		fired {
			schedule gossip event "heartbeat" at time:add(time:now(), {"seconds": frequency});
		}
	}

	rule stop_gossip {
		select when gossip stop
		pre {

		}
		send_directive("stopping gossip")
		always {
			ent:frequency := 0;
		}
	}
}
