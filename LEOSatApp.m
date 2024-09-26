classdef LEOSatApp < handle
    properties (Access = private)
        UIFigure               matlab.ui.Figure
        TabGroup               matlab.ui.container.TabGroup
        SimulationTab          matlab.ui.container.Tab
        ConstellationTab       matlab.ui.container.Tab
        GroundStationTab       matlab.ui.container.Tab
        TrafficTab             matlab.ui.container.Tab
        GridLayout             matlab.ui.container.GridLayout
        % Define layouts for each tab
        SimulationLayout       matlab.ui.container.GridLayout
        ConstellationLayout    matlab.ui.container.GridLayout
        GroundStationLayout    matlab.ui.container.GridLayout
        TrafficLayout          matlab.ui.container.GridLayout
        % Simulation Fields
        StartYear     matlab.ui.control.NumericEditField
        StartMonth    matlab.ui.control.NumericEditField
        StartDay    matlab.ui.control.NumericEditField
        StartHour    matlab.ui.control.NumericEditField
        StartMinute  matlab.ui.control.NumericEditField
        StartSecond  matlab.ui.control.NumericEditField
        StopYear      matlab.ui.control.NumericEditField
        StopMonth   matlab.ui.control.NumericEditField
        StopDay  matlab.ui.control.NumericEditField
        StopHour     matlab.ui.control.NumericEditField
        StopMinute    matlab.ui.control.NumericEditField
        StopSecond    matlab.ui.control.NumericEditField
        TimeStep matlab.ui.control.NumericEditField
        %Constellation Parameter Fields
        NumSatellites      matlab.ui.control.NumericEditField
        NumPlanes               matlab.ui.control.NumericEditField
        Inclination       matlab.ui.control.NumericEditField
        Altitude                matlab.ui.control.NumericEditField
        RelativeSpacing         matlab.ui.control.NumericEditField
        ConstellationType       matlab.ui.control.EditField
        % Ground Stations Parameter Fields
        GsName          matlab.ui.control.EditField
        GsLatitude          matlab.ui.control.NumericEditField
        GsLongitude        matlab.ui.control.NumericEditField
        GsAltitude          matlab.ui.control.NumericEditField
        DsName          matlab.ui.control.EditField
        DsLatitude          matlab.ui.control.NumericEditField
        DsLongitude         matlab.ui.control.NumericEditField
        DsAltitude         matlab.ui.control.NumericEditField
        % Traffic Parameters Fields
        TrafficTypeDropDown    matlab.ui.control.DropDown
        TrafficIntensityField  matlab.ui.control.NumericEditField

        DefaultButton          matlab.ui.control.Button
    end
    
    methods (Access = public)

        function app = LEOSatApp()
            createComponents(app);
            app.UIFigure.Visible = 'on';
        end

    end


    methods (Access = private)

        function createComponents(app)

            %% Create UIFigure
            app.UIFigure = uifigure('Position', [100, 100, 700, 500], 'Name', 'MATLAB App');

            %% Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure, 'Position', [10, 10, 680, 480]);

            %% Simulation Tab
            app.SimulationTab = uitab(app.TabGroup, 'Title', 'Simulation Parameters');
            app.SimulationLayout = uigridlayout(app.SimulationTab, [5, 6]);

            % Add Simulation Parameters fields
            addSimulationParameters(app);

            %% Constellation Parameters Tab
            app.ConstellationTab = uitab(app.TabGroup, 'Title', 'Constellation Parameters');
            app.ConstellationLayout = uigridlayout(app.ConstellationTab, [5, 4]);

            % Add Constellation Parameters fields
            addConstellationParameters(app);

            %% Ground Station Parameters Tab
            app.GroundStationTab = uitab(app.TabGroup, 'Title', 'Ground Station Parameters');
            app.GroundStationLayout = uigridlayout(app.GroundStationTab, [4, 4]);

            % Add Ground Station Parameters fields
            addGroundStationParameters(app);

            %% Traffic Parameters Tab
            app.TrafficTab = uitab(app.TabGroup, 'Title', 'Traffic Parameters');
            app.TrafficLayout = uigridlayout(app.TrafficTab, [4, 4]);

            % Add Traffic Parameters fields
            addTrafficParameters(app);

        end

        %% Helper function for adding Simulation Parameters fields
        function addSimulationParameters(app)
            uilabel(app.SimulationLayout, 'Text', 'Simulation Start Year', 'HorizontalAlignment', 'right');
            app.StartYear = uieditfield(app.SimulationLayout, 'numeric');

            uilabel(app.SimulationLayout, 'Text', 'Simulation Start Month', 'HorizontalAlignment', 'right');
            app.StartMonth = uieditfield(app.SimulationLayout, 'numeric');

            uilabel(app.SimulationLayout, 'Text', 'Simulation Start Day', 'HorizontalAlignment', 'right');
            app.StartDay = uieditfield(app.SimulationLayout, 'numeric');

            uilabel(app.SimulationLayout, 'Text', 'Simulation Start Hour', 'HorizontalAlignment', 'right');
            app.StartHour = uieditfield(app.SimulationLayout, 'numeric');

            uilabel(app.SimulationLayout, 'Text', 'Simulation Start Minute', 'HorizontalAlignment', 'right');
            app.StartMinute = uieditfield(app.SimulationLayout, 'numeric');

            uilabel(app.SimulationLayout, 'Text', 'Simulation Start Second', 'HorizontalAlignment', 'right');
            app.StartSecond = uieditfield(app.SimulationLayout, 'numeric');

            uilabel(app.SimulationLayout, 'Text', 'Simulation Stop Year', 'HorizontalAlignment', 'right');
            app.StopYear = uieditfield(app.SimulationLayout, 'numeric');

            uilabel(app.SimulationLayout, 'Text', 'Simulation Stop Month', 'HorizontalAlignment', 'right');
            app.StopMonth = uieditfield(app.SimulationLayout, 'numeric');

            uilabel(app.SimulationLayout, 'Text', 'Simulation Stop Day', 'HorizontalAlignment', 'right');
            app.StopDay = uieditfield(app.SimulationLayout, 'numeric');

            uilabel(app.SimulationLayout, 'Text', 'Simulation Stop Hour', 'HorizontalAlignment', 'right');
            app.StopHour = uieditfield(app.SimulationLayout, 'numeric');

            uilabel(app.SimulationLayout, 'Text', 'Simulation Stop Minute', 'HorizontalAlignment', 'right');
            app.StopMinute = uieditfield(app.SimulationLayout, 'numeric');

            uilabel(app.SimulationLayout, 'Text', 'Simulation Stop Second', 'HorizontalAlignment', 'right');
            app.StopSecond = uieditfield(app.SimulationLayout, 'numeric');

            uilabel(app.SimulationLayout, 'Text', 'Simulation Time Step', 'HorizontalAlignment', 'right');
            app.TimeStep = uieditfield(app.SimulationLayout, 'numeric');
        end

        %% Helper function for adding Constellation Parameters fields
        function addConstellationParameters(app)
            uilabel(app.ConstellationLayout, 'Text', 'Number of Satellites', 'HorizontalAlignment', 'right');
            app.NumSatellites = uieditfield(app.ConstellationLayout, 'numeric');

            uilabel(app.ConstellationLayout, 'Text', 'Number of Planes', 'HorizontalAlignment', 'right');
            app.NumPlanes = uieditfield(app.ConstellationLayout, 'numeric');

            uilabel(app.ConstellationLayout, 'Text', 'Inclination (deg)', 'HorizontalAlignment', 'right');
            app.Inclination = uieditfield(app.ConstellationLayout, 'numeric');

            uilabel(app.ConstellationLayout, 'Text', 'Relative Spacing', 'HorizontalAlignment', 'right');
            app.RelativeSpacing = uieditfield(app.ConstellationLayout, 'numeric');
            
            uilabel(app.ConstellationLayout, ...
                    'Text', 'Walker Constellation Type', ...
                    'HorizontalAlignment', 'right');
            app.ConstellationType = uieditfield(app.ConstellationLayout, 'text');
            app.ConstellationType.Value = 'star'; 
        end

        %% Helper function for adding Ground Station Parameters fields
        function addGroundStationParameters(app)
            uilabel(app.GroundStationLayout, ...
                    'Text', 'GSName', ...
                    'HorizontalAlignment', 'right');
            app.GsName = uieditfield(app.GroundStationLayout, 'text');
            app.GsName.Value = 'G'; 

            uilabel(app.GroundStationLayout, 'Text', 'Latitude (deg)', 'HorizontalAlignment', 'right');
            app.GsLatitude = uieditfield(app.GroundStationLayout, 'numeric');

            uilabel(app.GroundStationLayout, 'Text', 'Longitude (deg)', 'HorizontalAlignment', 'right');
            app.GsLongitude = uieditfield(app.GroundStationLayout, 'numeric');

            uilabel(app.GroundStationLayout, 'Text', 'Altitude (m)', 'HorizontalAlignment', 'right');
            app.GsAltitude = uieditfield(app.GroundStationLayout, 'numeric');

            uilabel(app.GroundStationLayout, ...
                    'Text', 'DSName', ...
                    'HorizontalAlignment', 'right');
            app.DsName = uieditfield(app.GroundStationLayout, 'text');
            app.DsName.Value = 'D'; 

            uilabel(app.GroundStationLayout, 'Text', 'Dest Latitude (deg)', 'HorizontalAlignment', 'right');
            app.DsLatitude = uieditfield(app.GroundStationLayout, 'numeric');

            uilabel(app.GroundStationLayout, 'Text', 'Dest Longitude (deg)', 'HorizontalAlignment', 'right');
            app.DsLongitude = uieditfield(app.GroundStationLayout, 'numeric');

            uilabel(app.GroundStationLayout, 'Text', ' Dest Altitude (m)', 'HorizontalAlignment', 'right');
            app.DsAltitude = uieditfield(app.GroundStationLayout, 'numeric');
        end

        %% Helper function for adding Traffic Parameters fields
        function addTrafficParameters(app)
            uilabel(app.TrafficLayout, 'Text', 'Traffic Type', 'HorizontalAlignment', 'right');
            app.TrafficTypeDropDown = uidropdown(app.TrafficLayout, 'Items', {'Data', 'Voice', 'Video'}, 'Value', 'Data');

            uilabel(app.TrafficLayout, 'Text', 'Traffic Intensity (bps)', 'HorizontalAlignment', 'right');
            app.TrafficIntensityField = uieditfield(app.TrafficLayout, 'numeric');
        end

    end

end
