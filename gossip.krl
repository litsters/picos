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

		getLog = function(){
			ent:log.defaultsTo({})
		}

		getLogsForPeer = function(peer){
			filtered = getLog().filter(function(value,key){ key == peer});
			filtered
		}

		getSmartTracker = function(){
			ent:smart_tracker.defaultsTo({})
		}

		parseIndexFromId = function(messageID){
			length = messageID.length();
			id = messageID.substr(length - 1, -1);
			id
		}

		getPeer = function(){
			peers_to_help = getSmartTracker().map(function(tracked_info, peer){
				needed_rumors = tracked_info.map(function(last_seen, other_peer){
					known_rumors_for_other_peer = getLogsForPeer(other_peer);
					missing_rumors = known_rumors_for_other_peer.filter(function(message, messageID){
						index = parseIndexFromId(messageID);
						index > last_seen
					});
					missing_rumors
				});
				needed_rumors
			});
			peers_needing_info = peers_to_help.filter(function(needed_rumors,peer){ needed_rumors.keys().length() > 0 });
			num_peers = peers_needing_info.keys().length();
			chosen_index = random:integer(num_peers - 1);
			chosen_peer = peers_needing_info.keys().index(chosen_index);
			ret_val = {"peer": chosen_peer, "needed_rumors": peers_needing_info{chosen_peer}};
			ret_val
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

	rule change_frequency {
		select when gossip update_frequency where event:attr("frequency")
		pre {
			frequency = event:attr("frequency")
		}
		if frequency >= 0 then
			send_directive("updating frequency")
		fired {
			ent:frequency := frequency;
		}
	}
}
