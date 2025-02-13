function [sc, scenario, accumulatedTable,connectionsTable] = network_with_shortest_path( ...
    start_y, start_mon, start_d, start_h, start_min, start_s, ...
    stop_y, stop_mon, stop_d, stop_h, stop_min, stop_s, stepping_u, ...
    numSatellites, numPlanes, relativeSpacing, altitude, inclination, ...
    walker_type, filename, source, target,routing_step)
    % Create the scenario and constellation
    [sc, scenario] = walker_constellation(start_y, start_mon, start_d, start_h, start_min, start_s, ...
        stop_y, stop_mon, stop_d, stop_h, stop_min, stop_s, stepping_u, ...
        numSatellites, numPlanes, relativeSpacing, altitude, inclination, walker_type);
    
    sats = scenario.Satellites; % Satellites in the scenario
    GS = groundstations(filename, scenario); % Ground stations from the input file
    %disp(sats(1).Name)
    %disp(GS(1).GroundStationObj.Name)
    % Create mappings for nodes
    nodeMapping = createNodeMapping(sats, GS);
    reverseMapping = createReverseMapping(sats, GS);
    %disp(nodeMapping)
    % Define time parameters
    totalTime = scenario.StopTime - scenario.StartTime;
    timeStep = routing_step; % Seconds per step
    numTimeSteps = floor(seconds(totalTime) / timeStep);
    try
        switch st_types
            case 0  % Satellite to Satellite
                src = nodeMapping.Satellites{source};
                tgt = nodeMapping.Satellites{target};
            case 1  % Ground Station to Ground Station
                src = nodeMapping.GroundStations{source(1)};
                tgt = nodeMapping.GroundStations{target(1)};
            case 2  % Ground Station to Satellite
                src = nodeMapping.GroundStations{source(1)};
                tgt = nodeMapping.Satellites{target};
            case 3  % Satellite to Ground Station
                src = nodeMapping.Satellites{source};
                tgt = nodeMapping.GroundStations{target(1)};
            otherwise % Default Ground Station to Ground Station
                src = nodeMapping.GroundStations{source(1)};
                tgt = nodeMapping.GroundStations{target(1)};
        end
    catch
        warning('Invalid source/target selection. Please check inputs.');
    end
    % Initialize results
    accumulatedPaths = cell(numTimeSteps, 1);
    accumulatedDistances = NaN(numTimeSteps, 1);
    timeIntervals = NaT(numTimeSteps, 1);
    
    % Loop through time steps
    for t = 1:numTimeSteps
        currentTime = scenario.StartTime + seconds(t * timeStep);
        currentTime.TimeZone = ''; % Ensure no time zone mismatch

        % Create the connections table for the current time
        connectionsTable = createConnectionsTable(sats, GS, numSatellites, numPlanes, currentTime);

        % Build a graph from the connections table
        %disp(connectionsTable.Source);
        %disp(connectionsTable.Target);
        %idx = (connectionsTable.Time == currentTime);
        %filteredTable = connectionsTable(idx, :);
        %G = graph(filteredTable.Source, filteredTable.Target, filteredTable.Weight);
        G = graph(connectionsTable.Source, connectionsTable.Target, connectionsTable.Weight);
        %disp(G.Edges)
        %disp(G.Nodes)
        % Determine the correct source and target indices
        % try
        %     switch st_types
        %         case 0  % Satellite to Satellite
        %             src = nodeMapping.Satellites{source};
        %             tgt = nodeMapping.Satellites{target};
        %         case 1  % Ground Station to Ground Station
        %             src = nodeMapping.GroundStations{source(1)};
        %             tgt = nodeMapping.GroundStations{target(1)};
        %         case 2  % Ground Station to Satellite
        %             src = nodeMapping.GroundStations{source(1)};
        %             tgt = nodeMapping.Satellites{target};
        %         case 3  % Satellite to Ground Station
        %             src = nodeMapping.Satellites{source};
        %             tgt = nodeMapping.GroundStations{target(1)};
        %         otherwise % Default Ground Station to Ground Station
        %             src = nodeMapping.GroundStations{source(1)};
        %             tgt = nodeMapping.GroundStations{target(1)};
        %     end
        % catch
        %     warning('Invalid source/target selection. Please check inputs.');
        %     continue;
        % end
        %disp(src)
        %disp(tgt)
        % Compute the shortest path
        %[path, dist] = shortestpath(G, src, tgt);
        try
            [path, dist] = shortestpath(G, src, tgt);
        catch ME
            if contains(ME.message, 'Graph does not contain a node named')
                fprintf('Error: One or both of the specified nodes do not exist in the graph.\n');
                path = [];
                dist = Inf;
            else
                rethrow(ME); % Rethrow unexpected errors
            end
        end

        %disp([path, dist]);
        disp(path)

        % Store results
        accumulatedPaths{t} = path;
        accumulatedDistances(t) = dist;
        timeIntervals(t) = currentTime;
    end

    % Create a table with the results
    accumulatedTable = table(timeIntervals, accumulatedPaths, accumulatedDistances, ...
        'VariableNames', {'TimeInterval', 'Path', 'Weight'});
    numSatellitesPerPlane = numSatellites / numPlanes;
    % Add visualization of links in the main function
    for plane = 1:numPlanes
        for sat = 1:numSatellitesPerPlane
            currentIndex = (plane - 1) * numSatellitesPerPlane + sat;
            % Connect to "right" neighbor (next satellite in the same plane)
            if sat < numSatellitesPerPlane
                rightNeighborIndex = currentIndex + 1;
                link = access(sats(currentIndex), sats(rightNeighborIndex));
                if isPartOfShortestPath(sats(currentIndex).Name, sats(rightNeighborIndex).Name, accumulatedPaths, src,tgt)
                    link.LineColor = [0.5, 0, 0.5]; % Purple
                end
            end

            % Connect to "left" neighbor (previous satellite in the same plane)
            if sat > 1
                leftNeighborIndex = currentIndex - 1;
                link = access(sats(currentIndex), sats(leftNeighborIndex));
                if isPartOfShortestPath(sats(currentIndex).Name, sats(leftNeighborIndex).Name, accumulatedPaths, src,tgt)
                    link.LineColor = [0.5, 0, 0.5]; % Purple
                end
            end

            % Connect to "up" neighbor (satellite in the next plane, same position)
            if plane < numPlanes
                upNeighborIndex = currentIndex + numSatellitesPerPlane;
                link = access(sats(currentIndex), sats(upNeighborIndex));
                if isPartOfShortestPath(sats(currentIndex).Name, sats(upNeighborIndex).Name, accumulatedPaths, src,tgt)
                    link.LineColor = [0.5, 0, 0.5]; % Purple
                end
            end

            % Connect to "down" neighbor (satellite in the previous plane, same position)
            if plane > 1
                downNeighborIndex = currentIndex - numSatellitesPerPlane;
                link = access(sats(currentIndex), sats(downNeighborIndex));
                if isPartOfShortestPath(sats(currentIndex).Name, sats(downNeighborIndex).Name, accumulatedPaths, src,tgt)
                    link.LineColor = [0.5, 0, 0.5]; % Purple
                end
            end
        end
    end

    for g = 1:numel(GS)
        gsName = GS(g).GroundStationObj.Name;
        for s = 1:numSatellites
            link = access(GS(g).GroundStationObj, sats(s));
            satName = sats(s).Name;
            %gsIndex = nodeMapping.GroundStations(g);
            %satIndex = nodeMapping.Satellites(s);
            if isPartOfShortestPath(gsName,satName, accumulatedPaths, src,tgt)
                link.LineColor = [0.5, 0, 0.5]; % Purple
            end
        end
    end
