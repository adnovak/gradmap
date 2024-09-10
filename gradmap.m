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

% HOURS SPENT DEBUGING: Way too much.


% Check for updated version on https://github.com/adnovak/gradmap

function gradmap(GUI_par, ...               % variables used to switch between command line and GUI use. When calling function from command line use 'Run'. [string]
    ...
    input_units_option, ...                 % specifies height unit that operator used during measurements '1' for centimetres and '2' for metres [double]. User should store height measured to the upper edge of the instrument to correctly assign 
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

            panel1lower_boundary = 0.665;
            panel1height = 0.33;
            
            panel2lower_boundary = 0.355;
            panel2height = 0.305;

            panel3lower_boundary = 0.07;
            panel3height = 0.28;
            
            panelheight = 510; % in pixels
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
    
            % Panel na vyber suboru   
            uicontrol(M,'Units','normalized','position',[leftboundary+0.02 0.885 0.3 windowsize7],...
                    'Style','pushbutton','string','Choose file(s)',...
                    'tag','push_input_path','Callback','gradmap input_path','FontName','Trebuchet MS','FontSize',fs);
            
            % show filename(s) 
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.32 0.885 0.55 windowsize5],...
                'backgroundcolor',[R1 G1 B1],'tag','show_local_path',...
                'Style','Text','string','','FontName','Trebuchet MS','FontSize',fs-0.5);

            % Number of header lines text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.82 0.38 windowsize6],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','number of header lines','FontName','Trebuchet MS','FontSize',fs);
    
            % Unit text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.77 0.2 windowsize6],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','height units','FontName','Trebuchet MS','FontSize',fs);

            % Uncertainty text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.725 0.5 windowsize5],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','instrument uncertainty in µGal','FontName','Trebuchet MS','FontSize',fs);

            % Standard deviation scaling text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.675 0.42 windowsize5],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','standard deviation scaling','FontName','Trebuchet MS','FontSize',fs);

            % number of header lines window
            uicontrol(M,'Units','normalized','Position',[leftboundary+0.74 0.835 0.1 windowsize5],...
                        'Style','Edit','tag','edit_pocet_riadkov',...
                        'string','34','backgroundcolor','white',...
                        'FontName','Trebuchet MS','FontName','Trebuchet MS','FontSize',fs-0.5);
    
            % units option window
            uicontrol(M,'Units','normalized','position',[leftboundary+0.74 0.77 0.12 0.055],...
                        'Style','Popupmenu','tag','units_option',...
                        'string','cm|m','value',1,'BackgroundColor','white','FontName','Trebuchet MS','FontSize',fs-0.5);

            % accuracy window
            uicontrol(M,'Units','normalized','Position',[leftboundary+0.74 0.735 0.1 windowsize5],...
                        'Style','Edit','tag','edit_unc',...
                        'string','5','backgroundcolor','white',...
                        'FontName','Trebuchet MS','FontName','Trebuchet MS','FontSize',fs-0.5);
            
            % Standard deviation scaling window
            uicontrol(M,'Units','normalized','position',[leftboundary+0.7 0.67 0.18 0.055],...
                        'Style','Popupmenu','tag','SD_scaling',...
                        'string','series|second','value',1,'BackgroundColor','white','FontName','Trebuchet MS','FontSize',fs-0.5);

