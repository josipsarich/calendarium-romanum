module CalendariumRomanum

  # Information on one particular day of the liturgical year
  class Day
    # Note: despite of all constructor arguments being nullable,
    # instances returned by {Calendar} always have all of them set,
    # the only exception being +vespers+.
    #
    # @param date [Date, nil]
    # @param season [Season, nil]
    # @param season_week [Integer, nil]
    # @param celebrations [Array<Celebration>, nil]
    # @param vespers [Celebration, nil]
    def initialize(date: nil, season: nil, season_week: nil, celebrations: nil, vespers: nil)
      @date = date
      @season = season
      @season_week = season_week
      @celebrations = celebrations ? celebrations.dup : []
      @vespers = vespers
    end

    # @return [Date]
    attr_reader :date

    # Weekday as integer (Sunday is 0)
    #
    # @return [Integer]
    def weekday
      date.wday
    end

    # Weekday as internationalized string
    #
    # @return [String]
    # @since 0.7.0
    def weekday_name
      I18n.t(date.wday, scope: 'weekday')
    end

    # @return [Season]
    attr_reader :season

    # Week of the season
    #
    # @return [Integer]
    attr_reader :season_week

    # List of celebrations for the given day.
    #
    # In tests and other "less-standard" situations the array
    # may be empty, but it's never empty for instances
    # returned by {Calendar}.
    #
    # @return [Array<Celebration>]
    attr_reader :celebrations

    # {Celebration} whose first Vespers are celebrated
    # in place of Vespers of the day's {Celebration}(s).
    # Please note that {Calendar} by default _doesn't_ populate
    # Vespers, - it's an opt-in feature
    # (see {Calendar#initialize}, {Calendar#populates_vespers?},
    # {Calendar#day}).
    #
    # @return [Celebration, nil]
    # @since 0.5.0
    attr_reader :vespers

    def ==(other)
      self.class == other.class &&
        date == other.date &&
        season == other.season &&
        season_week == other.season_week &&
        celebrations == other.celebrations &&
        vespers == other.vespers
    end

    # Are the day's Vespers suppressed in favour of first Vespers
    # of a Sunday or solemnity?
    #
    # @return [Boolean]
    def vespers_from_following?
      !vespers.nil?
    end

    # String representation of the instance listing it's contents.
    # Intended mostly for debugging purposes.
    #
    # @return [String]
    # @since 0.7.0
    def to_s
      celebrations_string = '['
      celebrations.each do |c|
        celebrations_string << c.to_s + ', '
      end
      celebrations_string = celebrations_string.chomp(', ') << ']'
      "#<#{self.class.name} @date=#{date} @season=#{season} @season_week=#{season_week} celebrations=#{celebrations_string} vespers=#{vespers.inspect}>"
    end
  end

  # One particular celebration of the liturgical year
  # (like a Sunday, feast or memorial);
  # some days have one,
  # some have more among which one is to be chosen
  class Celebration
    include RankPredicates

    # All arguments can be passed either as positional or keyword arguments.
    # In case of conflict keyword arguments win.
    # @example
    #   Celebration.new('Lost title', title: 'Winning title') # will have title 'Winning title'
    #
    # @param title [String|Proc]
    #   Celebration title/name.
    #   If a +Proc+ is passed, it is expected not to receive
    #   arguments and to return a +String+.
    #   (Used for celebration titles which have to be
    #   internationalizable - the +Proc+ is called whenever
    #   {#title} is invoked, which allows the value to vary
    #   depending e.g. on state of the +Proc+ or some
    #   global setting - like +I18n.locale+ - it may access.)
    # @param rank [Rank] Celebration rank
    # @param colour [Colour] Liturgical colour
    # @param symbol [Symbol, nil]
    #   Unique machine-readable identifier of the celebration
    # @param date [AbstractDate, nil]
    #   Normal fixed date of the celebration
    # @param cycle [:sanctorale, :temporale]
    #   Cycle the celebration belongs to
    def initialize(title = '', rank = Ranks::FERIAL, colour = Colours::WHITE, symbol = nil, date = nil, cycle = :sanctorale, sunday = false, **kwargs)
      @title = kwargs.delete(:title) || title
      @rank = kwargs.delete(:rank) || rank
      @colour = kwargs.delete(:colour) || kwargs.delete(:color) || colour
      @symbol = kwargs.delete(:symbol) || symbol
      @date = kwargs.delete(:date) || date
      @cycle = kwargs.delete(:cycle) || cycle
      @sunday = kwargs.delete(:sunday) || sunday

      unless kwargs.empty?
        raise ArgumentError.new('Unexpected keyword arguments: ' + kwargs.keys.inspect)
      end

      if @sunday && ![Ranks::SUNDAY_UNPRIVILEGED, Ranks::PRIMARY].include?(@rank)
        raise ArgumentError.new("Rank #{@rank} cannot be Sunday")
      end
    end

    # Build a new instance using the receiver's attributes
    # for all properties for which (a non-nil) value was not passed.
    #
    # @return [Celebration]
    # @since 0.5.0
    def change(title: nil, rank: nil, colour: nil, color: nil, symbol: nil, date: nil, cycle: nil, sunday: nil)
      self.class.new(
        title: title || self.title,
        rank: rank || self.rank,
        colour: colour || color || self.colour,
        symbol: symbol || self.symbol,
        date: date || self.date,
        cycle: cycle || self.cycle,
        sunday: sunday || @sunday
      )
    end

    # @return [Rank]
    attr_reader :rank

    # Feast title/name
    #
    # @return [String]
    def title
      if @title.respond_to? :call
        @title.call
      else
        @title
      end
    end

    # Liturgical colour
    #
    # @return [Colour]
    attr_reader :colour
    alias color colour

    # Symbol uniquely identifying the celebration
    #
    # @return [Symbol, nil]
    # @since 0.5.0
    attr_reader :symbol

    # Usual date of the celebration.
    #
    # Only set for celebrations with fixed date.
    # (Only) In case of solemnities it may happen that
    # {Celebration#date} differs from {Day#date} due to
    # transfer of an impeded solemnity.
    #
    # @return [AbstractDate, nil]
    # @since 0.6.0
    attr_reader :date

    # Describes the celebration as belonging either to the
    # temporale or sanctorale cycle
    #
    # @return [:sanctorale, :temporale]
    # @since 0.6.0
    attr_reader :cycle

    def ==(b)
      self.class == b.class &&
        title == b.title &&
        rank == b.rank &&
        colour == b.colour &&
        symbol == b.symbol &&
        date == b.date &&
        cycle == b.cycle
    end

    # Does the celebration belong to the temporale cycle?
    #
    # @return [Boolean]
    # @since 0.6.0
    def temporale?
      cycle == :temporale
    end

    # Does the celebration belong to the sanctorale cycle?
    #
    # @return [Boolean]
    # @since 0.6.0
    def sanctorale?
      cycle == :sanctorale
    end

    # Is the celebration a Sunday?
    #
    # Please note that for "privileged Sundays" true is returned, while {Rank#sunday?}
    # returns false (because not all celebrations of that rank are Sundays).
    #
    # @return [Boolean]
    def sunday?
      rank.sunday? || @sunday
    end

    # String representation of the object's contents
    # (not very pretty, intended mostly for development inspections).
    #
    # @return [String]
    # @since 0.7.0
    def to_s
      "#<#{self.class.name} @title=\"#{title}\" @rank=#{rank} @colour=#{colour} symbol=#{symbol.inspect} date=#{date.inspect} cycle=#{cycle.inspect}>"
    end
  end
end
