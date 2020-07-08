% Battery Analysis Script
% by: Conrad Rowling - 7/4/20
% Using MIT Data 

clc; clear; clf;
cellName = "Cell 4";
        % or "Cell" to look for at all cells
batteryType = "VTC6";
        % or "30Q"
analysis = "VOLTAGE";
        % or "IR"
stepInspect = false;
        % to look at a sample interrupt
showFIT = false;
        % to look at the fit 
save = false; 
        % to save the file

% input charge values to inspect the results from
% chg = [10 50 90];
% would be 10% 50% and 90%

chg = linspace(0,100);

%this outputs at every integer percentage


topFileLocation = 'MIT Motorsports Cell Data 2019\';
topDir = dir(topFileLocation);                      % directory
topNames = {topDir(:).name}';                       % get the names of all files from the directory

allCells = topNames(startsWith(topNames,cellName)); % search for ones that start with cellName
cellNum = fullfile(allCells);                       % full file location of search results


for j = 1:length(cellNum)
    
    cellDir = dir(strcat(topFileLocation,char(cellNum(j))));
    fileNames = {cellDir(:).name}';
    cellNames = fileNames(startsWith(fileNames, batteryType));
    t40Files = cellNames(contains(cellNames,"_40_"));
    t60Files = cellNames(contains(cellNames,"_60_"));
    t40CSV = fullfile(strcat(topFileLocation,char(cellNum(j))),t40Files);
    t60CSV = fullfile(strcat(topFileLocation,char(cellNum(j))),t60Files);
    
    fitDATA40 = [];
    fitSOC40 = [];
    fitDATA60 = [];
    fitSOC60 = [];
    

% Analysis:

        for i = 1:length(t40CSV)
            
            temp40 = importfile(char(t40CSV(i)));                                            %this means temporary not temperature
            [Bat(j,i).Raw.Temp40.DATA, Bat(j,i).Raw.Temp40.SOC] ...
                = peakFilter1(temp40.Amps,temp40.Volts,temp40.Times, analysis);                          
            fitDATA40 = vertcat(fitDATA40, Bat(j,i).Raw.Temp40.DATA);
            fitSOC40 = vertcat(fitSOC40, Bat(j,i).Raw.Temp40.SOC);
        end
        for k = 1:length(t60CSV)
            temp60 = importfile(char(t60CSV(k)));                                            %this means temporary not temperature
            [Bat(j,k).Raw.Temp60.DATA, Bat(j,k).Raw.Temp60.SOC] ...
                = peakFilter1(temp60.Amps, temp60.Volts, temp60.Times, analysis);
            fitDATA60 = vertcat(fitDATA60, Bat(j,k).Raw.Temp60.DATA);
            fitSOC60 = vertcat(fitSOC60, Bat(j,k).Raw.Temp60.SOC); 
            
        end 
        
    [FITcurve(j).Temp40.fit, FITcurve(j).Temp40.gof] = GENERATEFIT(fitSOC40, fitDATA40, batteryType, analysis);
    [FITcurve(j).Temp60.fit, FITcurve(j).Temp60.gof] = GENERATEFIT(fitSOC60, fitDATA60, batteryType, analysis);
  

% Fitting Data
 
    if showFIT
        %To display the fits relative to the data if desired
        figure(j)
        plot(FITcurve(j).Temp40.fit,fitSOC40, fitDATA40)
        legend(analysis, 'fit', 'Location', 'NorthEast', 'Interpreter', 'none' );
        % Label axes
        xlabel( 'S.O.C (%)', 'Interpreter', 'none' );
        ylabel( analysis + ' (40 degrees)', 'Interpreter', 'none' );
        grid on        
        plot(FITcurve(j).Temp60.fit,fitSOC60, fitDATA60)
        legend(analysis, 'fit', 'Location', 'NorthEast', 'Interpreter', 'none' );
        % Label axes
        xlabel( 'S.O.C (%)', 'Interpreter', 'none' );
        ylabel( analysis + ' (60 degrees)', 'Interpreter', 'none' );
        grid on        
    end
    
    fitDATA40 = [];
    fitSOC40 = [];
    fitDATA60 = [];
    fitSOC60 = [];
end

%Bat :
%   Cell 1
%   Cell 10
%   Cell 100
%   Cell 2
%   Cell 3
%    .
%    .
%    .
%   Cell 9


% Inspecting Interrupts

if stepInspect == true
    subplot(2,1,1)
    plot(0:0.1:2.5 ,temp40.Amps(3970:3995)), ylabel("Current (A)");
    subplot(2,1,2)
    plot(0:0.1:2.5 ,temp40.Volts(3970:3995)), ylabel ("Voltage (V)"), xlabel("Times (s)");
end

% Processing Results

Results.raw.temp40=[];
Results.raw.temp60=[];

for i = 1:length(cellNum) 
  Results.raw.temp40 =  horzcat(Results.raw.temp40, FITcurve(i).Temp40.fit(chg));
  Results.raw.temp60 =  horzcat(Results.raw.temp60, FITcurve(i).Temp60.fit(chg));
end

Results.temp40.mean = mean(Results.raw.temp40,2);
Results.temp40.dev = std(Results.raw.temp40,0,2);
       
Results.temp60.mean = mean(Results.raw.temp60,2);
Results.temp60.dev = std(Results.raw.temp60,0,2);


% Object Creation

if save
    addpath( 'C:\Users\...' );
    name = batteryType + '_' + analysis +'_SOC';
    switch analysis
        case "IR"
            RESULTS = InternalResistance( 'FE8', Results, batteryType);
        case "VOLTAGE"
            RESULTS = VoltageAtCharge( 'FE8', Results, batteryType);
    end
    
    cd( 'C:\Users\...' )
    save( [RESULTS.Name, '.mat'], 'RESULTS' );