end



function isInPath = isPartOfShortestPath(source, target, paths, check1, check2)
    isInPath = false;

    % Iterate through all paths stored in `paths`
    for i = 1:numel(paths)
        path = paths{i}; % Extract path (should be a cell array of strings)
        
        % Reset flags for each path
        flag1 = false;
        flag2 = false;
        flag3 = false;
        flag4 = false;

        % Check if the source and target are in the path
        for j = 1:length(path)
            if strcmp(path{j}, source)
                flag1 = true;
            end
            if strcmp(path{j}, check1)
                flag2 = true;
            end
            if strcmp(path{j}, check2)
                flag3 = true;
            end
            if strcmp(path{j}, target)
                flag4 = true;
            end
        end

        % If both check1 and check2 are in the path, and either source or target is in the path
        if flag2 && flag3 && (flag1 && flag4)
            isInPath = true;
            break; % Exit early if the condition is met
        end
    end
end

%% Function to map nodes to indices
function nodeMapping = createNodeMapping(constellation, groundStations)
    %nodeMapping = struct('GroundStations', [], 'Satellites', []);
    nodeMapping = struct('GroundStations', {{}}, 'Satellites', {{}});
    for i = 1:numel(groundStations)
        %nodeMapping.GroundStations(i) = i;
        nodeMapping.GroundStations{i}= groundStations(i).GroundStationObj.Name;
    end
    for i = 1:numel(constellation)
        %nodeMapping.Satellites(i) = numel(groundStations) + i;
        nodeMapping.Satellites{i} = constellation(i).Name;
    end
