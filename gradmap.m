% GradMap v1.0 - Gradient mapping tool enabling gradient calculation based on
% relative gravity measurements.
% Author: Adam Novak
% Workplace: Geodetic and Cartographic Institute, reference frames group.
% Description:
% The tool enables gravity gradient calculations along one axis (vertical direction)
% assuming measurements are taken along a vertical in 2 or more positions
% or standard gravity differences processing.
% User can choose from two processing options, first one uses gravity
% differences and measured positions to derive a point based gravity
% gradient information.
% Second option treats gravity changes along vertical as a function of height and
% time allowing gradient to be computed for any given height afterwards.
% Several limiting factors are incorporated within the tool enabling
% customization of the calculation process, such as number of measured
% levels (vertical positions), instrument accuracy, height units provided
% by the user, standard deviation scaling and more.

% Python version in progress

% Check for updated version on https://github.com/adnovak/gradmap

function gradmap(GUI_par, ...               % variables used to switch between command line and GUI use. When calling function from command line use 'Run'. [string]
    ...
    input_units_option, ...                 % specifies height unit that operator used during measurements '1' for centimetres and '2' for metres [double]. User should store height measured to the upper edge of the instrument CG5 and bottom edge for CG6
    ...                                 
    instrument_type,...                     %specifies which instrument was used to use appropriate reading of data: current options are 'CG5' or 'CG6' [string]
    ...
    header_lines, ...                       % number of headerlines in file to skip [double]
    ...
    SD_scale_information,...                % information whether Standard Deviation is scaled to 1 second or 1 minute measurement. Values more than 0.15 - 0.2 might indicate, SD is provides accuracy of 1s measurement. '0' for standard deviation scaled to minute measurement and '1' for 1 second scaled standard deviation [double].
    ...
    input_files, ...                        % path to input file(s) (fullfile) [string] in case of multiple files use ['D:/.../file1'; 'D:/.../file2'; etc ].
    ... 
    uncertainty,...                         % instrument standard deviation e.g. 1 microGal [double], This is to be decided by gravimeter operator.
    ...
    calibration_factor,...                  % enables user to provide calibration factor and scale gravity gradient - usually determined during gravity calibration on gravity baseline, when left blank or set to '1.0' (calibration_factor = []), algorithm will use original GCAL1 from protocol. [double]
    ...
    rejection_threshold,  ...               % threshold for rejecting solution in microGals per metre [double]. 
    ...
    number_of_measured_levels, ...          % number of measured position (levels) [double]. Use '1' for two measured levels, '2' for three measured levels and '3' to let the algorithm decide. Option '3' however assumes that each measured point has always correctly assigned ID (no typo has occured). 
    ...
    significance_level,...                  % significance level or statistical significance determines the result of statistic tests performed within the processing. Recommended to check three sigma rule. Set to '1' for 1-sigma (68% probability), '2' for 2-sigma (95% probability) and '3' for 3-sigma (99% probability) for correctly identifying outliers and performing statistic tests.
    ...
    gradient_output_format,...              % linear gravity gradient represented by a single value in μGal/m or function Δg = aH + b. where b is linear component and a is quadratic component. Use "linear" for linear and "function" for function [string]
    ...
    reference_point,...                     % value to be treated as reference point - all relative measurements will be linked to this point, leave blank if first measured point is reference [string]
    ...
    reference_value,...                     % reference gravity value in desired gravity units (check next parameter), if left empty 0 is assigned and values relative to reference point are provided [double]
    ...
    output_gravity_units,...                % set desired units of gravity for output. 1 - μGal, 2 - mGal, 3 - nm/s² [double]
    ...
    report_file,...                         % report file path + filename. Note: reports from all processed data are stored in this file [string]
    ...
    store_gravity_dif,...                   % option to store gravity differences and their standard deviations intead of gradient, choosing this option '1' will disable gradient format and number of measured positions since this doesn't affect standard processing. '0' for no, '1' for yes [double]
    ...
    plot_errors_option, ...                 % option to plot graphics for each processed station '0' for no and '1' for yes [double]
    ...
    summary_option)                         % store summary in excel file , '0' for no, '1' for yes [double]. excel file will be created in same folder as report file with a name "processing_summary".

    if nargin == 0

        check_open_window = get(findobj('Tag','check_graphics'),'Value');

        if numel(check_open_window)>0
           fprintf('GUI window already open, closing window \n')
           close all
        else
            
% open GUI
    % Main window
        % color palettes        
            R1=0.93; G1=0.93; B1=0.93;
            R2=0.99; G2=0.99; B2=0.99;
            
            % font size
            fs = 11;

            % prepared for switching to continue data downwards
            leftboundary = 0.04;
            % rightboundary = 0.96;

            panel1lower_boundary = 0.66;
            panel1height = 0.33;
            
            panel2lower_boundary = 0.295;
            panel2height = 0.36;

            panel3lower_boundary = 0.06;
            panel3height = 0.23;
            
            panelheight = 600; % in pixels
            windowsize5 = 20/panelheight; % in pixels
            windowsize6 = 24/panelheight; % in pixels
            windowsize7 = 28/panelheight; % in pixels
            
            M = figure('units','pixels','numbertitle','off','name','GradMap v1.0',...
            'color',[R1 G1 B1],'position',[250 100 420 100+panelheight],'Resize','off',...
            'tag','Window','menubar','none');

 %______________________________________________________________________
            % PANEL 1 - vstupne udaje
	        p1 = uipanel(M,'Title','Input Data','Units','normalized','position',[0.02 panel1lower_boundary 0.96 panel1height],...
            'backgroundcolor',[R1 G1 B1],'HighlightColor',[R2 G2 B2],'tag',...
            'Locpanel','FontName','Georgia','FontSize',fs+1.5);
    
            % choose file panel  
            uicontrol(M,'Units','normalized','position',[leftboundary+0.02 0.9 0.3 windowsize7],...
                    'Style','pushbutton','string','Choose file(s)',...
                    'tag','push_input_path','Callback','gradmap input_path','FontName','Trebuchet MS','FontSize',fs);

            % show filename(s)
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.32 0.9 0.55 windowsize5],...
                'backgroundcolor',[R1 G1 B1],'tag','show_local_path',...
                'Style','Text','string','','FontName','Trebuchet MS','FontSize',fs-0.5);

            % instrument type text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.845 0.26 windowsize6],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','instrument type','FontName','Trebuchet MS','FontSize',fs);

            % instrument used option window
            uicontrol(M,'Units','normalized','position',[leftboundary+0.74 0.84 0.12 0.055],...
                        'Style','Popupmenu','tag','instrument_option',...
                        'string','CG5|CG6','value',1,'BackgroundColor','white','FontName','Trebuchet MS','FontSize',fs-0.5,...
                        'Callback',@instrument_callback);

            % Number of header lines text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.8 0.38 windowsize6],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','number of header lines','FontName','Trebuchet MS','FontSize',fs);

             % number of header lines window
            uicontrol(M,'Units','normalized','Position',[leftboundary+0.74 0.81 0.1 windowsize5],...
                        'Style','Edit','tag','edit_pocet_riadkov',...
                        'string','34','backgroundcolor','white',...
                        'FontName','Trebuchet MS','FontName','Trebuchet MS','FontSize',fs-0.5);

            % height unit text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.75 0.2 windowsize6],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','height units','FontName','Trebuchet MS','FontSize',fs);

            % Uncertainty text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.708 0.5 windowsize5],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','instrument uncertainty in µGal','FontName','Trebuchet MS','FontSize',fs);

            % accuracy window
            uicontrol(M,'Units','normalized','Position',[leftboundary+0.74 0.715 0.1 windowsize5],...
                        'Style','Edit','tag','edit_unc',...
                        'string','5','backgroundcolor','white',...
                        'FontName','Trebuchet MS','FontName','Trebuchet MS','FontSize',fs-0.5);
    
            % units option window
            uicontrol(M,'Units','normalized','position',[leftboundary+0.74 0.745 0.12 0.055],...
                        'Style','Popupmenu','tag','units_option',...
                        'string','cm|m','value',1,'BackgroundColor','white','FontName','Trebuchet MS','FontSize',fs-0.5);
                        
            % Standard deviation scaling text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.665 0.42 windowsize5],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','standard deviation scaling','FontName','Trebuchet MS','FontSize',fs);
            
            % Standard deviation scaling window
            uicontrol(M,'Units','normalized','position',[leftboundary+0.7 0.65 0.18 0.055],...
                        'Style','Popupmenu','tag','SD_scaling',...
                        'string','series|second','value',1,'BackgroundColor','white','FontName','Trebuchet MS','FontSize',fs-0.5);

% ===== PANEL 2 - processing information

        p2 = uipanel(M,'Title','Processing','Units','normalized',...
            'position',[0.02 panel2lower_boundary 0.96 panel2height],...
            'backgroundcolor',[R1 G1 B1],'HighlightColor',[R2 G2 B2],'tag',...
            'Locpanel','FontName','Georgia','FontSize',fs+1.5);

        % text part
        % number of measured positions
        uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.575 0.52 windowsize5],...
                     'backgroundcolor',[R1 G1 B1],...
                     'Style','Text','string','number of measured positions','FontName','Trebuchet MS','FontSize',fs);

        % rejection threshold
        uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.53 0.45 windowsize5],...
                     'backgroundcolor',[R1 G1 B1],...
                     'Style','Text','string','rejection threshold in µGal','FontName','Trebuchet MS','FontSize',fs);

        % gradient format
        uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.485 0.28 windowsize5],...
                     'backgroundcolor',[R1 G1 B1],...
                     'Style','Text','string','gradient format','FontName','Trebuchet MS','FontSize',fs);

        % significance level
        uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.44 0.29 windowsize5],...
                     'backgroundcolor',[R1 G1 B1],...
                     'Style','Text','string','significance level','FontName','Trebuchet MS','FontSize',fs);

        % calibration factor
        uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.395 0.3 windowsize5],...
                     'backgroundcolor',[R1 G1 B1],...
                     'Style','Text','string','calibration factor','FontName','Trebuchet MS','FontSize',fs);

        % Reference point
        uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.35 0.27 windowsize5],...
                     'backgroundcolor',[R1 G1 B1],...
                     'Style','Text','string','reference point','FontName','Trebuchet MS','FontSize',fs);
        
        % Reference value
        uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.48 0.35 0.11 windowsize5],...
                     'backgroundcolor',[R1 G1 B1],...
                     'Style','Text','string','value:','FontName','Trebuchet MS','FontSize',fs);

        % Output gravity units
        uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.305 0.22 windowsize5],...
                     'backgroundcolor',[R1 G1 B1],...
                     'Style','Text','string','output units','FontName','Trebuchet MS','FontSize',fs);

        % window part
        % number of measured positions
        uicontrol(M,'Units','normalized','position',[leftboundary+0.725 0.58 0.15 windowsize5],...
                    'Style','Popupmenu','tag','number_measured_levels',...
                    'string','2|3|4|5|from file','value',5,'BackgroundColor','white','FontName','Trebuchet MS','FontSize',fs-0.5);

        % rejection threshold
        uicontrol(M,'Units','normalized','Position',[leftboundary+0.74 0.535 0.1 windowsize5],...
                    'Style','Edit','tag','rejection_threshold',...
                    'string','5','backgroundcolor','white',...
                    'FontName','Trebuchet MS','FontSize',fs-0.5);

        % gradient result format
        uicontrol(M,'Units','normalized','position',[leftboundary+0.7 0.49 0.18 windowsize5],...
                    'Style','Popupmenu','tag','gradient_option',...
                    'string','linear|function','value',1,'BackgroundColor','white','FontName','Trebuchet MS','FontSize',fs-0.5,'Callback',@gradient_method_callback);

        % significance level
        uicontrol(M,'Units','normalized','position',[leftboundary+0.7 0.445 0.18 windowsize5],...
                    'Style','Popupmenu','tag','significance_tag',...
                    'string','1-σ (68% confidence bounds) |2-σ (95% confidence bounds)|3-σ (99.7% confidence bounds)','value',2,'BackgroundColor','white','FontName','Trebuchet MS','FontSize',fs-0.5);

        % calibration factor
        uicontrol(M,'Units','normalized','Position',[leftboundary+0.7 0.4 0.18 windowsize5],...
                    'Style','Edit','tag','calibration',...
                    'string','','backgroundcolor','white',...
                    'FontName','Trebuchet MS','FontSize',fs-0.5);
    
        % reference point 
        uicontrol(M,'Units','normalized','Position',[leftboundary+0.31 0.355 0.14 windowsize5],...
                    'Style','Edit','tag','ref_point',...
                    'string','','backgroundcolor','white',...
                    'FontName','Trebuchet MS','FontSize',fs-0.5);
   
        % reference value 
        uicontrol(M,'Units','normalized','Position',[leftboundary+0.62 0.355 0.26 windowsize5],...
                    'Style','Edit','tag','ref_value',...
                    'string','','backgroundcolor','white',...
                    'FontName','Trebuchet MS','FontSize',fs-0.5);

        % output gravity units - options
        uicontrol(M,'Units','normalized','position',[leftboundary+0.7 0.31 0.18 windowsize5],...
                    'Style','Popupmenu','tag','output_units',...
                    'string','µGal|mGal|nm/s²','value',1,'BackgroundColor','white','FontName','Trebuchet MS','FontSize',fs-0.5);

