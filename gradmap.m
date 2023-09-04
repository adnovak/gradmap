% GradMap - Gradient mapping tool, vypocet vertikalneho gradientu 
% Author: Ing. Adam Novak PhD.
% Pracovisko: Katedra Globalnej geodezie a Geoinformatiky & Geodeticky a Kartograficky ustav v Bratislave.
% Nastroj umoznuje vypocet gradientu tiazoveho zrychlenia v smere merania.



function gradmap(GUI_par, ...               % premenna ktora sa vyuziva na prepinanie medzi uzivatelskym rozhranim a davkovym spracovanim. Pri volani nastroja bez pouzitia uzivatelskeho rozhrania treba uviest 'Run'. [string]
    ...
    input_units_option, ...                 % vstupne jednotky merania vysky nad bodom '1' pre cm alebo '2' pre metre [double]
    ...                                 
    header_lines, ...                       % pocet riadkov hlavicky pre preskocenie [double]
    ...
    input_file, ...                         % cesta k vstupnemu suboru/ suborom v pripade davkoveho spracovania [string]
    ...
    plot_errors_option, ...                 % moznost vytvorit graficky vystup spracovania - '0' pre nie '1' pre ano [double]
    ...
    report_file)                            % cesta ku vystupnym datam - miesto a nazov suboru pre ulozenie reportu [string]

    if nargin == 0
        
% open GUI
    % Main window
        % color palettes        
        R1=0.9; G1=0.9; B1=0.9;
        R2=0.99; G2=0.99; B2=0.99;

        panel1lower_boundary = 0.52;
        panel1height = 0.45;
        panel2lower_boundary = 0.15;
        panel2height = 0.35;

    M = figure('units','pixels','numbertitle','off','name','GradMap - Vypocet Gradientu Tiazoveho Zrychlenia',...
        'color',[R1 G1 B1],'position',[250 100 280 280],'Resize','on',...
        'tag','Window','menubar','none');

 %______________________________________________________________________
        % PANEL 1 - vstupne udaje
	    p1 = uipanel(M,'Title','Vstupne Data','Units','normalized','position',[0.02 panel1lower_boundary 0.96 panel1height],...
        'backgroundcolor',[R1 G1 B1],'HighlightColor',[R2 G2 B2],'tag',...
        'Locpanel','FontName','Georgia','FontSize',10);

        % Panel na vyber suboru   
        uicontrol(p1,'Units','normalized','position',[0.02 0.67 0.3 0.25],...
                'Style','pushbutton','string','vybrat subor',...
                'tag','push_input_path','Callback','gradmap input_path','FontName','Trebuchet MS');

        % Vypis nazvu vybraneho suboru
        uicontrol(p1,'Units','normalized', 'Position',[0.32 0.6 0.45 0.25],...
            'backgroundcolor',[R1 G1 B1],'tag','show_local_path',...
            'Style','Text','string','','FontName','Trebuchet MS','FontSize',8);

        % Pocet riadkov hlavicky
        uicontrol(p1,'Units','normalized','Position',[0.74 0.4 0.15 0.2],...
                    'Style','Edit','tag','edit_pocet_riadkov',...
                    'string','34','backgroundcolor',[R2 G2 B2],...
                    'FontName','Trebuchet MS','FontName','Trebuchet MS','FontSize',8.5);

        % Pocet riadkov hlavicky text
        uicontrol(p1,'Units','normalized', 'Position',[0.01 0.37 0.5 0.2],...
                     'backgroundcolor',[R1 G1 B1],...
                     'Style','Text','string','pocet riadkov hlavicky:','FontName','Trebuchet MS','FontSize',9);

        % Vyber jednotiek meranej vysky text
        uicontrol(p1,'Units','normalized', 'Position',[0.01 0.09 0.59 0.2],...
                     'backgroundcolor',[R1 G1 B1],...
                     'Style','Text','string','vyska merana v jednotkach:','FontName','Trebuchet MS','FontSize',9);

        % Vyber jednotiek meranej vysky
        uicontrol(p1,'Units','normalized','position',[0.74 0.1 0.15 0.2],...
                    'Style','Popupmenu','tag','units_option',...
                    'string','cm|m','value',1,'BackgroundColor','white','FontName','Trebuchet MS','FontSize',8.5);


