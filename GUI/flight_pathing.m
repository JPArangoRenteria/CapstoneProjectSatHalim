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
    % m.trajectory = flighttime;
    flight_path = flighttime;
end