% ===== PANEL 3 - Output data - specify output files and file preference
	        p3 = uipanel(M,'Title','Output data','Units','normalized','position',[0.02 panel3lower_boundary 0.96 panel3height],...
            'backgroundcolor',[R1 G1 B1],'HighlightColor',[R2 G2 B2],'tag',...
            'Locpanel','FontName','Georgia','FontSize',fs+1.5);

            % Panel na vyber suboru
            uicontrol(M,'Units','normalized','position',[leftboundary+0.02 0.20 0.35 windowsize7],...
                    'Style','pushbutton','string','Create report file',...
                    'tag','push_report_file_name','Callback','gradmap report_filename','FontName','Trebuchet MS','FontSize',fs);

            % Vypis nazvu vybraneho suboru
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.45 0.205 0.45 windowsize5],...
                'backgroundcolor',[R1 G1 B1],'tag','show_report_path',...
                'Style','Text','string','','FontName','Trebuchet MS','FontSize',fs-1),'borders';

            % Ulozenie grafickych vystupov spracovania text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.15 0.4 windowsize6],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','store processing figures',...
                         'FontName','Trebuchet MS','FontSize',fs);

            % fixovanie rozsahu osi v grafoch - natvrdo sa definuje +-100
            % rozsah
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.53 0.15 0.25 windowsize6],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','fix y-axis',...
                         'FontName','Trebuchet MS','FontSize',fs);

            % text for saving summary of all calculations in an excel table 
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.108 0.38 windowsize6],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','save summary in table',...
                         'FontName','Trebuchet MS','FontSize',fs);

            % text for saving gravity differences instead of gradient
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.07 0.53 windowsize5],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','save gravity differences instead',...
                         'FontName','Trebuchet MS','FontSize',fs);

            % button for saving graphic output
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.48 0.152 0.09 windowsize7],...
                        'BackgroundColor',[R1 G1 B1],...
                        'Style','Checkbox','tag','check_graphics',...
                        'string','','value',0);
            
            % button for locking extent of y axis to +- 100
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.78 0.152 0.09 windowsize7],...
                        'BackgroundColor',[R1 G1 B1],...
                        'Style','Checkbox','tag','check_graphics_extent',...
                        'string','','value',0);


            % Button for saving a summary (table) of all calculated values
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.78 0.11 0.09 windowsize7],...
                        'BackgroundColor',[R1 G1 B1],...
                        'Style','Checkbox','tag','check_summary',...
                        'string','','value',1);

            % button for saving gravity differences instead of gradient for
            % all calculations

            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.78 0.07 0.09 windowsize7],...
                        'BackgroundColor',[R1 G1 B1],...
                        'Style','Checkbox','tag','check_gravity_dif',...
                        'string','','value',0,'Callback',@processing_callback);


% ===== PART 4 - start calculations, close window utility

            % Execute button
	        uicontrol('Units','normalized','position',[0.25 0.01 0.19 windowsize6],...
            'style','pushbutton','string','Execute','FontName','Trebuchet MS','FontSize',fs,'fontweight', 'demi','Callback','gradmap Run');

            % Close button
	        uicontrol('Units','normalized','position',[0.6 0.01 0.19 windowsize6],...
            'Style','pushbutton','string','Close','FontName','Trebuchet MS','FontSize',fs,'fontweight', 'demi','Callback','gradmap Close');
        end

    else
            % define what happens when individual buttons are pressed.
        switch GUI_par
            % Click on choose input files button ---------------------------------------
            case 'input_path'

                % [data_filename,data_path]=uigetfile({'*.txt';'*.dat';'*.*'},'Select measurement file(s)','MultiSelect','on');
                % get input data path
                [data_filename,data_path]=uigetfile({'*.*'},'Select measurement file(s)','MultiSelect','on');

                if iscell(data_filename)
                    nfiles = length(data_filename);
                    
                    for i = 1:nfiles
                        data(i,:) = string(fullfile(data_path,data_filename{i}));
                    end
                    
                    % for multiple files processed at the same time reset
                    % reference point and value - is the reference point in
                    % all measurements?
                    if nfiles > 1
                        reference_point = [];
                        reference_value = [];
                    end

                    % write local data filenames when more than one file
                    % is selected
                    show_files = [data_filename{1} ', ' data_filename{2}, ', ...'];
                    set(findobj('tag','show_local_path'),'string',show_files, 'FontSize',8); drawnow
                    % save filenames - this is how GUI works, it has to be
                    % stored in userdata for later use.
                    set(findobj('tag','edit_pocet_riadkov'),'userdata',data);

                elseif data_filename ~= 0 & iscell(data_filename) == 0
                
                    % write local data filename
                    data = fullfile(data_path,data_filename);
                    set(findobj('tag','show_local_path'),'string',data_filename, 'FontSize',8); drawnow
                    % save filename
                    set(findobj('tag','edit_pocet_riadkov'),'userdata',data);
                
                elseif data_filename == 0
                    fprintf('File(s) not selected. \n')
                end
            
            % clicking on button to create a report file ---------------------------------
            case 'report_filename'
                [outname,outpath] = uiputfile('*.*');
                if outname == 0
                    fprintf('-> No report file created. \n')
                else
                    
                    outfile = fullfile(outpath,outname);
                    prip = outfile(end-3:end);
    
                    if prip == '.txt'
                       outfile = outfile(1:end-4);
                       outname = outname(1:end-4);
                    end 
    
                    set(findobj('tag','show_report_path'),'string',strcat(outname,'.txt'), 'FontSize',8);
                    set(findobj('tag','push_report_file_name'),'userdata',outfile);
                end
% --------------------- after pushing execute button ---------------------------------
            case 'Run'
                if nargin == 1 % when using user interface
                    GUI = 1;
                else
                    GUI = 0; % when working with command line
                end
                
                % variables when working with GUI are taken from the
                % UIcontrol
                if GUI == 1
                    
                    % get input files from GUI
                    input_files =  get(findobj('tag','edit_pocet_riadkov'),'userdata');
                    % get number of headerlines from GUI
                    header_lines = str2double(get(findobj('tag','edit_pocet_riadkov'),'string'));
                    % get input unit information from GUI
                    input_units_option = get(findobj('tag','units_option'),'value');
                    % get instrument uncertainty from GUI
                    SD00 = str2double(get(findobj('tag','edit_unc'),'string'));
                    % get SD scaling information from GUI
                    SD_scaling = get(findobj('tag','SD_scaling'),'value');
                    % GUI can only provide 1 or 2 from popupmenu, however
                    % we ought to know whether Standard deviation has
                    % already been scaled properly
                    SD_scale_information = SD_scaling - 1;
                    % get instrument info
                    instrument_option = get(findobj('tag','instrument_option'),'value');

                    if instrument_option == 1
                        instrument_type = 'CG5';
                    elseif instrument_option == 2
                        instrument_type = 'CG6';
                    end

                    % get num of measured levels from GUI
                    measured_levels = get(findobj('tag','number_measured_levels'),'value');
                    % get rejection criteria from GUI
                    rejection_threshold = str2double(get(findobj('tag','rejection_threshold'),'string'));
                    % get gradient output format from GUI
                    gradient_format = get(findobj('tag','gradient_option'),'value');

                    % get significance level from GUI
                    significance = get(findobj('tag','significance_tag'),'value');
                    reference_point = get(findobj('Tag', 'ref_point'), 'String');
                    reference_value = get(findobj('Tag', 'ref_value'), 'String');
                    output_gravity_units = get(findobj('tag','output_units'),'value');

                    if output_gravity_units == 1
                        output_gravity_units_text = 'μGal';
                        gravity_multiplier = 1;
                        format = '%.1f';
                    elseif output_gravity_units == 2
                        output_gravity_units_text = 'mGal';
                        gravity_multiplier = 0.001;
                        format = '%.4f';
                    else
                        output_gravity_units_text = 'nm/s²';
                        gravity_multiplier = 10;
                        format = '%.0f';
                    end

                    % get calibration factor from GUI
                    calibration_factor = str2double(get(findobj('tag','calibration'),'string'));
                    if isnan(calibration_factor)
                        calibration_factor = [];
                    end

                    % get report file path
                    report_file = get(findobj('tag','push_report_file_name'),'userdata');
                    % get plot errors option button
                    plot_errors_option = get(findobj('tag','check_graphics'),'value');
                    % get plot errors extent button value
                    plot_errors_extent = get(findobj('tag','check_graphics_extent'),'value');
                    % get summary option
                    summary_option = get(findobj('tag','check_summary'),'value');
                    % get save gravity difference options
                    store_gravity_dif = get(findobj('tag','check_gravity_dif'),'value');

                    % - workaround. measured levels is number value in pop
                    % up window, number of measured levels is exact number,
                    % for measured levels == 5 we use blank so the software
                    % automaticaly takes number of measured levels fro
                
                    if measured_levels == 1
                        number_of_measured_levels = 2;
                    elseif measured_levels == 2
                        number_of_measured_levels = 3;
                    elseif measured_levels == 3
                        number_of_measured_levels = 4;
                    elseif measured_levels == 4
                        number_of_measured_levels = 5;
                    elseif measured_levels == 5
                        number_of_measured_levels = []; 
                    end

                    clear measured_levels
                    
                % calling function from command line.
                elseif GUI == 0
                    
                    input_files = input_files;
                    instrument_type = instrument_type;
                    header_lines = header_lines;
                    input_units_option = input_units_option;
                    SD00 = uncertainty;
                    SD_scale_information = SD_scale_information;
                    number_of_measured_levels = number_of_measured_levels;
                    significance = significance_level;
                    rejection_threshold = rejection_threshold;
                    gradient_output_format = gradient_output_format;
                    reference_point = reference_point;
                    reference_value = reference_value;
                    output_gravity_units = output_gravity_units;

                    if output_gravity_units == 1
                        output_gravity_units_text = 'μGal';
                        gravity_multiplier = 1;
                        format = '%.1f';
                    elseif output_gravity_units == 2
                        output_gravity_units_text = 'mGal';
                        gravity_multiplier = 0.001;
                        format = '%.4f';
                    else
                        output_gravity_units_text = 'nm/s²';
                        gravity_multiplier = 10;
                        format = '%.0f';
                    end


                    switch gradient_output_format
                        case 'linear'
                        gradient_format = 1;
                        case 'function'
                        gradient_format = 2;
                    end

                    calibration_factor = calibration_factor;
                    report_file = report_file;
                    plot_errors_option = plot_errors_option;
                    summary_option = summary_option;
                    store_gravity_dif = store_gravity_dif;
                end
                
