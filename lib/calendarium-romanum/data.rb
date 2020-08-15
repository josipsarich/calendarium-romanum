module CalendariumRomanum
  # Allows easy access to bundled data files
  #
  # @example
  #   sanctorale = CalendariumRomanum::Data::GENERAL_ROMAN_LATIN.load
  class Data < Enum

    class SanctoraleFile
      # This class is not intended to be initialized by client code -
      # it's sole purpose is to provide functionality for easy
      # loading of the bundled sanctorale data files.
      #
      # @api private
      def initialize(base_name)
        @siglum = base_name.sub(/\.txt$/, '')
        @path = File.expand_path('../../data/' + base_name, File.dirname(__FILE__))
      end

      attr_reader :siglum, :path

      # Load the data file
      #
      # @return [Sanctorale]
      def load
        SanctoraleLoader.new.load_from_file(path)
      end

      # Load the data file and all it's parents
      #
      # @return [Sanctorale]
      # @since 0.7.0
      def load_with_parents
        SanctoraleFactory.load_with_parents(path)
      end
    end

    GENERAL_ROMAN = SanctoraleFile.new('universal.txt')
    GENERAL_ROMAN_LATIN_1969 = SanctoraleFile.new('universal-1969-la.txt')
    CZECH = SanctoraleFile.new('czech-cs.txt')

    values(index_by: :siglum) do
      # only calendars of broader interest have constants defined
      [
        GENERAL_ROMAN,
        GENERAL_ROMAN_LATIN_1969,
        CZECH,
      ] \
      +
        %w(
          czech-brno-cs.txt
          czech-budejovice-cs.txt
          czech-cechy-cs.txt
          czech-hradec-cs.txt
          czech-litomerice-cs.txt
          czech-morava-cs.txt
          czech-olomouc-cs.txt
          czech-ostrava-cs.txt
          czech-plzen-cs.txt
          czech-praha-cs.txt
        ).collect {|basename| SanctoraleFile.new(basename) }
    end
  end
end
