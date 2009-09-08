#!/usr/bin/ruby

# (c) 2008-01-07 Philipp Hofmann <phil@s126.de>

class SwintBot

	attr_reader :speed, :sight, :power, :weight, :energy, :name, :owner

	def initialize
		@speed, @sight, @power, @weight, @energy = 4, 4, 4, 4, 4
		@name, @owner = 'BasicBot', 'noname'
	end

	def next env
		# reply with :do_nothing, :move_to, or :push_object
		# env is array of: :free, :enegry, :goal, :object, :robot, :outside
		:do_nothing
	end

	def move
	end

	def push
	end

	def end_game msg
	end

end

# require 'bot_server'
# BotServer.new('BasicBot').start