%_______________Calculations start____________________%
                if isempty(report_file);
                   fprintf('No file & directory set for the report file \n')
                else
                % number of files selected by user
                    if store_gravity_dif == 0
    
                        % check number of files
                        [nfiles,~] = size(input_files);
                        % if number of files is zero, no files have
                        % been chosen by the user
                        if nfiles == 0
                            fprintf('input files are missing \n')
                        else
    
                            % initilize variable that counts rejected files starting at zero, for each rejected file +1 is added to this variable    
                            rejected_files = 0;
                            
                            % initialize station ID variable to save
                            % station IDs and storedata variable to change
                            % within each iteration
                            stationID = [];
                            storedata = [];
    
                            for i = 1:nfiles
                                input_file = input_files(i,:);
                                fprintf('Processing file %.0f/%.0f \nNamed: %s\n', i, nfiles, input_file);
                                % prevents overrunning input file
                                preserve = input_file(1:end-4);
                                % compares input and output file name and returns 0 or 1;
                                overguard = strcmp(preserve,report_file);
                                % in case input and output file match, output sufix is
                                % added to original filename
                                if overguard == 1
                                    report_file = strcat(report_file,'_output');
                                end

                                if gradient_format == 1
                                    % call output_linear function
                                    output = gradient_linear(input_file,header_lines,instrument_type,calibration_factor,SD_scale_information,number_of_measured_levels,input_units_option,significance,SD00);
                                    
                                    % compose report for each processed file
                                    % empty line at the start each
                                    % processing report
                                    report(1,i) = "";
                                    report(2,i) = strcat("processed file: ",output.stationinfo.filename);
                                    report(3,i) = strcat("point ID: ",output.stationinfo.ID);
                                    report(4,i) = strcat("measurement date: ",output.stationinfo.measurement_date);
        
                                    % check for accepted or rejected status
                                    if output.gradient.std_num*gravity_multiplier > rejection_threshold*gravity_multiplier
                                        report(5,i) = "status: rejected";
                                    else
                                        report(5,i) = "status: accepted";
                                    end
                                    
                                    report(6,i) = strcat("number of measurements accepted: ",num2str(output.processing.number_of_measurements,'%.0f'));
                                    report(7,i) = strcat("number of outliers: ",num2str(output.processing.number_of_rejected_measurements,'%.0f'));
                                    report(8,i) = strcat("root mean square error ",output_gravity_units_text,": ",num2str(output.processing.RMSE*gravity_multiplier,format));
                                    report(9,i) = strcat("drift polynomial degree: ",pad(num2str(output.drift.polynomial_degree,'%1.0f'),10));
                                    report(10,i) = strcat("average height [m],", "gradient",output_gravity_units_text,", standard deviation ");
                                    report(11,i) = sprintf(['%.3f, ', format, ', ', format], ...
                                                        output.gradient.average_height_num, ...
                                                        output.gradient.average_gradient_num * gravity_multiplier, ...
                                                        output.gradient.std_num * gravity_multiplier);

                                    % count rejected files
                                    if output.gradient.std_num*gravity_multiplier > rejection_threshold*gravity_multiplier
                                        rejected_files = rejected_files +1;
                                    end                                   

                                    % store summary data
                                    stationID = [string(stationID); string(output.stationinfo.ID)];
                                    sumdata = [output.gradient.average_gradient_num*gravity_multiplier output.gradient.std_num*gravity_multiplier];
                                    storedata = [storedata; sumdata];

                                    if plot_errors_option == 1
                                        % Create figure and tiled layout
                                        F = figure;
                                        ax = axes(F);
                                        cla(ax,'reset');
                                        % clear figure every time
                                        F.Position(3) = F.Position(3) * 1.10;   % width ×1.10
                                        F.Position(4) = F.Position(4) * 1.40;   % height ×1.30
                                        hold(ax,'on');
                                        % ---- Ensure top stays below upper 15% of screen ----
                                        screen = get(0, 'ScreenSize');
                                        screen_height = screen(4);
                                        top_limit = screen_height * 0.85;   % keep below top 15%
                                        bottom = F.Position(2);
                                        height = F.Position(4);
                                        top_of_figure = bottom + height;
                                        
                                        % If too tall, push figure downward
                                        if top_of_figure > top_limit
                                            F.Position(2) = top_limit - height;
                                        end
                                        hold on
                                        
                                        plot(output.time.all_measurements, output.drift.drift_all_measurements*gravity_multiplier, '--', 'color','black', 'LineWidth', 0.9);
                                        title(ax, sprintf('Measured station code: %s', string(output.stationinfo.ID)));
                                        scatter(output.time.all_measurements, output.processing.errors_all*gravity_multiplier, 10, 'b', 'filled');
                                        scatter(output.time.outliers, output.processing.errors_outliers*gravity_multiplier, 10, 'r', 'filled');
                                        hAdj = plot(output.time.no_outliers, output.drift.drift_no_outliers*gravity_multiplier, 'color', 'black', 'LineWidth', 1);
                                        
                                        ylabel(output_gravity_units_text)
                                        xlabel('time')
                                        set(gca, 'YGrid', 'on', 'XGrid', 'off')
                                        
                                        % ---- Build dynamic equation text ----
                                        params = output.drift.drift_parameters;
                                        if output.drift.polynomial_degree == 2
                                            a = params(1); b = params(2); c = params(3);
                                            eq_text = sprintf('y(t) = %.4f + %.4f t + %.4f t^{2}', a, b, c);
                                        elseif output.drift.polynomial_degree == 1
                                            a = params(1); b = params(2);
                                            eq_text = sprintf('y(t) = %.4f + %.4f t', a, b);
                                        else
                                            eq_text = 'y(t) = (unsupported degree)';
                                        end

                                        % ---- Compose legend entries, embedding eq_text into adjusted-drift label ----
                                        leg_entries = { ...
                                            'approximate drift', ...
                                            'accepted measurements', ...
                                            'outliers', ...
                                            sprintf('adjusted drift \n%s', eq_text) ...
                                        };
                                        % Create legend below the axes, horizontal orientation
                                        lgd = legend(leg_entries, 'Location', 'southoutside', 'Orientation', 'vertical', 'Box', 'on');
                                        set(lgd,'Interpreter','tex');
                                        try
                                            % 1) Preferred: remove all interactions (HG2)
                                            if isprop(lgd,'Interactions')
                                                lgd.Interactions = [];   % disable interactive behaviors
                                            end
                                        catch
                                            % ignore if not supported
                                        end
                                        try
                                            % 2) Prevent clicks/picks on the legend (newer graphics)
                                            if isprop(lgd,'PickableParts')
                                                lgd.PickableParts = 'none';   % makes legend ignore mouse hits
                                            end
                                            if isprop(lgd,'HitTest')
                                                lgd.HitTest = 'off';          % older option to ignore mouse
                                            end
                                        catch
                                            % ignore if not supported
                                        end
                                        try
                                            % 3) Remove context menu — no right-click menu appears
                                            if isprop(lgd,'ContextMenu')
                                                lgd.ContextMenu = []; 
                                            end
                                        catch
                                            % ignore if not supported
                                        end
                                        try
                                            % 4) Ensure the axes do not auto-adjust when legend moves
                                            ax = lgd.PlotChildren(1).Parent; % safe attempt to get axes
                                            if ~isempty(ax) && isprop(ax,'ActivePositionProperty')
                                                ax.ActivePositionProperty = 'position';
                                            end
                                        catch
                                            % ignore lookup failures
                                        end
                                        % OPTIONAL: also stop the legend from responding to clicks on individual items
                                        % (useful if you previously used ItemHitFcn). Clear it if present:
                                        try
                                            if isprop(lgd,'ItemHitFcn')
                                                lgd.ItemHitFcn = [];
                                            end
                                        catch
                                        end
                                        set(F, 'Renderer', 'painters');

                                        if plot_errors_extent == 1
                                            ylim([-100*gravity_multiplier 100*gravity_multiplier])
                                        end

                                        print(F,strcat(report_file(1:end),"_",num2str(i,'%2.0f')),'-djpeg','-r400')
                                        
                                    end

                                elseif gradient_format == 2
                                
                                    % call processing function
                                    output = gradient_function(input_file, header_lines,instrument_type, calibration_factor, SD_scale_information, input_units_option,significance,SD00);
                                    % compose report for each processed file
                                    % empty line at the start each
                                    % processing report

                                    report(1,i) = "";
                                    report(2,i) = strcat("processed file: ",output.stationinfo.filename);
                                    report(3,i) = strcat("point ID: ",output.stationinfo.ID);
                                    report(4,i) = strcat("measurement date: ",output.stationinfo.measurement_date);

                                    % check for accepted or rejected status
                                    if output.gradient.std(1)*gravity_multiplier > rejection_threshold*gravity_multiplier
                                        report(5,i) = "status: rejected";

                                    elseif output.processing.number_of_rejected_measurements > 0.5*output.processing.number_of_measurements
                                        report(5,i) = "status: rejected";
                                    else
                                        report(5,i) = "status: accepted";
                                    end
                                    
                                    report(6,i) = strcat("number of measurements accepted: ",num2str(output.processing.number_of_measurements,'%.0f'));
                                    report(7,i) = strcat("number of outliers: ",num2str(output.processing.number_of_rejected_measurements,'%.0f'));
                                    report(8,i) = strcat("root mean square error ",output_gravity_units_text,": ",num2str(output.processing.RMSE*gravity_multiplier,'%.1f'));
                                    report(9,i) = strcat("drift polynomial degree: ",output.drift.polynomial_degree);
                                    report(10,i) = strcat("gradient polynomial degree: ",output.gradient.polynomial_degree);
                                    report(11,i) = strcat("gradient parameters",output_gravity_units_text,"/m");
                                    report(12,i) = string(strjoin(arrayfun(@(x) num2str(x),output.gradient.gradient_param*gravity_multiplier,'UniformOutput',false),','));
                                    report(13,i) = string("standard deviation ",output_gravity_units_text,"/m");
                                    report(14,i) = string(strjoin(arrayfun(@(x) num2str(x),output.gradient.std*gravity_multiplier,'UniformOutput',false),','));
                                    report(15,i) = strcat("covariance:",string(output.gradient.cov*gravity_multiplier));
    

                                    % % store summary data
                                    stationID = [string(stationID); string(output.stationinfo.ID)];
                                    sumdata = [output.gradient.gradient_param*gravity_multiplier' output.gradient.std*gravity_multiplier' output.gradient.cov*gravity_multiplier];
                                    storedata = [storedata; sumdata];

                                    % plot errors compared to approximate and
                                    % adjusted drift
                                    if plot_errors_option == 1

                                        F = figure;
                                        hold on
                                        plot(output.time.all_measurements,output.drift.drift_all_measurements*gravity_multiplier,'--','color','black','LineWidth',0.9);
                                        scatter(output.time.all_measurements,output.processing.errors_all*gravity_multiplier,10,'r','filled');
                                        scatter(output.time.no_outliers,output.processing.outliers_removed*gravity_multiplier,10,'b','filled');
                                        
                                        plot(output.time.no_outliers,output.drift.drift_no_outliers*gravity_multiplier,'color','black','LineWidth',1);
                                        set(gca, 'YGrid', 'on', 'XGrid', 'off');

                                        ylabel(output_gravity_units_text)
                                        xlabel('time')
                                        legend('approximate drift','outliers','accepted measurements','adjusted drift','Location','best')
                                        
                                        if plot_errors_extent == 1
                                            ylim([-100*gravity_multiplier 100*gravity_multiplier])
                                        end

                                        print(F,strcat(report_file(1:end),"_",num2str(i,'%2.0f')),'-djpeg','-r400')
                                    end
    
                                    % count rejected files
                                    if output.gradient.std(1)*gravity_multiplier > rejection_threshold*gravity_multiplier
                                        rejected_files = rejected_files +1;
                                    end
                                end
                            end
                        end
    
                        % summary header
                        headerline(1,1) = "Summary";
                        headerline(2,1) = strcat("number of processed files: ",num2str(nfiles,'%.0f'));
                        headerline(3,1) = strcat("number of files exceeding the rejection threshold: ", num2str(rejected_files,'%.0f'));
                        headerline(4,1) = strcat("calibration factor used: ", num2str(calibration_factor,'%8.7f'));
                        headerline(5,1) = strcat("instrument used: ",instrument_type);
                        headerline(6,1) = strcat("computation performed on: ", string(datetime("today")));
                        if significance == 1 
                            confidence = '68%';
                        elseif significance == 2 
                            confidence = '95%';
                        elseif significance == 3
                            confidence ='99.7%';
                        end
                        headerline(7,1) = strcat("confidence: ", confidence);
                        if gradient_format == 1
                            headerline(8,1) = strcat("processing method: linear");
                            headerline(9,1)= strcat("gradient units: ",output_gravity_units_text,"/m");
                        elseif gradient_format == 2
                            headerline(8,1) = strcat("processing method: function AH + BH²");
                            headerline(9,1)= strcat("Parameter units: A[",output_gravity_units_text,"/m]","B[",output_gravity_units_text,"/m²]");
                        end
                        headerline(10,1) = "End of summary";
    
                        % reshape header
                        report = reshape(report,[],1);
                        % create file and write data
                        fid = fopen(strcat(report_file,'.txt'),'w');
                        fprintf(fid,'%s\n',headerline);
                        fprintf(fid,'%s\n',report);
                        fclose(fid);
    
                        if summary_option == 1
                            filename = strcat(report_file,'_summary.xlsx');
    
                            if gradient_format == 1
                                T = table(stationID,storedata(:,1),storedata(:,2));
                                T.Properties.VariableNames{1,1} = 'Station ID';
                                T.Properties.VariableNames{1,2} = 'Gradient';
                                T.Properties.VariableNames{1,3} = 'Gradient SD';
                                
                            elseif gradient_format == 2
                                T = table(stationID,storedata(:,1),storedata(:,2),storedata(:,3),storedata(:,4),storedata(:,5));
                                T.Properties.VariableNames{1,1} = 'Station ID';
                                T.Properties.VariableNames{1,2} = 'A';
                                T.Properties.VariableNames{1,3} = 'B';
                                T.Properties.VariableNames{1,4} = 'SD_A';
                                T.Properties.VariableNames{1,5} = 'SD_B';
                                T.Properties.VariableNames{1,6} = 'cov_A_B';

                            end
                            % save data into xlsx file
                            writetable(T,filename);
                        end
                      

        % switch to standard gravity difference processing
                    elseif store_gravity_dif == 1
                        % check number of files
                        [nfiles,~] = size(input_files);
                        % if number of files is zero, no files have
                        % been chosen by the user
                        if nfiles == 0
                            fprintf('input files are missing /n')
                        else

                        % initialize station ID variable to save
                        % station IDs and storedata variable to change
                        % within each iteration
                        stationID = [];
                        storedata = [];

                        % run through all the files and process them
                        for i = 1:nfiles
                            input_file = input_files(i,:);
                            fprintf('Processing file %.0f/%.0f \nNamed: %s\n', i, nfiles, input_file);
                            % prevents overrunning input file
                            preserve = input_file(1:end-4);
                            % compares input and output file name and returns 0 or 1;
                            overguard = strcmp(preserve,report_file);
                            % in case input and output file match, output sufix is
                            % added to original filename to prevent
                            % overwriting
                            if overguard == 1
                                report_file = strcat(report_file,'_output');
                            end
                            % call function for gravity difference
                            % computing
                            output = gravity_differences(input_file,header_lines,instrument_type,calibration_factor,SD_scale_information,input_units_option,significance,reference_point,SD00);
                            
                            report(1,i) = "";
                            report(2,i) = strcat("processed file: ",output.stationinfo.filename);
                            report(3,i) = strcat("measurement date: ",output.stationinfo.measurement_date);                                     
                            report(4,i) = strcat("number of measurements accepted: ",num2str(output.processing.number_of_measurements - output.processing.rejected_measurements,'%.0f'));
                            report(5,i) = strcat("number of outliers: ",num2str(output.processing.rejected_measurements,'%.0f'));
                            report(6,i) = strcat("drift polynomial degree: ",output.drift.polynomial_degree);
                            report(7,i) = strcat("root mean square error", output_gravity_units_text,": ",num2str(output.processing.RMSE*gravity_multiplier,'%.1f'));

                            og = output.stationinfo.ID;
                            mp = output.stationinfo.measuredpoints;
                            gd = output.adjusted.differences*gravity_multiplier;
                            sd = output.adjusted.std*gravity_multiplier;

                           % if reference value is not provided,
                           % continue with graivty differences
                            if isempty(reference_value)

                                reference_value = [];
                                report(8,i) = strcat("reference point: ", reference_point," gravity:");
                                report(9,i) = "####################################################################################";
                                report(10,i) = strcat("starting point, ending point, gravity difference [", output_gravity_units_text, "], standard deviation [",output_gravity_units_text,"]");

                                for zz = 1:length(mp)
                                    report(10+zz,i) = strcat(og,", ",...
                                        mp(zz),", ",...
                                        num2str(gd(zz),format),", ", ...
                                        num2str(sd(zz),format));
                                end
                                
                                report(11+length(mp),i) = "####################################################################################";

                            % if reference value is provided, switch to
                            % full gravity values
                            elseif ~isempty(reference_value)
                                reference_value_num = str2double(reference_value);
                                report(8,i) = strcat("reference point: ", reference_point," gravity: ", reference_value, "[",output_gravity_units_text,"]");
                                report(9,i) = "####################################################################################";
                                report(10,i) = strcat("measured point, gravity [", output_gravity_units_text, "], standard deviation [",output_gravity_units_text,"]");

                                for zz = 1:length(mp)
                                    report(10+zz,i) = strcat(mp(zz),", ",...
                                        num2str(gd(zz)+reference_value_num,format),", ", ...
                                        num2str(sd(zz),format));
                                end
                                
                                report(11+length(mp),i) = "####################################################################################";

                            else
                                error('I hereby declare that I have no idea what is happening and am genuinely curious how you achieved this')
                            end

                            if isempty(reference_value)
                                % Store summary data for all measured points
                                stationID = [stationID; ...
                                             repmat(string(og), length(mp), 1), string(mp)];
                                storedata = [storedata; ...
                                             gd(:), sd(:)];
                            else
                                % Store absolute gravity values
                                stationID = [stationID; string(mp(:))];
                            
                                gravity_values = gd(:) + str2double(reference_value);
                                storedata = [storedata; ...
                                             gravity_values, sd(:)];
                            end

                            % plot errors compared to approximate and
                            % adjusted drift

                            if plot_errors_option == 1
                                F = figure;
                                ax = axes(F);
                                cla(ax,'reset');
                                % clear figure every time
                                F.Position(3) = F.Position(3) * 1.10;   % width ×1.10
                                F.Position(4) = F.Position(4) * 1.40;   % height ×1.30
                                hold(ax,'on');
                                % ---- Ensure top stays below upper 15% of screen ----
                                screen = get(0, 'ScreenSize');
                                screen_height = screen(4);
                                top_limit = screen_height * 0.85;   % keep below top 15%
                                bottom = F.Position(2);
                                height = F.Position(4);
                                top_of_figure = bottom + height;
                                
                                % If too tall, push figure downward
                                if top_of_figure > top_limit
                                    F.Position(2) = top_limit - height;
                                end
                                hold on

                                plot(output.time.all_measurements,output.drift.drift_all_measurements*gravity_multiplier,'--','color','black','LineWidth',0.9);
                                title(ax, sprintf('Measured station code: %s', string(output.stationinfo.ID)));
                                scatter(output.time.all_measurements,output.processing.errors_all*gravity_multiplier,10,'b','filled');
                                scatter(output.time.outliers,output.processing.errors_outliers*gravity_multiplier,10,'r','filled');
                                hAdj = plot(output.time.no_outliers, output.drift.drift_no_outliers*gravity_multiplier, 'color', 'black', 'LineWidth', 1);
                                ylabel(output_gravity_units_text)
                                xlabel('time')

                                % ---- Build dynamic equation text ----
                                    params = output.drift.drift_parameters*gravity_multiplier;
                                    if output.drift.polynomial_degree == 2
                                        a = params(1); b = params(2); c = params(3);
                                        eq_text = sprintf('y(t) = %.4f + %.4f t + %.4f t^{2}', a, b, c);
                                    elseif output.drift.polynomial_degree == 1
                                        a = params(1); b = params(2);
                                        eq_text = sprintf('y(t) = %.4f + %.4f t', a, b);
                                    else
                                        eq_text = 'y(t) = (unsupported degree)';
                                    end
                                    % ---- Compose legend entries, embedding eq_text into adjusted-drift label ----
                                    leg_entries = { ...
                                        'approximate drift', ...
                                        'accepted measurements', ...
                                        'outliers', ...
                                        sprintf('adjusted drift \n%s', eq_text) ...
                                    };
                                    % Create legend below the axes, horizontal orientation
                                    lgd = legend(leg_entries, 'Location', 'southoutside', 'Orientation', 'vertical', 'Box', 'on');
                                    set(lgd,'Interpreter','tex');
                                    try
                                        % 1) Preferred: remove all interactions (HG2)
                                        if isprop(lgd,'Interactions')
                                            lgd.Interactions = [];   % disable interactive behaviors
                                        end
                                    catch
                                        % ignore if not supported
                                    end
                                    try
                                        % 2) Prevent clicks/picks on the legend (newer graphics)
                                        if isprop(lgd,'PickableParts')
                                            lgd.PickableParts = 'none';   % makes legend ignore mouse hits
                                        end
                                        if isprop(lgd,'HitTest')
                                            lgd.HitTest = 'off';          % older option to ignore mouse
                                        end
                                    catch
                                        % ignore if not supported
                                    end
                                    try
                                        % 3) Remove context menu — no right-click menu appears
                                        if isprop(lgd,'ContextMenu')
                                            lgd.ContextMenu = []; 
                                        end
                                    catch
                                        % ignore if not supported
                                    end
                                    try
                                        % 4) Ensure the axes do not auto-adjust when legend moves
                                        ax = lgd.PlotChildren(1).Parent; % safe attempt to get axes
                                        if ~isempty(ax) && isprop(ax,'ActivePositionProperty')
                                            ax.ActivePositionProperty = 'position';
                                        end
                                    catch
                                        % ignore lookup failures
                                    end
                                    % OPTIONAL: also stop the legend from responding to clicks on individual items
                                    % (useful if you previously used ItemHitFcn). Clear it if present:
                                    try
                                        if isprop(lgd,'ItemHitFcn')
                                            lgd.ItemHitFcn = [];
                                        end
                                        
                                    catch
                                    end
                                    set(F, 'Renderer', 'painters');

                                    if plot_errors_extent == 1

                                        ylim([-100*gravity_multiplier 100*gravity_multiplier])

                                        % axis extent specified
                                    end

                                    print(F,strcat(report_file(1:end),"_",num2str(i,'%2.0f')),'-djpeg','-r400')                
                                end
                            end
                        end
                        
                        % summary header
                        headerline(1,1) = "Summary";
                        headerline(2,1) = strcat("number of processed files: ",num2str(nfiles,'%.0f'));
                        headerline(3,1) = strcat("computation performed on: ", string(datetime("today")));
                        headerline(4,1) = strcat("calibration factor: ", num2str(calibration_factor,'%8.7f'));
                        headerline(5,1) = strcat("instrument used: ",instrument_type);
                        headerline(6,1) = strcat("instrument uncertainty used in μGal: ", num2str(SD00,'%2.0f'));
                        if significance == 1 
                            confidence = '68%';
                        elseif significance == 2 
                            confidence = '95%';
                        elseif significance == 3
                            confidence ='99.7%';
                        end
                        
                        headerline(7,1) = strcat("confidence: ", confidence);
                        headerline(8,1) = "End of summary";
    
                        % reshape header
                        report = reshape(report,[],1);
                        report = rmmissing(report);

                        % create file for writing data
                        fid = fopen(strcat(report_file,'.txt'),'w');
                        fprintf(fid,'%s\n',headerline);
                        fprintf(fid,'%s\n',report);
                        fclose(fid);

                        if summary_option == 1
                            filename = strcat(report_file,'_summary.xlsx');

                            if isempty(reference_value)
                                T = table(stationID(:,1), ...
                                          stationID(:,2), ...
                                          storedata(:,1), ...
                                          storedata(:,2));
                            
                                T.Properties.VariableNames = { ...
                                    'Reference station', ...
                                    'Station ID', ...
                                    'Gravity difference', ...
                                    'Gravity SD'};
                            
                            else
                                T = table(stationID, ...
                                          storedata(:,1), ...
                                          storedata(:,2));
                                
                                T.Properties.VariableNames = { ...
                                    'Station ID', ...
                                    'Gravity', ...
                                    'Gravity SD'};
                            end

                            % save data into xlsx file
                           writetable(T,filename);
                       end

                    % end for store_ gravity_dif    
                    end
                end
                % finished
           % Close button
            case 'Close'
               close all
        end
    end
