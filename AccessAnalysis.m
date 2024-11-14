function [accessout, aircraftout, constellationout, selectiveout] = AccessAnalysis(scenario)
    % Aircraft/constellation making
    % aircraft = create_sim_airport(starting, 3); % For airport stuff
    scenario.scenario.AutoSimulate = true;
    aircraftout = create_mission(scenario, scenario.scenario.StartTime, 3, 53.31, -113.58, 45.32, -75.67); % For testing
    constellationout = walker_constellation_v2(scenario.scenario, 72, 6, 1, 750, 70, 'star');

    % Access stuff
    accessfirst = Access_AnalysisTable(constellationout, aircraftout);
    accessout = accessFSPL(scenario, constellationout, aircraftout, accessfirst, 0.125);
    fix_table(accessout);

    selectiveout = streamlinedaccess(scenario, accessout, aircraftout);
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

    aircraftout.Connection.Connected = false;
    aircraftout.Connection.sat = '';
    aircraftout.Connection.index = 0;
    aircraftout.Connection.number = 0;
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
    accessAnalysisTable.obj.LineColor = "#00FF00";
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
    for index = 1:size(accessobj.Intervals.Source, 1)
        strippedsat = split(accessobj.Intervals.Source(index, 1), '_'); % Get satellite number
        satnum = str2double(strippedsat(2));
        
        % Calculate FSPL for each row in access table
        indexFSPL = calculateFSPL(scenario.scenario.Satellites(1, satnum+1), aircraftobj.obj, accessobj.Intervals.StartTime(index), accessobj.Intervals.EndTime(index), 10, lambda);
        meanFSPL = mean(indexFSPL, "all"); % Take average
        accessout.Intervals.FSPL(index, 1) = meanFSPL; % Add average to access table
    end
end

function streamlined = streamlinedaccess(scenario,accessobj,aircraft)
    % Vars needed
    connectedaccessrow = 1;
    connected = false;
    tablerow = 1;

    % Getting current and end time
    scenariostart = scenario.scenario.StartTime;
    scenariostart.Format = 'd-MMMM-yyyy HH:mm:ss';
    scenariostart.TimeZone = '';
    scenarioend = scenario.scenario.StopTime;
    scenarioend.Format = 'd-MMMM-yyyy HH:mm:ss';
    scenarioend.TimeZone = '';

    timevector = scenariostart:minutes(1):scenarioend;
    vectorsize = size(timevector, 2);

    streamlined = table('Size',[vectorsize 4], 'VariableTypes', {'string', 'datetime', 'datetime', 'double'}, 'VariableNames',{'Satellite', 'Connection Start', 'Connection End', 'FSPL'});

    % Start of Sim
    starttime = accessobj.Intervals.StartTime(connectedaccessrow);
    starttime.TimeZone = '';
    starttime.Format = 'd-MMMM-yyyy HH:mm:ss';
    streamlined(tablerow, [1, 2, 4]) = {accessobj.Intervals.Source(connectedaccessrow), starttime, accessobj.Intervals.FSPL(connectedaccessrow)};
    connected = true;

    for vectorindex = 1:vectorsize % For each minute
        currenttime = timevector(vectorindex);
        currenttime.Format = 'd-MMMM-yyyy HH:mm:ss';
        currenttime.TimeZone = '';

        connectedsatend = accessobj.Intervals.EndTime(connectedaccessrow);
        connectedsatend.Format = 'd-MMMM-yyyy HH:mm:ss';
        connectedsatend.TimeZone = '';

        if currenttime == connectedsatend % If already connected sat ends
            connected = false;
            streamlined(tablerow, 3) = {currenttime};
        end

        if connected % If connected
            for rownumber = connectedaccessrow:size(accessobj.Intervals.Source,1)
                % Get sat connection times
                satstart = accessobj.Intervals.StartTime(rownumber);
                satstart.Format = 'd-MMMM-yyyy HH:mm:ss';
                satstart.TimeZone = '';
    
                satend = accessobj.Intervals.EndTime(rownumber);
                satend.Format = 'd-MMMM-yyyy HH:mm:ss';
                satend.TimeZone = '';
    
                intime = isbetween(currenttime, satstart, satend);
    
                if intime % If theres a sat within range at the time
                    if accessobj.Intervals.FSPL(rownumber) < accessobj.Intervals.FSPL(connectedaccessrow) % If better FSPL
                        % Disconnect from old
                        streamlined(tablerow, 3) = {currenttime};
                        
                        % Connect to new
                        tablerow = tablerow + 1;
                        connectedaccessrow = rownumber;
                        streamlined(tablerow, [1, 2, 4]) = {accessobj.Intervals.Source(connectedaccessrow), currenttime, accessobj.Intervals.FSPL(connectedaccessrow)};
                    end
                end        
            end

            
        % If not connected
        elseif connected == false
            for nonconnectedindex = connectedaccessrow+1:size(accessobj.Intervals.Source,1)
                satstart = accessobj.Intervals.StartTime(nonconnectedindex);
                satstart.Format = 'd-MMMM-yyyy HH:mm:ss';
                satstart.TimeZone = '';
        
                satend = accessobj.Intervals.EndTime(nonconnectedindex);
                satend.Format = 'd-MMMM-yyyy HH:mm:ss';
                satend.TimeZone = '';
        
                intime = isbetween(currenttime, satstart, satend);
                reconnected = false;
        
                if intime % If there's a sat in range at the time
                    if reconnected == false % If we haven't already reconnected
                        tablerow = tablerow + 1;
                        connectedaccessrow = nonconnectedindex;
                        accessobj.Intervals.Source(connectedaccessrow);
                        streamlined(tablerow, [1, 2, 4]) = {accessobj.Intervals.Source(connectedaccessrow), currenttime, accessobj.Intervals.FSPL(connectedaccessrow)};
                        connected = true;
                        reconnected = true;
                    
                    elseif reconnected == true % If we did reconnect, multiple sats in range
                        if accessobj.Intervals.FSPL(nonconnectedindex) < accessobj.Intervals.FSPL(connectedaccessrow) % If better FSPL
                        % Disconnect from old
                        streamlined(tablerow, 3) = {currenttime};
                        
                        % Connect to new
                        tablerow = tablerow + 1;
                        connectedaccessrow = nonconnectedindex;
                        streamlined(tablerow, [1, 2, 4]) = {accessobj.Intervals.Source(connectedaccessrow), currenttime, accessobj.Intervals.FSPL(connectedaccessrow)};
                        end
                    end
                end
            end
        end
    end
    % Cleaning up
    streamlined = rmmissing(streamlined);
end