end

function reverseMapping = createReverseMapping(constellation, groundStations)
    reverseMapping = struct();
    for i = 1:numel(groundStations)
        reverseMapping(i).Type = 'GroundStation';
        reverseMapping(i).Object = groundStations(i);
    end
    for i = 1:numel(constellation)
        idx = numel(groundStations) + i;
        reverseMapping(idx).Type = 'Satellite';
        reverseMapping(idx).Object = constellation(i);
    end
end
%% Function to create the connections table
function connectionsTable = createConnectionsTable(sats, GS, numSatellites, numPlanes, time)
    c = 3e8; % Speed of light (m/s)
    numSatellitesPerPlane = numSatellites / numPlanes;
    connectionsCell = {}; % Store connections as cell array

    % Satellite-to-satellite connections
    for plane = 1:numPlanes
        for sat = 1:numSatellitesPerPlane
            currentIndex = (plane - 1) * numSatellitesPerPlane + sat;
            satName = sats(currentIndex).Name;
            % Right neighbor
            if sat < numSatellitesPerPlane
                rightNeighborIndex = currentIndex + 1;
                delay = calculateDelay(sats(currentIndex), sats(rightNeighborIndex), time, c);
                if delay > 0
                    if hasAccess(sats(currentIndex), sats(rightNeighborIndex), time,0);
                        connectionsCell = [connectionsCell; {satName, sats(rightNeighborIndex).Name, delay, time}];
                    end
                    %connectionsCell = [connectionsCell; {satName, sats(rightNeighborIndex).Name, delay,time}];
                end
            end

            % Left neighbor
            if sat > 1
                leftNeighborIndex = currentIndex - 1;
                delay = calculateDelay(sats(currentIndex), sats(leftNeighborIndex), time, c);
                if delay > 0
                    if hasAccess(sats(currentIndex), sats(leftNeighborIndex), time,0);
                        connectionsCell = [connectionsCell; {satName, sats(leftNeighborIndex).Name, delay, time}];
                    end
                    %connectionsCell = [connectionsCell; {satName, sats(leftNeighborIndex).Name, delay,time}];
                end
            end

            % Up neighbor
            if plane < numPlanes
                UpNeighborIndex = currentIndex + numSatellitesPerPlane;
                delay = calculateDelay(sats(currentIndex), sats(UpNeighborIndex), time, c);
                if delay > 0
                    if hasAccess(sats(currentIndex), sats(UpNeighborIndex), time,0);
                        connectionsCell = [connectionsCell; {satName, sats(UpNeighborIndex).Name, delay, time}];
                    end
                end
            end

            % Down neighbor
            if plane > 1
                downNeighborIndex = currentIndex - numSatellitesPerPlane;
                if downNeighborIndex > 0
                    delay = calculateDelay(sats(currentIndex), sats(downNeighborIndex), time, c);
                    if delay > 0
                        if hasAccess(sats(currentIndex), sats(downNeighborIndex), time,0);
                            connectionsCell = [connectionsCell; {satName, sats(downNeighborIndex).Name, delay, time}];
                        end
                    end
                end
            end
        end
    end

    % Satellite-to-ground station connections
    for g = 1:numel(GS)
        gsName = GS(g).GroundStationObj.Name;
        for s = 1:numSatellites
            satName = sats(s).Name;
            %disp(satName)
            %disp(gsName)
            delay = calculateDelay(GS(g).GroundStationObj, sats(s), time, c);
            if delay > 0
                if hasAccess(GS(g).GroundStationObj, sats(s), time,0);
                    connectionsCell = [connectionsCell; {gsName, satName, delay,time}];
                    %connectionsCell = [connectionsCell; {g, s, delay}];
                end
            end
        end
    end

    % Convert the cell array to a table including the time column
    connectionsTable = cell2table(connectionsCell, 'VariableNames', {'Source', 'Target', 'Weight', 'Time'});
