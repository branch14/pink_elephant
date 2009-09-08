# (c) 2008-01-14 Philipp Hofmann <phil@s126.de>

class PriorityQueue

	def initialize
		@list = []
	end

	def add(priority, item)
		# Add @list.length so that sort is always using Fixnum comparisons,
		# which should be fast, rather than whatever is comparison on `item'
		@list << [priority, @list.length, item]
		@list.sort!
		self
	end

	def <<(pritem)
		add(*pritem)
	end

	def next
		@list.shift[2]
	end

	def empty?
		@list.empty?
	end

end
