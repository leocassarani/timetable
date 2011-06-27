require 'hpricot'

module Timetable
  class Parser
    def initialize(delegate)
      @delegate = delegate
    end

    def parse(input)
      unless input
        delegate(:parsing_ended)
        return
      end

      @input = input
      @doc = nil

      find_week_range
      find_week_start
    end

  private

    def delegate(method, *args)
      if @delegate.respond_to?(method)
        @delegate.send(method, *args)
      end
    end

    def find_week_range
      @doc ||= Hpricot(@input)
      tag = @doc.search("body/h3[2]/font")
      return if tag.empty?
      text = tag.inner_html

      # Matches both "(Week 1)" and "(Weeks 2 - 11)"
      range = text.scan(/\(Week[s]? (\d{1,2})[\s-]*(\d{1,2})?\)/)
      range_start, range_end = range.flatten

      range_start = range_start.to_i
      # The range terminates at range_end, if it exists, or range_start
      # itself, if the calendar only describes a single week of term
      range_end = range_end.nil? ? range_start : range_end.to_i

      delegate(:process_week_range, range_start..range_end)
    end

    def find_week_start
      @doc ||= Hpricot(input)
      # Retrieve the first occurrence of a stand-alone <font> tag,
      # which happens to be the week start date. Return if nil,
      # which would normally indicate bad input, e.g. empty string.
      tag = @doc.at("body/font")
      return if tag.nil?
      start_text = tag.inner_html

      # Retrieve the number of the week the calendar starts on
      @week_no = start_text.scan(/Week (\d+) start date/)
      @week_no = @week_no.flatten.first.to_i

      # Retrieve text of the form "Monday 11 October, 2010"
      start_text = start_text.scan(/\w+ \d{1,2} \w+, \d{4}$/).first
      week_start = DateTime.strptime(start_text, "%a %d %b, %Y")

      delegate(:process_week_start, week_start)
    end
  end
end
