% 
% function accessAnalysisTable = Access_AnalysisTable(constellationobject, aircraftobject)
%     accessAnalysisTable = access(constellationobject, aircraftobject);
%     accessAnalysisTable.obj.LineColor = "#00FF00";
%     accessAnalysisTable.Intervals = accessIntervals(accessAnalysisTable);
%     accessAnalysisTable.Intervals = sortrows(accessAnalysisTable.Intervals,"StartTime");
% end
function accessAnalysisTable = Access_AnalysisTable(constellationobject, aircraftobject)
    % Validate input types
    % aircraft is a satellite type
    % ~isa(aircraftobject, 'matlabshared.satellitescenario.Satellite') &&
    % if ~isa(constellationobject, 'matlabshared.satellitescenario.Satellite') && ...
    %    ~isa(constellationobject, 'matlabshared.satellitescenario.GroundStation') && ...
    %    ~isa(constellationobject, 'matlabshared.satellitescenario.Platform')
    %     error('constellationobject must be a Satellite, GroundStation, or Platform object.');
    % end
    % 
    % if ~isa(aircraftobject, 'matlabshared.satellitescenario.GroundStation') && ...
    %    ~isa(aircraftobject, 'matlabshared.satellitescenario.Platform')
    %     error('aircraftobject must be a Satellite, GroundStation, or Platform object.');
    % end

    % Call the access function
    accessAnalysisTable.obj = access(constellationobject, aircraftobject.obj);
    accessAnalysisTable.obj.LineColor = "#00FF00";
    accessAnalysisTable.Intervals = accessIntervals(accessAnalysisTable.obj);
    accessAnalysisTable.Intervals = sortrows(accessAnalysisTable.Intervals, "StartTime");
end
