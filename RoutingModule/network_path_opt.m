function [sc, scenario, accumulatedTable, validLinks] = network_path_opt( ...
    start_y, start_mon, start_d, start_h, start_min, start_s, ...
    stop_y, stop_mon, stop_d, stop_h, stop_min, stop_s, stepping_u, ...
    numSatellites, numPlanes, relativeSpacing, altitude, inclination, ...
    walker_type, filename, source, target, st_types, routing_step)

    % Create the scenario and constellation
    [sc, scenario] = walker_constellation(start_y, start_mon, start_d, start_h, start_min, start_s, ...
        stop_y, stop_mon, stop_d, stop_h, stop_min, stop_s, stepping_u, ...
        numSatellites, numPlanes, relativeSpacing, altitude, inclination, walker_type);
    
    sats = scenario.Satellites; % Satellites in the scenario
    GS = groundstations(filename, scenario); % Ground stations from the input file
    
    % Create mappings for nodes
    nodeMapping = createNodeMapping(sats, GS);

    % Precompute access tables for faster routing
    accessTables = createAccessTables(sats, GS,numSatellites,numPlanes);

    % Define time parameters
    totalTime = scenario.StopTime - scenario.StartTime;
    timeStep = routing_step; % Seconds per step
    numTimeSteps = floor(seconds(totalTime) / timeStep);

    % Determine the source and target nodes
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

        % Use precomputed access table to get active connections
        validLinks = filterActiveLinks(accessTables, sats, GS, currentTime);
        G = graph(validLinks.Source, validLinks.Target, validLinks.Weight);

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

        % Store results
        accumulatedPaths{t} = path;
        accumulatedDistances(t) = dist;
        timeIntervals(t) = currentTime;
    end

    % Create a table with the results
    accumulatedTable = table(timeIntervals, accumulatedPaths, accumulatedDistances, ...
        'VariableNames', {'TimeInterval', 'Path', 'Weight'});

end

%% Function to Precompute Access Tables
function accessTables = createAccessTables(sats, GS,numSatellites,numPlanes)
    accessTables = struct();

    % Satellite-to-Satellite access
    % for i = 1:numel(sats)
    %     for j = i+1:numel(sats)
    %         accessObj = access(sats(i), sats(j)); % Create access object
    %         accessTables.SatSat{i, j} = accessIntervals(accessObj); % Store intervals
    %     end
    % end
    numSatellitesPerPlane = numSatellites / numPlanes; % Satellites per plane

    % Initialize access table structure
    accessTables.SatSat = cell(numel(sats), numel(sats));
    
    for plane = 1:numPlanes
        for sat = 1:numSatellitesPerPlane
            currentIndex = (plane - 1) * numSatellitesPerPlane + sat;
    
            % Connect to "right" neighbor (next satellite in the same plane)
            if sat < numSatellitesPerPlane
                rightNeighborIndex = currentIndex + 1;
                accessObj = access(sats(currentIndex), sats(rightNeighborIndex));
                accessTables.SatSat{currentIndex, rightNeighborIndex} = accessIntervals(accessObj);
            end
    
            % Connect to "left" neighbor (previous satellite in the same plane)
            if sat > 1
                leftNeighborIndex = currentIndex - 1;
                accessObj = access(sats(currentIndex), sats(leftNeighborIndex));
                accessTables.SatSat{currentIndex, leftNeighborIndex} = accessIntervals(accessObj);
            end
    
            % Connect to "up" neighbor (satellite in the next plane, same position)
            if plane < numPlanes
                upNeighborIndex = currentIndex + numSatellitesPerPlane;
                accessObj = access(sats(currentIndex), sats(upNeighborIndex));
                accessTables.SatSat{currentIndex, upNeighborIndex} = accessIntervals(accessObj);
            end
    
            % Connect to "down" neighbor (satellite in the previous plane, same position)
            if plane > 1
                downNeighborIndex = currentIndex - numSatellitesPerPlane;
                accessObj = access(sats(currentIndex), sats(downNeighborIndex));
                accessTables.SatSat{currentIndex, downNeighborIndex} = accessIntervals(accessObj);
            end
        end
    end


    % Ground Station to Satellite access
    for g = 1:numel(GS)
        for s = 1:numel(sats)
            accessObj = access(GS(g).GroundStationObj, sats(s));
            accessTables.GS_Sat{g, s} = accessIntervals(accessObj);
        end
    end
end

%% Function to Filter Active Links at Current Time
function validLinks = filterActiveLinks(accessTables, sats, GS, currentTime)
    validLinks = {};

    % Satellite-to-Satellite links
    for i = 1:size(accessTables.SatSat, 1)
        for j = 1:size(accessTables.SatSat, 2)
            if isAccessActive(accessTables.SatSat{i, j}, currentTime)
                delay = calculateDelay(sats(i), sats(j), currentTime, 3e8);
                validLinks = [validLinks; {sats(i).Name, sats(j).Name, delay}];
            end
        end
    end
    

    % Ground Station to Satellite links
    for g = 1:size(accessTables.GS_Sat, 1)
        for s = 1:size(accessTables.GS_Sat, 2)
            if isAccessActive(accessTables.GS_Sat{g, s}, currentTime)
                delay = calculateDelay(GS(g).GroundStationObj, sats(s), currentTime, 3e8);
                validLinks = [validLinks; {GS(g).GroundStationObj.Name, sats(s).Name, delay}];
            end
        end
    end

    % Convert cell array to table
    validLinks = cell2table(validLinks, 'VariableNames', {'Source', 'Target', 'Weight'});
end

%% Function to Check If Access is Active
function active = isAccessActive(accessIntervals, currentTime)
    if isempty(accessIntervals)
        active = false;
    else
        currentTime.TimeZone = accessIntervals.StartTime.TimeZone;
        active = any(currentTime >= accessIntervals.StartTime & currentTime <= accessIntervals.EndTime);
    end
end

%% Function to Map Nodes
function nodeMapping = createNodeMapping(sats, GS)
    nodeMapping = struct('GroundStations', {{}}, 'Satellites', {{}});
    for i = 1:numel(GS)
        nodeMapping.GroundStations{i} = GS(i).GroundStationObj.Name;
    end
    for i = 1:numel(sats)
        nodeMapping.Satellites{i} = sats(i).Name;
    end
end

%% Function to Calculate Delay
function delay = calculateDelay(obj1, obj2, time, c)
    distance = calculateDistance(obj1, obj2, time);
    delay = distance / c; % Delay in seconds
end

%% Function to Calculate Distance
function distance = calculateDistance(obj1, obj2, time)
    pos1 = getGeographicPosition(obj1, time);
    pos2 = getGeographicPosition(obj2, time);
    distance = norm(pos1 - pos2);
end

%% Function to Get Geographic Position
function pos = getGeographicPosition(obj, time)
    if isa(obj, 'matlabshared.satellitescenario.Satellite')
        [pos, ~] = states(obj, time, "CoordinateFrame", "geographic");
    elseif isa(obj, 'matlabshared.satellitescenario.GroundStation')
        pos = [obj.Latitude, obj.Longitude, obj.Altitude];
    else
        error('Unsupported object type.');
    end
end
