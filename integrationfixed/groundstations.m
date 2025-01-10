function G = groundstations(filename, sc)
    [names, lats, longs, alts] = getCSVColumns(filename);
    
    % Initialize an empty structure array for ground stations
    G(length(names)) = struct('Name', '', 'Latitude', 0, 'Longitude', 0, 'Altitude', 0, 'GroundStationObj', []);
    
    % Loop through each ground station data
    for i = 1:length(names)
        % Store information in the structure fields
        G(i).Name = names(i);
        G(i).Latitude = lats(i);
        G(i).Longitude = longs(i);
        G(i).Altitude = alts(i);
        
        % Create a ground station object and store it in the structure
        G(i).GroundStationObj = groundStation(sc, 'Latitude', lats(i), 'Longitude', longs(i), 'Altitude', alts(i));
    end
end