end

function [Data] = importfile(filename, dataLines)
    if nargin < 2
        dataLines = [7, Inf];
    end

    opts = delimitedTextImportOptions("NumVariables", 6);

    % Specify range and delimiter
    opts.DataLines = dataLines;
    opts.Delimiter = ",";

    % Specify column names and types
    opts.VariableNames = ["Times", "Volts", "Amps", "Var4", "Var5", "Var6"];
    opts.SelectedVariableNames = ["Times", "Volts", "Amps"];
    opts.VariableTypes = ["double", "double", "double", "string", "string", "string"];

    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";

    % Specify variable properties
    opts = setvaropts(opts, ["Var4", "Var5", "Var6"], "WhitespaceRule", "preserve");
    opts = setvaropts(opts, ["Var4", "Var5", "Var6"], "EmptyFieldRule", "auto");

    % Import the data
    Q14023 = readtable(filename, opts);
    
    % Convert to output type
    Data.Times = Q14023.Times;
    Data.Volts = Q14023.Volts;
    Data.Amps = Q14023.Amps;
end

function [DATA, SOC] = peakFilter1(i, v, time, select)
    di = diff(i);
    v2 = v;
    di(1:500) = [];
    v(1:500) = [];
   

    %finding the average with the zeros removed
    temp1 = di(di~=0);
    avgI = mean(temp1);
    
    % this is all resizing the data to be the same length:
    % cutting off initial & terminal noise 
    di(length(di)-400:length(di)) = [];
    v(length(v)-1) =[];
    v(length(v)-400:length(v)) = [];
    
    soc = 100 - cumsum([0; diff(time)].*i./10800.*100);
    fsoc = soc;
    soc(1:501) = [];
    soc(length(soc)-400:length(soc)) = [];
    
    Vselect = zeros(length(v), 1);
    dI = zeros(length(v), 1);
    dV = zeros(length(v),1);
    filter = zeros(length(v), 1);
    filterNot = ones(length(v2), 1);
    
    di(1:4) = 0;
    % this loop finds current interupts above a threshold (100 x avg)
    % then creates a voltage array with the values surrounding the peaks
    
    for i = 4:length(di)
        if (di(i) <= (50*avgI))
            di(i) = 0;
        elseif (di(i) > (50*avgI)) && (3 < i < length(di)-4)
            for j = -3:3
                Vselect(i + j) = v(i+j);
            end
        end
    end
    
    %this computes the total initial current change
    %and the voltage change around it
    %once it finds a peak it skips ahead to ignore subsequent changes
    
%      IR = [Vselect, di];
%      IR( ~any(IR,2), : ) = [];
    
    k = 4;
    while k  < length(di)
        sumdI = 0;
        if (di(k) ~= 0)
            filter(k) = 1;
            filterNot(500+k) = 0;
            for h = -20:20
                filterNot(k+h+500) = 0;
            end
            for j = -3:3 
                nextdI = di(k + j);
                sumdI = sumdI + nextdI;
            end 
            dV(k) = Vselect(k -3) - Vselect(k + 3);
            dI(k) = sumdI;
            k = k + 3;
        end
        k = k + 1;
    end
    
    fsoc = fsoc.*filterNot;
    VOLT = v2.*filterNot;
    fsoc = fsoc(fsoc~=0);
    VOLT = VOLT(VOLT~=0);
    
    soc = soc.*filter;
    SOC = soc(soc~=0);
    dV = dV(dV~=0);
    dI = dI(dI~=0);
    IR = dV./dI;
    
    if select == "VOLTAGE"
        SOC = fsoc;
        DATA = VOLT;
    else 
        DATA = IR;
    end
end

function [fitResult, gof] = GENERATEFIT(x, y, select1, select2)

    % Each of these different fits were created by analyzing the behavior of
    % one cell, using cftool and then used the same fit for all the other
    % cells. the fit is good. The plots can be inspected by checking
    % showFIT at the top of the script
    
    [xData, yData] = prepareCurveData( x, y );
    switch select1
        case "VTC6"
            switch select2
                case "IR"
%                     Set up fittype and options.
                    ft = fittype( 'smoothingspline' );
                    opts = fitoptions( 'Method', 'SmoothingSpline' );
                    opts.SmoothingParam = 20e-4;
%                     Fit model to data.
                    [fitResult, gof] = fit( xData, yData, ft, opts );

                case "VOLTAGE"
                    % Set up fittype and options.
                    ft = fittype( 'poly9' );
                    opts = fitoptions( 'Method', 'LinearLeastSquares' );
                    opts.Robust = 'LAR';
                    % Fit model to data.
                    [fitResult, gof] = fit( xData, yData, ft );                    
            end
        case "30Q"
            switch select2
                case "IR"
                    % Set up fittype and options.
                    ft = fittype( 'smoothingspline' );
                    opts = fitoptions( 'Method', 'SmoothingSpline' );
                    opts.SmoothingParam = 0.00165725505892051;
                    % Fit model to data.
                    [fitResult, gof] = fit( xData, yData, ft, opts );                    
                case "VOLTAGE"
                    ft = fittype( 'poly9' );
                    opts = fitoptions( 'Method', 'LinearLeastSquares' );
                    opts.Robust = 'LAR';
                    % Fit model to data.
                    [fitResult, gof] = fit( xData, yData, ft, 'Normalize', 'on' );
            end

    end
end