end
% End of Main Function
%
%
%
%
%
%
%
%
%
%
% % Additional functions called within processing, DO not remove, delete or
% move these.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%________________________________________________________________________

% Callback for instrument used
function instrument_callback(hObject, ~)
    % Get the selected value from the instrument popup menu
    instrument_value = get(hObject, 'Value');

    % Find the SD scaling and height units controls
    SD_scaling = findobj('Tag', 'SD_scaling');
    units_option = findobj('Tag', 'units_option');
    edit_pocet_riadkov = findobj('Tag', 'edit_pocet_riadkov');

    % Check if "CG6" (second option) is selected
    if instrument_value == 2
        % Disable and darken the "SD scaling" and "height units" controls
        set(SD_scaling, 'Enable', 'off', 'BackgroundColor', [0.8 0.8 0.8]);
        set(units_option, 'Enable', 'off', 'BackgroundColor', [0.8 0.8 0.8]);
        set(edit_pocet_riadkov, 'String', '21');
        % set(edit_pocet_riadkov, 'Enable', 'off', 'BackgroundColor', [0.8 0.8 0.8]);
        
    else
        % Enable and reset the "SD scaling" and "height units" controls
        set(SD_scaling, 'Enable', 'on', 'BackgroundColor', 'white');
        set(units_option, 'Enable', 'on', 'BackgroundColor', 'white');
        set(edit_pocet_riadkov, 'Enable', 'on', 'BackgroundColor', 'white');
        set(edit_pocet_riadkov, 'String', '34');
    end

