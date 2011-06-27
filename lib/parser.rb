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
      parse_cells
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

    def parse_cells
      cells = find_cells

      day = time = 0

      cells.each do |cell|
        # Reset day and time if it's a horizontal heading (e.g. "0900")
        if cell =~ /^(\d{2})00$/
          day = 0
          time = $1.to_i
          next
        end

        # Move on if the cell is empty or just a newline
        unless cell.empty? || cell == "<br />"
          lines = cell.split("<br />").delete_if(&:empty?)
          # Each event is made up of two lines, so we take them both
          lines.each_slice(2) do |event|
            parse_event(event, day, time)
          end
        end

        day += 1
      end

      delegate(:parsing_ended)
    end
    
    # Retrieves an array of the textual contents of the table cells
    def find_cells
      @doc ||= Hpricot(input)
      cells = @doc.search("table/tbody/tr/td/font")
      cells.map!(&:inner_html)
    end

    def parse_event(event, day, time)
      # Grab the title from event[0], metadata from event[1]
      title, extra = event
      title.gsub!("&amp;", "&")
      info, attendees, locations = extra.split(" / ")

      type, weeks = parse_info(info)
      attendees = parse_attendees(attendees)
      locations = parse_locations(locations)

      event = {
        :day => day,
        :time => time,
        :name => title,
        :type => type,
        :weeks => weeks,
        :attendees => attendees,
        :locations => locations
      }
      delegate(:process_event, event)
    end

    def parse_info(info)
      # Match strings like "LEC (2-6)"
      if info =~ /(\w+) \((\d{1,2})-(\d{1,2})\)/
        type = $1
        weeks = $2.to_i..$3.to_i
        [type, weeks]
      end
    end

    def parse_attendees(attendees)
      return [] if attendees.nil?
      # Match strings like "ajf (2-6)"
      attendees = attendees.scan(/([\w-']+) \([-0-9]{3,5}\)/)
      attendees.flatten
    end

    def parse_locations(locations)
      return [] if locations.nil?
      locations.split(', ')
    end
  end
end
