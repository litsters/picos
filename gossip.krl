ruleset gossip {
	meta {
		name "Gossip"
		description <<
A ruleset for gossiping
>>
		author "Sam Litster"
		logging on

		use module io.picolabs.subscription alias Subscription
	}

	global {
		getHeartbeatFrequency = function(){
			ent:frequency.defaultsTo(0)
		}

		getIndex = function(){
			ent:index.defaultsTo(-1)
		}

		getNeighborKnowledge = function(){
			ent:neighbor_knowledge.defaultsTo({})
		}

		getRumors = function(){
			ent:rumors.defaultsTo({})
		}

		getRumorsForNode = function(picoID){
			rumors = getRumors(){picoID}.defaultsTo({});
			rumors
		}

		generateNextMessageID = function(){
			id = meta:picoId;
			number = getIndex() + 1;
			messageID = id + ":" + number;
			messageID
		}

		parseIndexFromId = function(messageID){
			length = messageID.length();
			id = messageID.substr(length - 1, -1);
			id
		}

		missingRumors = function(neighbor){
			neighbor_knowledge = getNeighborKnowledge(){neighbor}.klog("neighbor knowledge=");
			missing_rumors = getRumors().map(function(rumors,picoID){
				pico_seen = neighbor_knowledg >< picoID;
				last_seen = neighbor_knowledge{picoID};
				unknown_rumors = rumors.filter(function(message,messageID){
					index = parseIndexFromId(messageID);
					unknown = (not pico_seen || index > last_seen);
					unknown
				});
				unknown_rumors
			}).filter(function(missing_rumors,picoID){
				missing_rumors.keys().length() > 0
			});
			missing_rumors
		}

		unknownRumors = function(picoID, givenRumors){
			knownRumors = getRumorsForNode(picoID);
			neededRumors = (knownRumors.keys().length() == 0) => givenRumors | givenRumors.filter(function(message,messageID){
				known = knownRumors >< messageID;
				needed = not known;
				needed
			});
			neededRumors
		}

		determineLastSeen = function(picoID){
			last_seen = getRumorsForNode(picoID).map(function(message,messageID){
				index = parseIndexFromId(messageID);
				index
			}).values().sort("numeric").reduce(function(highest_sequence,index){
				next_in_sequence = highest_sequence + 1;
				next_highest = (index == next_in_sequence) => index | highest_sequence;
				next_highest
			}, -1);
			last_seen
		}

		generateSeen = function(){
			seen_report = getRumors().map(function(rumors,picoID){
				last_seen = determineLastSeen(picoID);
				last_seen
			});
			seen_report
		}

		selectPeer = function(helpMap){
			needHelp = helpMap.filter(function(needed_rumors,neighbor){
				count_rumors_needed = needed_rumors.map(function(rumors,picoID){
					rumors.keys().length()
				}).values().reduce(function(total,count){
					total + count
				},0);
				count_rumors_needed > 0
			});
			num_peers = help_map.keys().length().klog("num peers=" + num_peers);
			chosen_index = random:integer(num_peers - 1).klog("chosen index=" + chosen_index);
			chosen_peer = (num_peers > 0) => help_map.keys()[chosen_index].klog("chosen peer=" + chosen_peer) | randomPeer();
			chosen_peer
		}

		randomPeer = function(){
			neighbors = getNeighborKnowledge().keys().klog("neighbors=");
			chosen_index = random:integer(neighbors.length() - 1).klog("random neighbor index=");
			chosen = neighbors[chosen_index].klog("random neighbor=");
			chosen
		}

		getPeer = function(){
			help_map = getNeighborKnowledge().map(function(neighbor_knowledge,neighbor){
				missingRumors = missingRumors(neighbor);
				missingRumors
			}).klog("helpmap=");
			peer = (help_map.keys().length() > 0) => selectPeer(help_map).klog("selected peer=") | randomPeer();
			peer
		}

		prepareMessage = function(peer){
			choice = random:integer(1);
			message = (choice < 1) => prepareRumorMessage(peer) | prepareSeenMessage(peer);
			message
		}

		prepareRumorMessage = function(peer){
			needed_rumors = missingRumors(peer).klog("needed rumors=");
			message = {
				"domain": "gossip",
				"type": "rumor",
				"eci": peer,
				"eid": "prop",
				"attrs": {
					"rumors": needed_rumors
				}
			};
			message
		}

		prepareSeenMessage = function(peer){
			message = {
				"domain": "gossip",
				"type": "seen",
				"eci": peer,
				"eid": "prop",
				"attrs": {
					"last_seen": generateSeen()
				}
			};
			message
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
			ent:frequency := frequency;
			raise gossip event "initialize"
		}
	}

	rule initialize_neighbor_knowledge {
		select when gossip initialize
		foreach Subscription:established("Tx_role", "role") setting (value, key)
			pre {
				node = value{"Tx"}.klog("tx=")
				exists = (getNeighborKnowledge() >< node)
				shouldCreate = not exists
			}
			if shouldCreate then
				send_directive("initializing neighbor knowledge")
			fired {
				ent:neighbor_knowledge := getNeighborKnowledge().put(node, {});
			} finally {
				schedule gossip event "heartbeat" at time:add(time:now(), {"seconds": frequency}) on final;
			}
	}

	rule process_heartbeat {
		select when gossip heartbeat
		pre {
			frequency = getHeartbeatFrequency()
			peer = getPeer()
			message = prepareMessage(peer).klog("heartbeat message=")
		}
		if frequency > 0 then
			event:send(message)
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

	rule process_seen {
		select when gossip seen where getHeartbeatFrequency() > 0
		foreach event:attr("last_seen") setting (last_seen_rumor,picoID)
			pre {
				neighbor = meta:eci.klog("neighbor=")
			}
			send_directive("updating seen rumors for neighbor " + neighbor)
			always {
				ent:neighbor_knowledge := getNeighborKnowledge(){neighbor}.put(picoID, last_seen_rumor);
				raise gossip event "seen_updated" attributes { "neighbor": neighbor } on final;
			}
	}

	rule respond_to_seen {
		select when gossip seen_updated
		pre {
			neighbor = event:attr("neighbor")
			missing_rumors = missingRumors(neighbor)
			should_fire = (missing_rumors.keys().length() > 0)
		}
		if should_fire then
			send_directive("responding to neighbor with missing rumors")
		fired {
			message = {
				"eci": neighbor,
				"eid": "response",
				"domain": "gossip",
				"type": "rumor",
				"attrs": {
					"rumors": missing_rumors
				}
			};
			event:send(message);
		}
	}

	rule process_rumors {
		select when gossip rumor where getHeartbeatFrequency() > 0
		foreach event:attr("rumors") setting (rumors,picoID)
			foreach rumors setting (message,messageID)
				pre {
					pico_seen = getRumorsForNode(picoID).keys().length() > 0
				}
				if pico_seen then
					noop()
				fired {
					ent:rumors := getRumors(){picoID}.put(messageID, message);
				} else {
					ent:rumors := getRumors().put(picoID, rumors);
				} 
	}

	rule new_temp {
		select when wovyn new_temperature_reading
		pre {
			temperature = event:attr("temperature")
			timestamp = event:attr("timestamp")
			sensorID = meta:picoId
			messageID = generateNextMessageID()
			rumor = {
				"temperature": temperature,
				"timestamp": timestamp,
				"sensorID": sensorID,
				"messageID": messageID
			}
		}
		send_directive("new temperature reading")
		always {
			ent:rumors := getRumors(){sensorID}.put(messageID, rumor).klog("rumors=");
		}
	}
}
