function [sc, scenario] = network_topology_with_checking(start_y, start_mon, start_d, start_h, start_min, start_s, ...
                                   stop_y, stop_mon, stop_d, stop_h, stop_min, stop_s, stepping_u, ...
                                   numSatellites, numPlanes, relativeSpacing, altitude, inclination, ...
                                   walker_type, filename, fsplThreshold1,fsplThreshold2 ,lambda)
    % Create walker constellation scenario
    [sc, scenario] = walker_constellation(start_y, start_mon, start_d, start_h, start_min, start_s, ...
                                   stop_y, stop_mon, stop_d, stop_h, stop_min, stop_s, stepping_u, ...
                                   numSatellites, numPlanes, relativeSpacing, altitude, inclination, ...
                                   walker_type);
    sats = scenario.Satellites;
    scenario.AutoSimulate = true;  % Enable AutoSimulate for continuous progression
    
    % Add ground stations from file
    GS = groundstations(filename, scenario);
    
    % Establish initial access links and set colors based on FSPL
    for i = 1:length(GS)
        accessLinki = access(GS(i).GroundStationObj, sats);
        
        % Check FSPL for each satellite connection at the starting time
        for j = 1:length(accessLinki)
            currentTime = scenario.StartTime; % Initial simulation time
            
            % Calculate FSPL and set link color based on threshold
            pathLoss = FSPLsat(GS(i).GroundStationObj, sats(j), lambda, currentTime);
            if pathLoss > fsplThreshold1
                accessLinki(j).LineColor = 'red'; % High FSPL: red
            else
                accessLinki(j).LineColor = 'green'; % Acceptable FSPL: green
            end
        end
    end
    
    % Determine number of satellites per plane
    numSatellitesPerPlane = numSatellites / numPlanes;

    % Connect and color neighboring satellite links
    for plane = 1:numPlanes
        for sat = 1:numSatellitesPerPlane
            currentIndex = (plane - 1) * numSatellitesPerPlane + sat;

            % Connect to "right" neighbor in the same plane
            if sat < numSatellitesPerPlane
                rightNeighborIndex = currentIndex + 1;
                colorLinkBasedOnFSPL(sats(currentIndex), sats(rightNeighborIndex), fsplThreshold2, lambda, scenario.StartTime);
            end

            % Connect to "left" neighbor in the same plane
            if sat > 1
                leftNeighborIndex = currentIndex - 1;
                colorLinkBasedOnFSPL(sats(currentIndex), sats(leftNeighborIndex), fsplThreshold2, lambda, scenario.StartTime);
            end

            % Connect to "up" neighbor in the next plane, same position
            if plane < numPlanes
                upNeighborIndex = currentIndex + numSatellitesPerPlane;
                colorLinkBasedOnFSPL(sats(currentIndex), sats(upNeighborIndex), fsplThreshold2, lambda, scenario.StartTime);
            end

            % Connect to "down" neighbor in the previous plane, same position
            if plane > 1
                downNeighborIndex = currentIndex - numSatellitesPerPlane;
                colorLinkBasedOnFSPL(sats(currentIndex), sats(downNeighborIndex), fsplThreshold2, lambda, scenario.StartTime);
            end
        end
    end
end

function colorLinkBasedOnFSPL(obj1, obj2, fsplThreshold2, lambda, time)
    % Calculate FSPL between two objects and set link color based on FSPL threshold
    pathLoss = FSPLsat(obj1, obj2, lambda, time);
    accessLink = access(obj1, obj2);  % Establish access link
    
    if pathLoss > fsplThreshold2
        accessLink.LineColor = 'red';  % High FSPL: red
    else
        accessLink.LineColor = 'green';  % Acceptable FSPL: green
    end
end