end


% Callback for gradient method used
function gradient_method_callback(hObject, ~)

    % Get the selected value from the instrument popup menu
    gradient_option_value = get(hObject, 'Value');
    
    % Find the number of measured positions window
    num_of_positions = findobj('Tag', 'number_measured_levels');

    % Check if gradient option is set to function
    if gradient_option_value == 2

        % Disable and darken the number of positions window
        set(num_of_positions, ...
            'Enable', 'off', ...
            'BackgroundColor', [0.8 0.8 0.8]);
    else
        % Enable and reset the number of positions window
        set(num_of_positions, ...
            'Enable', 'on', ...
            'BackgroundColor', 'white');
    end

end


% Callback for standard gravity data processing - turning off gradient
% option
function processing_callback(hObject, ~)

    % Get the selected value from the checkbox
    processing_value = get(hObject, 'Value');
    % Find UI objects
    num_of_positions = findobj('Tag', 'number_measured_levels');
    gradient_format   = findobj('Tag', 'gradient_option');
    reference_point   = findobj('Tag', 'ref_point');
    reference_value   = findobj('Tag', 'ref_value');

    % Standard gravity data processing selected
    if processing_value == 1

        % Enable reference point and reference value
        set(reference_point, ...
            'Enable', 'on', ...
            'BackgroundColor', 'white');

        set(reference_value, ...
            'Enable', 'on', ...
            'BackgroundColor', 'white');

        % Disable gradient-related options
        set(num_of_positions, ...
            'Enable', 'off', ...
            'BackgroundColor', [0.8 0.8 0.8]);

        set(gradient_format, ...
            'Enable', 'off', ...
            'BackgroundColor', [0.8 0.8 0.8]);

    else
        % Disable reference point and reference value
        set(reference_point, ...
            'Enable', 'off', ...
            'BackgroundColor', [0.8 0.8 0.8]);

        set(reference_value, ...
            'Enable', 'off', ...
            'BackgroundColor', [0.8 0.8 0.8]);

        % Enable gradient-related options
        set(num_of_positions, ...
            'Enable', 'on', ...
            'BackgroundColor', 'white');

        set(gradient_format, ...
            'Enable', 'on', ...
            'BackgroundColor', 'white');

    end
end