end


% Function to calculate delay
function delay = calculateDelay(obj1, obj2, time, c)
    distance = calculateDistance(obj1, obj2, time);
    delay = distance / c; % Delay in seconds
end

% Function to calculate distance
function distance = calculateDistance(obj1, obj2, time)
    if isa(obj1, 'matlabshared.satellitescenario.Satellite')
        [pos1, ~] = states(obj1, time, "CoordinateFrame", "geographic");
    elseif isa(obj1, 'matlabshared.satellitescenario.GroundStation')
        pos1 = [obj1.Latitude, obj1.Longitude, obj1.Altitude];
    else
        error('Unsupported object type for obj1.');
    end

    if isa(obj2, 'matlabshared.satellitescenario.Satellite')
        [pos2, ~] = states(obj2, time, "CoordinateFrame", "geographic");
    elseif isa(obj2, 'matlabshared.satellitescenario.GroundStation')
        pos2 = [obj2.Latitude, obj2.Longitude, obj2.Altitude];
    else
        error('Unsupported object type for obj2.');
    end

    % Euclidean distance
    distance = norm(pos1 - pos2);
end
function access = hasAccess(obj1, obj2, time, elevationThreshold)
% hasAccess Determine whether two objects have an unobstructed access link.
%
%   access = hasAccess(obj1, obj2, time) returns true if a line-of-sight access
%   link exists between obj1 and obj2 at the specified time. The objects can be 
%   either matlabshared.satellitescenario.Satellite or 
%   matlabshared.satellitescenario.GroundStation.
%
%   access = hasAccess(obj1, obj2, time, elevationThreshold) uses the specified
%   elevation threshold (in degrees) for links involving a ground station.
%
%   For a ground station–satellite link, the function checks that the computed
%   elevation exceeds the threshold. For satellite–satellite (or non-ground)
%   links, it computes the minimum distance from the line segment connecting the
%   satellites to Earth's center and declares an access link if that distance is
%   greater than the effective Earth radius.
%
%   This version uses a custom geodetic-to-ECEF conversion function that does
%   not require the Mapping Toolbox.

    if nargin < 4
        elevationThreshold = 0; % Default threshold: 0° (satellite above horizon)
    end

    % Get geographic positions: [latitude (deg), longitude (deg), altitude (m)]
    pos1 = getGeographicPosition(obj1, time);
    pos2 = getGeographicPosition(obj2, time);

    % Convert to ECEF coordinates using WGS84 parameters
    ecef1 = geodetic2ecef_wgs84(pos1(1), pos1(2), pos1(3));
    ecef2 = geodetic2ecef_wgs84(pos2(1), pos2(2), pos2(3));

    % If one of the objects is a ground station, use the elevation-angle test.
    if isa(obj1, 'matlabshared.satellitescenario.GroundStation') || ...
       isa(obj2, 'matlabshared.satellitescenario.GroundStation')
        % Identify which object is the ground station.
        if isa(obj1, 'matlabshared.satellitescenario.GroundStation')
            gsPos = ecef1;
            satPos = ecef2;
        else
            gsPos = ecef2;
            satPos = ecef1;
        end

        % Compute the local up vector at the ground station.
        up = gsPos / norm(gsPos);
        % Compute the line-of-sight (LOS) vector from the ground station to the satellite.
        los = satPos - gsPos;
        losUnit = los / norm(los);
        % Compute the elevation angle (in degrees).
        elevation = asind(dot(losUnit, up));
        % Access exists if the elevation meets or exceeds the threshold.
        access = (elevation >= elevationThreshold);
    else
        % Both objects are satellites (or non-ground objects). Use a refined geometric
        % test that ensures we check the line segment (not the infinite line).
        
        % Vector from satellite 1 to satellite 2.
        d = ecef2 - ecef1;
        d_norm2 = norm(d)^2;
        % Compute the parameter 't' for the closest approach on the infinite line.
        % The parametric line is: r(t) = ecef1 + t*d, with t in [0,1] representing the segment.
        t = -dot(ecef1, d) / d_norm2;
        
        if t >= 0 && t <= 1
            % The closest point on the infinite line lies within the segment.
            % This is the standard cross-product formula.
            d_min = norm(cross(ecef1, ecef2)) / norm(d);
        else
            % If the closest point is not on the segment, use the smaller distance
            % from Earth’s center to one of the endpoints.
            d_min = min(norm(ecef1), norm(ecef2));
        end
        
        % Define the effective Earth radius (in meters). You might adjust this value
        % or introduce a margin if you wish.
        d_sat = norm(ecef2 - ecef1); % Direct distance between satellites
        maxRange = 3000000;
        R_E = 6371000;
        %access = (d_min > R_E) || (d_sat < maxRange);
        access = (d_sat < maxRange * 1.5) || ((d_sat < maxRange) && (d_min > R_E));

    end
