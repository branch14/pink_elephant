#!/usr/bin/ruby

require "xmlrpc/server"

class SwintServer

	def initialize(bot_class, port=11111)
		
		trap("INT") { self.stop }

		@bot_class = bot_class
		@bot_pool = Hash.new
		
		@srv = XMLRPC::Server.new(port)

		@srv.add_handler "start_game" do
			b = Kernel.const_get(@bot_class).new
			@bot_pool[b.hash] = b
			b.hash # gameid
		end
		
		@srv.add_handler "end_game" do |id, msg|
			@bot_pool[id].end_game(msg)
			@bot_pool.delete(id)
			"Another Ruby Victory!"
		end
		
		@srv.add_handler("get_speed") { |id| @bot_pool[id].speed }
		@srv.add_handler("get_sight") { |id| @bot_pool[id].sight }
		@srv.add_handler("get_power") { |id| @bot_pool[id].power }
		@srv.add_handler("get_weight") { |id| @bot_pool[id].weight }
		@srv.add_handler("get_energy") { |id| @bot_pool[id].energy }
		@srv.add_handler("get_name") { |id| @bot_pool[id].name }
		@srv.add_handler("get_owner") { |id| @bot_pool[id].owner }
		
		@srv.add_handler("next") { |id, env| @bot_pool[id].next(env.collect { |e| e.to_sym }).to_s }
		@srv.add_handler("move") { |id| @bot_pool[id].move.to_i }
		@srv.add_handler("push") { |id| @bot_pool[id].push.to_i }
		
		@srv.set_default_handler do |name, *args|
			# if md = name.match(/get_(.*)/)
			# 	@bot_pool[*args.shift].send(md[1], *args)
			# end
			raise XMLRPC::FaultException.new(-99, "Method #{name} missing or wrong number of parameters!")
		end
	end		

	def start	
		@srv.serve
	end

	def stop
		@srv.shutdown
	end

end		