% ===== PANEL 2 - processing information

	        p2 = uipanel(M,'Title','Processing','Units','normalized','position',[0.02 panel2lower_boundary 0.96 panel2height],...
            'backgroundcolor',[R1 G1 B1],'HighlightColor',[R2 G2 B2],'tag',...
            'Locpanel','FontName','Georgia','FontSize',fs+1.5);

            % text part
            % number of measured positions text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.565 0.52 windowsize5],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','number of measured positions','FontName','Trebuchet MS','FontSize',fs);
            
            % rejection threshold text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.515 0.45 windowsize5],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','rejection threshold in µGal','FontName','Trebuchet MS','FontSize',fs);

            % gradient format text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.465 0.28 windowsize5],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','gradient format','FontName','Trebuchet MS','FontSize',fs);

            % significance level text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.415 0.29 windowsize5],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','significance level','FontName','Trebuchet MS','FontSize',fs);

            % calibration factor text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.365 0.3 windowsize5],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','calibration factor','FontName','Trebuchet MS','FontSize',fs);

            % window part
            % number of measured positions
            uicontrol(M,'Units','normalized','position',[leftboundary+0.725 0.57 0.15 windowsize5],...
                        'Style','Popupmenu','tag','number_measured_levels',...
                        'string','2|3|from file','value',3,'BackgroundColor','white','FontName','Trebuchet MS','FontSize',fs-0.5);

            % rejection threshold window
            uicontrol(M,'Units','normalized','Position',[leftboundary+0.74 0.52 0.1 windowsize5],...
                        'Style','Edit','tag','rejection_threshold',...
                        'string','5','backgroundcolor','white',...
                        'FontName','Trebuchet MS','FontName','Trebuchet MS','FontSize',fs-0.5);

            % gradient result format
            uicontrol(M,'Units','normalized','position',[leftboundary+0.7 0.474 0.18 windowsize5],...
                        'Style','Popupmenu','tag','gradient_option',...
                        'string','linear|function','value',1,'BackgroundColor','white','FontName','Trebuchet MS','FontSize',fs-0.5);

            % significance level
            uicontrol(M,'Units','normalized','position',[leftboundary+0.7 0.424 0.18 windowsize5],...
                        'Style','Popupmenu','tag','significance_tag',...
                        'string','1-σ (68% confidence bounds) |2-σ (95% confidence bounds)|3-σ (99.7% confidence bounds)','value',2,'BackgroundColor','white','FontName','Trebuchet MS','FontSize',fs-0.5);

            % calibration factor window
            uicontrol(M,'Units','normalized','Position',[leftboundary+0.7 0.372 0.18 windowsize5],...
                        'Style','Edit','tag','calibration',...
                        'string','','backgroundcolor','white',...
                        'FontName','Trebuchet MS','FontName','Trebuchet MS','FontSize',fs-0.5);

% ===== PANEL 3 - Output data - specify output files and file preference
	        p3 = uipanel(M,'Title','Output data','Units','normalized','position',[0.02 panel3lower_boundary 0.96 panel3height],...
            'backgroundcolor',[R1 G1 B1],'HighlightColor',[R2 G2 B2],'tag',...
            'Locpanel','FontName','Georgia','FontSize',fs+1.5);

            % Panel na vyber suboru
            uicontrol(M,'Units','normalized','position',[leftboundary+0.02 0.24 0.35 windowsize7],...
                    'Style','pushbutton','string','Create report file',...
                    'tag','push_report_file_name','Callback','gradmap report_filename','FontName','Trebuchet MS','FontSize',fs);

            % Vypis nazvu vybraneho suboru
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.45 0.235 0.45 windowsize5],...
                'backgroundcolor',[R1 G1 B1],'tag','show_report_path',...
                'Style','Text','string','','FontName','Trebuchet MS','FontSize',fs-1),'borders';

            % Ulozenie grafickych vystupov spracovania text
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.175 0.4 windowsize6],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','store processing figures',...
                         'FontName','Trebuchet MS','FontSize',fs);

            % text for saving summary of all calculations in an excel table 
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.125 0.38 windowsize6],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','save summary in table',...
                         'FontName','Trebuchet MS','FontSize',fs);

            % text for saving gravity differences instead of gradient for
            % all calculations
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.02 0.085 0.53 windowsize5],...
                         'backgroundcolor',[R1 G1 B1],...
                         'Style','Text','string','save gravity differences instead',...
                         'FontName','Trebuchet MS','FontSize',fs);

            % button for saving graphic output
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.77 0.18 0.09 windowsize7],...
                        'BackgroundColor',[R1 G1 B1],...
                        'Style','Checkbox','tag','check_graphics',...
                        'string','','value',0);
            
            % Button for saving a summary (table) of all calculated values
            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.77 0.13 0.09 windowsize7],...
                        'BackgroundColor',[R1 G1 B1],...
                        'Style','Checkbox','tag','check_summary',...
                        'string','','value',1);

            % button for saving gravity differences instead of gradient for
            % all calculations

            uicontrol(M,'Units','normalized', 'Position',[leftboundary+0.77 0.08 0.09 windowsize7],...
                        'BackgroundColor',[R1 G1 B1],...
                        'Style','Checkbox','tag','check_gravity_dif',...
                        'string','','value',0);

