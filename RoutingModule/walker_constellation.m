function [sc,scenario] = walker_constellation(start_y, start_mon, start_d, start_h, start_min, start_s, ...
                                   stop_y, stop_mon, stop_d, stop_h, stop_min, stop_s, stepping_u, ...
                                   numSatellites, numPlanes, relativeSpacing, altitude, inclination, ...
                                   walker_type)
    % Earth's radius in kilometers
    EarthRadius = 6378.14; % in kilometers

    % Convert altitude to radius from Earth's center in meters
    radius = (EarthRadius + altitude) * 1000; % Convert to meters
    % Define start and stop times
    startTime = datetime(start_y, start_mon, start_d, start_h, start_min, start_s);
    stopTime = datetime(stop_y, stop_mon, stop_d, stop_h, stop_min, stop_s);

    % Create satellite scenario
    scenario = satelliteScenario(startTime, stopTime, stepping_u);

    % Generate Walker constellation based on inclination
    if strcmp(walker_type,'delta') == 1
        % Use walkerDelta for non-polar orbits (inclination < 90 degrees)
        sc = walkerDelta(scenario,radius,inclination,numSatellites,numPlanes,relativeSpacing);
    elseif strcmp(walker_type,'star') == 1
        % Use walkerStar for polar orbits (inclination = 90 degrees)
        sc = walkerStar(scenario,radius,inclination,numSatellites,numPlanes,relativeSpacing);
    else
        % walkerDelta for retrograde orbits (inclination > 90 degrees)
        sc = walkerStar(scenario,radius,inclination,numSatellites,numPlanes,relativeSpacing);
    end
    
    % Visualize the satellite scenario
    %satelliteScenarioViewer(scenario);
end
