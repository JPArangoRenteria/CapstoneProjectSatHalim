function [gs,ds] = ground_station_pair(scenario,gsAlt,gsLat,gsLong,dsAlt,dsLat,dsLong)
    gs = groundStation(scenario, 'Latitude', gsLat, 'Longitude', gsLong, 'Altitude', gsAlt);
    ds = groundStation(scenario, 'Latitude', dsLat, 'Longitude', dsLong, 'Altitude', dsAlt);
end