% ===== PART 4 - start calculations, close window utility

            % Execute button
	        uicontrol('Units','normalized','position',[0.25 0.01 0.19 windowsize6],...
            'style','pushbutton','string','Execute','FontName','Trebuchet MS','FontSize',fs,'fontweight', 'demi','Callback','gradmap Run');

            % Close button
	        uicontrol('Units','normalized','position',[0.6 0.01 0.19 windowsize6],...
            'Style','pushbutton','string','Close','FontName','Trebuchet MS','FontSize',fs,'fontweight', 'demi','Callback','gradmap Close'); 
        end
    else
        switch GUI_par

            % Click on choose input files button ---------------------------------------
            case 'input_path' 
                [data_filename,data_path]=uigetfile({'*.txt';'*.*'},'Select measurement file(s)','MultiSelect','on');

                if iscell(data_filename)
                    nfiles = length(data_filename);
                    
                    for i = 1:nfiles
                        data(i,:) = string(fullfile(data_path,data_filename{i}));
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
                    else
                        outfile = outfile;
                    end
    
                    set(findobj('tag','show_report_path'),'string',strcat(outname,'.txt'), 'FontSize',8)
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

                    % get num of measured levels from GUI
                    measured_levels = get(findobj('tag','number_measured_levels'),'value');
                    % get rejection criteria from GUI
                    rejection_threshold = str2double(get(findobj('tag','rejection_threshold'),'string'));
                    % get gradient output format from GUI
                    gradient_format = get(findobj('tag','gradient_option'),'value');

                    % get significance level from GUI
                    significance = get(findobj('tag','significance_tag'),'value');

                    % get calibration factor from GUI
                    calibration_factor = str2double(get(findobj('tag','calibration'),'string'));
                    if isnan(calibration_factor)
                        calibration_factor = [];
                    end

                    % get report file path
                    report_file = get(findobj('tag','push_report_file_name'),'userdata');
                    % get plot errors option
                    plot_errors_option = get(findobj('tag','check_graphics'),'value');
                    % get summary option
                    summary_option = get(findobj('tag','check_summary'),'value');
                    % get save gravity difference options
                    store_gravity_dif = get(findobj('tag','check_gravity_dif'),'value');

                    if measured_levels == 1;
                        number_of_measured_levels = 2;
                    elseif measured_levels == 2;
                        number_of_measured_levels = 3;
                    elseif measured_levels == 3;
                        number_of_measured_levels = [];
                    end

                    clear measured_levels
                    
                % calling function from command line.
                elseif GUI == 0
                    
                    input_files = input_files;
                    header_lines = header_lines;
                    input_units_option = input_units_option;
                    SD00 = uncertainty;
                    SD_scale_information = SD_scale_information;
                    number_of_measured_levels = number_of_measured_levels;
                    significance = significance_level;
                    rejection_threshold = rejection_threshold;
                    gradient_output_format = gradient_output_format;
                    
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
                                fprintf('Processing file %.0f/%.0f \n',i, nfiles)
                                input_file = input_files(i,:);
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
                                    output = gradient_linear(input_file,header_lines,calibration_factor,SD_scale_information,number_of_measured_levels,input_units_option,significance,SD00);
                                    % compose report for each processed file
                                    % empty line at the start each
                                    % processing report
                                    report(1,i) = "";
                                    report(2,i) = strcat("processed file: ",output.stationinfo.filename);
                                    report(3,i) = strcat("point ID: ",output.stationinfo.ID);
                                    report(4,i) = strcat("measurement date: ",output.stationinfo.measurement_date);
        
                                    % check for accepted or rejected status
                                    if str2num(output.gradient.std) > rejection_threshold
                                        report(5,i) = ["status: rejected",];
                                    else
                                        report(5,i) = ["status: accepted",];
                                    end
                                    
                                    report(6,i) = strcat("number of measurements accepted: ",num2str(output.processing.number_of_measurements,'%.0f'));
                                    report(7,i) = strcat("number of outliers: ",num2str(output.processing.number_of_rejected_measurements,'%.0f'));
                                    report(8,i) = strcat("root mean square error: ",num2str(output.processing.RMSE,'%.1f'));
                                    report(9,i) = strcat("drift polynomial degree: ",output.drift.polynomial_degree);
                                    report(10,i) = "average height, gradient, standard deviation";
                                    report(11,i)= strcat(output.gradient.average_height,",",output.gradient.average_gradient,",",output.gradient.std);
    
                                    % count rejected files
                                    if output.gradient.std > rejection_threshold
                                        rejected_files = rejected_files +1;
                                    end
    
                                    % store summary data
                                    stationID = [string(stationID); string(output.stationinfo.ID)];
                                    sumdata = [output.gradient.average_gradient_num output.gradient.std_num];
                                    storedata = [storedata; sumdata];

                                    if plot_errors_option == 1
                                        F = figure;
                                        hold on
                                        plot(output.time.all_measurements,output.drift.drift_all_measurements,'--','color','black','LineWidth',0.9);
                                        scatter(output.time.all_measurements,output.processing.errors_all,10,'b','filled');
                                        scatter(output.time.outliers,output.processing.errors_outliers,10,'r','filled');
                                        plot(output.time.no_outliers,output.drift.drift_no_outliers,'color','black','LineWidth',1);
                                        ylabel('\muGal')
                                        xlabel('time')
            
                                        legend('approximate drift','accepted measurements','outliers','adjusted drift','Location','best')
                                        set(gca, 'YGrid', 'on', 'XGrid', 'off')
                                        print(F,strcat(report_file(1:end),"_",num2str(i,'%2.0f')),'-djpeg','-r400')
                                    end
                                
                                elseif gradient_format == 2
                                
                                    % call processing function
                                    output = gradient_function(input_file, header_lines, calibration_factor, SD_scale_information, input_units_option,significance,SD00);
                                    % compose report for each processed file
                                    % empty line at the start each
                                    % processing report
                                    report(1,i) = "";
                                    report(2,i) = strcat("processed file: ",output.stationinfo.filename);
                                    report(3,i) = strcat("point ID: ",output.stationinfo.ID);
                                    report(4,i) = strcat("measurement date: ",output.stationinfo.measurement_date);

                                    % check for accepted or rejected status
                                    if output.gradient.std(1) > rejection_threshold
                                        report(5,i) = ["status: rejected",];

                                    elseif output.processing.number_of_rejected_measurements > 0.5*output.processing.number_of_measurements
                                        report(5,i) = ["status: rejected",];
                                    else
                                        report(5,i) = ["status: accepted",];
                                    end
                                    
                                    report(6,i) = strcat("number of measurements accepted: ",num2str(output.processing.number_of_measurements,'%.0f'));
                                    report(7,i) = strcat("number of outliers: ",num2str(output.processing.number_of_rejected_measurements,'%.0f'));
                                    report(8,i) = strcat("root mean square error: ",num2str(output.processing.RMSE,'%2.1f'));
                                    report(9,i) = strcat("drift polynomial degree: ",output.drift.polynomial_degree);
                                    report(10,i) = strcat("gradient polynomial degree: ",output.gradient.polynomial_degree);
                                    report(11,i) = "gradient parameters";
                                    report(12,i) = string(strjoin(arrayfun(@(x) num2str(x),output.gradient.gradient_param ,'UniformOutput',false),','));
                                    report(13,i) = "standard deviation ";
                                    report(14,i) = string(strjoin(arrayfun(@(x) num2str(x),output.gradient.std ,'UniformOutput',false),','));
                                    report(15,i) = strcat("covariance:",string(output.gradient.cov));
    
                                    % % store summary data
                                    stationID = [string(stationID); string(output.stationinfo.ID)];
                                    sumdata = [output.gradient.gradient_param' output.gradient.std' output.gradient.cov];
                                    storedata = [storedata; sumdata];

                                    % plot errors compared to approximate and
                                    % adjusted drift
                                    if plot_errors_option == 1
                                        F = figure;
                                        hold on
                                        plot(output.time.all_measurements,output.drift.drift_all_measurements,'--','color','black','LineWidth',0.9);
                                        scatter(output.time.all_measurements,output.processing.errors_all,10,'r','filled');
                                        scatter(output.time.no_outliers,output.processing.outliers_removed,10,'b','filled');
                                        
                                        plot(output.time.no_outliers,output.drift.drift_no_outliers,'color','black','LineWidth',1);
                                        set(gca, 'YGrid', 'on', 'XGrid', 'off');
                                        ylabel('\muGal')
                                        xlabel('time')
                                        legend('approximate drift','outliers','accepted measurements','adjusted drift','Location','best')
                                        print(F,strcat(report_file(1:end),"_",num2str(i,'%2.0f')),'-djpeg','-r400')
                                    end
    
                                    % count rejected files
                                    if output.gradient.std(1) > rejection_threshold
                                        rejected_files = rejected_files +1;
                                    end
                                end
                            end
                        end
    
                        % summary header
                        headerline(1,1) = "Summary";
                        headerline(2,1) = strcat("number of processed files: ",num2str(nfiles,'%2.0f'));
                        headerline(3,1) = strcat("number of files passing the rejection threshold:", num2str(rejected_files,'%2.0f'));
                        headerline(4,1) = strcat("calibration factor used: ", num2str(calibration_factor,'%8.7f'));
                        headerline(5,1) = strcat("instrument uncertainty used: ", num2str(SD00,'%2.0f'));
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
                            headerline(9,1)= "gradient units: μGal/m";
                        elseif gradient_format == 2
                            headerline(8,1) = strcat("processing method: function AH + BH²");
                            headerline(9,1)= "Parameter units: A[μGal/m], B[μGal/m²]";
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
                            % run through all the files and process them
                            for i = 1:nfiles
                                fprintf('Processing file %.0f/%.0f \n',i, nfiles)
                                input_file = input_files(i,:);
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
                                output = gravity_differences(input_file,header_lines,calibration_factor,SD_scale_information,input_units_option,significance,SD00);
                                report(1,i) = "";
                                report(2,i) = strcat("processed file: ",output.stationinfo.filename);
                                report(3,i) = strcat("measurement date: ",output.stationinfo.measurement_date);                                     
                                report(4,i) = strcat("number of measurements accepted: ",num2str(output.processing.number_of_measurements,'%.0f'));
                                report(5,i) = strcat("number of outliers: ",num2str(output.processing.rejected_measurements,'%.0f'));
                                report(6,i) = strcat("drift polynomial degree: ",output.drift.polynomial_degree);
                                report(7,i) = strcat("root mean square error [μGal]: ",num2str(output.processing.RMSE,'%.1f'));
                                report(8,i) = "####################################################################################";
                                report(9,i) = "starting point, ending point, gravity difference [μGal], standard deviation [μGal]";

                                mp = output.stationinfo.measuredpoints;
                                gd = output.adjusted.differences;
                                sd = output.adjusted.std;
                             
                                for zz = 1:length(mp)-1
                                    report(9+zz,i) = strcat(mp(1),",",...
                                        mp(zz+1),",",...
                                        num2str(gd(zz),'%5.1f'),",", ...
                                        num2str(sd(zz),'%5.1f'));
                                end
                                
                                report(9+length(mp),i) = "####################################################################################";

                                % plot errors compared to approximate and
                                % adjusted drift
                                if plot_errors_option == 1
                                    F = figure;
                                    hold on
                                    plot(output.time.all_measurements,output.drift.drift_all_measurements,'--','color','black','LineWidth',0.9);
                                    scatter(output.time.all_measurements,output.processing.errors_all,10,'b','filled');
                                    scatter(output.time.outliers,output.processing.errors_outliers,10,'r','filled');
                                    plot(output.time.no_outliers,output.drift.drift_no_outliers,'color','black','LineWidth',1);
                                    ylabel('\muGal')
                                    xlabel('time')
        
                                    legend('approximate drift','accepted measurements','outliers','adjusted drift','Location','best')
                                    set(gca, 'YGrid', 'on', 'XGrid', 'off')
                                    print(F,strcat(report_file(1:end),"_",num2str(i,'%2.0f')),'-djpeg','-r400')
                                
                                end
                            end
                        end
                        
                        % summary header
                        headerline(1,1) = "Summary";
                        headerline(2,1) = strcat("number of processed files: ",num2str(nfiles,'%.0f'));
                        headerline(3,1) = strcat("computation performed on: ", string(datetime("today")));
                        headerline(4,1) = strcat("calibration factor used in μGal: ", num2str(calibration_factor,'%8.7f'));
                        headerline(5,1) = strcat("instrument uncertainty used: ", num2str(SD00,'%2.0f'));
                        if significance == 1 
                            confidence = '68%';
                        elseif significance == 2 
                            confidence = '95%';
                        elseif significance == 3
                            confidence ='99.7%';
                        end
                        
                        headerline(6,1) = strcat("confidence: ", confidence);
                        headerline(7,1) = "End of summary";
    
                        % reshape header
                        report = reshape(report,[],1);
                        report = rmmissing(report);

                        % create file for writing data
                        fid = fopen(strcat(report_file,'.txt'),'w');
                        fprintf(fid,'%s\n',headerline);
                        fprintf(fid,'%s\n',report);
                        fclose(fid);
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
% % Additional functions called within processing, do not remove, delete or
% move these.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%________________________________________________________________________

