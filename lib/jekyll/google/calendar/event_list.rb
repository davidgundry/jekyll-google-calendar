require 'date'

module Jekyll
    module Google
        module Calendar
            module EventListFilter
                def get_google_calendar_events_by_date_offset(events, startOffset, endOffset, soft_max)
                    i = 0
                    newEvents = []
                    unless events.nil?
                        for event in events
                            date = event["start"]["date"] || event["start"]["dateTime"]
                            date = date.to_time

                            start_of_day = Time.new(Time.now.year, Time.now.month, Time.now.day) + 60*60*24 * startOffset
                            end_of_range = nil
                            if endOffset >= 0
                                end_of_range = Time.new(Time.now.year, Time.now.month, Time.now.day) + 60*60*24 * (endOffset + 1)
                            end

                            today = date < start_of_day + 60*60*24


                            if (date >= start_of_day.utc) && (!end_of_range || date < end_of_range)
                                if (today || i < soft_max)
                                    newEvents.push(event)
                                    i = i + 1
                                else
                                    return newEvents
                                end
                            end 
                        end
                    end
                    newEvents
                end
            end
        end
    end
end

Liquid::Template.register_filter(Jekyll::Google::Calendar::EventListFilter)