% ===== PANEL 2 - Vystupne udaje - dodatocne informacie
	    p2 = uipanel(M,'Title','Vystupne udaje','Units','normalized','position',[0.02 panel2lower_boundary 0.96 panel2height],...
        'backgroundcolor',[R1 G1 B1],'HighlightColor',[R2 G2 B2],'tag',...
        'Locpanel','FontName','Georgia','FontSize',10);

        % Nazov a cesta k suboru reportu - vyber
        uicontrol(p2,'Units','normalized','position',[0.02 0.51 0.3 0.32],...
                    'Style','Pushbutton','units','characters',...
                    'string','vybrat subor','FontName','Trebuchet MS','UserData','[]',...
                    'tag','push_report_file_name','Callback','gradmap report_filename');

        % Tlacidlo pre ulozenie grafickych vystupov spracovania
        uicontrol(p2,'Units','normalized', 'Position',[0.77 0.19 0.09 0.2],...
                    'BackgroundColor',[R1 G1 B1],...
                    'Style','Checkbox','tag','check_graphics',...
                    'string','','value',0);

        % Ulozenie grafickych vystupov spracovania text
        uicontrol(p2,'Units','normalized', 'Position',[0.02 0.135 0.5 0.25],...
                     'backgroundcolor',[R1 G1 B1],...
                     'Style','Text','string','ulozit graficky vystup:',...
                     'FontName','Trebuchet MS','FontSize',9);

        % Vypocet tlacidlo
	    uicontrol('Units','normalized','position',[0.25 0.035 0.19 0.09],...
        'style','pushbutton','string','Vypocet','FontName','Trebuchet MS','Callback','gradmap Run');

        % Zavriet tlacidlo
	    uicontrol('Units','normalized','position',[0.6 0.035 0.19 0.09],...
        'Style','pushbutton','string','Zavriet','FontName','Trebuchet MS','Callback','gradmap Close'); 

    else
        switch GUI_par

            % klinutie na ikonku vstupnych dat ---------------------------------------
            case 'input_path' 
                    [data_filename,data_path]=uigetfile('*.*','Vyber subor z merania');
                        if data_filename == 0
                            fprintf('subor nebol vybrany. \n')
                        else
                            % write local data filename
                            data = fullfile(data_path,data_filename);
                            set(findobj('tag','show_local_path'),'string',data_filename, 'FontSize',8)
                            % save filename 
                            set(findobj('tag','edit_pocet_riadkov'),'userdata',data);
                        end

            % klinutie na ikonku vystupnych dat ---------------------------------
            case 'report_filename'
                [outname,outpath] = uiputfile('*.*');
                        if outname == 0 & outpath == 0 
                                        fprintf('Vytvorenie suboru pre zapis reportu. \n')
                                        outfile = fullfile(pwd,'output');
                                        clear outpath
                                        outname = 'output';
                        elseif outname == 0
                                        outname = 'output';
                                        outfile = fullfile(outpath,outname);
                        else
                                        outfile = fullfile(outpath,outname);
                        end

                                    set(findobj('tag','push_report_file_name'),'userdata',outfile);

            % klinutie na zaciatok vypoctu ---------------------------------
            case 'Run' 

                if nargin == 1 % pre pracu s GUI
                GUI = 1;
                else
                GUI = 0; % pre pracu s command line
                end
                
                % PRACA s GUI
                if GUI == 1 

                input_units_option = get(findobj('tag','units_option'),'value');
                header_lines = str2double(get(findobj('tag','edit_pocet_riadkov'),'string'));
                input_file =  get(findobj('tag','edit_pocet_riadkov'),'userdata');
                plot_errors_option = get(findobj('tag','check_graphics'),'value');
                report_file = get(findobj('tag','push_report_file_name'),'userdata');

                % Volanie z prikazoveho riadku
                elseif GUI == 0
                
                input_units_option = input_units_option;
                header_lines = header_lines;
                input_file = input_file;
                plot_errors_option = plot_errors_option;
                report_file = report_file;
                end

                % Zaciatok Vypoctu

                % nacitanie suboru
                fileID = fopen(input_file);
                % citanie dat
                filedata = textscan (fileID, '%f%f%f%f%f%f%f%f%f%f%f%9s%f%f%f%s', 'Delimiter', '', 'WhiteSpace', '', 'headerLines', header_lines);
                % apriori stredna chyba pristroja CG5 - 5 mikrogalov (double)
                SD00 = 5; % v mikrogaloch
                
                % informacia o meranom bode
                points = string(filedata{2});
                % urcenie unikatnych bodov (string)
                uniquepoints = string(unique(points,'stable'));
                if length(uniquepoints)>2
                    fprintf('Subor obsahuje merania z viac ako dvoch bodov - skontroluj subor s meraniami ci neobsahuje chybny popis bodu. \n')
                else
                end

                % casova numericka informacia - dn (datenum)
                dn = filedata{13};
                % casova informacia - dtime (datetime)
                dtime = datetime(dn,'ConvertFrom','datenum');
                
                % informacia o vyske senzora v cm - prevedena na metre. Senzor sa nachadza
                % 21.1 cm pod hornou hranou gravimetra, ktorej vyska sa uvadza v zapisniku.
                % Vyska hornej hrany sa uvadza nad znackou bodu.

                if input_units_option == 1
                    vyska = (filedata{3} - 21.1 )/100;
                elseif input_units_option == 2
                    vyska = (filedata{3} - 0.211 );
                end
                % merane gravimetricke data - prevedenie na mikrogaly.
                grav = filedata{4}*1000;
               
                % Metoda najm. stvorcov
                n0 = length(points); % pocet riadkov matice planu
                k = length(uniquepoints); % pocet meranych bodov
                
                % stupen polynomu zaciatocny - spracovanim sa urci vysledny stupen polynomu
                % ale startovaci je kvadraticky
                stupen_polynomu = 2;
                
                % prva cast matice planu suvisiaca s meranymi bodmi
                for i = 1:k
                ind = find(points == uniquepoints(i));
                    A(ind,i) = 1; A(~ind,i) = 0;
                    % urcenie priemernej vysky urovni - predpoklad je ze vyska urovni sa
                    % nemeni, ale +- 1 mm.
                    vyska_urovni(i,1) = mean(vyska(ind));
                end
                % cast matica planu suvisiaca s chodom - zohladnuje casovu informacia merani
                A(:,k+1) = 1;
                for i = k+2:k+1+stupen_polynomu;
                   A(:,i) = (dn - dn(1)).^(i -(k+1));
                end
                % regularizacia matice planu odstranenim prveho merania - fixovanie
                % merani na zaciatocnu (spodnu) uroven.
                A(:,1)= [];
                
                % vytvorenie kovariancnej matice pouzitim meranych presnosti a ich
                % vzajomnych vah.
                ERR = filedata{5}*1000;
                % vahy
                weight = mean(ERR)./ERR;
                % vahova matica
                P = diag(weight);
                % kofaktorova matica a kovariancna matica
                Q = P^-1; C = (SD00^2)*Q;
                
                % Metoda najmensich stvorcov odhad
                odhadnute_parametre = (A'/C*A)\A'/C*grav;
                % opravy meranych hodnot
                v = (A*odhadnute_parametre) - grav;
                % odhad jednotkovej strednej chyby
                SD0 = sqrt((v'*inv(C)*v)/(n0-k-2-stupen_polynomu));
                % kovariancna matica odhadnutych parametrov
                C_theta = (SD0^2)*inv(A'*inv(C)*A);
                % stredne chyby odhadnutych parametrov
                SD_theta = sqrt(diag(C_theta));

                % koeficienty chodu
                drift_koef = odhadnute_parametre(end-stupen_polynomu:end);
                % cast matice planu urcujuca chod
                AA = A(:,end-stupen_polynomu:end);
                % transportacny drift
                res_drift = AA*drift_koef;
                % test odhadu pridanim oprav
                test = res_drift + v;
                
                %%  testovanie odlahlych merani
                % testovacia statistika urcena ako 3 nasobok stadnardnej odchylky pre hladinu
                % vynamnosti 0.05.
                % index odlahlych merani.
                index_e = find(abs(v)>=SD00*3);
                
                % statisticky test parametrov druheho linearneho modelu
                testovacia_statistika = odhadnute_parametre(end)/SD_theta(end);
                % urcenie vyznamnosti kvadratickeho chodu
                if abs(testovacia_statistika) < 2 % honota 2 zodpoveda minimalnemu poctu merani 30 ~ 35, ktory je zabezpeceny hodinovym meranim
                    stupen_polynomu_novy = 1;
                    fprintf('použitie linearnej aproximácie chodu gravimetra na základe štatistického testu\n')
                else
                    stupen_polynomu_novy = 2;
                    fprintf('použitie kvadratickej aproximácie chodu gravimetra na základe štatistického testu\n')
                end
                
                %% outlier removal
                grav(index_e) = [];
                dn(index_e) = [];
                points(index_e) = [];
                ERR(index_e) = [];
                
                n = length(points);
                clear A AA C Q v C_theta

                %% reprocessing without outliers
                for i = 1:k;
                ind = find(points == uniquepoints(i));
                    A(ind,i) = 1; A(~ind,i) = 0;
                end
                % the not so useful part of Jacobi's matrix
                A(:,k+1) = 1;
                for i = k+2:k+1+stupen_polynomu_novy;
                   A(:,i) = (dn - dn(1)).^(i -(k+1));
                end
                
                A(:,1)=[];
                
                weight= mean(ERR)./ERR;
                P = diag(weight);
                Q = P^-1; C = (SD00^2)*Q;
                
                odhadnute_parametre_nove = (A'/C*A)\A'/C*grav;
                v = (A*odhadnute_parametre_nove) - grav;
                SD0_new = sqrt((v'*inv(C)*v)/(n-k-2-stupen_polynomu_novy));           
                C_theta = (SD0_new^2)*inv(A'*inv(C)*A);                   
                SD_theta_new = sqrt(diag(C_theta));
                
                drift_koef2 = odhadnute_parametre_nove(end-stupen_polynomu_novy:end);
                AA = A(:,end-stupen_polynomu_novy:end);
                res_drift_novy = AA*drift_koef2;
                
                % casova informacia - dtime (datetime)
                dtime_new = datetime(dn,'ConvertFrom','datenum');
                
                Wzz(1) = odhadnute_parametre(1)/abs(vyska_urovni(2) - vyska_urovni(1));
                Wzz(2) = odhadnute_parametre_nove(1)/abs(vyska_urovni(2) - vyska_urovni(1));
                sigma_Wzz(1) = sqrt((SD_theta(1)/abs(vyska_urovni(2) - vyska_urovni(1)))^2);
                sigma_Wzz(2) = sqrt((SD_theta_new(1)/abs(vyska_urovni(2) - vyska_urovni(1)))^2);
                priemerna_vyska = (vyska_urovni(2) + vyska_urovni(1))/2;

                % vystupna cast - vytvorenie suboru
                
                % hlavicka s dodatocnymi informaciami
                line1 = ['Nazov suboru pouziteho v spracovani: ', input_file];
                line2 = ['Merany bod: ',pad(num2str(uniquepoints(1,1),'%9.4f'),10)];
                line3 = ['Datum merania: ',datestr(dtime(1))];
                line4 = ['Pocet vykonanych merani: ',pad(num2str(n0,'%3.0f'),10)];
                line5 = ['Pocet vylucenych merani: ',pad(num2str(n0 - n,'%3.0f'),10)];
                line6 = ['Stupen aproximacie chodu: ',pad(num2str(stupen_polynomu_novy,'%1.0f'),10)];
                line7 = 'Jednotky gradientu: mikroGal/m';
                line8 = 'priemerna vyska, gradient, stredna chyba';
                header = {line1; line2; line3; line4; line5; line6; line7; line8};

                fid = fopen(strcat(report_file,'.txt'),'w');
                fprintf(fid,'%s\n',header{1:end,1});
                fprintf(fid,'%f,%f,%f',priemerna_vyska,Wzz(2),sigma_Wzz(2));
                fclose(fid);

                % vykreslenie obrazkov
                if plot_errors_option == 1
                    F = figure;
                    hold on
                    plot(dtime,res_drift - mean(res_drift),'k','LineWidth',0.8);
                    scatter(dtime,test- mean(res_drift_novy),10,'b','filled');
                    scatter(dtime(index_e),test(index_e)- mean(res_drift_novy),10,'r','filled');
                    plot(dtime_new,res_drift_novy- mean(res_drift_novy),'--','LineWidth',1);

                    legend('pôvodný drift','vsetky merania','odlahle merania','drift po oprave','Location','best')
                    print(F,report_file(1:end),'-djpeg','-r400')
                else
                end

           % kliknutie na tlacidlo zavriet
            case 'Close'
               close all
        end    
    end
end