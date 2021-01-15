classdef BatteryData

   properties
      Vehicle
      Name              % Instance Name [str]
      Date              % Data Generated [yyyy-mm-dd_HH_MM]
      Notes             % Input & Output Summary [str]
      Type              % Which kind of battery was used
      
      Parameters        % What temperature
      
   end
   
   methods
        function [IR, IR_SOC, Voltage, V_SOC] = PeakFilter1(I, V, Time)
            Di = diff(I);
            V2 = V;
            Di(1:500) = [];
            V(1:500) = [];


            %finding the average with the zeros removed
            Temp1 = Di(Di~=0);
            AvgI = mean(Temp1);

            % this is all resizing the data to be the same length:
            % cutting off initial & terminal noise 
            Di(length(Di)-400:length(Di)) = [];
            V(length(V)-1) =[];
            V(length(V)-400:length(V)) = [];

            Soc = 100 - cumsum([0; diff(Time)].*I./10800.*100);
            Vsoc = Soc;
            Soc(1:501) = [];
            Soc(length(Soc)-400:length(Soc)) = [];

            Vselect = zeros(length(V), 1);
            dI = zeros(length(V), 1);
            dV = zeros(length(V),1);
            Filter = zeros(length(V), 1);
            FilterNot = ones(length(V2), 1);

            Di(1:4) = 0;
            % this loop finds current interupts above a threshold (100 x avg)
            % then creates a voltage array with the values surrounding the peaks

            for I = 4:length(Di)
                if (Di(I) <= (50*AvgI))
                    Di(I) = 0;
                elseif (Di(I) > (50*AvgI)) && (3 < I < length(Di)-4)
                    for j = -3:3
                        Vselect(I + j) = V(I+j);
                    end
                end
            end

            %this computes the total initial current change
            %and the voltage change around it
            %once it finds a peak it skips ahead to ignore subsequent changes

        %      IR = [Vselect, di];
        %      IR( ~any(IR,2), : ) = [];

            k = 4;
            while k  < length(Di)
                SumdI = 0;
                if (Di(k) ~= 0)
                    Filter(k) = 1;
                    FilterNot(500+k) = 0;
                    for h = -20:20
                        FilterNot(k+h+500) = 0;
                    end
                    for j = -3:3 
                        NextdI = Di(k + j);
                        SumdI = SumdI + NextdI;
                    end 
                    dV(k) = Vselect(k -3) - Vselect(k + 3);
                    dI(k) = SumdI;
                    k = k + 3;
                end
                k = k + 1;
            end

            Vsoc = Vsoc.*FilterNot;
            Voltage = V2.*FilterNot;
            Vsoc = Vsoc(Vsoc~=0);
            Voltage = Voltage(Voltage~=0);

            Soc = Soc.*Filter;
            IR_SOC = Soc(Soc~=0);
            dV = dV(dV~=0);
            dI = dI(dI~=0);
            IR = dV./dI;

            x = 0;
            V_Filter = zeros(length(Voltage));
            for r = 1:length(Voltage)
                if r - x > 200
                    V_Filter(r) = 1;
                    x = r;
                end
            end
            V_Filter(1) = 1;
            V_Filter(length(IR)-1) = 1;
            Voltage = V_Filter.*Voltage;
            V_SOC = V_Filter.*Vsoc;
            Voltage = Voltage(Voltage~=0);
            V_SOC = V_SOC(V_SOC~=0);
        end
        
        function Model = GprMdl(X, Name, Temp) 
            %Takes combined
            Sorted_X = sortrows(X);    
            Model = fitrgp(Sorted_X(:,1),Sorted_X(:,2),'PredictMethod',"exact");
            [pred,~,ci] = predict(Model,Sorted_X(:,1));
            figure();
            plot(Sorted_X(:,1),Sorted_X(:,2),'r.','DisplayName', append(Name,' points'));  
            hold on
            plot(Sorted_X(:,1),pred,'b','DisplayName','Prediction');
            plot(Sorted_X(:,1),ci(:,1),'c','DisplayName','Lower 95% Limit');
            plot(Sorted_X(:,1),ci(:,2),'k','DisplayName','Upper 95% Limit');
            legend('show','Location','Best');
            title(append(Name,' (',Temp,'C)'));
            shg;
        end
        
        function obj = BatteryData(Vehicle, Parameters, Type)
         
            if nargin == 3
                obj.Vehicle = Vehicle;
                obj.Date = datestr(now,'yyyy-mm-dd_HH_MM');
                obj.Type = char(Type);
                obj.Name = [Vehicle, '_Battery_Analysis_', obj.Type, '_', obj.Date];
                obj.Notes{1} = input('Please Note Primary Parameter Changes: \n', 's');
                obj.Parameters = Parameters;

            end
        end
    end
end