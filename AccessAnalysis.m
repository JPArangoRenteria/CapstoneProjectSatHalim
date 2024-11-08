function [accessout, aircraftout, constellationout, selectiveout] = AccessAnalysis(scenario)
    % Aircraft/constellation making
    % aircraft = create_sim_airport(starting, 3); % For airport stuff
    aircraftout = create_mission(scenario, scenario.scenario.StartTime, 3, 53.31, -113.58, 45.32, -75.67); % For testing
    constellationout = walker_constellation_v2(scenario.scenario, 36, 6, 1, 750, 53, 'star');
    
    % Access stuff
    accessfirst = Access_AnalysisTable(constellationout, aircraftout);
    accessout = accessFSPL(scenario, constellationout, aircraftout, accessfirst, 0.125);
    fix_table(accessout);

    accessimproved = timedaccess(scenario, accessout, aircraftout);
    selectiveout = rmmissing(accessimproved);
end

function flight_path = flight_pathing(flightduration, startlat, startlong, endlat, endlong)

    mission.StartDate = datetime;

    mission.Duration = hours(flightduration);
    
    start.Lat = startlat; % Starting Latitude
    start.Long = startlong; % Starting Longitude
    
    ending.Lat = endlat; % Ending Latitude
    ending.Long = endlong; % Ending Longitude
    
    traj.Lat = ending.Lat - start.Lat; % Determine change in Latitude
    traj.Long = ending.Long - start.Long; % Determine change in Longitude
    
    durationseconds = flightduration * 3600; % Convert duration into seconds
    samples = durationseconds / 10; % Convert to sample count
    
    flight.Latdelta = traj.Lat/samples;
    flight.Longdelta = traj.Long/samples;
    
    moment.Missiontime = 0;
    moment.Lat = start.Lat;
    moment.Long = start.Long;
    
    matObj = matfile("trajectory.mat");
    m = matfile('trajectory.mat','Writable',true);
    flighttime = timetable(TimeStep=seconds(10));
    trajtime = createArray(samples+1,3);
    
    for i = 1:samples+1
        trajtime(i,1) = moment.Lat;
        trajtime(i,2) = moment.Long;
        trajtime(i,3) = 10000;
        moment.Lat = moment.Lat + flight.Latdelta;
        moment.Long = moment.Long + flight.Longdelta;
    end
    
    flighttime.LLA = trajtime;
    flight_path = flighttime;
end


function aircraftout = create_mission(satscenario, startdate, flightduration, startlat, startlong, endlat, endlong)
    % Create flight
    missionout.StartDate = startdate;
    missionout.Duration = hours(flightduration);
    pathing = flight_pathing(flightduration, startlat, startlong, endlat, endlong);
    m = matfile('trajectory.mat','Writable',true);
    m.trajectory = pathing;
    aircraftout = load("trajectory.mat", "trajectory");
    geoplot(aircraftout.trajectory.LLA(:,1), aircraftout.trajectory.LLA(:,2), "b-");
    geolimits([30 50],[-110 -50]);
    
    % Create Mission
    aircraftout.obj = satellite(satscenario.scenario,aircraftout.trajectory, CoordinateFrame="geographic", Name="Aircraft");
    aircraftout.obj.MarkerColor = "green";
    hide(aircraftout.obj.Orbit);
    show(aircraftout.obj.GroundTrack);
    aircraftout.Connected = false;
end


function aircraftout = create_sim_airport(starttime, duration)
    
    airports = readtable("iata-icao.csv");
    countrycode_list = unique(airports.country_code);

    % Get start country
    [startcountryindex, tf] = listdlg('ListString', countrycode_list, 'SelectionMode','single');
    startcountry = string(countrycode_list(startcountryindex));
    start_airport_list = airports(ismember(airports.country_code, startcountry), :);

    % Get start airport
    start_airport_names_list = table2cell([start_airport_list(:, [2 3])]);
    [startairportindex, tf] = listdlg('ListString', start_airport_names_list(:, 2), 'SelectionMode','single');

    % Start airport information
    startairportcode = string(table2array(start_airport_list(startairportindex, 2)));
    startairportname = string(table2array(start_airport_list(startairportindex, 3)));
    startlat = table2array(start_airport_list(startairportindex, 4));
    startlong = table2array(start_airport_list(startairportindex, 5));


    % Get end country
    [endcountryindex, tf] = listdlg('ListString', countrycode_list, 'SelectionMode','single');
    endcountry = string(countrycode_list(endcountryindex));
    end_airport_list = airports(ismember(airports.country_code, endcountry), :);

    % Get end airport
    end_airport_names_list = table2cell([end_airport_list(:, [2 3])]);
    [endairportindex, tf] = listdlg('ListString', end_airport_names_list(:, 2), 'SelectionMode','single');

    % End airport information
    endairportcode = string(table2array(end_airport_list(endairportindex, 2)));
    endairportname = string(table2array(end_airport_list(endairportindex, 3)));
    endlat = table2array(end_airport_list(endairportindex, 4));
    endlong = table2array(end_airport_list(endairportindex, 5));

    aircraftout = create_mission(starttime, duration, startlat, startlong, endlat, endlong);

