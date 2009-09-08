# (c) 2008-01-07 Philipp Hofmann <phil@s126.de>

require File.expand_path(File.join(File.dirname(__FILE__), 'priority_queue'))

class AStar

	def AStar.find_path(map, cost_method, goal, start=0)
		been_there = {}
		pqueue = PriorityQueue.new
		pqueue << [1, [start, [], 1]]
		while !pqueue.empty?
			spot, path_so_far, cost_so_far = pqueue.next
			next if been_there[spot]
			newpath = [path_so_far, spot]
			return newpath.flatten if (spot == goal)
			been_there[spot] = 1
			#puts "map[spot]: #{map[spot].inspect}"
			map[spot].each do |dirv, newspot|
				next if been_there[newspot] || !cost_method.call(spot, newspot)
				tcost = cost_method.call(spot, newspot)
				newcost = cost_so_far + tcost
				pqueue << [newcost + estimate(map, goal, newspot), [newspot, newpath, newcost]]
			end
		end
		return nil
	end	

	def AStar.estimate(map, goal, spot)
		0 # distance(map, goal, spot)
	end

	def AStar.distance(map, goal, start=0)
		@@distances ||= Hash.new
		@@distances[[start, goal]] = find_path(map, Hash.new(0), goal, start).size
		@@distances[[start, goal]]
	end

end