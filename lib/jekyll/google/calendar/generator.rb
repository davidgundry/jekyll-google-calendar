require 'google/apis/calendar_v3'
require 'googleauth'

GoogleCalendar = ::Google::Apis::CalendarV3

#TODO: Handle case where calendar doesn't exist or is not readable
#TODO: Add conference data to hash
#TODO: Add remaining calendar response data to hash

module Jekyll
    module Google
        module Calendar

            ##
            # This class represents a Jekyll page generated from a calendar event.
            
            class EventPage < Page
                def initialize(site, base, dir, name, layout, data, calendar_data, calendar_id)
                    @site = site
                    @base = base
                    @dir = dir
                    @name = name
                    self.process(@name)
                    self.data    = site.layouts[layout].data.dup
                    self.content = site.layouts[layout].content.dup
                    self.data['layout'] = layout
                    self.data['event'] = data
                    self.data['calendar'] = calendar_data
                    self.data['calendar_id'] = calendar_id
                    self.data['title'] = data['summary']
                end
            end

            ##
            # This class is a Generator that Jekyll will call to generate events from our Google Calendars

            class EventPageGenerator < Generator
                safe true

                ##
                # Called by Jekyll when generating pages. Here we set up the Google Calendar service,
                # and for each calendar described in our _config.yml, we generate pages for each event
                # Params:
                # +site+:: Jekyll site variable

                def generate(site)
                    @gcallendar_config = site.config['gcalendar']
                    raise 'Missing Google Calendar configuration in _config.yml' unless @gcallendar_config
                    service = setup_calendar()
                    @gcallendar_config['calendars'].each do |calendar|
                        process_calendar(site, service, calendar['id'], calendar['look_ahead'], calendar['directory'], calendar['date_format'], calendar['layout'])
                    end
                end
        
                private

                def setup_calendar()
                    scope = 'https://www.googleapis.com/auth/calendar'
                    calendar = GoogleCalendar::CalendarService.new
                    authorizer = ::Google::Auth::ServiceAccountCredentials.make_creds(
                        json_key_io: File.open(@gcallendar_config['key_file']),
                        scope: scope)
                    authorizer.fetch_access_token!
                    calendar.authorization = authorizer
                    calendar
                end

                def process_calendar(site, calendar, calendar_id, look_ahead, dir, date_format, layout)
                    page_token = nil
                    calendar_data = nil
                    end_time = DateTime.now + look_ahead
                    begin
                        response = get_events(calendar, calendar_id, page_token, end_time)
                        calendar_data = calendar_data ? calendar_data : hash_calendar_data(response)
                        response.items.each do |event|
                            create_event(site, event, calendar_data, calendar_id, dir, date_format, layout)
                        end
                        page_token = response.next_page_token != page_token ? response.next_page_token : nil
                    end while !page_token.nil?
                end

                def get_events(calendar, calendar_id, page_token, end_time)
                    response = calendar.list_events(calendar_id,
                                page_token: page_token,
                                single_events: true,
                                order_by:      "startTime",
                                time_max:      end_time.rfc3339)
                    response
                end

                def create_event(site, data, calendar_data, calendar_id, dir, date_format, layout)
                    hash = hash_event_data(data)
                    slug = data.summary.strip.downcase.gsub(/[\s\.\/\\]/, '-').gsub(/[^\w-]/, '').gsub(/[-_]{2,}/, '-').gsub(/^[-_]/, '').gsub(/[-_]$/, '')
                    if !date_format.nil? && date_format != ""
                        if !data.start.date_time.nil?
                            slug += "-" + data.start.date_time.strftime(date_format)
                        elsif !data.start.date.nil?
                            slug += "-" + data.start.date.strftime(date_format)
                        end
                    end
                    path = (dir[-1] == "/" ? dir : dir + "/") + slug
                    overlap = site.pages.select do |hash|
                        hash['url']== "/"+path+"/"
                    end
                    if overlap.length > 0
                        path += "-" + overlap.length.to_s
                    end
                    site.pages << EventPage.new(site, site.source, path, 'index.html', layout, hash, calendar_data, calendar_id)
                end

                def hash_calendar_data(response)
                    hash = {}
                    hash['kind'] = response.kind
                    hash['etag'] = response.etag
                    hash['summary'] = response.summary
                    hash['description'] = response.description
                    hash['updated'] = response.updated
                    hash['timeZone'] = response.time_zone
                    hash['accessRole'] = response.access_role
                    hash['defaultReminders'] = response.default_reminders ? response.default_reminders.map { |a| { "method" => a.method, "minutes" => a.minutes } } : nil
                    hash['nextPageToken'] = response.next_page_token
                    hash['nextSyncToken'] = response.next_sync_token
                    hash
                end

                def hash_event_data(data)
                    hash = {}
                    hash['kind'] = data.kind
                    hash['etag'] = data.etag
                    hash['id'] = data.id
                    hash['status'] = data.status
                    hash['htmlLink'] = data.html_link
                    hash['created'] = data.created
                    hash['summary'] = data.summary
                    hash['description'] = data.description
                    hash['location'] = data.location
                    hash['colorId'] = data.color_id
                    hash['creator'] = data.creator ? {"id" => data.creator.id, "email" => data.creator.email, "displayName" => data.creator.display_name, "self" => data.creator.self } : nil
                    hash['organizer'] = data.organizer ? {"id" => data.organizer.id, "email" => data.organizer.email, "displayName" => data.organizer.display_name, "self" => data.organizer.self } : nil
                    hash['start'] = data.start ? {"date" => data.start.date, "dateTime" => data.start.date_time, "timeZone" => data.start.time_zone } : nil
                    hash['end'] = data.end ? {"date" => data.end.date, "dateTime" => data.end.date_time, "timeZone" => data.end.time_zone } : nil
                    hash['endTimeUnspecified'] = data.end_time_unspecified
                    hash['recurrence'] = data.recurrence
                    hash['recurringEventId'] = data.recurring_event_id
                    hash['originalStartTime'] = data.original_start_time ? {"data" => data.original_start_time.date, "dateTime" => data.original_start_time.date_time, "timeZone" => data.original_start_time.time_zone } : nil
                    hash['transparency'] = data.transparency
                    hash['visibility'] = data.visibility
                    hash['iCalUID'] = data.i_cal_uid
                    hash['sequence'] = data.sequence
                    hash['attendees'] = data.attendees ? {"id" => data.attendees.id, "email" => data.attendees.email, "displayName" => data.attendees.display_name, "organizer" => data.attendees.organizer, "self" => data.attendees.self, "resource" => data.attendees.resource, "optional" => data.attendees.optional, "responseStatus" => data.attendees.response_status, "comment" => data.attendees.comment, "additionalGuests" => data.attendees.additionalGuests} : nil
                    hash['attendeesOmitted'] = data.attendees_omitted
                    hash['extendedProperties'] = data.extended_properties ? {"private" => data.extended_properties.private, "shared" => data.extended_properties.shared} : nil
                    hash['hangoutLink'] = data.hangout_link
                    hash['conferenceData'] = data.conference_data ? hash_conference_data(data.conference_data) : nil
                    hash["anyoneCanAddSelf"] = data.anyone_can_add_self
                    hash["guestsCanInviteOthers"] = data.guests_can_invite_others
                    hash["guestsCanModify"] = data.guests_can_modify
                    hash["guestsCanSeeOtherGuests"] = data.guests_can_see_other_guests
                    hash["privateCopy"] = data.private_copy
                    hash["locked"] = data.locked
                    hash['reminders'] = data.reminders ? {"useDefault" => data.reminders.use_default, "overrides" => data.reminders.overrides ? data.reminders.overrides.map { |o| {"methods" => o.methods, "minutes" => o.minutes} } : nil } : nil
                    hash['source'] = data.source ? {"url" => data.source.url, "title" => data.source.title } : nil
                    hash['attachments'] = data.attachments ? data.attachments.map { |a| { "fileUrl" => a.file_url, "title" => a.title, "mime_type" => a.mime_type, "iconLink" => a.icon_link, "fileId" => a.file_id } } : nil
                    hash
                end

                def hash_conference_data(data)
                    hash = {}
                    hash['createRequest'] = data.create_request ? data.create_request.map { |a| { "requestId" => a.request_id, "conferenceSolutionKey" => a.conference_solution_key ? a.conference_solution_key.map { |b| { "type" => b.type } } : nil } }: nil
                    hash['status'] = data.status ? {
                        'statusCode' => data.status.statusCode
                        } : nil
                    hash['entryPoints'] = data.entry_points ? data.entry_points.map { |a| { "entryPointType" => a.entry_point_type, "uri" => a.uri, "label" => a.label, "pin" => a.pin, "accessCode" => a.access_code, "meetingCode" => a.meeting_code, "passcode" => a.passcode, "password" => a.password }} : nil

                    hash['conferenceSolution'] = data.conference_solution ? {
                        "key" => data.conference_solution.key ? { "type" => data.conference_solution.key.type} : nil,
                        "name" => data.conference_solution.name,
                        "iconUri" => data.conference_solution.iconUri
                        } : nil
                    
                    hash['conferenceId'] = data.conference_id
                    hash['signature'] = data.signature
                    hash['notes'] = data.notes
                    hash['gadget'] = data.gadget ? {
                        'type' => data.gadget.type,
                        'title' => data.gadget.title,
                        'link' => data.gadget.link,
                        'iconLink' => data.gadget.iconLink,
                        'width' => data.gadget.width,
                        'height' => data.gadget.height,
                        'display' => data.gadget.display,
                        'preferences' => data.preferences
                        }: nil
                    hash
                end
            end
        end
    end
end