end

function pos = getGeographicPosition(obj, time)
% getGeographicPosition Returns the geographic position [lat, lon, alt] of an object.
%
%   For a Satellite, the function calls states() to get the position in the 
%   "geographic" coordinate frame. For a Ground Station, it reads the properties
%   Latitude, Longitude, and Altitude.
%
    if isa(obj, 'matlabshared.satellitescenario.Satellite')
        [pos, ~] = states(obj, time, "CoordinateFrame", "geographic");
    elseif isa(obj, 'matlabshared.satellitescenario.GroundStation')
        pos = [obj.Latitude, obj.Longitude, obj.Altitude];
    else
        error('Unsupported object type for %s.', inputname(1));
    end
end

function ecef = geodetic2ecef_wgs84(lat, lon, alt)
% geodetic2ecef_wgs84 Convert geodetic coordinates to ECEF coordinates using WGS84.
%
%   ecef = geodetic2ecef_wgs84(lat, lon, alt) converts latitude (deg), 
%   longitude (deg), and altitude (m) to Earth-Centered Earth-Fixed (ECEF)
%   coordinates (m) using the WGS84 ellipsoid parameters.
%
%   WGS84 parameters:
%       a = 6378137.0 (semi-major axis in meters)
%       f = 1/298.257223563 (flattening)
%
%   The formulas are:
%       N = a / sqrt(1 - e2 * sin(lat)^2)
%       x = (N + alt) * cos(lat) * cos(lon)
%       y = (N + alt) * cos(lat) * sin(lon)
%       z = ((1 - e2) * N + alt) * sin(lat)
%
%   Note: lat and lon must be in degrees. They are converted to radians
%   inside the function.

    % Convert degrees to radians.
    latRad = deg2rad(lat);
    lonRad = deg2rad(lon);
    
    % WGS84 ellipsoid parameters.
    a = 6378137.0;                    % Semi-major axis in meters.
    f = 1 / 298.257223563;            % Flattening.
    e2 = 2*f - f^2;                   % Square of eccentricity.
    
    % Compute the radius of curvature in the prime vertical.
    N = a ./ sqrt(1 - e2 * sin(latRad).^2);
    
    % Compute ECEF coordinates.
    x = (N + alt) .* cos(latRad) .* cos(lonRad);
    y = (N + alt) .* cos(latRad) .* sin(lonRad);
    z = ((1 - e2) * N + alt) .* sin(latRad);
    
    ecef = [x, y, z];
end

