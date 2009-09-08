# (c) 2008-01-07 Philipp Hofmann <phil@s126.de>

require File.expand_path(File.join(File.dirname(__FILE__), 'array'))

class HexLogic

	DIRV = [
		[-1, +1],
		[-1,  0],
		[ 0, -1],
		[+1, -1],
		[+1,  0],
		[ 0, +1]
	]

	################################################################################

	def HexLogic.chn(n)
 		1 + 3 * n * ( n - 1)
	end

	def HexLogic.ring(n)
		return 0..0 if n==0
		chn(n)..chn(n+1)-1
	end

	def HexLogic.star(n)
		f = [[], [], [], [], [], []]
		(n+1).times { |d| 6.times { |t| f[t] << chn(d+1)+t*(d+1) } }
		f
	end

	#def HexLogic.line(t, d=@sight)
	#	s = star(d)
	#	s.each { |f| return f if f.include?(t) }
	#end

	################################################################################

	#def path2directions(path)
	#	atad = @data.invert
	#	r = []
	#	prev = path.shift
	#	path.each do |spot|
	#		DIRV.size.times { |d| r << d if atad[prev].add(DIRV[d])==atad[spot]}
	#		prev = spot
	#	end		
	#	r
	#end

	################################################################################

	def HexLogic.calc_dirs(n)
		f = [[], [], [], [], [], []]
		n.times do |d|
			6.times do |t|
				f[t] << chn(d+1)+t*(d+1)
				d.times do |c|
					f[t] << chn(d+1)+t*(d+1)+c+1
					f[(t+1)%6] << chn(d+1)+t*(d+1)+c+1
				end
			end
		end
		f
	end

	def HexLogic.calc_map(depth)

		# A centered hexagonal number, or hex number, is a centered figurate
		# number that represents a hexagon with a dot in the center and all
		# other dots surrounding the center dot in a hexagonal lattice.
		# 1, 7, 19, 37, 61, 91, 127, 169, 217, 271, 331, 397, 469, 547, 631, 721, 817, 919

		# the map looks like this ... (for depth 3)
		#
		#       25  26  27  28
		#     24  11  12  13  29
		#   23  10  03  04  14  30
		# 22  09  02  00  05  15  31
		#   21  08  01  06  16  32
		#     20  07  18  17  33
		#       19  36  35  34

		# and the adjacency list looks like this
		#
		# 00: 01, 02, 03, 04, 05, 06
		# 01: 07, 08, 02, 00, 06, 18
		# 02: 08, 09, 10, 03, 00, 01
		# 03: 02, 10, 11, 12, 04, 00
		# 04: ...

		# and the map looks ... different now

		# relative directions
		reld = [2, 3, 4, 5, 0, 1]
	
		pos = [0, 0]
		spot = 0
		@data = { pos.clone => spot }

		depth.times do |d|
		 	pos.add!(DIRV[0])
			spot += 1
		 	@data[pos.clone] = spot
		 	5.times do |dir|
		 		(d+1).times do |i|
		 			pos.add!(DIRV[reld[dir]])
		 			spot += 1
					@data[pos.clone] = spot
		 		end
		 	end
	                d.times do |i|
	                        pos.add!(DIRV[reld[5]])
				spot += 1
		                @data[pos.clone] = spot
	                end
		 	pos.add!(DIRV[1])
		end

		spotsfrom = {}

		@data.each do |pos, spot|
			spotsfrom[spot] = {}
			6.times { |v| spotsfrom[spot][v] = @data[pos.add(DIRV[v])] if @data[pos.add(DIRV[v])] }
		end

		spotsfrom
	
	end

end