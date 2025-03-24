function aircraftout = create_mission(satscenario, startdate, flightduration, startlat, startlong, endlat, endlong)
    % Create flight
    missionout.StartDate = startdate;
    missionout.Duration = hours(flightduration); %#ok<*STRNU>
    pathing = flight_pathing(flightduration, startlat, startlong, endlat, endlong, satscenario);
    m = matfile('trajectory.mat','Writable',true);
    m.trajectory = pathing;
    aircraftout = load("trajectory.mat", "trajectory");
    % geoplot(aircraftout.trajectory.LLA(:,1), aircraftout.trajectory.LLA(:,2), "b-");
    % geolimits([30 50],[-110 -50]);
    
    % Create Mission
    aircraftout.obj = satellite(satscenario.scenario, aircraftout.trajectory, CoordinateFrame="geographic", Name="Aircraft");
    aircraftout.obj.MarkerColor = "green";
    hide(aircraftout.obj.Orbit);
    show(aircraftout.obj.GroundTrack);

    aircraftout.Connection.Connected = false;
    aircraftout.Connection.sat = '';
    aircraftout.Connection.index = 0;
    aircraftout.Connection.number = 0;
end

function flight_path = flight_pathing(flightduration, startlat, startlong, endlat, endlong, scenario)

    mission.StartDate = datetime;

    
    start.Lat = startlat; % Starting Latitude
    start.Long = startlong; % Starting Longitude
    
    ending.Lat = endlat; % Ending Latitude
    ending.Long = endlong; % Ending Longitude
    
    traj.Lat = ending.Lat - start.Lat; % Determine change in Latitude
    traj.Long = ending.Long - start.Long; % Determine change in Longitude
    
    durationseconds = seconds(flightduration); % Convert duration into seconds
    numsamples = durationseconds / scenario.scenario.SampleTime; % Convert to sample count
    
    flight.Latdelta = traj.Lat/numsamples;
    flight.Longdelta = traj.Long/numsamples;
    
    moment.Missiontime = 0;
    moment.Lat = start.Lat;
    moment.Long = start.Long;
    
    matObj = matfile("trajectory.mat");
    m = matfile('trajectory.mat','Writable',true);
    flighttime = timetable(TimeStep=seconds(scenario.scenario.SampleTime));
    trajtime = createArray(numsamples+1,3);
    
    for i = 1:numsamples+1
        trajtime(i,1) = moment.Lat;
        trajtime(i,2) = moment.Long;
        trajtime(i,3) = 10000;
        moment.Lat = moment.Lat + flight.Latdelta;
        moment.Long = moment.Long + flight.Longdelta;
    end
    
    flighttime.LLA = trajtime;
    flight_path = flighttime;
end