# (c) 2008-01-07 Philipp Hofmann <phil@s126.de>

class Array

	# vector addition

	def add(a) 
		n = []
		each_index { |i| n << (self[i] + a[i]) }
		n
	end

	def add!(a)
		replace(add(a))
	end

end