% Linear gradient _______________________________________________________________
function [output_linear] = gradient_linear(input_file, ...
                                           header_lines, ...
                                           calibration_factor, ...
                                           SD_scale_information, ...
                                           number_of_measured_levels, ...
                                           input_units_option, ...
                                           significance,...
                                           SD00)
    % file reading
    fileID = fopen(input_file);
    % read data from file
    filedata = textscan (fileID, '%f %s %f %f %f %f %f %f %f %f %f %9s %f %f %f %s', 'headerLines', header_lines);

    % point ID information
    points = string(filedata{2});
    % get unique points (string)
    uniquepoints = string(unique(points,'stable'));
    pts_num = str2double(uniquepoints(1));
    if isnan(pts_num) == 1
        measured_station_ID = uniquepoints(1);
    elseif isnan(pts_num) == 0
        measured_station_ID = num2str(pts_num,'%8.2f');
    end

    % datetime numeric information for each measurement - dn (datenum)
    dn = filedata{13};
    % time information - dtime (datetime) extracted from individual
    % information in file
    YY = filedata{15};
    dtime_t = datetime(dn,'ConvertFrom','datenum');
    MM = month(dtime_t); dd = day(dtime_t); hh = hour(dtime_t); mm = minute(dtime_t); ss = second(dtime_t);
    dtime = datetime(YY,MM,dd,hh,mm,ss);
    
    % height above surface (mark) - converted to metres. For CG5 the sensor
    % is located 21.1 cm below the top according to manual. The height in
    % the spreadsheet is usually a height difference between top of the
    % gravimeter and ground mark at individual position

    if input_units_option == 1
        height = (filedata{3} - 21.1)/100;
    elseif input_units_option == 2
        height = (filedata{3} - 0.211);
        % check if height units are correctly assigned, assuming gravimeter
        % cannot be placed higher than 2 meters above ground
        if mean(height)>3
            height = (filedata{3} - 21.1)/100;
        end
    end

    % Measured mGal units converted to μGal.
    if isempty(calibration_factor)
        grav = filedata{4}*1000;
    else
        grav = filedata{4}*1000*calibration_factor;
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
    for i = k+2:k+1+polynomial_degree;
       A(:,i) = (dn - dn(1)).^(i -(k+1));
    end

    % regularization - by default first column is removed to fix position 1
    % as starting
    A(:,1)= [];
    
    % load errors from filedata
    ERR = filedata{5}*1000;
    
    % when scaled to series the values usually
    % resemble the value of uncertainty (usually 2 to 7 μGal)
    if SD_scale_information == 0
        ERR = ERR;
    
    % Standard deviation scaling
    % when scaled to seconds, the values usually
    % resemble the value of 1Hz freq uncertainty (usually more than 15
    % μGal) thus having to be rescaled to seconds.
    elseif SD_scale_information == 1
        ERR = ERR/sqrt(60);
    end

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

        elseif length(uniquepoints) < 4
            fprintf('Why would you measure at more than four levels?')
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

    output_linear.drift.polynomial_degree = pad(num2str(polynomial_degree_new,'%1.0f'),10);
    output_linear.drift.drift_all_measurements = res_drift - res_drift_av;
    output_linear.drift.drift_no_outliers = res_drift_new- res_drift_new_av;

    output_linear.gradient.average_height = num2str(av_height,'%5.3f');
    output_linear.gradient.average_gradient = num2str(av_Wzz,'%4.1f');
    output_linear.gradient.std = num2str(sigma_av_Wzz,'%2.1f');

    % numeric
    output_linear.gradient.average_height_num = av_height;
    output_linear.gradient.average_gradient_num = av_Wzz;
    output_linear.gradient.std_num = sigma_av_Wzz;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% gradient as a function of height and time
