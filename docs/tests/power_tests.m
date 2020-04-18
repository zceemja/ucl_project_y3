% matrix of [shunt volt mean, shunt volt std, supply volt, supply std]
shunt=1.020;  %ohms
data = [
%     80.599e-3   49e-6     4.0162  2e-3      % Empty FPGA
    89.47e-3    36e-6     4.0243  2.214e-3  % Empty socket test
    89.849e-3   33.1e-6   4.026   6e-3      % OISC8 mult 16bit loop
    89.968e-3   35.6e-6   4.0222  2.47e-3   % RISC8 mult 16bit loop
];

I=data(:,1)*shunt;  % current vector
P=(data(:,3)-data(:,1)).*I;  % power in W
Pstd=data(:,2).*data(:,4);

xnames = {'Auxilary' 'OISC' 'RISC'};
x = categorical(xnames);
x = reordercats(x,xnames); 
bar(x,P)   

hold on
er = errorbar(x,P,-Pstd./2,+Pstd./2); 
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
grid on

