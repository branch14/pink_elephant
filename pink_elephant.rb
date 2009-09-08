#!/usr/bin/ruby

require 'logger'
require 'ostruct'

require 'swint_bot'
require 'swint_server'

require File.expand_path(File.join(File.dirname(__FILE__), 'a_star'))
require File.expand_path(File.join(File.dirname(__FILE__), 'hex_logic'))

$logger = Logger.new('pink_elephant.log')
$logger.datetime_format = ''

def log(s)
  $logger.info(s)
end

class PinkElephant < SwintBot
  
  COST = {
    :free => 2,
    :energy => 1,
    :start => 2,
    :goal => 1,
    :object => nil,
    :robot => nil,
    :outside => nil
  }
  
  # ------------------------------
  
  def initialize
    log '='*30
    super
    @name, @owner = 'PinkElephant', 'phil'
    @turn = 0
    @speed, @sight, @power, @weight, @energy = 3, 7, 0, 0, 10
    @speed, @sight, @power, @weight, @energy = 4, 8, 0, 0, 8
    #@speed, @sight, @power, @weight, @energy = 1, 3, 0, 0, 16
    #@speed, @sight, @power, @weight, @energy = 3, 11, 0, 0, 8
    @energy_left = @energy
    # ---
    @nrgmap = Hash.new
    @hexmap = HexLogic::calc_map(@sight)
    @dirs = HexLogic::calc_dirs(@sight)
    # ---
    @history = []
    @spin = 1
    @path = []
    @here = nil
    @master_plan = []
    @here_pos = [0, 0]
  end
  
  # -------------------------------
  # --- internal api
  
  def next env
    @turn += 1
    @env = [@energy_left == @energy ? :energue : :free] + env # sbc conv
    :move_to
  end
  
  def move
    m = my_move
    @energy_left -= 1
    @history << m unless obstructed?(m+1)
    @energy_left = @energy if energy?(m+1)
    #log "MOVETO #{m}"
    m
  end
  
  def push
    @energy_left -= 1
    $logger.info "push to #{@push}"
  end
  
  # -------------------------------
  # --- business logic api
  
  def obstructed?(tile)
    [:outside, :object, :robot].include?(@env[tile])
  end
  
  def energy?(tile)
    @env[tile] == :energy		
  end
  
  def alternative(move)
    log "alternative"
    (move + @spin) % 6
  end
  
  def insight?(sym)
    @env.include?(sym)
  end
  
  def distance(tile)
    depth = 0
    depth += 1 until HexLogic::ring(depth).include?(tile)
    depth
  end
  
  def goal
    closest(:goal)
  end
  
  def closest(sym)
    @env.index(sym)
  end
  
  def directions(tile) # directions of tile
    # we don't need @dirs for this, and it returns -1 for 0
    return [tile-1] if tile < 7
    moves = []
    6.times { |c| moves << c if @dirs[c].include?(tile) }
    moves
  end
  
  def energy_fields
    tiles = []
    @env.each_index { |f| tiles << f if @env[f]==:energy }
    tiles.delete(0)
    tiles
  end
  
  def opposite?(m1, m2)
    ((m1 + 3) % 6) == m2
  end
  
  def opposite(x)
    (x + 3) % 6
  end
  
  def robot_around?
    @env[HexLogic::ring(1)].include?(:robot)
  end
  
  def costmap
    cost = { :free => 1, :energy => 1, :object => nil, :robot => nil, :outside => nil, :start => 1, :goal => 1 }
    cm = []
    @env.each { |e| cm << cost[e] }
    cm
  end
  
  def count_outside(dir)
    c = 0
    @dirs[dir].each { |s| c += 1 if @env[s]==:outside }
    c
  end
  
  def haze
    h = []
    6.times { |t| h << count_outside(t) } 
    h
  end
  
  def path2dirs(path)
    dirs = []
    prev = path.shift
    path.each do |spot|
      dirs << @hexmap[prev].index(spot)
      prev = spot
    end
    dirs
  end
  
  def reverse_dirs(dirs)
    dirs.reverse.collect { |d| opposite(d) }
  end
  
  # ------------------------------------------------------------
  # ------------------------------------------------------------
  
  def check_node(tile, state=:energy, from=nil)
    from ||= @here
    pos = from.pos.clone
    ds = path2dirs(AStar.find_path(@hexmap, lambda { |a, b| 1 } , tile))
    ds.each { |d| pos.add!(HexLogic::DIRV[d]) }
    @nrgmap[pos] = OpenStruct.new( :pos => pos, :state => state, :links => Hash.new, :been_there => 0 ) unless @nrgmap[pos]
    if !from.links.value?(@nrgmap[pos])
      path = AStar.find_path(@hexmap, lambda { |a, b| COST[@env[b]] }, tile)
      if path
        dirs = path2dirs(path)
        from.links[dirs] = @nrgmap[pos]
        @nrgmap[pos].links[reverse_dirs(dirs)] = from
      end
    end
    @nrgmap[pos]
  end
  
  def my_move
    if @turn==1
      @here = OpenStruct.new( :pos => [0, 0], :state => :start, :links => Hash.new, :been_there => 0 )
      @nrgmap[@here.pos] = @here
    end
    if @path.empty?
      #if !@master_plan.empty?
      #	next_spot = @master_plan.shift
      #	@path = @nrgmap[@here].index(next_spot)
      #	@here = next_spot
      #else
      check_node(goal, :goal) if insight?(:goal)
      energy_fields.each { |e| check_node(e) }
      # ============================================================ LOGIC HERE
      @here.been_there += 1
      #log display_nrgmap
      options = @here.links.select { |dirs, n| dirs.size<@energy_left && n.state==:goal }
      if options.empty?
        activity_center = [0, 0]
        sum = 0
        #@nrgmap.each { |k, v| activity_center.add!(k.collect { |e| e*v.been_there })}
        @nrgmap.each do |k, v|
          v.been_there.times do
            activity_center.add!(k)
            sum += 1
          end
        end
        activity_center = activity_center.collect { |d| -(d / sum) }
        #log "activity_center: #{activity_center*'x'}"
        options = @here.links.select { |dirs, n| dirs.size<@energy_left && n.been_there==0 } 
        a, d = nil, nil
        if !options.empty?
          options.each do |o|
            pos = o[1].pos.add(activity_center)
            dis = pos[0].abs + pos[1].abs
            a, d = o, dis if !a || d<dis
          end
          options = [a]			
          log "longest distance from activity center"
        end
      end
      if options.empty?
        log "we have to go back"
        options = @here.links.select { |dirs, n| dirs.size<@energy_left } 
        options.sort! { |x, y| x[1].been_there <=> y[1].been_there }
        log "the one where i have been less often"
      end
      log display_options(options)
      pick = options.first
      @path, @here = pick[0].clone, pick[1]
      log "aim: #{human(@here.pos)} been_there: #{@here.been_there}, path: #{@path*'-'}"
      #end
      return my_move
    end
    log "PATH: #{@path*'->'}"
    m = @path.shift
    if obstructed?(m+1)
      @path = []
      return my_move
    end
    @here_pos.add!(HexLogic::DIRV[m])
    m
  end
  
  def human(x)
    @humanr ||= []
    @humanr << x unless @humanr.include?(x)
    "[%s]" % @humanr.index(x) 
  end
  
  def display_nrgmap
    output = "nrgmap:\n"
    @nrgmap.each do |pos, node|
      output += "#{human(pos)} => "
      output += node.links.to_a.collect { |a| "(#{a[0]*'-'})->#{human(a[1].pos)}" }.join(' ')
      output += "\n"
    end
    output
  end
  
  def display_options(options)
    output = "options:\n"
    options.each do |option|
      path, node = option
      output += "(#{path*'-'}) => #{human(node.pos)} #{node.been_there ? 'been there' : 'new'}"
      output += "\n"
    end
    output
  end

end

port = ARGV[0] || 3333
SwintServer.new('PinkElephant', port).start