function [output_function] = gradient_function(input_file, ...
                                               header_lines, ...
                                               calibration_factor, ...
                                               SD_scale_information, ...
                                               input_units_option, ...
                                               significance,...
                                               SD00)
    % file reading
    fileID = fopen(input_file);
    % read data from file
    filedata = textscan (fileID, '%f %s %f %f %f %f %f %f %f %f %f %9s %f %f %f %s', 'headerLines', header_lines);

    % point ID information
    points = string(filedata{2});
    % get unique points (string)
    uniquepoints = string(unique(points,'stable'));
    pts_num = str2double(uniquepoints(1));
    if isnan(pts_num) == 1
        measured_station_ID = uniquepoints(1);
    elseif isnan(pts_num) == 0
        measured_station_ID = num2str(pts_num,'%8.2f');
    end

    % datetime numeric information for each measurement - dn (datenum)
    dn = filedata{13};
    % time information - dtime (datetime) extracted from individual
    % information in file
    YY = filedata{15};
    dtime_t = datetime(dn,'ConvertFrom','datenum');
    MM = month(dtime_t); dd = day(dtime_t); hh = hour(dtime_t); mm = minute(dtime_t); ss = second(dtime_t);
    dtime = datetime(YY,MM,dd,hh,mm,ss);
    
    % height above surface (mark) - converted to metres. For CG5 the sensor
    % is located 21.1 cm below the top according to manual. The height in
    % the spreadsheet is usually a height difference between top of the
    % gravimeter and ground mark at individual position

    if input_units_option == 1
        height = (filedata{3} - 21.1)/100;
    elseif input_units_option == 2
        height = (filedata{3} - 0.211);
    end

    % Measured mGal units converted to μGal.
    grav = filedata{4}*1000; 
    
    if isempty(calibration_factor)
        grav = grav;
    else
        grav = grav*calibration_factor;
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
    % load errors from filedata and transfer from mGal to μGal
    ERR = filedata{5}*1000;
    
    % when scaled to series the values usually
    % resemble the value of uncertainty (usually 2 to 7 μGal)
    if SD_scale_information == 0
        ERR = ERR;

    % Standard deviation scaling
    % when scaled to seconds, the values usually
    % resemble the value of 1Hz freq uncertainty (usually more than 15
    % μGal) thus having to be rescaled to series.
    elseif SD_scale_information == 1
        ERR = ERR/sqrt(60);
    end

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

    hasLicenseForToolbox = license('test', 'Statistics_Toolbox');

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

    [ia,ib,ic] = intersect(dn,dn_final);

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
                                                     calibration_factor, ...
                                                     SD_scale_information, ...
                                                     input_units_option, ...
                                                     significance,...
                                                     SD00)
    % file reading
    fileID = fopen(input_file);
    % read data from file
    filedata = textscan (fileID, '%f %s %f %f %f %f %f %f %f %f %f %9s %f %f %f %s', 'headerLines', header_lines);

    % point ID information
    points = string(filedata{2});
    % get unique points (string)
    uniquepoints = string(unique(points,'stable'));
    pts_num = str2double(uniquepoints);
    for j = 1:length(uniquepoints)
        if isnan(pts_num(j)) == 1
            measured_points(j,1) =uniquepoints(j);

        elseif isnan(pts_num(j)) == 0
            measured_points(j,1) = string(num2str(pts_num(j),'%8.2f'));
        end
    end

    % datetime numeric information for each measurement - dn (datenum)
    dn = filedata{13};
    % time information - dtime (datetime) extracted from individual
    % information in file
    YY = filedata{15};
    dtime_t = datetime(dn,'ConvertFrom','datenum');
    MM = month(dtime_t); dd = day(dtime_t); hh = hour(dtime_t); mm = minute(dtime_t); ss = second(dtime_t);
    dtime = datetime(YY,MM,dd,hh,mm,ss);
    
    % height above surface (mark) - converted to metres. For CG5 the sensor
    % is located 21.1 cm below the top according to manual. The height in
    % the spreadsheet is usually a height difference between top of the
    % gravimeter and ground mark at individual position

    if input_units_option == 1
        height = (filedata{3} - 21.1)/100;
    elseif input_units_option == 2
        height = (filedata{3} - 0.211);
        % check if height units are correctly assigned, assuming gravimeter
        % cannot be placed higher than 3 meters above ground. meters are
        % switched to centimeters
        if mean(height) > 3
            height = (filedata{3} - 21.1)/100;
        end
    end

    % Measured mGal units converted to μGal.
    if isempty(calibration_factor)
        grav = filedata{4}*1000;
    else
        grav = filedata{4}*1000*calibration_factor;
    end

    % reducing measured values to a point using normal gradient
    grav = grav + height*(308.6);
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
    end

    % Jacobi matrix, drift part
    A(:,k+1) = 1;
    for i = k+2:k+1+polynomial_degree;
       A(:,i) = (dn - dn(1)).^(i -(k+1));
    end

    % regularization - by default first column is removed to fix position 1
    % as starting
    A(:,1)= [];
    
    % load errors from filedata
    ERR = filedata{5}*1000;
    
    % when scaled to series the values usually
    % resemble the value of uncertainty (usually 2 to 7 μGal)
    if SD_scale_information == 0
        ERR = ERR;
    
    % Standard deviation scaling
    % when scaled to seconds, the values usually
    % resemble the value of 1Hz freq uncertainty (usually more than 15
    % μGal) thus having to be rescaled to seconds.
    elseif SD_scale_information == 1
        ERR = ERR/sqrt(60);
    end

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

    output_gravity_diff.stationinfo.filename = pad(input_file,100);
    output_gravity_diff.stationinfo.measurement_date = char(dtime_new(1));
    output_gravity_diff.stationinfo.measuredpoints = measured_points;

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

    output_gravity_diff.adjusted.differences = adjusted_parameters_new(1:end-(polynomial_degree_new+1));
    output_gravity_diff.adjusted.std = SD_theta_new(1:end-(polynomial_degree_new+1));
end