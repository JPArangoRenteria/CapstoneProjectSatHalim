function accessout = accessFSPL(scenario, constellationobj, aircraftobj, accessobj, lambda)
    % Create output and add FSPL Table
    accessout = accessobj;
    FSPLColumn = zeros(height(accessobj.Intervals), 1);
    accessout.Intervals.("FSPL") = FSPLColumn;

    % Get each satellite times/connections
    for index = 1:size(accessobj.Intervals.Source, 1)
        strippedsat = split(accessobj.Intervals.Source(index, 1), '_'); % Get satellite number
        satnum = str2double(strippedsat(2));
        
        % Calculate FSPL for each row in access table
        indexFSPL = calculateFSPL(scenario.scenario.Satellites(1, satnum+1), aircraftobj.obj, accessobj.Intervals.StartTime(index), accessobj.Intervals.EndTime(index), 10, lambda);
        meanFSPL = mean(indexFSPL, "all"); % Take average
        accessout.Intervals.FSPL(index, 1) = meanFSPL; % Add average to access table
    end
end