% Linear gradient _______________________________________________________________
function [output_linear] = gradient_linear(input_file, ...
                                           header_lines, ...
                                           instrument_type, ...
                                           calibration_factor, ...
                                           SD_scale_information, ...
                                           number_of_measured_levels, ...
                                           input_units_option, ...
                                           significance,...
                                           SD00)
    
    % file reading
    if instrument_type == 'CG5'
        [points,dtime,dn,YY,height,grav,ERR] = read_CG5(input_file,header_lines,calibration_factor,SD_scale_information,input_units_option);
    elseif instrument_type == 'CG6'
        [points,dtime,dn,YY,height,grav,ERR] = read_CG6(input_file,header_lines,calibration_factor);
    end

    % get unique points (string)
    uniquepoints = unique(points, 'stable');
    pts_num = str2double(uniquepoints(1));
    if isnan(pts_num) == 1
        measured_station_ID = uniquepoints(1);
    elseif isnan(pts_num) == 0
        measured_station_ID = num2str(pts_num,'%8.2f');
    end

    % Least Square Adjustment - deterministic model
    n0 = length(points); % number of measurements taken
    k = length(uniquepoints); % number of measured levels
    
    % drift polynomial degree - initially, quadratic polynomial is
    % considered, however later testing can prove quadratic component to
    % be unsignificant and withdrawn from the adjusting process
    polynomial_degree = 2;
    
    % Jacobi matrix, point section
    for i = 1:k
    ind = find(points == uniquepoints(i));
        A(ind,i) = 1; A(~ind,i) = 0;
        % average height for individual measured levels
        level_height(i,1) = mean(height(ind));
    end

    % Jacobi matrix, drift part
    A(:,k+1) = 1;
    for i = k+2:k+1+polynomial_degree
       A(:,i) = (dn - dn(1)).^(i -(k+1));
    end

    % regularization - by default first column is removed to fix position 1
    % as starting
    A(:,1)= [];
    
    % weights
    weight = mean(ERR)./ERR;

    % weight matrix
    P = diag(weight);

    % Covariance matrix of measurements
    Q = P^-1; C = (SD00^2)*Q;
    
    % parameter adjustment usint LSE formulas
    adjusted_parameters = (A'/C*A)\A'/C*grav;
    % measurement errors to adjusted parameters
    v = (A*adjusted_parameters) - grav;
    % Root mean square error
    rmse1 = sqrt((v'*inv(C)*v)/(n0-k-2-polynomial_degree));
    % Covariance matrix of adjusted parameters
    C_theta = (rmse1^2)*inv(A'*inv(C)*A);
    % standard deviation of adjusted parameters
    SD_theta = sqrt(diag(C_theta));

    % drift coeficients
    drift_koef = adjusted_parameters(end-polynomial_degree:end);
    % drift section of Jacobi matrix
    AA = A(:,end-polynomial_degree:end);
    % residual (transportation drift)
    res_drift = AA*drift_koef;
    % test values 
    test = res_drift + v;
    % average drift value to subtract later
    res_drift_av = mean(res_drift);
    
    % outliers testing
    if significance == 1
        significance_level = 0.32;
        students_inverse_approximate = 480.7*exp(-2.068*(n0-k)) + 2.847*exp(-0.000441*(n0-k));

    elseif significance == 2
        significance_level = 0.05;
        students_inverse_approximate = 43.06*exp(-1.403*(n0-k)) + 2.071*exp(-0.0002368*(n0-k));

    elseif significance == 3
        significance_level = 0.01;
        students_inverse_approximate = 1.633*exp(-0.7396*(n0-k)) + 1.013*exp(-7.638e-05*(n0-k));
    end

    % outliers indexes 
    index_outliers = find(abs(v)>=SD00*rmse1*significance);
    
    % Statistical testing of parameters, where Tau is a result of
    % statistic test representing a Student's distribution
    Tau = adjusted_parameters(end)/SD_theta(end);

    % quadratic component significance testing by comparison to inverse
    % Student t's distribution values.
    
    % Check for statistic toolbox license


%%%%%%%%%%%%%%     hasLicenseForToolbox = license('test', 'Statistics_Toolbox');
    hasLicenseForToolbox = 0;
    
    if hasLicenseForToolbox == 0 % if working without statistic toolbox
        if abs(Tau) < students_inverse_approximate % approximate table values for 1/2/3 sigma and 
            polynomial_degree_new = 1; % drift approx. function set to linear
        else
            polynomial_degree_new = 2; % drift approx. function remains quadratic
        end

    elseif hasLicenseForToolbox == 1 % if working with statistic toolbox
        % critical value from Students t distribution
        students_inverse = tinv(1-(significance_level)/2,n0-k);
        
        if abs(Tau) < students_inverse
            polynomial_degree_new = 1; % drift approx. function set to linear
        else
            polynomial_degree_new = 2; % drift approx. function remains quadratic
        end
    end

    % removing outliers 
    grav(index_outliers) = [];
    dn(index_outliers) = [];
    points(index_outliers) = [];
    ERR(index_outliers) = [];
    YY(index_outliers) = [];
    
    n = length(points);
    clear A AA C Q v C_theta
    % reprocessing without outliers
    for i = 1:k
    ind = find(points == uniquepoints(i));
        A(ind,i) = 1; A(~ind,i) = 0;
    end
    % the not so useful part of Jacobi's matrix
    A(:,k+1) = 1;
    for i = k+2:k+1+polynomial_degree_new
       A(:,i) = (dn - dn(1)).^(i -(k+1));
    end
    
    % Jacobi Matrix new
    A(:,1)=[];
    
    % New weighing
    weight= mean(ERR)./ERR;
    P = diag(weight);
    Q = P^-1; C = (SD00^2)*Q; % Factor and Covariance matrix
    
    % new adjusted parameters without considering outliers in the
    % processing
    adjusted_parameters_new = (A'/C*A)\A'/C*grav;
    % measurements errors to adjusted parameters
    v = (A*adjusted_parameters_new) - grav;
    rmse2 = sqrt((v'*inv(C)*v)/(n-k-2-polynomial_degree_new-1));           
    C_theta = (rmse2^2)*inv(A'*inv(C)*A);                   
    SD_theta_new = sqrt(diag(C_theta));
    
    drift_koef2 = adjusted_parameters_new(end-polynomial_degree_new:end);
    AA = A(:,end-polynomial_degree_new:end);
    % new drift
    res_drift_new = AA*drift_koef2;
    res_drift_new_av = mean(res_drift_new);

    % time information - dtime (datetime)
    dtime_t_new = datetime(dn,'ConvertFrom','datenum');
    MM = month(dtime_t_new); DD = day(dtime_t_new); hh = hour(dtime_t_new); mm = minute(dtime_t_new); ss = second(dtime_t_new);
    dtime_new = datetime(YY,MM,DD,hh,mm,ss);

    % for 2 levels
    if number_of_measured_levels == 2
        if length(uniquepoints)>number_of_measured_levels
            fprintf('File contains data from more than 2 points - Check point Id for any typos. \n')
        elseif length(uniquepoints) == number_of_measured_levels
            av_Wzz = adjusted_parameters_new(1)/abs(level_height(2) - level_height(1));
            sigma_av_Wzz = sqrt((SD_theta_new(1)/abs(level_height(2) - level_height(1)))^2);
            av_height = sum(level_height)/number_of_measured_levels;
        end

    % for 3 levels
    elseif number_of_measured_levels == 3
        if length(uniquepoints)>number_of_measured_levels
            fprintf('File contains data from more than 3 points - Check point Id for any typos. \n')
        elseif length(uniquepoints) == number_of_measured_levels

            % height differences
            height_dif(1) = abs(level_height(2) - level_height(1));
            height_dif(2) = abs(level_height(3) - level_height(1));
            height_dif(3) = abs(level_height(3) - level_height(2));

            % gradient between level 1 and level 2
            Wzz(1) = adjusted_parameters_new(1)/height_dif(1);
            sigma_Wzz(1) = sqrt((SD_theta_new(1)/height_dif(1))^2);

            % gradient between level 1 and level 3
            Wzz(2) = adjusted_parameters_new(2)/height_dif(2);
            sigma_Wzz(2) = sqrt((SD_theta_new(2)/height_dif(2))^2);

            % gradient between level 2 and 3
            Wzz(3) = (adjusted_parameters_new(2)-adjusted_parameters_new(1))/height_dif(3);
            dg_sigma = sqrt(SD_theta_new(1)^2 + SD_theta_new(2)^2);
            sigma_Wzz(3) = sqrt((dg_sigma/height_dif(3))^2);

            % average gradient
            av_Wzz = mean(Wzz);
            sigma_av_Wzz = sqrt((sigma_Wzz(1)^2/number_of_measured_levels) + (sigma_Wzz(2)^2/number_of_measured_levels) + (sigma_Wzz(3)^2+SD_theta_new(2)^2/number_of_measured_levels));
            av_height = sum(level_height)/number_of_measured_levels;
        end

    elseif isempty(number_of_measured_levels)

        if length(uniquepoints) == 2
            number_of_measured_levels =2;
            av_Wzz = adjusted_parameters_new(1)/abs(level_height(2) - level_height(1));
            sigma_av_Wzz = sqrt((SD_theta_new(1)/abs(level_height(2) - level_height(1)))^2);
            av_height = sum(level_height)/number_of_measured_levels;

        elseif length(uniquepoints) == 3
            number_of_measured_levels = 3;
            % height differences
            height_dif(1) = abs(level_height(2) - level_height(1));
            height_dif(2) = abs(level_height(3) - level_height(1));
            height_dif(3) = abs(level_height(3) - level_height(2));

            % gradient between level 1 and level 2
            Wzz(1) = adjusted_parameters_new(1)/height_dif(1);
            sigma_Wzz(1) = sqrt((SD_theta_new(1)/height_dif(1))^2); 

            % gradient between level 1 and level 3
            Wzz(2) = adjusted_parameters_new(2)/height_dif(2);
            sigma_Wzz(2) = sqrt((SD_theta_new(2)/height_dif(2))^2);

            % gradient between level 2 and 3
            Wzz(3) = (adjusted_parameters_new(2)-adjusted_parameters_new(1))/height_dif(3);
            dg_sigma = sqrt(SD_theta_new(1)^2 + SD_theta_new(2)^2);
            sigma_Wzz(3) = sqrt((dg_sigma/height_dif(3))^2);

            % average gradient
            av_Wzz = mean(Wzz);
            sigma_av_Wzz = sqrt((sigma_Wzz(1)^2/number_of_measured_levels) + (sigma_Wzz(2)^2/number_of_measured_levels) + (sigma_Wzz(3)^2+SD_theta_new(2)^2/number_of_measured_levels));
            av_height = sum(level_height)/number_of_measured_levels;

        elseif length(uniquepoints) == 4
            number_of_measured_levels = 4;
            relg = adjusted_parameters_new(1:end-polynomial_degree_new-1);
            % relative differences 
            Dg= [relg(3)-relg(2) relg(2)-relg(1) relg(1) relg(3) relg(3)-relg(1) relg(2)]';
            % gradients
            Wzz = [(Dg(1)/(level_height(4)-level_height(3))) (Dg(2)/(level_height(3)-level_height(2))) (Dg(3)/(level_height(2)-level_height(1))) (Dg(4)/(level_height(4)-level_height(1))) (Dg(5)/(level_height(4)-level_height(2))) (Dg(6)/(level_height(3)-level_height(1)))]';
            % average gradients
            av_Wzz = mean(Wzz);

            % standard deviation 
            SD_Wzz(1)=sqrt((SD_theta(2)/(level_height(4)-level_height(3)))^2);
            SD_Wzz(2)=sqrt((SD_theta(1)/(level_height(3)-level_height(2)))^2);
            SD_Wzz(3)=sqrt((SD_theta(4)/(level_height(2)-level_height(1)))^2+(SD_theta(1)/(level_height(2)-level_height(1)))^2);
            SD_Wzz(4)=sqrt((SD_theta(3)/(level_height(4)-level_height(1)))^2);
            SD_Wzz(5)=sqrt((SD_theta(1)/(level_height(4)-level_height(2)))^2+(SD_theta(3)/(level_height(4)-level_height(2)))^2);
            SD_Wzz(6)=sqrt((SD_theta(2)/(level_height(3)-level_height(1)))^2+(SD_theta(4)/(level_height(3)-level_height(1)))^2);
            % average standard deviation
            sigma_av_Wzz = mean(SD_Wzz);
            % average height
            av_height = sum(level_height)/number_of_measured_levels;

        elseif length(uniquepoints) > 4
            fprintf('Why would you measure at more than four levels? not integrated')
        end
    end
    
    output_linear.stationinfo.ID = measured_station_ID;
    output_linear.stationinfo.filename = pad(input_file,100);
    output_linear.stationinfo.measurement_date = char(dtime_new(1));

    output_linear.time.all_measurements = dtime;
    output_linear.time.no_outliers = dtime_new;
    output_linear.time.outliers = dtime(index_outliers);

    output_linear.processing.number_of_measurements = n0;
    output_linear.processing.number_of_rejected_measurements =n0 - n;
    output_linear.processing.errors_all = test - res_drift_av;
    output_linear.processing.errors_outliers = test(index_outliers) - res_drift_av;
    output_linear.processing.RMSE = rmse2*SD00;

    output_linear.drift.polynomial_degree = polynomial_degree_new;
    output_linear.drift.drift_all_measurements = (res_drift - res_drift_av);
    output_linear.drift.drift_no_outliers = (res_drift_new- res_drift_new_av);
    output_linear.drift.drift_parameters = (adjusted_parameters_new(end-(polynomial_degree_new):end));
    
    % numeric
    output_linear.gradient.average_height_num = av_height;
    output_linear.gradient.average_gradient_num = av_Wzz;
    output_linear.gradient.std_num = sigma_av_Wzz;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% gradient as a function of height and time
function [output_function] = gradient_function(input_file, ...
                                               header_lines, ...
                                               instrument_type, ...
                                               calibration_factor, ...
                                               SD_scale_information, ...
                                               input_units_option, ...
                                               significance,...
                                               SD00)
        % file reading
    if instrument_type == 'CG5'
        [points,dtime,dn,YY,height,grav,ERR] = read_CG5(input_file,header_lines,calibration_factor,SD_scale_information,input_units_option);
    elseif instrument_type == 'CG6'
        [points,dtime,dn,YY,height,grav,ERR] = read_CG6(input_file,header_lines,calibration_factor);
    end    

    uniquepoints = unique(points, 'stable');
    pts_num = str2double(uniquepoints(1));
    if isnan(pts_num) == 1
        measured_station_ID = uniquepoints(1);
    elseif isnan(pts_num) == 0
        measured_station_ID = num2str(pts_num,'%8.2f');
    end

    % deterministic model
    n0 = length(points); % number of measurements taken
    k = length(uniquepoints); % number of measured levels
    
    % drift polynomial degree - initially, quadratic polynomial is
    % considered, however later testing can prove quadratic component to
    % be unsignificant and withdrawn from the adjusting process
    polynomial_degree_time = 2;

    % initial polynomial degree is set to k-1, maximum possible. Number of
    % measured levels defines maximum possible poly degree.
    
    polynomial_degree_height = k-1;
    if k-1>2
        polynomial_degree_height = 2;
    end

    % Jacobi matrix creation - first column
    A(:,1) = ones(n0,1);
    
    % Jacobi matrix - 2nd part: height section
    for i = 2:polynomial_degree_height+1
       A(:,i) = (height).^(i-1);
    end

    % Jacobi matrix - 3rd part: drift section
    for i = 2+polynomial_degree_height:polynomial_degree_height+1+polynomial_degree_time
        A(:,i) = (dn - dn(1)).^(i -(1+polynomial_degree_height));
    end

    [~,lgt] = size(A);
   
    % weights
    weight = mean(ERR)./ERR;
    % weight matrix
    P = diag(weight);
    % Covariance matrix of measurements
    Q = P^-1; C = (SD00^2)*Q;
    
    adjusted_parameters = (A'/C*A)\A'/C*grav;
    % measurement errors to adjusted parameters
    v = (A*adjusted_parameters) - grav;
    % Root mean square error
    rmse1 = sqrt((v'*inv(C)*v)/(n0-lgt));
    % Covariance matrix of adjusted parameters
    C_theta = (rmse1^2)*inv(A'*inv(C)*A);
    % standard deviation of adjusted parameters
    SD_theta = sqrt(diag(C_theta));
    % drift coeficients
    drift_koef = adjusted_parameters(end-polynomial_degree_time+1:end);
    % drift section of Jacobi matrix
    A_drift = A(:,end-polynomial_degree_time+1:end);
    % residual (transportation drift)
    res_drift = A_drift*drift_koef;
    % test values 
    test1 = res_drift + v;
    % priemerna hodnota pre vykreslenie
    res_drift_av = mean(res_drift);

    % outliers test and statistic test 1
    % get approximate values for student t inverse distribution
    if significance == 1
        significance_level = 0.32;
        students_inverse_approximate = 480.7*exp(-2.068*(n0-k)) + 2.847*exp(-0.000441*(n0-k));

    elseif significance == 2
        significance_level = 0.05;
        students_inverse_approximate = 43.06*exp(-1.403*(n0-k)) + 2.071*exp(-0.0002368*(n0-k));

    elseif significance == 3
        significance_level = 0.01;
        students_inverse_approximate = 1.633*exp(-0.7396*(n0-k)) + 1.013*exp(-7.638e-05*(n0-k));
    end

    % outliers indexes 
    index_outliers = find(abs(v)>=SD00*rmse1*significance);
    
    % Statistical testing of both drift and height components, where Tau is a result of
    % statistic test representing a Student's distribution
    Tau1 = adjusted_parameters(end)/SD_theta(end);
    Tau2 = adjusted_parameters(end-polynomial_degree_time)/SD_theta(end-polynomial_degree_time);

    %hasLicenseForToolbox = license('test', 'Statistics_Toolbox');
    hasLicenseForToolbox = 0;


    if hasLicenseForToolbox == 0 % if working without statistic toolbox
        if abs(Tau1) < students_inverse_approximate % 
            polynomial_degree_time_final = polynomial_degree_time - 1; % drift approx. function set to linear
        else
            polynomial_degree_time_final = polynomial_degree_time; % drift approx. function remains quadratic
        end

        if abs(Tau2) < students_inverse_approximate  % 
            polynomial_degree_height_new = polynomial_degree_height - 1; % polynomial of gradient approx. function is reduced
        else
            polynomial_degree_height_new = polynomial_degree_height; % polynomial of gradient approx. function remains the same
        end

    elseif hasLicenseForToolbox == 1 % if working with statistic toolbox
        % critical value from Students t distribution
        students_inverse = tinv(1-(significance_level)/2,n0-lgt);
        
        if abs(Tau1) < students_inverse
            polynomial_degree_time_final = 1; % drift approx. function set to linear
        else
            polynomial_degree_time_final = 2; % drift approx. function remains quadratic
        end

        if abs(Tau2) < students_inverse
            polynomial_degree_height_new = polynomial_degree_height - 1; % polynomial of gradient approx. function is reduced by 1
        else
            polynomial_degree_height_new = polynomial_degree_height; % polynomial of gradient approx. function remains the same
        end
    end
    
    % removing outliers 1
    grav_new = grav; grav_new(index_outliers) = [];
    dn_new = dn; dn_new(index_outliers) = [];
    points_new = points; points_new(index_outliers) = [];
    ERR_new = ERR; ERR_new(index_outliers) = [];
    YY_new = YY; YY_new(index_outliers) = [];
    height_new= height; height_new(index_outliers) = [];

    clear A AA C Q C_theta

    % reprocessing without outliers 1 
    % Jacobi matrix creation - first column
    A(:,1) = ones(length(points_new),1);
    
    % Jacobi matrix - height section
    for i = 2:polynomial_degree_height_new+1
       A(:,i) = (height_new).^(i-1);
    end

    % Jacobi matrix - drift section
    for i = 2+polynomial_degree_height_new:polynomial_degree_height_new+1+polynomial_degree_time_final
        A(:,i) = (dn_new - dn_new(1)).^(i -(1+polynomial_degree_height_new));
    end
    
    [nrows,lgt] = size(A);
    
    % weights
    weight = mean(ERR_new)./ERR_new;
    % weight matrix
    P = diag(weight);
    % Covariance matrix of measurements
    Q = P^-1; C = (SD00^2)*Q;
    
    adjusted_parameters_new = (A'/C*A)\A'/C*grav_new;
    % measurement errors to adjusted parameters
    v_new = (A*adjusted_parameters_new) - grav_new;
    % Root mean square error
    rmse2 = sqrt((v_new'*inv(C)*v_new)/(nrows-lgt));
    % Covariance matrix of adjusted parameters
    C_theta = (rmse2^2)*inv(A'*inv(C)*A);
    % standard deviation of adjusted parameters
    SD_theta_new = sqrt(diag(C_theta));
    % drift coeficients
    drift_koef = adjusted_parameters_new(end-polynomial_degree_time_final+1:end);
    % drift section of Jacobi matrix
    A_drift = A(:,end-polynomial_degree_time_final+1:end);
    % residual (transportation drift)
    res_drift_new = A_drift*drift_koef;
    % test values 
    test2 = res_drift_new + v_new;
    % priemerna hodnota pre vykreslenie
    res_drift_av_new = mean(res_drift_new);

    % time information - dtime (datetime)
    dtime_t_new = datetime(dn_new,'ConvertFrom','datenum');
    MM = month(dtime_t_new); DD = day(dtime_t_new); hh = hour(dtime_t_new); mm = minute(dtime_t_new); ss = second(dtime_t_new);
    dtime_new = datetime(YY_new,MM,DD,hh,mm,ss);

    % statistical test 2
    % outliers indexes 
    index_outliers_new = find(abs(v_new)>=SD00*rmse2*significance);

    % Statistical testing of height component where Tau is a result of
    % statistic test representing a Student's distribution
    Tau2_new = adjusted_parameters_new(end-polynomial_degree_time_final)/SD_theta_new(end-polynomial_degree_time_final);

    if hasLicenseForToolbox == 0 % if working without statistic toolbox

        if abs(Tau2_new) < sqrt(students_inverse_approximate) % intentionally decreased for 2nd test since one testing has already has been performed
            polynomial_degree_height_final = polynomial_degree_height_new - 1; % polynomial of gradient approx. function is reduced
            % else polynomial of gradient approx. function remains the same
        else
            polynomial_degree_height_final = polynomial_degree_height_new; % drift approx. function remains quadratic
        end

    elseif hasLicenseForToolbox == 1 % if working with statistic toolbox
        % critical value from Students t distribution
        students_inverse = tinv(1-(significance_level)/2,nrows-lgt);

        if abs(Tau2_new) < sqrt(students_inverse) % intentionally decreased for 2nd test, since one testing has already has been performed
            polynomial_degree_height_final = polynomial_degree_height_new - 1; % polynomial of gradient approx. function is reduced by 1
            % else polynomial of gradient approx. function remains the same

        else
            polynomial_degree_height_final = polynomial_degree_height_new; % drift approx. function remains quadratic
        end
    end

    % removing outliers 2
    grav_final = grav_new; grav_final(index_outliers_new) = [];
    dn_final = dn_new; dn_final(index_outliers_new) = [];
    points_final = points_new; points_final(index_outliers_new) = [];
    ERR_final = ERR_new; ERR_final(index_outliers_new) = [];
    YY_final = YY_new; YY_final(index_outliers_new) = [];
    height_final = height_new; height_final(index_outliers_new) = [];

    clear A AA C Q C_theta SD_theta_new

    [~,ib,~] = intersect(dn,dn_final);

    % reprocessing without outliers 2
    % Jacobi matrix creation - first column
    A(:,1) = ones(length(points_final),1);

    % Jacobi matrix - height section
    for i = 2:polynomial_degree_height_final+1
       A(:,i) = (height_final).^(i-1);
    end

    % Jacobi matrix - drift section
    for i = 2+polynomial_degree_height_final:polynomial_degree_height_final+1+polynomial_degree_time_final
        A(:,i) = (dn_final - dn_final(1)).^(i -(1+polynomial_degree_height_final));
    end

    [nrows,lgt] = size(A);
    % weights
    weight = mean(ERR_final)./ERR_final;
    % weight matrix
    P = diag(weight);
    % Covariance matrix of measurements
    Q = P^-1; C = (SD00^2)*Q;

    adjusted_parameters_final = (A'/C*A)\A'/C*grav_final;
    % measurement errors to adjusted parameters
    v_final = (A*adjusted_parameters_final) - grav_final;
    % Root mean square error
    rmse3 = sqrt((v_final'*inv(C)*v_final)/(nrows-lgt));
    % Covariance matrix of adjusted parameters
    C_theta = (rmse3^2)*inv(A'*inv(C)*A);
    % standard deviation of adjusted parameters
    SD_theta_final = sqrt(diag(C_theta));
    % covariance of parameters

    if polynomial_degree_height_final == 2
        covariance_parameter = sqrt(abs(C_theta(2,3)));
    else
        covariance_parameter = 0;
    end

    % drift coeficients
    drift_koef = adjusted_parameters_final(end-polynomial_degree_time_final+1:end);
    % drift section of Jacobi matrix
    A_drift = A(:,end-polynomial_degree_time_final+1:end);
    % residual (transportation drift)
    res_drift_final = A_drift*drift_koef;

    test_final = res_drift_final + v_final;
    % priemerna hodnota pre vykreslenie
    res_drift_av_final = mean(res_drift_final);

    % time information - dtime (datetime)
    dtime_t_final = datetime(dn_final,'ConvertFrom','datenum');
    MM = month(dtime_t_final); DD = day(dtime_t_final); hh = hour(dtime_t_final); mm = minute(dtime_t_final); ss = second(dtime_t_final);
    dtime_final = datetime(YY_final,MM,DD,hh,mm,ss);

    %% output results
    output_function.stationinfo.ID = measured_station_ID;
    output_function.stationinfo.filename = pad(input_file,100);
    output_function.stationinfo.measurement_date = char(dtime_new(1));

    output_function.time.all_measurements = dtime;
    output_function.time.no_outliers = dtime(ib);

    output_function.processing.number_of_measurements = nrows;
    output_function.processing.number_of_rejected_measurements = n0 - nrows;

    output_function.processing.errors_all = test1 - res_drift_av;
    output_function.processing.outliers_removed = output_function.processing.errors_all(ib);
    output_function.processing.RMSE = rmse3*SD00;

    output_function.drift.polynomial_degree = pad(num2str(polynomial_degree_time_final,'%1.0f'),10);
    output_function.drift.drift_all_measurements = res_drift - res_drift_av;
    output_function.drift.drift_no_outliers = res_drift_final - res_drift_av_final;
    output_function.drift_parameters = adjusted_parameters_new(end-(polynomial_degree_new):end);

    output_function.gradient.polynomial_degree = num2str(polynomial_degree_height_final,'%1.0f');
    output_function.gradient.gradient_param = adjusted_parameters_final(2:1+polynomial_degree_height_final);
    output_function.gradient.gradient_param = [output_function.gradient.gradient_param; zeros(2-numel(output_function.gradient.gradient_param),1)];

    output_function.gradient.std = SD_theta_final(2:1+polynomial_degree_height_final);
    output_function.gradient.std = [output_function.gradient.std; zeros(2-numel(output_function.gradient.std),1)];
    output_function.gradient.cov = covariance_parameter;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Gravity differences _______________________________________________________________
function [output_gravity_diff] = gravity_differences(input_file, ...
                                                     header_lines, ...
                                                     instrument_type, ...
                                                     calibration_factor, ...
                                                     SD_scale_information, ...
                                                     input_units_option, ...
                                                     significance,...
                                                     reference_point,...
                                                     SD00)

    % file reading
    if instrument_type == 'CG5'
        [points,dtime,dn,YY,height,grav,ERR] = read_CG5(input_file,header_lines,calibration_factor,SD_scale_information,input_units_option);
    elseif instrument_type == 'CG6'
        [points,dtime,dn,YY,height,grav,ERR] = read_CG6(input_file,header_lines,calibration_factor);
    end

    % get unique points (string)
    uniquepoints_original = unique(points, 'stable');

    % reducing measured values to a point using normal gradient
    grav = grav + height*(308.6);
    % Least Square Adjustment - deterministic model
    n0 = length(points); % number of measurements taken
    k = length(uniquepoints_original); % number of measured levels
    
    % drift polynomial degree - initially, quadratic polynomial is
    % considered, however later testing can prove quadratic component to
    % be unsignificant and withdrawn from the adjusting process
    polynomial_degree = 2;

    % Jacobi matrix, point section
    for i = 1:k
    ind = find(points == uniquepoints_original(i));
        A(ind,i) = 1; A(~ind,i) = 0;
        % average height for individual measured levels
    end

    % Jacobi matrix, drift part
    A(:,k+1) = 1;

    for i = k+2:k+1+polynomial_degree
       A(:,i) = (dn - dn(1)).^(i -(k+1));
    end

    % Normalize reference point input
    if isempty(strtrim(reference_point))
        % No reference point specified -> use first measured point
        id_ref_point = 1;
    else
        % Use the reference point exactly as entered
        id_ref_point = find(uniquepoints_original == strtrim(reference_point), 1);
    
        if isempty(id_ref_point)
            fprintf('Reference point "%s" was not found among the measured points. Defeulting to first measured point', ...
                  reference_point);
            id_ref_point = 1;
        end
    end


    % Remove reference point from adjustment
    A(:,id_ref_point) = [];

    % weights
    weight = mean(ERR)./ERR;
    % weight matrix
    P = diag(weight);
    % Covariance matrix of measurements
    Q = P^-1; C = (SD00^2)*Q;
    % parameter adjustment usint LSE formulas
    adjusted_parameters = (A'/C*A)\A'/C*grav;
    % measurement errors to adjusted parameters
    v = (A*adjusted_parameters) - grav;
    % Root mean square error
    rmse1 = sqrt((v'*inv(C)*v)/(n0-k-2-polynomial_degree));
    % Covariance matrix of adjusted parameters
    C_theta = (rmse1^2)*inv(A'*inv(C)*A);
    % standard deviation of adjusted parameters
    SD_theta = sqrt(diag(C_theta));
    % drift coeficients
    drift_koef = adjusted_parameters(end-polynomial_degree:end);
    % drift section of Jacobi matrix
    AA = A(:,end-polynomial_degree:end);
    % residual (transportation drift)
    res_drift = AA*drift_koef;
    % test values 
    test = res_drift + v;
    % average drift value to subtract later
    res_drift_av = mean(res_drift);

    % outliers testing
    if significance == 1
        significance_level = 0.32;
        students_inverse_approximate = 480.7*exp(-2.068*(n0-k)) + 2.847*exp(-0.000441*(n0-k));

    elseif significance == 2
        significance_level = 0.05;
        students_inverse_approximate = 43.06*exp(-1.403*(n0-k)) + 2.071*exp(-0.0002368*(n0-k));

    elseif significance == 3
        significance_level = 0.01;
        students_inverse_approximate = 1.633*exp(-0.7396*(n0-k)) + 1.013*exp(-7.638e-05*(n0-k));
    end

    % outliers indexes 
    index_outliers = find(abs(v)>=SD00*rmse1*significance);

    % Statistical testing of parameters, where Tau is a result of
    % statistic test representing a Student's distribution
    Tau = adjusted_parameters(end)/SD_theta(end);

    % quadratic component significance testing by comparison to inverse
    % Student t's distribution values.

    % Check for statistic toolbox license
    hasLicenseForToolbox = license('test', 'Statistics_Toolbox');
    hasLicenseForToolbox = 0;
   
    if hasLicenseForToolbox == 0 % if working without statistic toolbox
        if abs(Tau) < students_inverse_approximate % approximate table values, for t-distrib. 
            polynomial_degree_new = 1; % drift approx. function set to linear
        else
            polynomial_degree_new = 2; % drift approx. function remains quadratic
        end

    elseif hasLicenseForToolbox == 1 % if working with statistic toolbox
        % critical value from Students t distribution
        students_inverse = tinv(1-(significance_level)/2,n0-k);

        if abs(Tau) < students_inverse
            polynomial_degree_new = 1; % drift approx. function set to linear
        else
            polynomial_degree_new = 2; % drift approx. function remains quadratic
        end
    end
    
    clear A AA C Q v C_theta
    
    % removing outliers 
    grav(index_outliers) = [];
    dn(index_outliers) = [];
    points(index_outliers) = [];
    ERR(index_outliers) = [];
    YY(index_outliers) = [];
    
    uniquepoints_new = unique(points, 'stable');
    missing_points = setdiff(uniquepoints_original, uniquepoints_new);
    
    if ~isempty(missing_points)
        fprintf('One or more points were not measured properly and are not included in final processing:\n');
        disp(missing_points);
    end

    n = length(points);
    k = length(uniquepoints_new);

    % reprocessing without outliers
    for i = 1:k
    ind = find(points == uniquepoints_new(i));
        A(ind,i) = 1; A(~ind,i) = 0;
    end
    % the not so useful part of Jacobi's matrix
    A(:,k+1) = 1;
    for i = k+2:k+1+polynomial_degree_new
       A(:,i) = (dn - dn(1)).^(i -(k+1));
    end

    % Find reference point again after outlier removal
    if isempty(strtrim(reference_point))
        % No reference point specified -> use first measured point
        id_ref_point_new = 1;
    else
        % Use the reference point exactly as entered
        id_ref_point_new = find(uniquepoints_new == strtrim(reference_point), 1);
    
        if isempty(id_ref_point_new) && ~isempty(strtrim(reference_point))
            fprintf('Reference point "%s" was not found among the measured points. Defeulting to first measured point', ...
                  reference_point);
            id_ref_point_new = 1;
        end
    end


    % Find reference point again after outlier removal
    id_ref_point_new = find(uniquepoints_new == strtrim(reference_point), 1);

    if isempty(id_ref_point_new) && ~isempty(reference_point)
        id_ref_point_new = 1;
        fprintf('Reference point was completely removed during outlier rejection.\n');
    else
        id_ref_point_new = 1;
        
    end

    % Remove the same reference point from the adjustment
    A(:,id_ref_point_new) = [];
    
    % New weighing 
    weight= mean(ERR)./ERR;
    P = diag(weight);
    Q = P^-1; C = (SD00^2)*Q; % Factor and Covariance matrix
    
    % new adjusted parameters without considering outliers in the
    % processing
    adjusted_parameters_new = (A'/C*A)\A'/C*grav;
    % measurements errors to adjusted parameters
    v = (A*adjusted_parameters_new) - grav;
    rmse2 = sqrt((v'*inv(C)*v)/(n-k-2-polynomial_degree_new-1));           
    C_theta = (rmse2^2)*inv(A'*inv(C)*A);                   
    SD_theta_new = sqrt(diag(C_theta));

    drift_koef2 = adjusted_parameters_new(end-polynomial_degree_new:end);
    AA = A(:,end-polynomial_degree_new:end);
    % new drift
    res_drift_new = AA*drift_koef2;
    res_drift_new_av = mean(res_drift_new);

    ref_point = uniquepoints_new(id_ref_point);
    uniquepoints_new(id_ref_point) = [];
    gravity_diff = adjusted_parameters_new(1:end-(polynomial_degree_new+1));

    % time information - dtime (datetime)
    dtime_t_new = datetime(dn,'ConvertFrom','datenum');
    MM = month(dtime_t_new); DD = day(dtime_t_new); hh = hour(dtime_t_new); mm = minute(dtime_t_new); ss = second(dtime_t_new);
    dtime_new = datetime(YY,MM,DD,hh,mm,ss);
    
    output_gravity_diff.stationinfo.ID = ref_point;
    output_gravity_diff.stationinfo.filename = pad(input_file,100);
    output_gravity_diff.stationinfo.measurement_date = char(dtime_new(1));
    output_gravity_diff.stationinfo.measuredpoints = uniquepoints_new; 

    output_gravity_diff.time.all_measurements = dtime;
    output_gravity_diff.time.no_outliers = dtime_new;
    output_gravity_diff.time.outliers = dtime(index_outliers);

    output_gravity_diff.processing.number_of_measurements = n0;
    output_gravity_diff.processing.rejected_measurements = n0 - n;
    output_gravity_diff.processing.RMSE = rmse2*SD00;
    output_gravity_diff.processing.errors_all = test - res_drift_av;
    output_gravity_diff.processing.errors_outliers = test(index_outliers) - res_drift_av;

    output_gravity_diff.drift.polynomial_degree = pad(num2str(polynomial_degree_new,'%1.0f'),10);
    output_gravity_diff.drift.drift_all_measurements = res_drift - res_drift_av;
    output_gravity_diff.drift.drift_no_outliers = res_drift_new- res_drift_new_av;
    output_gravity_diff.drift.drift_parameters = adjusted_parameters_new(end-(polynomial_degree_new):end);
    
    output_gravity_diff.adjusted.differences = gravity_diff;
    output_gravity_diff.adjusted.std = SD_theta_new(1:end-(polynomial_degree_new+1));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read CG5 data _______________________________________________________________
function [points,dtime,dn,YY,height,grav,ERR] = read_CG5(input_file, ...
                                          header_lines, ...
                                          calibration_factor, ...
                                          SD_scale_information, ...
                                          input_units_option)

    % Open file
    fileID = fopen(input_file);
    % Read data
    filedata = textscan(fileID, ...
        '%f %s %f %f %f %f %f %f %f %f %f %s %f %f %s', ...
        'headerLines', header_lines, ...
        'Delimiter', ' ', ...
        'MultipleDelimsAsOne', true);
    fclose(fileID);
    % Point ID information

    points_num = str2double(filedata{2});
    points = string(num2str(points_num, '%.3f'));
    points = regexprep(points, '\.0+$', '');

    % -------------------------------------------------------------------------
    % -------------------------------------------------------------------------
    % TIME INFORMATION
    % -------------------------------------------------------------------------
    
    date_str = string(filedata{15});
    time_str = string(filedata{12});
    
    % Combine date and time
    datetime_str = date_str + " " + time_str;
    
    % Create MATLAB datetime
    dtime = datetime(datetime_str, ...
                     'InputFormat', 'yyyy/MM/dd HH:mm:ss');
    
    % Year
    YY = year(dtime);
    
    % Calculate datenum directly from the correct datetime
    dn = datenum(dtime);
    % -------------------------------------------------------------------------
    % HEIGHT
    % -------------------------------------------------------------------------
    % CG5 sensor is located 21.1 cm below the top of the gravimeter.

    if input_units_option == 1
        height = (filedata{3} - 21.1) / 100;
    elseif input_units_option == 2
        height = filedata{3} - 0.211;

        % Check if units were actually centimeters
        if mean(height, 'omitnan') > 3
            height = (filedata{3} - 21.1) / 100;
        end
    end
    % -------------------------------------------------------------------------
    % GRAVITY
    % -------------------------------------------------------------------------
    if isempty(calibration_factor)
        grav = filedata{4} * 1000;
    else
        grav = filedata{4} * 1000 * calibration_factor;
    end
    % -------------------------------------------------------------------------
    % ERROR
    % -------------------------------------------------------------------------
    ERR = filedata{5} * 1000;
    % Standard deviation scaling
    if SD_scale_information == 0
        ERR = ERR;
    elseif SD_scale_information == 1
        ERR = ERR / sqrt(60);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read CG6 data _______________________________________________________________
% height is measured from the point to the bottom of gravimeter, this has
% to be revised in the future
function [points, dtime, dn, YY, height, grav, ERR] = read_CG6(input_file, header_lines, calibration_factor)

    % Open file
    fileID = fopen(input_file);

    % Skip header lines
    for i = 1:header_lines
        fgetl(fileID);
    end

    % Read valid lines into a cell array
    valid_lines = {};
    while ~feof(fileID)
        line = fgetl(fileID);
        if isempty(line)
            continue;
        end
        if contains(line, '******')
            continue; % Skip corrupted lines
        end
        valid_lines{end+1} = line; %#ok<AGROW>
    end

    fclose(fileID);

    % Join valid lines into one big char array separated by newlines
    combined_data = strjoin(valid_lines, '\n');

    % Define format spec
    formatSpec = ['%s %s %s '...      % PointID, Date, Time
                  '%f %f %f %f %f %f %f %f %f %f %f %f %f %f '... % Main numeric fields
                  '%f %f %f '...      % Lat, Lon, Height
                  '%s %s %s '...      % Often '--'
                  '%f'];              % Final correction value

    % Use textscan on cleaned data
    filedata = textscan(combined_data, formatSpec, ...
        'Delimiter', {'\t', ' '}, 'MultipleDelimsAsOne', true, ...
        'TreatAsEmpty', {'--'});

    % Extract outputs - point numbering 
    points = string(filedata{1});
    points = strrep(string(points), '_', '.');
    points = regexprep(points, '\.0+$', '');

    date_str = filedata{2};
    time_str = filedata{3};

    % Combine and parse datetime
    datetime_str = strcat(date_str, {' '}, time_str);
    dtime = datetime(datetime_str, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    YY = year(dtime);

    % Gravity (µGal)
    if isempty(calibration_factor)
        grav = filedata{4} * 1000;
    else
        grav = filedata{4} * 1000 * calibration_factor;
    end

    % Error
    ERR = filedata{7} * 1000;
    
    % Height
    h_raw = filedata{17}/100;
    height = h_raw + 0.0658;
    
    %% careful this is a temporary workaround.
    height = height - 0.215;

    % datenum
    dn = datenum(dtime);
end
