# Timetable

Timetable is a web-based scraper for the [Imperial College](http://www.imperial.ac.uk) [Department of Computing](http://www.doc.ic.ac.uk) timetables. It is written in Ruby and the [Sinatra](http://www.sinatrarb.com/) web framework.

## The problem

The Department of Computing at Imperial College London only publish their timetables as a series of HTML tables where every cell represent an hour-long slot (see [example](http://www.doc.ic.ac.uk/internal/timetables/timetable/autumn/class/3_2_11.htm)). Not wanting to miss any lectures because of their convoluted format, I wanted to import all the events into iCal (or equivalent calendar software) for easy and quick access.

## The solution

Given the user's degree course and year of entry, this will fetch the HTML pages corresponding to their timetable (and cache them for later), parse them, and finally output the resulting information as an iCalendar feed, which is supported by all the major calendar applications.

## Presets

A very common feature request I got was for users to be able to selectively exclude the modules they weren't taking from their timetable - in other words, users wanted to have a personalised timetable based on the modules they were taking.

Users can now visit the main timetable page and, after selecting their year of entry, untick the boxes corresponding to the modules they're not taking this year. The list of excluded modules forms a "preset", which gets saved to a [MongoHQ](http://mongohq.com) instance and is used to filter out the contents of a user's timetable every time their feed is generated.

## URL scheme

Users without a preset (no modules excluded) can access their timetable directly by visiting `/course/year_of_entry`, e.g. `/comp/09` for Computing students who started their degree in 2009. Presets, on the other hand, have a 5-letter unique name associated with them, and can be simply retrieved at `/preset_name`.

## Copyright

Copyright (c) 2011 Leo Cassarani. See LICENSE for details.