end

function accessAnalysisTable = Access_AnalysisTable(constellationobject, aircraftobject)
    accessAnalysisTable.obj = access(constellationobject, aircraftobject.obj);
    accessAnalysisTable.Intervals = accessIntervals(accessAnalysisTable.obj);
    accessAnalysisTable.Intervals = sortrows(accessAnalysisTable.Intervals,"StartTime");
end


function fix_table(accesstable)
    % Get access stuff we want
    [sourcechars, targetchars, startchars, endchars, durationchars] = convertStringsToChars(accesstable.Intervals.Source,accesstable.Intervals.Target, ...
        string(accesstable.Intervals.StartTime),string(accesstable.Intervals.EndTime), accesstable.Intervals.Duration);
    chartable = table(sourcechars, targetchars, startchars, endchars, durationchars, accesstable.Intervals.FSPL);
    celltable = table2cell(chartable);
    figure2 = figure("Name", "Access Analysis", "NumberTitle","off");
    figure(figure2);
    
    % Make a better table
    tablepic = uitable(figure2, 'ColumnWidth', 'auto', "Data", celltable);
    tablepic.ColumnName = {"Source","Target","Start Time","End Time","Duration", "FSPL"};
    table_extent = get(tablepic,'Extent');
    set(tablepic,'Position',[1 1 table_extent(3) table_extent(4)]);
    figure_size = get(figure2,'outerposition');
    desired_fig_size = [figure_size(1) figure_size(2) table_extent(3)+70 table_extent(4)+50];
    set(figure2,'outerposition', desired_fig_size);
end

function accessout = accessFSPL(scenario, constellationobj, aircraftobj, accessobj, lambda)
    % Create output and add FSPL Table
    accessout = accessobj;
    FSPLColumn = zeros(height(accessobj.Intervals), 1);
    accessout.Intervals.("FSPL") = FSPLColumn;

    % Get each satellite times/connections
    for index = 1:size(accessobj.Intervals.Source)
        strippedsat = split(accessobj.Intervals.Source(index, 1), '_'); % Get satellite number
        satnum = str2double(strippedsat(2));
        
        % Calculate FSPL for each row in access table
        indexFSPL = calculateFSPL(scenario.scenario.Satellites(1, satnum+1), aircraftobj.obj, accessobj.Intervals.StartTime(index), accessobj.Intervals.EndTime(index), 10, lambda);
        meanFSPL = mean(indexFSPL, "all"); % Take average
        accessout.Intervals.FSPL(index, 1) = meanFSPL; % Add average to access table
    end
    disp(accessout.Intervals)
end

