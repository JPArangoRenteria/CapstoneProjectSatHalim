function accessout = AccessAnalysis(scenario)
    % Aircraft/constellation making
    % aircraft = create_sim_airport(starting, 3); % For airport stuff
    aircraft = create_mission(scenario1, starting, 3, 53.31, -113.58, 45.32, -75.67); % For testing
    constellation = create_satellite(scenario1, 7200000, 70, 12, 4, 1, 15);
    
    % Access stuff
    accessanalysistest = Access_AnalysisTable(constellation, aircraft);
    updatedaccess = accessFSPL(constellation, aircraft, accessanalysistest, 0.125)
    fix_table(updatedaccess);
end

function scenarioout = create_scenario(startdate, duration, steptime)
    time = hours(duration);
    scenarioout.scenario = satelliteScenario(startdate, startdate+time, steptime);
    scenarioout.viewer = satelliteScenarioViewer(scenarioout.scenario);
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
    aircraftout = load("trajectory.mat", "trajectory"); % Created using flight_pathing.mlx
    geoplot(aircraftout.trajectory.LLA(:,1), aircraftout.trajectory.LLA(:,2), "b-");
    geolimits([30 50],[-110 -50]);
    
    % Create Mission
    aircraftout.obj = satellite(satscenario.scenario,aircraftout.trajectory, CoordinateFrame="geographic", Name="Aircraft");
    aircraftout.obj.MarkerColor = "green";
    hide(aircraftout.obj.Orbit);
    show(aircraftout.obj.GroundTrack);
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
    startairportcode = string(table2array(start_airport_list(startairportindex, 2)))
    startairportname = string(table2array(start_airport_list(startairportindex, 3)))
    startlat = table2array(start_airport_list(startairportindex, 4))
    startlong = table2array(start_airport_list(startairportindex, 5))


    % Get end country
    [endcountryindex, tf] = listdlg('ListString', countrycode_list, 'SelectionMode','single');
    endcountry = string(countrycode_list(endcountryindex));
    end_airport_list = airports(ismember(airports.country_code, endcountry), :);

    % Get end airport
    end_airport_names_list = table2cell([end_airport_list(:, [2 3])]);
    [endairportindex, tf] = listdlg('ListString', end_airport_names_list(:, 2), 'SelectionMode','single');

    % End airport information
    endairportcode = string(table2array(end_airport_list(endairportindex, 2)))
    endairportname = string(table2array(end_airport_list(endairportindex, 3)))
    endlat = table2array(end_airport_list(endairportindex, 4))
    endlong = table2array(end_airport_list(endairportindex, 5))

    aircraftout = create_mission(starttime, duration, startlat, startlong, endlat, endlong);

end

function constellationout = create_satellite(missionin, radius, inclination, totalcount, planes, phasing, lat)
    % Establish values
    constellationout.Radius = radius;
    constellationout.Inclination = inclination;
    constellationout.TotalSatellites = totalcount;
    constellationout.GeometryPlanes = planes;
    constellationout.Phasing = phasing;
    constellationout.ArgLat = lat;

    % Create constellation
    constellationout.obj = walkerDelta(missionin.scenario, ...
    constellationout.Radius, ...
    constellationout.Inclination, ...
    constellationout.TotalSatellites, ...
    constellationout.GeometryPlanes, ...
    constellationout.Phasing, ...
    ArgumentOfLatitude=constellationout.ArgLat, ...
    Name="Satellite");
end


function accessAnalysisTable = Access_AnalysisTable(constellationobject, aircraftobject)
    accessAnalysisTable.obj = access(constellationobject.obj, aircraftobject.obj);
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

function accessout = accessFSPL(constellationobj, aircraftobj, accessobj, lambda)
    % Create output and add FSPL Table
    accessout = accessobj;
    FSPLColumn = zeros(height(accessobj.Intervals), 1);
    accessout.Intervals.("FSPL") = FSPLColumn;

    % Get each satellite times/connections
    for index = 1:size(accessobj.Intervals.Source)
        strippedsat = split(accessobj.Intervals.Source(index, 1), '_'); % Get satellite number
        satnum = str2num(strippedsat(2));
        
        % Calculate FSPL for each row in access table
        indexFSPL = calculateFSPL(constellationobj.obj(1, satnum), aircraftobj.obj, accessobj.Intervals.StartTime(satnum), accessobj.Intervals.EndTime(satnum), 10, lambda);
        meanFSPL = mean(indexFSPL, "all") % Take average
        accessout.Intervals.FSPL(index, 1) = meanFSPL; % Add average to access table
    end
    disp(accessout.Intervals)
end

