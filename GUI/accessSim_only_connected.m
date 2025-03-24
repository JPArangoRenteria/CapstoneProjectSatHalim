function accessSim_only_connected(scenario, tableitem, accessobj) %should we lower sample time?
    hide(accessobj.obj, scenario.viewer);
    scenario.scenario.AutoSimulate = false;
    accessobj.obj.LineColor = 'red';
    show(accessobj.obj, scenario.viewer);

    % Connect to first sat
    index = 1;
    

    starttime = tableitem.('Connection Start')(1);
    starttime.Format = 'd-MMMM-yyyy HH:mm:ss';
    starttime.TimeZone = '';
    endtime = tableitem.('Connection End')(1);
    endtime.Format = 'd-MMMM-yyyy HH:mm:ss';
    endtime.TimeZone = '';

    strippedsat = split(tableitem.Satellite(1), '_'); % Get satellite number
    satnum = str2double(strippedsat(2));
    
    startofsim = scenario.scenario.StartTime;
    startofsim.Format = 'd-MMMM-yyyy HH:mm:ss';
    startofsim.TimeZone = '';

    endofsim = scenario.scenario.StopTime;
    endofsim.Format = 'd-MMMM-yyyy HH:mm:ss';
    endofsim.TimeZone = '';

    sampletime = scenario.scenario.SampleTime;
    timeframe = scenario.scenario.StopTime - scenario.scenario.StartTime;
    numsamples = seconds(timeframe) /sampletime;

    for row = 1:size(tableitem.Satellite, 1)
        if endtime == startofsim
            index = index + 1;
            starttime = tableitem.('Connection Start')(index);
            starttime.Format = 'd-MMMM-yyyy HH:mm:ss';
            starttime.TimeZone = '';
            endtime = tableitem.('Connection End')(index);
            endtime.Format = 'd-MMMM-yyyy HH:mm:ss';
            endtime.TimeZone = '';
        end
    end

    while advance(scenario.scenario)
        currenttime = scenario.scenario.SimulationTime;
        currenttime.Format = 'd-MMMM-yyyy HH:mm:ss';
        currenttime.TimeZone = '';
        
        if currenttime == endtime && currenttime ~= endofsim % If connection ends now
            % Disconnect old sat
            hide(accessobj.obj(1,satnum), scenario.viewer)
            strippedsat = split(tableitem.Satellite(index), '_'); % Get satellite number
            satnum = str2double(strippedsat(2));
            %accessobj.obj(1,satnum).LineColor = 'red';
            
            %Connect new sat
            index = index + 1;
            strippedsat = split(tableitem.Satellite(index), '_'); % Get satellite number
            satnum = str2double(strippedsat(2));
            %accessobj.obj(1,satnum).LineColor = 'green';
            show(accessobj.obj(1,satnum), scenario.viewer)
            endtime = tableitem.('Connection End')(index);
            endtime.Format = 'd-MMMM-yyyy HH:mm:ss';
            endtime.TimeZone = '';

            if currenttime == endtime % If connected for not even 1 minute
                % Disconnect
                hide(accessobj.obj(1,satnum), scenario.viewer)
                %accessobj.obj(1,satnum).LineColor = 'red';

                %Connect to one after it
                index = index + 1;
                strippedsat = split(tableitem.Satellite(index), '_'); % Get satellite number
                satnum = str2double(strippedsat(2));
                %accessobj.obj(1,satnum).LineColor = 'green';
                show(accessobj.obj(1,satnum), scenario.viewer)
                endtime = tableitem.('Connection End')(index);
                endtime.Format = 'd-MMMM-yyyy HH:mm:ss';
                endtime.TimeZone = '';
            end
        end
    end
end