function selectiveaccess = timedaccess(scenarioobj, accessobj, aircraftobj)
    
    % Getting current and end time
    scenariostart = scenarioobj.scenario.StartTime;
    scenariostart.Format = 'd-MMMM-yyyy HH:mm:ss';
    scenariostart.TimeZone = '';
    scenarioend = scenarioobj.scenario.StopTime;
    scenarioend.Format = 'd-MMMM-yyyy HH:mm:ss';
    scenarioend.TimeZone = '';

    timevector = [scenariostart:minutes(1):scenarioend];
    vectorsize = size(timevector, 2);
    timevector(1) = timevector(1)+duration(0, 0, 0, 1);

    % Creating table
    selectiveaccess = table('Size',[vectorsize 4], 'VariableTypes', {'string', 'datetime', 'datetime', 'double'}, 'VariableNames',{'Satellite', 'Connection Start', 'Connection End', 'FSPL'});
    aircraftobj.Connection.Connected = false;
    aircraftobj.Connection.sat = '';
    aircraftobj.Connection.index = 0;
    aircraftobj.Connection.number = 0;
    aircraftobj.Connection.vectornum = 0;

    for timeindex = 1:vectorsize
        if timeindex == 1 % If start of sim
            for row = 1:size(accessobj.Intervals.StartTime, 1)
                comparetime = accessobj.Intervals.StartTime(row);
                comparetime.Format = 'd-MMMM-yyyy HH:mm:ss';
                comparetime.TimeZone = '';

                if comparetime == scenariostart && aircraftobj.Connection.Connected == false % If connected at start and table not added

                    % Make connection
                    aircraftobj.Connection.Connected = true;
                    aircraftobj.Connection.sat = accessobj.Intervals.Source(row);
                    aircraftobj.Connection.index = row;
                    aircraftobj.Connection.number = aircraftobj.Connection.number+1;
                    aircraftobj.Connection.vectornum = aircraftobj.Connection.vectornum+1;

                    % Table stuff
                    connecttime = timevector(row);
                    connecttime.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
                    connecttime.TimeZone = '';
                    selectiveaccess(1, [1 2 4]) = {accessobj.Intervals.Source(row), connecttime, accessobj.Intervals.FSPL(row)};

                elseif comparetime == scenariostart && aircraftobj.Connection.Connected == true % If multiple connections at start
                    if accessobj.Intervals.FSPL(row) < accessobj.Intervals.FSPL(aircraftobj.Connection.index) % And if connection of new one is better than old, replace

                    % Connection
                    aircraftobj.Connection.Connected = true;
                    aircraftobj.Connection.sat = accessobj.Intervals.Source(row);
                    aircraftobj.Connection.index = row;
                    aircraftobj.Connection.number = aircraftobj.Connection.number+1;
                    aircraftobj.Connection.vectornum = aircraftobj.Connection.vectornum+1;

                    % Table stuff
                    connecttime = datetime(timevector(row));
                    connecttime.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
                    connecttime.TimeZone = '';
                    selectiveaccess(aircraftobj.Connection.vectornum, [1 2 4]) = {accessobj.Intervals.Source(row), connecttime, accessobj.Intervals.FSPL(row)};
                    end
                end % Otherwise keep connected
                break
            end
        end % Exit start of sim section

        if aircraftobj.Connection.Connected == true % If connected
            currenttime = timevector(timeindex);
            connectionendtime = accessobj.Intervals.EndTime(aircraftobj.Connection.index);
            connectionendtime.Format = 'd-MMMM-yyyy HH:mm:ss';
            connectionendtime.TimeZone = '';
            
            for row = 1:size(accessobj.Intervals.StartTime, 1)
                satstart = accessobj.Intervals.StartTime(row);
                satstart.Format = 'd-MMMM-yyyy HH:mm:ss';
                satstart.TimeZone = '';

                satend = accessobj.Intervals.EndTime(row);
                satend.Format = 'd-MMMM-yyyy HH:mm:ss';
                satend.TimeZone = '';
                intime = isbetween(currenttime, satstart, satend); 
                
                if intime == true && currenttime ~= connectionendtime % If another sat is within time range
                    if accessobj.Intervals.FSPL(row) < accessobj.Intervals.FSPL(aircraftobj.Connection.index) % Check if lower FSPL

                        % Disconnect from old one
                        selectiveaccess(aircraftobj.Connection.vectornum, 3) = {currenttime};
                        aircraftobj.Connection.Connected = false;
                        aircraftobj.Connection.sat = '';
                        aircraftobj.Connection.index = '';

                        % Connection to new one
                        aircraftobj.Connection.Connected = true;
                        aircraftobj.Connection.sat = accessobj.Intervals.Source(row);
                        aircraftobj.Connection.index = row;
                        aircraftobj.Connection.number = aircraftobj.Connection.number+1;
                        aircraftobj.Connection.vectornum = aircraftobj.Connection.vectornum+1;
                        
                        % Table stuff
                        connecttime = currenttime;
                        connecttime.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
                        connecttime.TimeZone = '';
                        selectiveaccess(aircraftobj.Connection.vectornum, [1 2 4]) = {accessobj.Intervals.Source(row), connecttime, accessobj.Intervals.FSPL(row)};
                    end

                elseif currenttime == connectionendtime % If none, check if we disconnect from current one yet
                    selectiveaccess(aircraftobj.Connection.vectornum, 3) = {currenttime};
                    aircraftobj.Connection.Connected = false;
                    aircraftobj.Connection.sat = '';
                    aircraftobj.Connection.index = '';
                end
            end
        else % If not connected
            currenttime = timevector(timeindex);
            for row = 1:size(accessobj.Intervals.StartTime, 1)
                satstart = accessobj.Intervals.StartTime(row);
                satstart.Format = 'd-MMMM-yyyy HH:mm:ss';
                satstart.TimeZone = '';

                satend = accessobj.Intervals.EndTime(row);
                satend.Format = 'd-MMMM-yyyy HH:mm:ss';
                satend.TimeZone = '';
                intime = isbetween(currenttime, satstart, satend); 

                if intime == true % If a sat is within time range
                    % Connection
                    aircraftobj.Connection.Connected = true;
                    aircraftobj.Connection.sat = accessobj.Intervals.Source(row);
                    aircraftobj.Connection.index = row;
                    aircraftobj.Connection.vectornum = aircraftobj.Connection.vectornum+1;
                    
                    % Table stuff
                    connecttime = currenttime;
                    connecttime.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
                    connecttime.TimeZone = '';
                    selectiveaccess(aircraftobj.Connection.vectornum, [1 2 4]) = {accessobj.Intervals.Source(row), connecttime, accessobj.Intervals.FSPL(row)};
                end
            end
        end % End the if connected
        
    end % End run through
    
    % Cleanup
    selectiveaccess = rmmissing(selectiveaccess);
end