ruleset hello_world {
	meta {
		name "Hello World"
		description <<
A first ruleset for the Quickstart
>>
		author "Phil Windley"
		logging on
		shares hello
	}

	global {
		hello = function(obj) {
			msg = "Hello " + obj;
			msg
		}
	}

	rule hello_world {
		select when echo hello
		send_directive("say", { "something": "Hello World"})
	}

	rule monkey {
		select when echo monkey
		pre {
			//text = event:attr("name").defaultsTo("Monkey").klog(text)
			text = (event:attr("name")) => event:attr("name") | "Monkey"
			message = hello(text)
		}
		send_directive(message)
	}
}
