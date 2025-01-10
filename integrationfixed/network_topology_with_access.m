function [sc, scenario, accessout, aircraftout, selectiveout] = network_topology_with_access(start_y, start_mon, start_d, start_h, start_min, start_s, ...
                                   stop_y, stop_mon, stop_d, stop_h, stop_min, stop_s, stepping_u, ...
                                   numSatellites, numPlanes, relativeSpacing, altitude, inclination, ...
                                   walker_type, filename, duration, startlat, startlong, endlat, endlong)
    % Generate Walker constellation and scenario
    [sc, scenario] = walker_constellation(start_y, start_mon, start_d, start_h, start_min, start_s, ...
                                   stop_y, stop_mon, stop_d, stop_h, stop_min, stop_s, stepping_u, ...
                                   numSatellites, numPlanes, relativeSpacing, altitude, inclination, ...
                                   walker_type);
    sats = scenario.Satellites;

    % Add ground stations
    GS = groundstations(filename, scenario);

    % Connect ground stations to satellites in view
    for i = 1:length(GS)
        access(GS(i).GroundStationObj, sats);
    end

    % Define number of satellites per plane
    numSatellitesPerPlane = numSatellites / numPlanes;

    % Create inter-satellite links
    for plane = 1:numPlanes
        for sat = 1:numSatellitesPerPlane
            currentIndex = (plane - 1) * numSatellitesPerPlane + sat;

            % Connect to neighboring satellites within the same plane
            if sat < numSatellitesPerPlane
                rightNeighborIndex = currentIndex + 1;
                access(sats(currentIndex), sats(rightNeighborIndex));
            end
            if sat > 1
                leftNeighborIndex = currentIndex - 1;
                access(sats(currentIndex), sats(leftNeighborIndex));
            end

            % Connect to neighboring satellites in adjacent planes
            if plane < numPlanes
                upNeighborIndex = currentIndex + numSatellitesPerPlane;
                access(sats(currentIndex), sats(upNeighborIndex));
            end
            if plane > 1
                downNeighborIndex = currentIndex - numSatellitesPerPlane;
                access(sats(currentIndex), sats(downNeighborIndex));
            end
        end
    end

    % Perform access analysis
    [accessout, aircraftout, selectiveout] = AccessAnalysis(scenario, duration, sats, startlat, startlong, endlat, endlong);
end
