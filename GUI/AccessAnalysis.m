function accessout= AccessAnalysis(scenario, aircraft, constellation, frequency)
    scenario.scenario.AutoSimulate = true;

    % Access stuff
    accessout = Access_AnalysisTable(constellation, aircraft);
end

function accessAnalysisTable = Access_AnalysisTable(constellationobject, aircraftobject)
    accessAnalysisTable.obj = access(constellationobject, aircraftobject.obj);
    accessAnalysisTable.obj.LineColor = "#00FF00";
    accessAnalysisTable.Intervals = accessIntervals(accessAnalysisTable.obj);
    accessAnalysisTable.Intervals = sortrows(accessAnalysisTable.Intervals,"StartTime");
end


function fix_table(accesstable)
    % Get access stuff we want
    [sourcechars, targetchars, startchars, endchars, durationchars] = convertStringsToChars(accesstable.Intervals.Source,accesstable.Intervals.Target, ...
        string(accesstable.Intervals.StartTime),string(accesstable.Intervals.EndTime), accesstable.Intervals.Duration);
    chartable = table(sourcechars, targetchars, startchars, endchars, durationchars);
    celltable = table2cell(chartable);
    figure2 = figure("Name", "Access Analysis", "NumberTitle","off");
    figure(figure2);
    
    % Make a better table
    tablepic = uitable(figure2, 'ColumnWidth', 'auto', "Data", celltable);
    tablepic.ColumnName = {"Source","Target","Start Time","End Time","Duration"};
    table_extent = get(tablepic,'Extent');
    set(tablepic,'Position',[1 1 table_extent(3) table_extent(4)]);
    figure_size = get(figure2,'outerposition');
    desired_fig_size = [figure_size(1) figure_size(2) table_extent(3)+70 table_extent(4)+50];
    set(figure2,'outerposition', desired_fig_size);
    figure2.WindowState = 'minimized';
end



