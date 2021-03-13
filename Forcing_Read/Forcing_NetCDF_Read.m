function BAforcing = Forcing_NetCDF_Read(prmname)

% Syntax
%
%       Forcing_NetCDF_Read(...)
% 
% Discription
%
%       The pupoose of this function is to read files from two sources,
%       including GEM-CaPA and RDRS and compare the basin-average from two
%       source and plot the differences.
%        
%
% Input 
%
%       prmname                 The input parameter files 
%
% Output      
% 
%                               series of plots                  
%
% Reference 
%       
%
% See also: 
%
% Author: Ala Bahrami       
%
% Created Date: 03/12/2021
%
%
%% Setting input 
    if (nargin == 0)
        prmname = 'forcing_list.txt';
    end 

    fid  = fopen(prmname);
    Info = textscan(fid, '%s %s');
    fclose(fid);

    n = length(Info{1,2});
    
%% file info
    finfo = cell(n,1);

    for i = 1 : n
          finfo{i} = ncinfo(char(Info{1,2}(i)));
    end
    
%% Assigning time 
    % check time GEM-CaPA 
    t1_s = datetime(2004, 09 , 1 , 6 , 0 , 0);
    t1_f = datetime(2017 ,09 , 1 , 5 , 0 , 0);
    timegem    = t1_s : hours(1) : t1_f;
    timegem_dl = t1_s : days(1) : t1_f;
     
    % RDRS
    t2_s = datetime(2000, 01 , 1 , 13 , 0 , 0);
    t2_f = datetime(2018 ,01 , 1 , 12 , 0 , 0);
    timerdrs    = t2_s : hours(1) : t2_f;
    timerdrs_dl = t2_s : days(1) : t2_f;
    timerdrs_mo = t2_s : calmonths(3) : t2_f;
    timerdrs_y  = t2_s : calyears(3) : t2_f;

    % time gaps 
    t3_s        = datetime(2000, 01 , 01 , 13 , 0 , 0);
    t3_f        = datetime(2004, 09 , 1 , 5 , 0 , 0);
    timegap     = t3_s : hours(1) : t3_f;
    p           = length(timegap);
    
    n1 = length(timerdrs);
    n2 = length(timegem);
    
%% reading variables 
    time = ncread(char(Info{1,2}(1)),finfo{1}.Variables(3).Name);
    lon = zeros(81,n);
    lat = zeros(64,n);

    for i = 1 : n
           lon(:,i) = ncread(char(Info{1,2}(i)),finfo{1}.Variables(1).Name);
           char(Info{1,2}(i));
           lat(:,i) = ncread(char(Info{1,2}(i)),finfo{1}.Variables(2).Name);
    end 

%% reading rank for basin average value
    %Todo : this part should called the function drainageread2()
    rank = dlmread('rank.txt');
    rank = flipud(rank);
    rank(rank ~= 0) = 1;
    rank(rank == 0) = NaN;
    
%% plot style 
    color ={[0.35 0.35 0.35],[0.850 0.325 0.0980],[0.055 0.310 0.620],...
                                 [0 0.48 0.070],'w'};
    lsty  =  {'-','--'}; 
    yl = {'Specific Humidity [kg kg^{-1}]', 'Longwave Radiation [W m^{-2}]',...
            'Surface Air Pressure [Pa]', 'Precipitation Rate [mm s^{-1}]',...
            'Shorwave Radiation [W m^{-2}]','Air Temperature [K]',...
            'Wind Speed [m s^{-1}]'};

%% output directory
    outdir = 'output\';

%% reading GEM-CaPA forcing and calculate basin average  
    BAforcing = struct([]);
    wt = waitbar(0,'Program is running');
    
    for j = 1 : 7
        
        waitbar(j/7, wt);    
        forc_gem = ncread(char(Info{1,2}(j)),finfo{j}.Variables(end).Name); 
        forc_gem_m = zeros(n2,1);

        % basin average
        for i = 1 : n2
            A = forc_gem(:,:,i)' .* rank;
            A(isnan(A)) = [];
            forc_gem_m(i)  = mean(A); 
            A = [];
        end 

        clear forc_gem;

        % calculate 24h average radiation
        m = n2 / 24; 
        forcgem_m_daily = reshape(forc_gem_m, 24, m);
        forcgem_m_daily = mean(forcgem_m_daily);

%% reading RDRS forcing and calculate basin average SW
        forc_rdrs = ncread(char(Info{1,2}(j+7)),finfo{j+7}.Variables(end).Name); 
        forc_rdrs_m = zeros(n1,1);

        % basin average
        for i = 1 : n1
            A = forc_rdrs(:,:,i)' .* rank;
            A(isnan(A)) = [];
            forc_rdrs_m(i)  = mean(A); 
            A = [];
        end 

        clear forc_rdrs;

        % calculate 24h average radiation
        m = n1 / 24; 
        forc_rdrs_m_daily = reshape(forc_rdrs_m, 24, m);
        forc_rdrs_m_daily = mean(forc_rdrs_m_daily);

%% compare two horly forcing 
        forcgem_m_ed (1 : p , 1)      = NaN;
        forcgem_m_ed (p+1 : p+n2, 1)  = forc_gem_m;
        forcgem_m_ed (p+n2+1 : n1, 1) = NaN;

        % hourly differnce 
        BAforcing(j).diff    = forcgem_m_ed - forc_rdrs_m;
        BAforcing(j).rdrsgem =  [forc_rdrs_m , forcgem_m_ed];

%% display the difference 
            if (j ==1)
                fig = figure ('units','normalized','outerposition',[0 0 1 1]);
            end
            subplot(4,2,j)
            if (j==7)
                subplot(4,2,[7 8])
            end 
            h = plot(timerdrs, BAforcing(j).diff,'DatetimeTickFormat' , 'yyyy-MMM');
            h.LineStyle =  lsty{1};
            h.LineWidth = 2;
            h.Color = color{1};
            grid on 

            % Axis Labels
            xlabel('\bf Time [hours]','FontSize',14,'FontName', 'Times New Roman');
            ylabel(yl{j},'FontSize',9,'FontName', 'Times New Roman');
            title('Basin Average Forcing difference : RDRS - GEM-CaPA','FontSize',14,...
                     'FontWeight','bold','FontName', 'Times New Roman')

            % Axis limit
            % xlimit
            xlim([timerdrs(1) timerdrs(end)])

            % Axis setting
            ax = gca; 
            set(ax , 'FontSize', 10,'FontWeight','bold','FontName', 'Times New Roman')
            ax.GridAlpha = 0.4;
            ax.GridColor = [0.65, 0.65, 0.65];
            ax.XTick = timerdrs_y;

%             h = legend(DataName{:});
%             h.Location = 'northwest'; 
%             h.FontSize = 14;
%             h.Orientation = 'horizontal';
%             h.EdgeColor = color{end};
            
    end 
    
    fs1 = strcat(outdir,'forcingdiff.fig');
    %fs2 = strcat(outdir,'imbalance.tif');
    fs2 = strcat(outdir,'forcingdiff.png');
    saveas(fig, fs1);
    saveas(fig, fs2);
    close(fig);
    close(wt)
end